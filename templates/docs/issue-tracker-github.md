# Issue tracker: GitHub

Issues and PRDs for this repo live on GitHub, driven with the `gh` CLI.

## Conventions

- One PRD per epic issue, with its implementation slices as separate issues linked from it
- Triage state is carried by labels (see `triage-labels.md` for the mapping)
- Dependencies are stated in the issue body under `## Depends on`, as `#<N>` references
- The change surface is stated under `## Relevant files`
- Outcomes and conversation live in issue comments — `gh issue comment <N>`

## Commands the pipeline uses

```bash
gh issue view <N> --comments                      # read an issue and its history
gh issue list --label ready-for-agent --json number,title,labels
gh issue close <N> --reason completed         # closing IS "done" — there is no done label
gh issue comment <N> --body-file <file>           # record an outcome
gh pr create --fill                               # after the local gate is green
gh pr checks <N> --watch                          # CI, which is not your gate
gh pr merge <N> --squash                          # last step of the merge sequence
```

## Every issue carries its dependencies and its change surface

Two sections the pipeline reads directly, so they are not optional:

- **`## Depends on`** — the issues that must close first. The orchestrator builds its selectable set from these.
- **`## Relevant files`** — the files this slice expects to touch. Two issues that share an entry here must not run in parallel; that is a merge conflict scheduled on purpose.

## CI is not the gate

The local gate is what the orchestrator is accountable for, and it runs before the push. CI tells you what a second machine thinks; waiting on CI to find what the gate would have found costs a round every time. A green PR is not a closed issue — merge only after the reviewer returns PASS on top of a green local gate.

## Ticket readiness command

Before any implementation role starts:

```bash
gh issue view "$ISSUE_NUMBER" --json body --jq .body | .orc2/bin/orc2-ticket-check -
```

For UI fidelity work, insert `--ui` after `orc2-ticket-check`. A non-zero exit means `needs-info`; do not spawn the implementer.

## Visual Reference on screen-fidelity issues

When an issue renders something with a designed appearance, give it a `## Visual Reference` section so the implementer has the contract up front rather than guessing.

A reference is one or more **tagged entries** — source, scope, viewport:

```
## Visual Reference

- Figma · whole-screen · 1440: [node 1:2639](https://www.figma.com/design/.../?node-id=1-2639&m=dev)
- Image · component: TrustBadges · 375: `{{REF_DIR}}/trust-badges-375.png`
```

Rules:

- **Only screen-fidelity issues.** A stray reference on a backend issue is noise a weak model will chase.
- **A node link is a tight contract; a plain image is a looser one.** The `source` tag tells the implementer which it is, so never drop it.
- **Verify a node id before pinning it.** A wrong id is trusted blindly and produces a confident wrong build.
- **Commit image files into the repo** rather than attaching them to the issue — a lane worktree can read a committed file and cannot read an attachment.

## Pull requests from outside

An external PR is a triage surface. Treat it as an issue: read it, label it, and route it. It does not enter the implement pipeline — the pipeline builds from specified issues, and an unsolicited diff is not one.
