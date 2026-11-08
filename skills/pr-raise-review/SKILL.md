---
name: pr-raise-review
description: Unified GitHub PR workflow skill that can either raise a PR from the current branch or review an existing PR using gh CLI, with structured summaries, test evidence, and optional review submission.
---

# PR Raise + Review (gh)

Use this skill when the user asks to **create/draft a PR** or **review/audit/approve/request-changes** on a PR.

## Requirements

- Run inside a git repository
- `gh` installed and authenticated (`gh auth status`)
- GitHub remote configured
- Network access to GitHub

## Mode detection

Pick mode from user intent:

- **Raise mode**: “raise PR”, “create PR”, “draft PR summary”, “open PR for this branch”
- **Review mode**: “review PR”, “audit PR”, “approve PR”, “request changes”

If unclear, ask one short clarifying question.

---

## Raise mode workflow

1. Determine current branch and base branch.
   - Default base: `develop` unless user specifies otherwise.
2. Check for existing PR for the head branch.
   - If exists, return URL and avoid duplicate unless user asks explicitly.
3. Inspect complete branch changes (not just last commit):
   - `git log --oneline <base>..HEAD`
   - `git diff --stat <base>...HEAD`
   - `git diff <base>...HEAD`
4. Infer core behavior change, risk/compatibility impact, config/API changes, and test surface.
5. Gather verification evidence.
   - Run relevant checks when practical.
   - Never mark checks as passed without evidence in current context.
6. Draft PR title and body.
7. Push branch if needed.
8. Create PR:
   - `gh pr create --base <base> --head <branch> --title <title> --body-file <file>`
9. Return PR URL.

### Raise mode title format

```text
<type>(<scope>): <concise imperative description>
```

- Types: `feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `build`, `ci`
- Keep concise (preferably <= 72 chars)
- Describe principal outcome (not files/branch/ticket dump)

### Raise mode body format

```markdown
## Summary
- <principal behavior or capability>
- <important implementation detail>
- <compatibility/fallback/security/ops note if relevant>

## <Change-specific section (optional)>
- <important reviewer context>

## Test plan
- [x] <check actually run and passed>
- [ ] <pending or unverified check>
```

Rules:
- Keep behavior-focused and specific.
- Add sections only when they improve reviewer understanding.
- Do not paste raw commit/file lists.
- No AI attribution/footer.

---

## Review mode workflow

1. Collect PR context (PR number/url/branch, or current branch PR):

```bash
~/.pi/agent/skills/review-pr-gh/scripts/collect-pr-review-context.sh [pr-number-or-url-or-branch]
```

2. Read generated artifacts:
   - `summary.md`
   - `diff.patch`
   - `files.json`
   - `reviews.json`
   - `comments.json`
   - `checks.json`
3. Review for correctness, edge cases, regressions, security/privacy, tests, performance/reliability, maintainability.
4. Return findings ordered by severity with file + line references when possible.
5. If asked to submit review, post via:

```bash
gh pr review [pr] --comment --body-file /tmp/pr-review.md
gh pr review [pr] --request-changes --body-file /tmp/pr-review.md
gh pr review [pr] --approve --body-file /tmp/pr-review.md
```

- Use `--request-changes` only for blocking issues.
- Use `--approve` only when explicitly requested, or no blocking issues remain and user asked to approve.

### Review output template

```markdown
## PR Review

### Findings
- [High] `path/to/file.ext:123` — Problem, impact, suggested fix.
- [Medium] ...

### Questions
- ...

### Summary
- Overall assessment and residual risks.
```

If no issues, say so clearly and mention unverified checks/risks.
