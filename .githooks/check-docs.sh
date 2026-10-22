#!/bin/sh
# Docs-before-push check, shared by the pre-push hook and the GitHub workflow.
#   .githooks/check-docs.sh <rev-range...>   e.g. origin/playtest..HEAD
# Fails when the commits in the range change Classes/ but touch neither docs/ nor README.md,
# unless one of their messages has a "Docs: none (<reason>)" line.
[ $# -gt 0 ] || { echo "usage: check-docs.sh <rev-range...>"; exit 2; }

files=$(git log --format= --name-only "$@" | sort -u)
echo "$files" | grep -q '^Classes/' || exit 0
echo "$files" | grep -qE '^(docs/|README\.md$)' && exit 0
git log --format=%B "$@" | grep -qE '^Docs: none \(.+\)' && exit 0

echo "docs check: these commits change Classes/ but no docs:"
git log --oneline "$@"
echo
echo "Update docs/ARCHITECTURE.md or README.md in the same push, or add a line"
echo "'Docs: none (<reason>)' to the last commit message. Bypass once with git push --no-verify."
exit 1
