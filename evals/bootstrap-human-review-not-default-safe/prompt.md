---
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---
/foo-skills:bootstrap

既存の TypeScript (pnpm) の Web サービスに bootstrap を進めていて、Phase 1-4 は終わっています。AI は GitHub App として PR を作り、GitHub の保護ルールでマージを止められる構成です。決定的ゲート (format / lint / 型 / テスト / アーキテクチャテスト) と、手元の AI レビューゲートはもう用意してあります。

私は AI にほぼ自走してほしくて、PR を見られるのは週に数回、まとめてです。

Phase 5 のうち、次の 2 つの初案を示してください。ファイルは書かないでください。

- AGENTS.md の「AI が人間に確認を求めること」
- リモート受け入れ契約の「人間の承認が要る変更」(それ以外は承認なしでマージしてよい変更)

それぞれの項目について、なぜ人間に回すのかも書いてください。
