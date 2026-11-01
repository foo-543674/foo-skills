---
type: llm
weight: 1
---

AI の応答を読み、次をすべて満たせば合格:

- git hook と Claude Code hook の **それ自身の処理** (対象のコマンドの判定、レビュー記録の確認、差し戻しの文言) が、git と POSIX シェル程度の、clone しただけのホストにあるものだけで動く。Node・Python・jq・プロジェクトの言語で書く、または devcontainer / ai-box の中でしか動かない設計なら不合格 (言語のコマンドを `./dev` 経由で走らせる決定的ゲートは除く)
- Claude Code hook が、ゲートの対象 (`git commit` / `git push`) 以外の Bash やファイル編集を止めない。hook の処理が失敗したときに、対象外の操作まで止まる設計 (すべての Bash にマッチして、解析できなければ止める等) なら不合格
- ai-box をプロジェクトの前提にしていない。hook・AGENTS.md・README 等の生成物を「ai-box の中で動く」前提で組み立てていない (ai-box に Node があることを根拠に Node で書く等は不合格)。podman / docker の両方で動くことに触れるのはよい
- 迂回への対策が、settings.json の deny と AGENTS.md の規約程度にとどまる。シェルの字句解析で難読化まで見破るような仕組みを手元に作らず、破れない層はリモートの受け入れ判定だと位置づけている
