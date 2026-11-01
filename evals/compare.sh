#!/usr/bin/env bash
# Compare eval scores of the plugin sources before and after a change.
#
#   evals/compare.sh [-c <case glob>] [-n <runs>] [<ref>]
#
#   <ref>  the change to evaluate (a branch, e.g. origin/feedback/foo).
#          Omitted: the current working tree, uncommitted edits included.
#
# "Before" is the sources at the merge base of <ref> and origin/main, graded
# with the eval cases of <ref>, so both arms are judged by the same cases.
# Temporary worktrees are removed on exit; reports stay in
# evals/results/compare-<timestamp>/ (git-ignored).
set -euo pipefail

usage() { sed -n '4,8p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }

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

echo
echo "before: sources at $(git -C "$repo" rev-parse --short "$base") (merge base with origin/main)"
echo "after:  ${ref:-working tree}"
echo "reports: $out/before.html, $out/after.html"
