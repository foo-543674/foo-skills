---
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---
/foo-skills:bootstrap

既存のプロジェクト (backend: Rust、frontend: TypeScript + pnpm) に bootstrap を進めていて、Phase 1-4 は終わっています。開発コマンドの入口は `./dev` (例: `./dev cargo test`) に決まっています。Phase 5 のうち、ローカルレビューゲート (git hook と Claude Code hook) と `.claude/settings.json` の hooks / permissions だけ設計してください。

前提:
- 私は普段、ai-box (Claude Code を動かすコンテナ。Node は入っているが Rust は入っていない) の中から AI に作業させています。devcontainer もあり、Rust と Node が入っています
- 私のホストには git と docker だけがあり、Node も Rust も入っていません
- リポジトリは public です

ファイルは書かず、hook の検査内容と、それぞれを何で実装しどこで動かすか、settings.json に入れる内容を示してください。
