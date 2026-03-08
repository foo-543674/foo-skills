---
name: setup-local-infra
description: ローカル開発用のインフラをコンテナで構築する。DB・キャッシュ・メッセージキュー等をdocker composeで用意し、コマンド一発で起動できる環境を作るときに使う。
---

# ローカルインフラ構築

開発・テストに必要なインフラ（DB、キャッシュ、メッセージキュー等）をコンテナで用意し、コマンド一発で起動・停止できる環境を作る。

技術品質の基盤。「自分のマシンでは動く」を全員のマシンで再現可能にする。

## プロセス

### 1. 必要なインフラの特定

**確認すべきこと**:
- アプリケーションが依存する外部サービス（DB, キャッシュ, キュー, メール等）
- 既存の docker-compose.yml の有無
- テスト実行に必要なインフラ（テスト用 DB 等）
- 各サービスのバージョン要件（本番環境と合わせる）

**最低限のインフラ構成例**:

| サービス | 用途 | イメージ例 |
|---------|------|-----------|
| DB | データ永続化 | postgres, mysql, mongo |
| キャッシュ | セッション、キャッシュ | redis, memcached |
| メールサーバー | メール送信テスト | mailhog, mailpit |
| オブジェクトストレージ | ファイルアップロードテスト | minio |

### 2. docker-compose.yml の作成

#### 2.1 基本構成

```yaml
# docker-compose.yml の構成イメージ
services:
  db:
    image: postgres:16
    ports:
      - "5432:5432"
    environment:
      POSTGRES_DB: app_development
      POSTGRES_USER: app
      POSTGRES_PASSWORD: password
    volumes:
      - db-data:/var/lib/postgresql/data
      - ./docker/db/init:/docker-entrypoint-initdb.d  # 初期化スクリプト
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U app"]
      interval: 5s
      timeout: 5s
      retries: 5

volumes:
  db-data:
```

**必須設計項目**:
- `healthcheck`: 各サービスの起動完了を検知できるようにする
- `volumes`: データの永続化（named volume）と初期化スクリプトの配置
- `ports`: ホスト側のポートが他プロジェクトと衝突しないか確認する
- `environment`: 接続情報は `.env.example` に記載し、アプリ側の設定と一致させる

#### 2.2 テスト用インフラ

テスト実行用に専用のインフラが必要な場合は、別プロファイルまたは別 compose ファイルで管理する。

```yaml
services:
  db-test:
    image: postgres:16
    ports:
      - "5433:5432"  # テスト用は別ポート
    environment:
      POSTGRES_DB: app_test
      POSTGRES_USER: app
      POSTGRES_PASSWORD: password
    # テスト用は volumes 不要（毎回クリーンな状態）
    tmpfs:
      - /var/lib/postgresql/data  # メモリ上で高速化
```

### 3. コマンド一発の起動・停止

Makefile またはスクリプトで、起動・停止・リセットをコマンド一発にする。

**必須コマンド**:

| コマンド | 動作 |
|---------|------|
| 起動 | コンテナ起動 + ヘルスチェック待機 + マイグレーション実行 |
| 停止 | コンテナ停止 |
| リセット | コンテナ停止 + データ削除 + 再起動 |
| ログ | コンテナのログ表示 |

**コマンドの実現方法**:
- `Makefile` が既にあればそこに追加する
- なければ `Makefile` を作成する（`make up`, `make down`, `make reset`）
- プロジェクトに npm scripts 等の慣習があればそれに従う

**起動コマンドの要件**:
- コンテナの起動だけでなく、ヘルスチェックの通過まで待つ
- DB の場合、マイグレーションの実行まで含める
- 初回実行時もリピート実行時も同じコマンドで動作する

### 4. 初期データ・マイグレーション

**マイグレーション**:
- アプリケーションのマイグレーションツール（Prisma, Alembic, ActiveRecord 等）を使う
- 起動コマンドにマイグレーション実行を含める

**シードデータ**:
- 開発用の初期データが必要な場合、シードスクリプトを用意する
- シードは冪等に設計する（何度実行しても同じ結果になる）

### 5. 環境変数の管理

```
.env.example    # リポジトリにコミットする。必要な環境変数の一覧と開発用デフォルト値
.env            # .gitignore に含める。各開発者のローカル設定
```

- `.env.example` に開発用のデフォルト値を記載する（本番シークレットは含めない）
- アプリケーションの接続設定が docker-compose の設定と一致していることを確認する
- `postCreateCommand` 等で `.env.example` から `.env` を自動生成する仕組みを検討する

### 6. 動作確認

- [ ] `make up`（または相当コマンド）でインフラが起動する
- [ ] ヘルスチェックが全サービスでパスする
- [ ] アプリケーションからインフラに接続できる
- [ ] テストがインフラを使って実行できる
- [ ] `make down` でクリーンに停止する
- [ ] `make reset` でデータを含めてリセットできる
- [ ] 別のプロジェクトとポートが衝突しない

## devcontainer との連携

devcontainer と組み合わせる場合、devcontainer.json の `dockerComposeFile` でこの docker-compose.yml を参照する。アプリケーションのコンテナと共に起動する構成にできる。

## よくあるアンチパターン

- **No Healthcheck**: ヘルスチェックがなく、DB 起動前にアプリが接続しようとして失敗する
- **Port Conflict**: ポート番号がハードコードされ、他プロジェクトと衝突する
- **Missing .env.example**: 環境変数の設定方法がドキュメントにしかなく、設定漏れが発生する
- **Manual Migration**: マイグレーションが手動で、実行し忘れてエラーになる
- **Production Image in Dev**: 本番用と異なるバージョンの DB イメージを使い、本番でのみ発生する問題を見逃す
- **Persistent Test Data**: テスト用 DB にデータが残り、テスト結果が前回の実行に依存する
