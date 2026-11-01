---
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---
/foo-skills:bootstrap

既存の TypeScript (pnpm) のプロジェクトに bootstrap を進めていて、Phase 1-4 は終わっています。AI は GitHub App として PR を作り、GitHub の保護ルールでマージを止められる構成です。CI は `frontend/package.json` の `scripts` (lint / test / arch:test) を呼んでいます。

方針が決まった後の作業で、私が PR ごとに承認するのがボトルネックになっています。依存の追加・更新の大半と、普通の機能の実装は、私の承認なしでマージされてよいと思っています。CI やルールを緩める変更は見たいです。

Phase 5 のうち、リモート受け入れ契約の「人間の承認なしでマージしてよい変更」の初案と、それを検証器がどう確かめるかを示してください。ファイルは書かないでください。
