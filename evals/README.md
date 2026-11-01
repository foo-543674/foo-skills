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

ai-box の中の AI のシェルからは eval が動かない (子の `claude` がログインできない)。ホストで別の端末を開き、次の 1 行を貼る。checkout も作業用ディレクトリも要らない:

```bash
ai-box shell foo-543674/foo-skills -c 'git fetch -q origin && git show origin/main:evals/compare.sh | bash -s -- -c "bootstrap-*" origin/<PR のブランチ>'
```

修正前は「main から分かれた時点の原料 + PR の評価ケース」、修正後は「PR のブランチ」で、同じ事例を同じ回数 (`-n`、既定 3) ずつ流し、最後にケースごとの通過率と、修正後に落ちた基準とその理由を端末に出す。作業用の worktree は終了時に消える。JSON・HTML レポート・要約 (`summary.txt`) は ai-box の中の clone の `evals/results/compare-<日時>/` (git の管理外) に残り、同じ clone を使う AI のセッションからも読める。レポートは公開しない (`--no-publish`)。費用を抑えるため、プラグインなしの比較 (`--ablation`) は行わない。

ai-box の中で直接実行するなら `evals/compare.sh -c 'bootstrap-*' origin/<PR のブランチ>`。ブランチを省くと今の作業ツリー (未コミットの変更を含む) を修正後として比べる。
