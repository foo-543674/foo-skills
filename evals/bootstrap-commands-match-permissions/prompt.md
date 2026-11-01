---
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---
/foo-skills:bootstrap

既存の TypeScript (pnpm) のプロジェクトに bootstrap を進めていて、Phase 1-4 は終わっています。開発コマンドの入口は `./dev` (例: `./dev pnpm test`) に決まっています。Phase 5 のうち、`.claude/settings.json` の permissions と、AGENTS.md で AI のコマンド実行に関わる部分だけ設計してください。

私は AI に指示を出したら席を離れることが多いです。

ファイルは書かず、settings.json の allow / ask / deny の方針と主な中身、AGENTS.md に載せる内容を示してください。
