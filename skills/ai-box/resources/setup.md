# ai-box セットアップ手順

`<slug>` は GitHub App の slug (App 設定ページの URL `github.com/settings/apps/<slug>` の部分)。

## 1. App の権限を設定する (ブラウザ)

`https://github.com/settings/apps/<slug>/permissions` を開き、Repository permissions を次のとおりにして保存する。

| 権限 | 設定 |
|---|---|
| Metadata | Read-only (自動) |
| Contents | Read and write |
| Pull requests | Read and write |
| Issues | Read and write |
| Actions | Read-only |
| Checks | Read-only |
| Commit statuses | Read-only |
| Workflows | Read and write (CODEOWNERS で人間の承認を必須にする前提) |
| Administration / Secrets / Variables / Environments / その他 | No access |

Account permissions はすべて No access。

## 2. 検証用リポジトリを作り、App をそこにだけインストールする

ホストのターミナル (あなたの認証) で:

```bash
# gh のバージョンに依存しないよう API で作る (auto_init で README 付きの main ができる)
gh api -X POST user/repos -f name=ai-box-sandbox -F private=true -F auto_init=true --jq .full_name
gh api repos/<owner>/ai-box-sandbox --jq .default_branch   # main であること
```

private リポジトリは GitHub Free だと ruleset・ブランチ保護が使えない。ここでの検証は「App の権限が絞られているか」までで、マージを止められるかは確かめられない。

`https://github.com/settings/apps/<slug>/installations` → Install → **Only select repositories** → `ai-box-sandbox` だけを選ぶ。
foo-skills と ai-box 自身のリポジトリには、保護設定が整うまでインストールしない。

インストール後に開くページの URL `https://github.com/settings/installations/<数字>` の数字が **Installation ID**。
**App ID** は `https://github.com/settings/apps/<slug>` の General に表示されている。

## 3. 秘密鍵を置く

`https://github.com/settings/apps/<slug>` の一番下 → **Generate a private key**。Windows の Downloads に `.pem` が保存される。

```bash
ls /mnt/c/Users/*/Downloads/*.private-key.pem          # ファイル名を確認
install -m 600 /mnt/c/Users/<Windowsユーザー>/Downloads/<slug>.<日付>.private-key.pem ~/ai-box/secrets/app-private-key.pem
rm /mnt/c/Users/<Windowsユーザー>/Downloads/<slug>.<日付>.private-key.pem   # 元ファイルを消す
```

## 4. Claude のトークンを発行する

**Claude Code の会話の中 (`!` 付き) ではなく、自分のターミナルで** 実行する。表示されたトークンを控える。

```bash
claude setup-token
```

## 5. secrets/.env を作る

値がシェル履歴に残らないよう `read` で入力する。

```bash
cd ~/ai-box/secrets
read -rp 'App ID: ' APP_ID
read -rp 'Installation ID: ' INST_ID
read -rsp 'Claude token: ' CC_TOKEN; echo
( umask 077; printf 'GH_APP_ID=%s\nGH_APP_INSTALLATION_ID=%s\nCLAUDE_CODE_OAUTH_TOKEN=%s\n' "$APP_ID" "$INST_ID" "$CC_TOKEN" > .env )
unset APP_ID INST_ID CC_TOKEN
ls -l ~/ai-box/secrets                                   # 2 ファイルとも -rw------- であること
```

## 6. 初期化と確認

```bash
ai-box seed          # ホストの Claude 設定から、許可した非秘密の項目だけをコンテナへ
ai-box codex-login   # 表示された URL とコードでログイン (1 回だけ)
ai-box check; echo "exit=$?"
```

`check` の期待結果: すべての行が `ok:` で、`exit=0`。`NG:` が 1 つでもあれば非 0 で終わる。

- `repositories` に出るのは、App をインストールしたリポジトリ (ここでは `<owner>/ai-box-sandbox`) だけ
- `bot identity` は `<slug>[bot] <数字+<slug>[bot]@users.noreply.github.com>`
- `project containers` の 4 行がすべて `ok:` (箱に `CAP_SYS_ADMIN` がなく、seccomp が効いたまま、Podman が名前空間を作れる、ストレージ設定が効いている)

## 7. 実際に bot として PR を作れるか

```bash
ai-box shell <owner>/ai-box-sandbox
```

コンテナ内で:

```bash
git switch -c ai-box-smoke
echo smoke > smoke.txt && git add smoke.txt && git commit -m "ai-box smoke test"
git push -u origin ai-box-smoke
gh pr create --base main --fill
gh api -X PATCH repos/<owner>/ai-box-sandbox -f description=x   # 403 Resource not accessible by integration になること (Administration なし)
exit
```

PR のページで、作成者とコミットの author が `<slug>[bot]` になっていることを確認する。

続けて、プロジェクトのコマンドが開発イメージの中で動くこと (箱に言語ツールが入っていないこと) を確かめる:

```bash
ai-box shell
which cargo || echo "no cargo in the box"       # 箱には入っていないこと
mkdir -p ~/work/podman-smoke && cd ~/work/podman-smoke
podman run --rm -v "$PWD":/work -w /work docker.io/library/rust:1-slim \
  sh -c "cargo new --quiet hello && cd hello && cargo run --quiet"   # Hello, world!
ls -ln hello                                     # 所有者が 1000 (箱の node)
cd && rm -rf ~/work/podman-smoke && exit
```

## 8. Claude Code とプラグイン

```bash
ai-box claude <owner>/ai-box-sandbox
```

起動後、ログインを求められないこと、`/plugin` で foo-skills などホストと同じプラグインが入っていることを確認する。

## 9. 結果を返す

次を Claude に貼る (トークンや鍵は含まれない):

- `ai-box check` の出力
- 手順 7 の Podman で `Hello, world!` が出たか
- 手順 7 の PR の URL と、設定変更が 403 (Resource not accessible by integration) だったか
- 手順 8 でログイン不要だったか、プラグインが入っていたか
