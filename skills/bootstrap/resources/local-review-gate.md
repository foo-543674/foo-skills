# ローカルレビューゲートの設計基準

bootstrap が Phase 5 で生成する「commit / push の前にレビューを強制する仕組み」の設計基準。yaml やスクリプトの書き方 (How) ではなく、何をどこで止めるか (What / When) と、なぜその配置か (Why) を置く。

**リモート (GitHub Actions 等) の AI レビュー workflow は生成しない。** チーム開発を前提にしたリモートレビューは別途設計する (保留中)。レビューは開発者の手元で、commit と push の直前に走らせる。

## なぜ手元か

- フィードバックループの階層 (philosophy/development-values) では、遅い側のループは防壁であって 1 次フィードバックではない。リモートで AI レビューを回すと 1 ラウンド十数分 × 指摘数の往復になる。手元なら秒〜分で回り、指摘をその場で潰してから commit できる
- LLM レビューは非決定的。手元なら再実行が安く、ブレを運用者がその場で見られる。リモートでは「最後の 1 回」しか残らず、ブレが見えない
- 「レビューを通したか」を hook で **機構として強制** する。プロンプトで「commit 前にレビューして」と書くだけでは実装中に忘れられる (quality-standards の三層防御: Layer 1 ガイダンスは破れる)

## 2 層で構成する

| 層 | 発火点 | 誰にでも効くか | 検査内容 |
|---|---|---|---|
| **git hook** (pre-commit / pre-push) | `git commit` / `git push` の実行時 | AI ツールを問わず、人間の操作にも効く | 決定的ゲート (format / lint / 型チェック / テスト / アーキテクチャテスト) と、レビュー記録の存在確認 |
| **Claude Code PreToolUse hook** (`Bash` の `git commit` / `git push` にマッチ) | AI がコマンドを打つ直前 | Claude Code のみ | 同じ検査を、AI が読める形で差し戻す (exit 2 + stderr で「code-reviewer を走らせてから再実行」と伝える) |

git hook が本体で、Claude Code hook はその結果を AI に説明する層。git hook だけでもゲートは成立する。Claude Code hook だけにすると、他の AI ツールや人間の操作をすり抜ける。

### 発火点ごとの役割

| 発火点 | 決定的ゲート | AI レビューの対象 | 目的 |
|---|---|---|---|
| pre-commit | format / lint / 型チェック (staged 分) | staged diff | 小さい差分をその場で直す。コミットはフィードバックループの単位 |
| pre-push | テスト / アーキテクチャテスト / 関連文書の突き合わせ | base ブランチとの差分全体 | コミットをまたぐ設計上の問題 (責務の散らばり、命名の揺れ) を PR にする前に拾う |

決定的ゲートの中身は AGENTS.md「タスク種別ごとの最小チェックセット」から導出する。手元で機械的に見つかるものを AI レビューに見つけさせない (速い側から潰す)。

## レビュー記録

- レビューは `.claude/agents/code-reviewer.md` (Phase 3 で生成) が行い、**対象 diff のハッシュ・判定 (Critical / Important / Minor の件数)・実行時刻** をリポジトリ外 (例: `.git/` 配下) に記録する。追跡対象にしない
- hook は「現在の diff に対応する記録があり、Critical が 0 か」を見る。**記録が無い = レビューしていない = 止める**。「指摘なし」と「レビュー未実施」を外形で区別できる形にする
- 記録は diff ごとに 1 つ。diff が変わればレビューし直す (修正後に再レビューせず commit する経路を塞ぐ)
- Critical は止める。Important は直すか「直さない理由」をコミットメッセージ本文に残す。Minor は任意

## 迂回の禁止

hook は迂回できてしまうので、迂回経路を機構と規約の両方で塞ぐ:

- `.claude/settings.json` の deny に `git commit --no-verify` / `git commit -n` / `git push --no-verify` / `git config core.hooksPath` を入れる (bootstrap SKILL Phase 5 step 3 の方針と同じ「セッションを壊さない・ゲートを外さない」観点)
- レビュー記録の手書き・改変を AGENTS.md で禁止する。記録を書けるのは code-reviewer だけ
- hook 自体を「失敗するから」と弱める修正は禁止。hook のステップには `# DO NOT REMOVE OR WEAKEN:` で始まるコメントを付け、存在意義 (レビュー未実施を成功扱いしない) を書き残す。後続セッションが「失敗の原因はこのステップ」と誤診して外した前例がある

## 非決定性の扱い

- レビュー結果の冒頭に「LLM ベースで非決定的。再実行で別の指摘が出る可能性がある」を必ず出す
- 同じ diff への再レビューは安いので、判断に迷う指摘は 1 回再実行して残るか見る。残らない指摘に時間を使わない
- 同じカテゴリの指摘が 2 回続いたら全件スイープ (philosophy/development-values)。レビューを繰り返して 1 件ずつ潰さない

## 生成時の判断

- git hook の管理方法 (lefthook / husky / pre-commit / 言語標準の仕組み) は技術スタックから AI が選ぶ。条件は「clone 直後に追加 install なしで有効になる」こと (Phase 5 受け入れ基準「書ける」「止まる」)
- 所要時間: pre-commit は秒〜1 分、pre-push は数分以内を目安にする。超えるなら決定的ゲートの分割 (staged 分だけ / 変更範囲だけ) を先に検討し、AI レビューの省略を検討しない
- 他の AI ツール (Copilot / Cursor / Gemini CLI) 向けには、派生生成する指示ファイルに「hook に止められたら code-reviewer 相当のレビューを行い、記録を残してから再実行する」を含める。Claude Code hook が無くても git hook が止めるので、規約は同じ
