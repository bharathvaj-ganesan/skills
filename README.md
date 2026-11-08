# skills

A personal collection of agent skills kept in one place. Each skill lives under `skills/` with its own `SKILL.md`, license, and source notes.

## Skills

| Skill | What it does |
| --- | --- |
| [pr-raise-review](skills/pr-raise-review) | Combines PR creation and PR review into one workflow. It can draft/create a high-quality PR summary from branch diff + checks, and review a PR with severity-ranked findings (and optionally post approve/comment/request-changes via `gh`). |
| [visual-plan](skills/visual-plan) | Turns ordinary text plans into rich interactive visual plans with diagrams, file maps, annotated code, open questions, and optional UI/prototype review. |
| [visual-recap](skills/visual-recap) | Turns a PR/branch/commit diff into an interactive visual recap with file maps, diagrams, API/schema summaries, annotated diffs, and focused review notes. |

## Use in your projects

Run from your project root:

```sh
# see what's available
npx skills add <your-github-username>/<this-repo> --list

# install this skill
npx skills add <your-github-username>/<this-repo> --skill pr-raise-review -y
npx skills add <your-github-username>/<this-repo> --skill visual-plan -y
npx skills add <your-github-username>/<this-repo> --skill visual-recap -y

# update installed skills
npx skills update -p -y

# list or remove installed skills
npx skills list
npx skills remove pr-raise-review
```

## Adding more skills

1. Add a folder under `skills/<skill-name>/`.
2. Include `SKILL.md`.
3. Include `LICENSE`.
4. Include `SOURCE.md` with origin + changes.
5. Add a row to the Skills table above.

## License

Each skill keeps its own license in its folder.
