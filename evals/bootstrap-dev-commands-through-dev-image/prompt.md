---
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---
/foo-skills:bootstrap

既存の Rust (cargo workspace) のプロジェクトに bootstrap を進めていて、Phase 1-4 は終わっています。Phase 5 のうち「開発コマンド」の部分だけ設計してください。

前提:
- 私も AI も ai-box (Claude Code / Codex を動かすコンテナ) の中から作業します。ホストにも ai-box にも Rust は入っていません
- テスト・lint・format・ビルドのコマンドを AGENTS.md・git hook・CI で使います

ファイルは書かず、AGENTS.md の「開発コマンド」に載せる内容と、その実行の仕組みを示してください。
