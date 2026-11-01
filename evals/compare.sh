#!/usr/bin/env bash
# Compare eval scores of the plugin sources before and after a change.
#
#   evals/compare.sh [-c <case glob>] [-n <runs>] [<ref>]
#
#   <ref>  the change to evaluate (a branch, e.g. origin/feedback/foo).
#          Omitted: the current working tree, uncommitted edits included.
#
# From the host, in one line (no checkout needed; the script is read from main):
#   ai-box shell foo-543674/foo-skills -c 'git fetch -q origin && git show origin/main:evals/compare.sh | bash -s -- -c "bootstrap-*" origin/<branch>'
#
# "Before" is the sources at the merge base of <ref> and origin/main, graded
# with the eval cases of <ref>, so both arms are judged by the same cases.
# Prints a per-case before / after table and the failed criteria of the
# after arm. Temporary worktrees are removed on exit; the JSON, HTML reports
# and the summary stay in evals/results/compare-<timestamp>/ (git-ignored).
set -euo pipefail

usage() { echo 'usage: evals/compare.sh [-c <case glob>] [-n <runs>] [<ref>]' >&2; exit 2; }

case_glob='*'
runs=3
while getopts 'c:n:h' opt; do
  case "$opt" in
    c) case_glob=$OPTARG ;;
    n) runs=$OPTARG ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))
[ $# -le 1 ] || usage
ref=${1:-}

repo=$(git rev-parse --show-toplevel)
out="$repo/evals/results/compare-$(date +%Y%m%d-%H%M%S)"
tmp=$(mktemp -d)

cleanup() {
  git -C "$repo" worktree list --porcelain \
    | awk -v t="$tmp" '$1 == "worktree" && index($2, t) == 1 { print $2 }' \
    | xargs -r -n1 git -C "$repo" worktree remove --force
  rm -rf "$tmp"
}
trap cleanup EXIT

git -C "$repo" fetch --quiet origin

# The "after" arm: a worktree of <ref>, or the current working tree.
if [ -n "$ref" ]; then
  after="$tmp/after"
  git -C "$repo" worktree add --quiet --detach "$after" "$ref"
  after_rev=$(git -C "$repo" rev-parse "$ref")
else
  after=$repo
  after_rev=HEAD
fi

base=$(git -C "$repo" merge-base "$after_rev" origin/main)
before="$tmp/before"
git -C "$repo" worktree add --quiet --detach "$before" "$base"
rm -rf "$before/evals"
cp -R "$after/evals" "$before/evals"
rm -rf "$before/evals/results"

mkdir -p "$out"

# Each arm keeps going when scores fall below the threshold (exit 1);
# any other failure stops the comparison.
run_arm() {
  local label=$1 target=$2 status=0
  echo "=== $label ($target) ==="
  claude plugin eval "$target" \
    --case "$case_glob" --runs "$runs" \
    --ablation none --no-publish --trust-plugin \
    --output-dir "$out/$label" --report "$out/$label.html" --json "$out/$label.json" \
    || status=$?
  [ "$status" -le 1 ] || { echo "eval failed for $label (exit $status)" >&2; exit "$status"; }
}

run_arm before "$before"
run_arm after "$after"

# Per-case pass rate (runs that met every criterion) and mean score, then the
# criteria the after arm failed with the judge's explanation.
summarize() {
  jq -r -n --slurpfile b "$out/before.json" --slurpfile a "$out/after.json" '
    def pad($w): . + (" " * ([$w - length, 1] | max));
    def rate: if . == null then "-" else "\(.aggregates.passRate * 100 | round)% (score \(.aggregates.score * 100 | round / 100))" end;
    def byname(f): f[0].cases | map({key: .name, value: .}) | from_entries;
    (byname($b)) as $bc | (byname($a)) as $ac
    | ([$ac | keys[] | length] + [4] | max + 2) as $w
    | ("case" | pad($w)) + ("before" | pad(24)) + "after",
      ($ac | keys[] as $k | ($k | pad($w)) + ($bc[$k] | rate | pad(24)) + ($ac[$k] | rate)),
      "",
      "failed in after:",
      ([$a[0].cases[] | .name as $n | .arms.with | to_entries[] | .key as $i
        | (if .value.error then "  \($n) run \($i + 1): error: \(.value.error)" else empty end),
          (.value.graders[] | select(.passed | not)
            | "  \($n) run \($i + 1): \(.name): \(.explanation | gsub("\\s+"; " ") | .[0:300])")]
       | if length == 0 then "  (none)" else .[] end)
  '
  echo
  echo "before: sources at $(git -C "$repo" rev-parse --short "$base") (merge base with origin/main), cases of ${ref:-working tree}"
  echo "after:  ${ref:-working tree}"
  echo "files:  $out/"
}

echo
summarize | tee "$out/summary.txt"
