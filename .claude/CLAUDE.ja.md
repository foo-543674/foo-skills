# foo-skills リポジトリ

foo-543674 のエンジニアリング哲学に基づく AI 自走コンテキストジェネレータ。

## 基本思想

**このプラグインは「種」であって「ツール」ではない。**

プラグインはプロジェクトの中に AI 自走コンテキストを生成する。生成後はプラグインがなくても、Claude Code / Copilot / Cursor 等どの AI ツールでも動く。

- `philosophy/` と `perspectives/` は **原料** (作り手の価値観と品質基準)
- `skills/bootstrap/` は **エンジン** (原料をプロジェクト固有のコンテキストにコンパイルする)
- プラグインの成果物は **プロジェクト側に生成されたもの** であり、プラグイン自体ではない

## リポジトリ構造

```
foo-skills/
├── .claude-plugin/
│   └── plugin.json                # プラグインマニフェスト
├── .claude/
│   ├── CLAUDE.md                  # 開発者向け (英語)
│   └── CLAUDE.ja.md              # 開発者向け (日本語・このファイル)
├── CLAUDE.md                      # 利用者向け
├── PROPOSAL-v2.md                 # v2 設計企画書
├── philosophy/                    # 原料: 価値観・判断基準
│   ├── core-principles.md         #   語彙定義義務、逃げの禁止、捨てやすさ
│   ├── technology-choices.md      #   静的型付け優先、関数型寄り、技術選定基準
│   ├── quality-standards.md       #   製品品質 vs 技術品質、三層防御
│   └── development-values.md      #   バーチカルスライス、テストファースト、0→0.1 / 99.9→100
├── perspectives/                  # 原料: 品質レンズ (20 ファイル)
│   ├── architecture.md            #   営みの起源、レイヤー定義、依存方向
│   ├── api-design.md              #   契約の明確性、HTTP ステータスセマンティクス
│   └── ...                        #   (他 18 観点)
└── skills/
    └── bootstrap/                 # エンジン: プロジェクトに AI コンテキストを生成
        ├── SKILL.md
        └── resources/
            ├── context-template.md
            └── checklist.md
```

## 編集ルール

### philosophy/ ファイル

- **What/When/Why のみ** をエンコードする。How は書かない (AI が知っている)
- これらは作り手の価値観であり、一般的なベストプラクティスではない
- ここの変更は、今後 bootstrap で生成されるすべてのプロジェクトに影響する

### perspectives/ ファイル

- 各ファイルは **設計ガイダンスとしてもコードレビュー観点としても** 使える二重用途
- 構造: 「重視すること」→「判断基準」→「アンチパターン」→「品質チェックポイント」
- 手順やテンプレートは含めない
- 各ファイル 120 行以内

### skills/bootstrap/

- このプラグイン唯一のスキル
- プロジェクト固有のコンテキスト (CLAUDE.md, エージェント, アーキテクチャテスト, ツール横断ファイル) を生成する
- philosophy/ と perspectives/ を原料として参照する
- 技術インフラの How は含まない (AI が自身の知識から導出する)

## フィードバック反映

philosophy や perspectives の内容についてフィードバックを受けた場合:

1. 対象ファイルを修正する
2. フィードバックが汎用ルールなら、この CLAUDE.md にも追記する
3. 既存の他ファイルが同じルールに違反していないか確認し、修正する
