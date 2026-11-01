# evals — 実際の失敗から作った評価用の事例

原料 (philosophy / perspectives / スキル定義) を直す前に、その原因になった失敗をここに事例として残し、直した後に同じ事例で良くなったかを比べる。指摘を受けるたびにルールを足すだけにしないため。

## 事例の条件

- **実際に起きた失敗から作る。** 各事例の `source.md` に出典 (Issue 番号、`skills/skill-feedback/resources/examples.md` の例番号、PR 番号) を書く。想像で作った事例は入れない
- 1 事例 = 1 つの失敗パターン。`prompt.md` に失敗が起きた状況、`graders/*.md` に期待する判断を書く
- Issue を作る・push するなど外部に作用する操作は、`allowed_tools` で許可しない

## 実行

```bash
claude plugin eval . --no-publish                 # 全事例。プラグインあり / なしを比べる
claude plugin eval . --case 'consult-*' --runs 1  # 一部だけ、1 回ずつ
```

LLM の出力は毎回揺れるので、1 回の結果で判断しない。原料を直す前と後で、同じ事例を同じ回数ずつ流して比べる。

### 直す前と後を比べる

```bash
evals/compare.sh -c 'bootstrap-*' origin/feedback/foo   # PR のブランチを、main から分かれた時点の原料と比べる
evals/compare.sh -c 'bootstrap-*'                      # 今の作業ツリー (未コミットの変更を含む) で比べる
```

修正前は「main から分かれた時点の原料 + 対象の版の評価ケース」、修正後は「対象の版」で、同じ事例を同じ回数 (`-n`、既定 3) ずつ流す。作業用の worktree は終了時に消え、レポートは `evals/results/compare-<日時>/` (git の管理外) に `before.html` / `after.html` として残る。費用を抑えるため、プラグインなしの比較 (`--ablation`) は行わない。
