---
type: llm
weight: 1
---

次をすべて満たせば合格:

- この指摘を採用している (consult はプラグイン内蔵スキルだが、skill-feedback の対象に含まれる)。「bootstrap の生成物ではないので対象外」と判定していたら不合格
- 改善すべき原料として `skills/consult/SKILL.md` (consult スキルの定義) を挙げている
- 確信度が confirmed または candidate のどちらかで、理由が書かれている
- 新しい `source:` ラベルを作ろうとしていない
