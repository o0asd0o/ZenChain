# Local ticket-writing policy

Use this modifier whenever `/to-tickets` or `/to-issues` creates implementation slices. Do not edit, shadow, or copy either upstream skill. Tracker-specific publishing belongs to `docs/agents/issue-tracker.md`; the issue body below is identical for local markdown and GitHub.

## Agent-ready ticket packet

Every ticket contains these exact sections:

- `## Acceptance Criteria` — observable behavior and its proof.
- `## Scenarios` — applicable boundary cases; no unresolved `?` or TODO.
- `## Depends on` — explicit blockers or `None`.
- `## Relevant files` — expected change surface.
- `## Contract References` — exact path plus heading, or `None`.
- `## Approved Technical Changes` — new/replaced/major-upgraded dependency, engine, or provider, or `None`.
- `## Visual Reference` — only for UI fidelity work.

The issue is the implementation contract. `## PRD` may identify its parent but does not authorize reading the PRD in full. Put each binding PRD clause under `## Contract References` with its exact heading.

## Readiness gate

Do not publish or mark ready when a required section is missing, an acceptance criterion is not observable, a reference says only “relevant docs/ADRs,” a scenario is unresolved, or two requirements contradict. Put the material human question in `docs/INBOX.md` using plain language and a real-world scenario.

## Size budget

- Entire issue: at most 120 nonblank lines.
- `What to build`: at most 100 words.
- One observable sentence per acceptance criterion.
- `## Scenarios`: boundary cases only, at most 12 rows.
- `## Contract References`: links only, no summaries.
- No background essay, rejected-option history, research narrative, or implementation tutorial.

If the issue exceeds the budget, split the vertical slice.
