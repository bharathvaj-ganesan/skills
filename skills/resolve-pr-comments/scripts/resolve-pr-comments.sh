#!/usr/bin/env bash
# Resolve every unresolved review thread on a GitHub pull request using the gh CLI.
#
# Usage:
#   resolve-pr-comments.sh [PR] [--dry-run] [--author LOGIN] [--outdated-only] [--minimize-comments] [-R OWNER/REPO]
#
#   PR                   PR number, URL, or branch. Defaults to the PR for the current branch.
#   --dry-run            List what would be resolved; change nothing.
#   --author LOGIN       Only resolve threads started by LOGIN (repeatable).
#   --outdated-only      Only resolve threads GitHub marks as outdated.
#   --minimize-comments  Also hide top-level PR conversation comments as "Resolved"
#                        (those comments cannot be resolved, only minimized).
#   -R, --repo REPO      OWNER/REPO, when not running inside the repo.
#
# Requires: gh (authenticated, with write access to the repo).

set -euo pipefail

usage() { sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

pr_arg=""
dry_run=0
outdated_only=0
minimize=0
repo_flag=()
authors=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) dry_run=1 ;;
    --outdated-only) outdated_only=1 ;;
    --minimize-comments) minimize=1 ;;
    --author) authors+=("${2:?--author needs a login}"); shift ;;
    -R|--repo) repo_flag=(--repo "${2:?--repo needs OWNER/REPO}"); shift ;;
    -h|--help) usage 0 ;;
    -*) echo "Unknown option: $1" >&2; usage 1 ;;
    *) pr_arg="$1" ;;
  esac
  shift
done

command -v gh >/dev/null || { echo "gh CLI not found. Install: https://cli.github.com" >&2; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "gh is not authenticated. Run: gh auth login" >&2; exit 1; }

# Resolve PR -> owner, repo, number (works for number, URL, branch, or current branch).
pr_url=$(gh pr view ${pr_arg:+"$pr_arg"} ${repo_flag[@]+"${repo_flag[@]}"} --json url --jq .url)
if [[ ! "$pr_url" =~ github\.com/([^/]+)/([^/]+)/pull/([0-9]+) ]]; then
  echo "Could not parse PR URL: $pr_url" >&2; exit 1
fi
owner="${BASH_REMATCH[1]}"; name="${BASH_REMATCH[2]}"; number="${BASH_REMATCH[3]}"
echo "PR: $pr_url"

# Build a gh --jq filter for the unresolved threads we want.
author_json="[]"
if [[ ${#authors[@]} -gt 0 ]]; then
  author_json="[$(printf '"%s",' "${authors[@]}" | sed 's/,$//')]"
fi
thread_filter='.data.repository.pullRequest.reviewThreads.nodes[]
  | select(.isResolved | not)'
[[ $outdated_only -eq 1 ]] && thread_filter+=' | select(.isOutdated)'
thread_filter+=" | select(($author_json | length) == 0 or ((.comments.nodes[0].author.login // \"\") as \$a | $author_json | index(\$a)))"
thread_filter+=' | [.id, (.comments.nodes[0].author.login // "ghost"), (.path // "-"), ((.line // .originalLine // "") | tostring), (.comments.nodes[0].url // "")] | @tsv'

threads=$(gh api graphql --paginate \
  -F owner="$owner" -F name="$name" -F number="$number" \
  -f query='
query($owner: String!, $name: String!, $number: Int!, $endCursor: String) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $number) {
      reviewThreads(first: 100, after: $endCursor) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id isResolved isOutdated path line originalLine
          comments(first: 1) { nodes { author { login } url } }
        }
      }
    }
  }
}' --jq "$thread_filter")

resolved=0; failed=0; total=0
while IFS=$'\t' read -r id author path line url; do
  [[ -z "$id" ]] && continue
  total=$((total + 1))
  label="$path${line:+:$line} (@$author)"
  if [[ $dry_run -eq 1 ]]; then
    echo "  would resolve  $label  $url"
    continue
  fi
  if gh api graphql -f id="$id" -f query='
mutation($id: ID!) { resolveReviewThread(input: {threadId: $id}) { thread { isResolved } } }' >/dev/null 2>&1; then
    echo "  resolved       $label"
    resolved=$((resolved + 1))
  else
    echo "  FAILED         $label  $url" >&2
    failed=$((failed + 1))
  fi
done <<< "$threads"

echo "Review threads: $total unresolved matched, $resolved resolved, $failed failed"

if [[ $minimize -eq 1 ]]; then
  comment_filter='.data.repository.pullRequest.comments.nodes[] | select(.isMinimized | not)'
  comment_filter+=" | select(($author_json | length) == 0 or ((.author.login // \"\") as \$a | $author_json | index(\$a)))"
  comment_filter+=' | [.id, (.author.login // "ghost"), .url] | @tsv'

  comments=$(gh api graphql --paginate \
    -F owner="$owner" -F name="$name" -F number="$number" \
    -f query='
query($owner: String!, $name: String!, $number: Int!, $endCursor: String) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $number) {
      comments(first: 100, after: $endCursor) {
        pageInfo { hasNextPage endCursor }
        nodes { id isMinimized url author { login } }
      }
    }
  }
}' --jq "$comment_filter")

  m_total=0; m_done=0; m_failed=0
  while IFS=$'\t' read -r id author url; do
    [[ -z "$id" ]] && continue
    m_total=$((m_total + 1))
    if [[ $dry_run -eq 1 ]]; then
      echo "  would minimize @$author  $url"
      continue
    fi
    if gh api graphql -f id="$id" -f query='
mutation($id: ID!) { minimizeComment(input: {subjectId: $id, classifier: RESOLVED}) { minimizedComment { isMinimized } } }' >/dev/null 2>&1; then
      echo "  minimized      @$author  $url"
      m_done=$((m_done + 1))
    else
      echo "  FAILED         @$author  $url" >&2
      m_failed=$((m_failed + 1))
    fi
  done <<< "$comments"
  echo "Conversation comments: $m_total matched, $m_done minimized, $m_failed failed"
fi

[[ $dry_run -eq 1 ]] && echo "(dry run — nothing changed)"
[[ $failed -eq 0 && ${m_failed:-0} -eq 0 ]]
