# foo-skills

プロジェクトに AI が自走するためのコンテキスト基盤を生成する [Claude Code プラグイン](https://docs.anthropic.com/en/docs/claude-code/plugins)。

## これは何か

このプラグインは「直接使う AI ツール」ではなく、**プロジェクトに AI 自走基盤を生成するジェネレータ**。

- `philosophy/` と `perspectives/` に私の価値観と品質基準が定義されている (原料)
- `bootstrap` スキルがそれらをプロジェクト固有のコンテキストに変換する (エンジン)
- 生成されたプロジェクトはプラグインなしでも動く (Claude Code / Copilot / Cursor 対応)

## セットアップ

```bash
# 1. marketplace として登録
/plugin marketplace add foo-543674/foo-skills

# 2. プラグインをインストール
/plugin install foo-skills@foo-skills
```

アンインストール:

```bash
/plugin uninstall foo-skills
```

## 使い方

```
/foo-skills:bootstrap
```

新規プロジェクトまたは既存プロジェクトで実行すると、対話を通じて以下を生成する:

| 生成物 | 説明 |
|--------|------|
| `CLAUDE.md` | プロジェクト固有のコンテキスト (原則、品質基準、判断委任範囲、コミット規約) |
| `.github/copilot-instructions.md` | Copilot 用コンテキスト |
| `.cursorrules` | Cursor 用コンテキスト |
| `.claude/agents/code-reviewer.md` | プロジェクト固有のレビューエージェント |
| `tests/arch/` | アーキテクチャテスト (依存方向、型漏出等を CI で自動検証) |
| devcontainer, CI, etc. | 技術インフラ (AI が自走で構築) |

## 構成

```
foo-skills/
├── philosophy/          私の価値観・判断基準 (4 files)
│   ├── core-principles    語彙定義義務、逃げの禁止、捨てやすさ
│   ├── technology-choices 静的型付け優先、関数型寄り
│   ├── quality-standards  製品品質 vs 技術品質、三層防御
│   └── development-values バーチカルスライス、テストファースト
│
├── perspectives/        品質レンズ (20 files)
│   ├── architecture       営みの起源、レイヤー定義、依存方向
│   ├── api-design         契約の明確性、ステータスセマンティクス
│   ├── data-modeling      ストレージ非依存、正規化判断
│   ├── component          4 Tier 分割、シグネチャ境界
│   ├── disposability      影響範囲のコントロール可能性
│   ├── testing            テスト価値マトリクス、境界値
│   ├── error-handling     Result/Either vs 例外
│   ├── security           入力は信頼しない、最小権限
│   ├── performance        N+1、計算量、計測してから最適化
│   ├── concurrency        共有データ保護、デッドロック防止
│   ├── naming             名前と動作の一致、概念語の統一
│   ├── readability        認知負荷の最小化、ネスト深度
│   ├── comments           Why を書く、prefix 規約
│   ├── variables          Immutable by default
│   ├── solid              SRP、DIP
│   ├── functional         Pure functions、高階関数
│   ├── type-design        Discriminated Union、Branded Type
│   ├── state-design       Boolean Explosion 防止
│   ├── dependency         依存追加の意識的判断
│   └── documentation      設計判断の記録
│
└── skills/bootstrap/    AI 自走基盤の生成器
```

## 参考

- [Claude Code Plugins ドキュメント](https://docs.anthropic.com/en/docs/claude-code/plugins)
- [PROPOSAL-v2.md](PROPOSAL-v2.md) — v2 設計企画書
