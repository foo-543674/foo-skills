---
type: llm
weight: 1
---

AI の応答を読み、次をすべて満たせば合格:

- Makefile の言語のコマンドを呼ぶターゲット (`db-migrate` / `db-prepare` / `api-generate` / `arch-test`) を、入口 (`./dev sqlx ...` / `./dev cargo ...` / `./dev pnpm ...` 等) を通す形に書き換える案になっている。Makefile に触れていない、または一部のターゲットを直接実行のまま残すなら不合格。`infra-up` の `docker compose` は言語のコマンドではないので、そのままでよい
- settings.json の deny (`cargo` 等) だけでは、Makefile のターゲットの中で走るコマンドを止められないことを踏まえている。deny があるから Makefile は大丈夫、とする説明なら不合格
- 変更後の確かめ方に、Makefile 等のタスクランナー・README・その他の手順で、入口を通らない言語のコマンドが残っていないかの全件検索 (または同等の確認) が含まれる
