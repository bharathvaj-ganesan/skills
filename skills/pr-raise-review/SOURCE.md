# Source

This skill is a merged/adapted workflow from:

- Local skill: `raise-pr-summary`
- Local skill: `review-pr-gh`

Adaptation notes:

- Unified both capabilities into a single skill: `pr-raise-review`.
- Added intent-based mode detection (Raise vs Review).
- Preserved structured PR title/body guidance and severity-based review output.
- Retained `gh` CLI-based execution model.
