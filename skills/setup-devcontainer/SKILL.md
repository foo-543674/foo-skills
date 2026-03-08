---
name: setup-devcontainer
description: コンテナベースの開発環境を構築する。新規リポジトリの devcontainer 設定、既存リポジトリの開発環境改善を行うときに使う。
---

# 開発環境構築（devcontainer）

コンテナベースの開発環境を構築し、開発者が clone 後すぐに開発を始められる状態を作る。

技術品質の基盤。製品コードを書く前に整備する。

## プロセス

### 1. 現状の確認

**既存リポジトリの場合**:
- `.devcontainer/` の有無
- `Dockerfile` / `docker-compose.yml` の有無
- 既存の開発環境セットアップ手順（README、Makefile 等）
- 使用言語・フレームワーク・ツールチェーン

**新規リポジトリの場合**:
- 使用予定の言語・フレームワーク
- 必要な外部ツール（linter, formatter, CLI 等）
- チームの IDE（VS Code 前提か、他 IDE も考慮するか）

### 2. devcontainer 設定の作成

#### 2.1 ベースイメージの選定

プロジェクトの技術スタックに合ったベースイメージを選ぶ。

**選定基準**:
- Microsoft 公式の devcontainer イメージがあればそれを優先する
- 複数言語が必要な場合は汎用イメージ + feature で追加する
- イメージサイズと起動速度のバランスを考慮する

#### 2.2 devcontainer.json の構成

```jsonc
// .devcontainer/devcontainer.json
{
  "name": "プロジェクト名",
  "image": "or dockerComposeFile + service",
  "features": {},
  "customizations": {
    "vscode": {
      "extensions": [],
      "settings": {}
    }
  },
  "forwardPorts": [],
  "postCreateCommand": "",
  "postStartCommand": ""
}
```

**必須検討項目**:
- `features`: 言語ランタイム、CLI ツール、共通ユーティリティ
- `extensions`: linter, formatter, 言語サポート、テストランナー
- `settings`: formatter on save, lint on save, 言語固有設定
- `forwardPorts`: アプリケーション、DB、管理画面等のポート
- `postCreateCommand`: 依存パッケージのインストール、初期セットアップ
- `postStartCommand`: 起動時に毎回必要な処理

#### 2.3 Dockerfile が必要な場合

ベースイメージ + features では足りない場合に Dockerfile を作成する。

**Dockerfile を作る基準**:
- システムパッケージの追加インストールが必要
- 特定バージョンのツールを固定したい
- マルチステージビルドで開発用ツールを含めたい

```
.devcontainer/
├── devcontainer.json
├── Dockerfile          # 必要な場合のみ
└── docker-compose.yml  # ローカルインフラが必要な場合
```

### 3. 開発ツールチェーンの統一

devcontainer 内で以下が統一されていることを確認する。

**必須ツール**:
- linter: コードスタイルの統一（ESLint, Ruff, clippy 等）
- formatter: フォーマットの統一（Prettier, Black, rustfmt 等）
- 型チェッカー: 型安全性の担保（tsc, mypy, cargo check 等）

**設定の配置**:
- linter / formatter の設定ファイルはリポジトリルートに置く
- devcontainer の settings で IDE が設定ファイルを自動認識するようにする
- 保存時の自動フォーマット・自動 lint を有効にする

### 4. 動作確認

devcontainer の構築後、以下を確認する。

- [ ] devcontainer がエラーなくビルド・起動できる
- [ ] 依存パッケージがインストール済みである
- [ ] linter / formatter が IDE 上で動作する
- [ ] テストが実行できる
- [ ] アプリケーションが起動できる（該当する場合）
- [ ] ポートフォワーディングが機能する（該当する場合）

## docker-compose との連携

ローカルインフラ（DB 等）が必要な場合は setup-local-infra スキルと連携する。devcontainer.json の `dockerComposeFile` で setup-local-infra が作成した `docker-compose.yml` を参照する構成にできる。

## よくあるアンチパターン

- **Fat Container**: 不要なツールを大量にインストールし、ビルドが遅い
- **Snowflake Environment**: devcontainer に入っていないツールを各開発者がローカルに追加し、環境差異が生まれる
- **Missing Formatter Config**: formatter が入っているが設定ファイルがなく、デフォルト設定で動作する（プロジェクトのスタイルと不一致）
- **No Post-Create Setup**: clone 後に手動で `npm install` 等が必要で、すぐに開発を始められない
