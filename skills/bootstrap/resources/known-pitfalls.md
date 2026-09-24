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

### `anthropics/claude-code-action` + Copilot Coding Agent

- **症状**: Copilot Coding Agent が author の commit を pull_request event で processing するとき、`anthropics/claude-code-action@v1` が 2 段階で連続失敗する
  - 段階 1: Anthropic 側の App-token 交換が 401 (`User does not have write access`) — actor=`Copilot` (`[bot]` サフィックス無し) のため
  - 段階 2: github_token フォールバック後も action 内部の permission チェックで `octokit.repos.getCollaboratorPermissionLevel({ username: "Copilot" })` が 404 (`Copilot is not a user`)
- **回避策** (workflow yaml):
  - `claude_code_oauth_token: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}` だけでなく `github_token: ${{ secrets.GITHUB_TOKEN }}` も併せて渡す
  - `allowed_non_write_users: "Copilot"` を設定する
- **検出方法**: AI 自動レビュー workflow が pull_request event の actor=Copilot で連続失敗したログを観測した場合
- **参考**: triary commit `1d921e32` (github_token フォールバック追加), `b8c9a595` (allowed_non_write_users 追加)
