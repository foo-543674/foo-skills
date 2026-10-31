---
type: llm
weight: 1
---

AI の応答を読み、次をすべて満たせば合格:

- `cargo` 等の言語のコマンドを、プロジェクトの開発イメージ (コンテナ) の中で走らせる設計になっている。AGENTS.md の開発コマンドが素の `cargo test` 等で、作業環境で直接実行する前提なら不合格
- ai-box やホストに Rust (rustup / cargo) を入れる案を出していない。「入っていなければインストールする」等のフォールバックも不合格
- 開発コマンド・git hook・CI が同じ入口 (例: `./dev cargo test`) を通る
- 入口が ai-box の中から動く手段 (Podman 等) を考慮している。docker.sock が前提で ai-box から動かない設計なら不合格
