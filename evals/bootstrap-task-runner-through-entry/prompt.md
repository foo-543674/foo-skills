---
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---
/foo-skills:bootstrap

既存のプロジェクト (backend: Rust + sqlx、frontend: TypeScript + pnpm) に bootstrap を進めていて、Phase 1-4 は終わっています。開発コマンドの入口として `./dev` (開発イメージの中でコマンドを走らせるスクリプト。例: `./dev cargo test`) を作りました。Phase 5 のうち、開発コマンドを入口に切り替える部分を進めてください。

リポジトリにはすでに次のものがあります:
- `AGENTS.md` (開発コマンドの表あり)
- `.githooks/pre-commit` / `pre-push`
- `.github/workflows/ci.yml`
- `.claude/settings.json`
- 次の `Makefile` (抜粋)

```makefile
.PHONY: infra-up
infra-up: ## Start local infra (MySQL dev/test) and wait until healthy
	docker compose up -d --wait

.PHONY: db-migrate
db-migrate: ## Apply migrations to the development DB
	cd backend && sqlx migrate run

.PHONY: db-prepare
db-prepare: ## Regenerate sqlx offline metadata
	cd backend && cargo sqlx prepare -- --tests

.PHONY: api-generate
api-generate: ## Regenerate TypeScript types from the OpenAPI schema
	cd frontend && pnpm run api:generate

.PHONY: arch-test
arch-test: ## Run architecture tests for both backend and frontend
	cd backend && cargo nextest run --test architecture --all-features --no-tests=pass
	cd frontend && pnpm run arch:test
```

ファイルは書かず、変更するファイルごとに何をどう変えるかと、変更後の確かめ方を示してください。
