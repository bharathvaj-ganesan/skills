---
name: resolve-pr-comments
description: Resolve (auto-close) all unresolved review comment threads on a GitHub pull request with the gh CLI, optionally filtered by author or outdated status, and optionally minimize top-level conversation comments. Use when the user asks to close, resolve, or clear PR comments/threads.
---

# Resolve PR Comments (gh)

Use this skill when the user asks to **close / resolve / clear / mark done** the comments on a PR.

## Requirements

- `gh` installed and authenticated (`gh auth status`) with write access to the repo
- Run inside the repo, or pass `-R OWNER/REPO`

## What "close" means on GitHub

- **Review comments** (inline on code) live in threads that can be **resolved**. The script resolves these.
- **Conversation comments** (top-level on the PR) cannot be resolved; they can only be **minimized** (hidden as "Resolved"). The script does this only with `--minimize-comments`.

## Workflow

1. Work out the PR: a number, URL, or branch from the user; otherwise the current branch's PR.
2. Preview first with `--dry-run` and show the user how many threads match, unless they already said to just do it.
3. Run for real and report the counts from the summary lines. If any failed, say so and show the failing lines.

## Script

`scripts/resolve-pr-comments.sh` (path relative to this skill's folder):

```sh
# current branch's PR, preview
bash scripts/resolve-pr-comments.sh --dry-run

# resolve every unresolved thread on PR 123
bash scripts/resolve-pr-comments.sh 123

# only threads started by a bot, only outdated ones
bash scripts/resolve-pr-comments.sh 123 --author coderabbitai --outdated-only

# also hide top-level conversation comments
bash scripts/resolve-pr-comments.sh https://github.com/acme/api/pull/42 --minimize-comments

# from outside the repo
bash scripts/resolve-pr-comments.sh 123 -R acme/api
```

Options:

| Flag | Effect |
| --- | --- |
| `--dry-run` | List matches; change nothing |
| `--author LOGIN` | Only threads/comments started by `LOGIN` (repeatable; bot logins without `[bot]`) |
| `--outdated-only` | Only threads GitHub marks outdated |
| `--minimize-comments` | Also minimize top-level PR comments as "Resolved" |
| `-R, --repo OWNER/REPO` | Target repo when not inside it |

Exit code is non-zero if any resolve/minimize call failed.

## Notes

- Resolving is reversible in the GitHub UI ("Unresolve conversation"); minimizing is reversible via "Unhide".
- Resolving needs write access; on forks or restricted repos the calls fail and are reported as `FAILED`.
- Don't resolve threads someone else is still discussing unless the user asked for all of them; offer `--author` to narrow it.
