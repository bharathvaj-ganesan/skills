# Source

Original skill written for this collection.

- Uses the `gh` CLI only (`gh pr view`, `gh api graphql` with `--paginate` and built-in `--jq`); no other dependencies.
- Resolves review threads via the `resolveReviewThread` GraphQL mutation and optionally minimizes conversation comments via `minimizeComment`.
