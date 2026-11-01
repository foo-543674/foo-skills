# Known Pitfalls Registry

bootstrap 中に AI と人間の双方が参照する「既知の CI/Infra 落とし穴」レジストリ。技術インフラを組み立てるとき、踏み抜くと再現が難しい罠を症状ベースで記録する。

新しいプロジェクトで該当する技術 (CI、bot 連携、外部 action 等) を扱う場合は、対応するエントリの「症状」「回避策」「検出方法」を確認した上で構築する。エントリ追加の基準は「実際に踏んで解決した」こと。仮説段階のものは登録しない。

## CI/Infra Pitfalls

### devcontainer と手動 `docker compose` を同じ Compose プロジェクトに統合する

- **症状**: エディタの devcontainer とローカル実行 (手動 `docker compose up`) が同じポートを publish して衝突する。これを解消するために `.devcontainer/compose.yaml` に `name:` を明示して両者を 1 つの Compose プロジェクトに統合すると、片方から `docker compose down` を打った時点でもう片方 (ユーザーが作業中の devcontainer) が破棄される。衝突ではなく「開発環境とローカル実行は別物」という区別が消えている (philosophy/core-principles 逃げ J)
  - `up -d` も同種の危険を持つ: devcontainer CLI は override 込みの設定でコンテナを起動するため、素の compose ファイルから計算した config hash と稼働中コンテナのラベル (`com.docker.compose.config-hash`) が一致せず、`up -d` がコンテナを作り直す (実測済み)
  - devcontainer CLI は compose ファイルの `name:` を尊重する。「VS Code が独自の名前で上書きするから `name:` は無視される」は誤り (この誤った主張がコメントに断定形で残り、後続セッションの `down` の根拠になった — 逃げ G)
- **回避策**:
  - 開発環境とローカル実行は別の Compose プロジェクト (別ディレクトリ、または別 `name:`) にする。統合は最後の手段で、するなら ADR に 3 点 (理由 / 代替案 / 見直しトリガー) を残す
  - ポートを publish するのは片方だけ。競合解消は「分離を保ったまま競合点だけ動かす → 片方を止める → 統合」の順
  - Docker outside of Docker は devcontainer の `features` (`docker-outside-of-docker`) で入れる。ソケットの手動マウントはしない
  - `docker compose down` / `up` を `.claude/settings.json` の allow に入れない (bootstrap SKILL Phase 5 step 3)
- **検出方法**: `docker compose ls` で devcontainer と手動起動が同じプロジェクト名に見える。または AI が「検証用コンテナを停止した」と報告した直後にエディタとの接続が切れる
- **参考**: finance-simulator (foo-skills Issue #58 / #59 / #61)

### 言語のコマンドを作業環境で直接叩く (ai-box で「rust がない」)

- **症状**: ai-box で開発リポジトリを扱うと、AI が `cargo` 等を直接叩いて「コマンドがない」で止まる。AI はそこで箱へのインストールや別の実行方法を探し始める
- **原因**: 開発コマンドが素のコマンド (`cargo test`) で定義され、「言語ツールは作業環境に入れない」が原料に書かれていなかった。ai-box は docker.sock を持たないので、開発コンテナを起動する手段もなかった
- **回避策**:
  - 開発コマンドの入口 (例: `./dev cargo test`) を用意し、AGENTS.md・hook・CI をすべてそこに通す。入口は docker と podman の両方で動かす (bootstrap SKILL Phase 5)
  - `.claude/settings.json` で言語のコマンドの直接実行を deny する
  - 開発イメージは CI でビルドしてレジストリから取得する。ai-box の Podman は単一 UID のため、`apt-get` を含む Dockerfile を箱の中でビルドできない (`setgroups ... Operation not permitted`)
- **検出方法**: AGENTS.md の開発コマンドや git hook に、入口を通らない言語のコマンドがある。ai-box の中で開発コマンドを実行して `command not found` になる
- **参考**: foo-skills PR #86
- **再発: タスクランナーだけ取り残される**: AGENTS.md・hook・CI を入口に通した後も、Makefile のターゲット (`cd backend && sqlx migrate run`、`pnpm run api:generate` 等) が言語のコマンドを直接叩いたまま残り、オーナーが指摘するまで直らないことが多い (triary の Makefile は別のコミットで直した)。原料が入口を通す場所を「AGENTS.md・git hook・CI」とだけ挙げていた。settings.json は `make db-migrate` を allow しており、`cargo:*` の deny はターゲットの中の `cargo` を捕まえないので、ここでも気づけない。生成後に Makefile・justfile・`package.json` の scripts・README・devcontainer の lifecycle コマンドを全件検索する

### hook をプロジェクトの言語や AI の作業環境のランタイムで書く (ホストで push も Claude も動かない)

- **症状**: Node のないホストで clone すると `git commit` / `git push` が hook で失敗し、devcontainer を起動しないとリポジトリに触れない。同じホストの Claude Code は、Bash もファイル編集もすべて PreToolUse hook に止められ、動作確認の手伝いすらできない。docker があっても、`frontend/` に触れる commit はテキストの修正でも「frontend dependencies are missing; run '../dev pnpm install' ...」で止まる (ゲートが依存を自分で用意せず、準備不足で止めていた)
- **原因**: レビューゲートの本体を TypeScript で書き、git hook が作業環境の Node で実行していた。根拠は「ai-box と devcontainer が既に Node を持つ」で、オーナー個人の AI 用の環境をプロジェクトの前提にしていた。Claude Code hook はすべての Bash と Edit / Write にマッチし、入力の解析に `node` を使い、解析できなければ止めていた。迂回の検出にはシェルの字句解析器を自作していた
- **回避策**:
  - hook と入口それ自身は git と POSIX シェルで書く。言語のコマンドが要る決定的ゲートだけを入口経由で開発イメージに通す (philosophy/technology-choices「開発イメージに入れるもの、clone したままで動かすもの」)
  - Claude Code hook は対象外のツール呼び出しをすぐ通す。止めてよいのは `git commit` / `git push` だけ
  - ゲートが要る依存はゲート自身か入口が用意する。準備不足で止めない
  - 迂回対策は deny と AGENTS.md の規約にとどめる。破れない層はリモートの受け入れ判定 (local-review-gate.md「迂回の禁止」)
- **検出方法**: hook のスクリプトに `node` / `python` / `jq` 等の呼び出しがある。Node のないホストで clone して `git commit` を試す、または同じホストの Claude Code で `ls` を実行すると止まる
- **参考**: triary (foo-skills の、この項目を追加した PR)

### `anthropics/claude-code-action` + Copilot Coding Agent

- **症状**: Copilot Coding Agent が author の commit を pull_request event で processing するとき、`anthropics/claude-code-action@v1` が 2 段階で連続失敗する
  - 段階 1: Anthropic 側の App-token 交換が 401 (`User does not have write access`) — actor=`Copilot` (`[bot]` サフィックス無し) のため
  - 段階 2: github_token フォールバック後も action 内部の permission チェックで `octokit.repos.getCollaboratorPermissionLevel({ username: "Copilot" })` が 404 (`Copilot is not a user`)
- **回避策** (workflow yaml):
  - `claude_code_oauth_token: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}` だけでなく `github_token: ${{ secrets.GITHUB_TOKEN }}` も併せて渡す
  - `allowed_non_write_users: "Copilot"` を設定する
- **検出方法**: AI 自動レビュー workflow が pull_request event の actor=Copilot で連続失敗したログを観測した場合
- **参考**: triary commit `1d921e32` (github_token フォールバック追加), `b8c9a595` (allowed_non_write_users 追加)
