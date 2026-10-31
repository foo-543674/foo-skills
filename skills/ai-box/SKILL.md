---
name: ai-box
description: Claude Code / Codex を、GitHub に GitHub App (AI 専用の別主体) としてしか触れないコンテナで動かす実行環境 ai-box を端末に構築・更新・移行する。「AI をオーナーの認証から切り離したい」「ai-box を作って」「別の端末で ai-box を使いたい」「端末を引っ越す」ときに使う。`/foo-skills:ai-box` で起動。
---

# ai-box — AI をオーナーの認証から切り離す実行環境

端末に、AI 用のコンテナ環境 `~/ai-box/` を構築する。コンテナの中の Claude Code / Codex は、GitHub に **権限を絞った GitHub App としてだけ** 触れ、オーナーの gh トークン・SSH 鍵・ssh-agent には届かない。

## Why: なぜ必要か

リモートの受け入れ判定で AI のマージを止められるかは、置き場所ではなく AI の資格情報で決まる (`bootstrap/resources/remote-acceptance.md`)。AI がオーナーと同じ OS ユーザーで動いていれば、AI はオーナーの認証を使って ruleset を外したり、CODEOWNERS の承認をしたりできる。ai-box はその前提を端末の側で作る。

## このスキルが How を持つ理由

このプラグインは原則として How を置かない。ai-box は例外で、検証済みの実装 (`resources/box/`) をそのまま配る。

- AI にオーナーの認証を渡してしまう誤り (ssh-agent の転送、設定ディレクトリの書き込み可能なマウント等) は、導出を少し間違えるだけで静かに入り、動作には現れない
- 技術スタックで形が変わらないので、毎回導出させる利点がない

実装を変えるときは、下の「破ってはいけない条件」を保ち、`ai-box check` と `resources/setup.md` の手順 6〜8 を通してから反映する。

## 破ってはいけない条件

- ホストの `~/.claude`・`~/.codex`・作業中のリポジトリを **マウントしない**。書き込み可能なら、コンテナの AI が書いた hook や `.git/hooks` がオーナーの認証でホスト上で動く。読み取り専用でも、設定ファイルに書かれた環境変数・認証ヘッダー・MCP の資格情報が読める
- 設定は **許可した非秘密の項目だけ** を抜き出して渡す (`settings.json` の `model` / `enabledPlugins` / `extraKnownMarketplaces`)。元の設定ファイルは箱に入れない。`CLAUDE.md` は指示文としてそのまま渡すので、秘密を書かない
- ssh-agent・`~/.ssh`・gh の `hosts.yml`・docker.sock をコンテナに入れない。VS Code Dev Containers は既定で ssh-agent と git 認証を転送するので使わない
- コンテナ内の gh と git は App のトークンだけを使う。App の情報がなければ失敗させ、別の認証に切り替えない
- **ai-box 専用の App を使う。** 箱の中の AI は秘密鍵を読めるので、Installation ID の指定に関係なく、App のすべてのインストール先に App の全権限で届く。インストール先と権限の全体が「AI に渡してよい範囲」になるように保つ
- App に Administration・Checks / Commit statuses の write・Secrets / Variables / Environments を与えない。ruleset の bypass に App を入れない
- ai-box の置き場所 (と、それを管理するリポジトリがあればそれ) に App をインストールしない。AI が自分の箱を書き換えられる
- AI が作業するリポジトリはコンテナ内で App の権限で clone する。オーナーとのやり取りは PR だけ
- 秘密鍵・トークンは `~/ai-box/secrets/` (権限 700 / 600) に置き、どのリポジトリにも Docker のビルドコンテキストにも入れない (`.dockerignore`)
- 言語のツールチェーン (cargo / node のパッケージ / go 等) を箱のイメージに入れない。プロジェクトのコマンドは箱の中の rootless Podman で、プロジェクトの開発イメージの中で動かす (下記)
- 箱のコンテナに `privileged`・`cap_add: SYS_ADMIN`・`seccomp=unconfined` を付けない。Podman のために緩めるのは `seccomp.json` に足したシステムコールだけ

箱の中の AI が、読める鍵やトークンを意図的にリポジトリや外部へ持ち出すことは、この構成では機構的に防げない。被害は App の権限とインストール先の範囲に限られ、鍵を失効すれば止められる。`ai-box check` が確かめるのは、表示している場所にオーナーの資格情報がないことまでで、それ以外の場所に無いことは保証しない。

## プロジェクトのコマンドを動かす仕組み

箱の中にはプロジェクトの言語ツールがない。AI は `cargo test` 等を直接叩かず、プロジェクトが用意した入口 (bootstrap Phase 5 の「開発コマンドの入口」) を通して、開発イメージの中で動かす。入口が `podman` を見つければ箱の中の Podman で、オーナーの端末では `docker` で動く。

箱の中の Podman は次の形で動かす。いずれも実機 (Docker 27.2.0 / WSL2 カーネル 6.18) で確かめた結果に基づく。

| 決めたこと | 理由 (観測した事実) |
|---|---|
| subuid を割り当てない単一 UID モード (コンテナ内の root = 箱の node) | 通常の rootless Podman は `newuidmap` が uid_map を書く。setuid root の `newuidmap` は名前空間の作成者 (node) と euid が違うため、カーネル (`kernel/user_namespace.c` の `map_write`) が親の名前空間での `CAP_SYS_ADMIN` を要求し、Docker の既定では `write to uid_map failed: Operation not permitted` になる。作成者が自分の uid 1 つだけを割り当てるマッピングは特権なしで書ける (`new_idmap_permitted`) |
| `seccomp.json` = Docker 標準プロファイル (moby v27.2.0、Apache-2.0) + `clone` `unshare` `setns` `mount` `umount2` `pivot_root` `sethostname` 新マウント API `keyctl` | 標準プロファイルは名前空間作成を `CAP_SYS_ADMIN` 持ちにしか許さず、`unshare` が `Operation not permitted`。`keyctl` がないと crun の `create keyring` が失敗する。`unconfined` は `bpf` `io_uring` `userfaultfd` 等まで開けるので使わない |
| ストレージは vfs + `ignore_chown_errors`。設定は `~/.config/containers/` に entrypoint が毎回置く | 単一 UID では他 UID 所有のファイル (debian 系イメージの `/etc/gshadow` は gid 42) を chown できず、イメージの展開が `lchown ... invalid argument` で失敗する。rootless Podman はストレージオプションをユーザー側の設定ファイルからしか読まない (`/etc/containers/storage.conf` に置いたときは `podman info` の `graphOptions` が空で、同じ失敗が起きた) |
| ネットワークは箱と共有 (`netns = "host"`) | 箱には `/dev/net/tun` がなく、slirp4netns / pasta が使えない |

この構成で、AI が届くのは箱の中のファイルと箱のネットワークまで。ホストの Docker API には届かない。箱から出るにはカーネルの脆弱性が要るが、名前空間とマウントのシステムコールを開けた分、その攻撃面は既定の Docker より広い。

制約:

- 開発イメージは、root 以外の UID が所有するファイルを含むと正しく展開されないことがある (chown を無視するため)
- 単一 UID のため、ビルド中にユーザーを切り替える Dockerfile (apt の `_apt` 等) は箱の中でビルドできない可能性がある。プロジェクトの開発イメージは CI でビルドしてレジストリから取得する形を既定にする
- `podman` が出す `no subuid ranges found` と `"/" is not a shared mount` は単一 UID モードの想定どおりの警告

## 秘密情報の扱い

このスキルを実行する AI は、秘密情報の値に触れない。

- 秘密鍵の作成、`claude setup-token`、`secrets/.env` の作成はユーザーが自分のターミナルで行う。手順は `resources/setup.md` を示す
- 会話に貼らせない。`!` 付きで実行させない (出力が会話の記録に残る)
- 確認は `ai-box check` の出力 (値を含まない) で行う

## 手順

### 1. 前提を確かめる

- `docker` と `docker compose` が使えること
- 既に `~/ai-box/` があれば、`resources/box/` との差分を示し、上書きしてよいかをユーザーに確かめる。`secrets/` と Docker ボリューム (`ai-box_ai-home`) には触れない

### 2. 配置する

- `resources/box/` の中身を `~/ai-box/` にコピーし、`ai-box` と `bin/*` に実行権限を付ける
- `mkdir -m 700 ~/ai-box/secrets ~/ai-box/seed`、`env.example` を `secrets/` にも置く
- `~/.local/bin/ai-box` に `~/ai-box/ai-box` へのシンボリックリンクを張る (PATH に無ければ伝える)
- `ai-box build` でイメージを作る

### 3. ユーザーに渡す

`resources/setup.md` の手順 1〜5 (App の権限、検証用リポジトリへのインストール、秘密鍵、Claude トークン、`.env`) をユーザーに示す。`<owner>` と App の slug は、ユーザーの環境に合わせて書き換えて示す。ホスト側の gh のバージョンには依存しない手順にしてある。

### 4. 確かめる

ユーザーが手順 6 (`ai-box seed` / `ai-box codex-login`) を済ませたら、`ai-box check` を実行する。必須の検査が 1 つでも失敗すれば非 0 で終わるので、終了コードで判定する。続けて手順 7 (bot として PR を作れること、管理者の操作が `403 Resource not accessible by integration` になること) と手順 8 (Claude Code がログインなしで起動し、プラグインが入っていること) を確かめる。

### 5. マージを止められるかどうかを伝える

ai-box ができても、それだけで AI のマージを止められるとは限らない。対象リポジトリごとに次を伝える。

- ruleset・ブランチ保護が使えるか。GitHub Free の private リポジトリでは使えず、App の権限を絞っても base への直接 push や自分の PR のマージを止められない。その場合は PR に警告を出して後から気づけるようにするだけになる (`remote-acceptance.md`)
- マージを止めるための選択肢 (プランの変更、公開範囲の変更、組織のリポジトリを使う) と、その判断はユーザーのものであること。個人の private リポジトリなど、警告だけで足りる場合も多い

## 別の端末で使う・端末を移る

- **秘密鍵はコピーしない。** 端末ごとに App の設定ページで新しい鍵を発行する。手放す端末の鍵だけを失効できる
- Claude トークンも端末ごとに `claude setup-token` で発行する。App ID と Installation ID は同じ値でよい
- 新しい端末ではこのスキルを実行し、手順 3 以降を行う
- 古い端末を手放す前に、コンテナ内の clone に push していない変更がないか確かめる (`ai-box shell` で `git status` / `git log --branches --not --remotes`)。その後、その端末の鍵を App の設定から削除し、`docker volume rm ai-box_ai-home` と `~/ai-box/secrets/` の削除を行う

## 更新

このスキルを再実行すると、手順 1 で差分を示して `~/ai-box/` を更新する。Claude Code と Codex の更新は `ai-box build` (イメージの作り直し) で行う。
