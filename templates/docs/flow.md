# The flow: idea → tickets → merged

Two halves, one seam.

The **front half is interactive** — a human sharpening an idea until it is a set of agent-ready tickets. The **back half is unattended** — the pipeline in `{{PIPELINE_DIR}}/ORCHESTRATOR.md` driving those tickets to merged code. They meet at one point: **the moment tickets exist and are marked ready for an agent.**

```
                                                    ← human → | ← unattended →
  /research  ─┐
  /prototype ─┼→ /grill-with-docs → /to-spec → /to-tickets  ══╬══>  /run-prd
  /wayfinder ─┘                                              ║      ├ implement
  /triage ───────────────────────────────────────────────────┘      ├ gate  (you run it)
                                                                    ├ review (two axes)
                                                                    ├ fix    (capped)
                                                                    └ QA → human checkpoint
```

Nothing above the seam is automated by the pipeline, and that is deliberate: most of those skills are marked user-only (`disable-model-invocation: true`), because they exist to interview a human. An agent cannot invoke them, and a pipeline that tried would be inventing the requirements it is supposed to be building against.

## Above the seam — how work becomes tickets

Run these yourself, in one unbroken context window. Do not compact between them; the grilling, the spec, and the tickets should all build on the same thinking.

**On an empty repo, start with `/plan-app`.** It is the checklist for this whole half: the app-wide grilling agenda (stack, domain vocabulary, trust boundaries, operations) and the decomposition into PRD areas that covers the application from foundation to release, security included. `zen doctor` prints the same route and adapts it to what the repo already has.

| Situation | Start with |
| --- | --- |
| A greenfield repo, or nothing agent-ready to run | `/plan-app` — the app-wide agenda, then the PRD-area decomposition |
| An idea you can hold in one session | `/grill-with-docs` + `docs/agents/grill-with-docs-policy.md` — interview deeply; write only compact, human-approved documentation |
| An effort too big to hold at all — greenfield, or a huge feature | `/wayfinder` — charts a map of *decision* tickets and resolves them until the route is visible, then hands off to `/to-spec` |
| A design question that needs a runnable answer | `/prototype` — throwaway code that answers one question; keep the answer, delete the code |
| A question needing outside facts | `/research` — a background agent reads primary sources and leaves a cited file in the repo |
| Reports and requests arriving raw | `/triage` — moves them through the triage roles until they are agent-ready |

Then `/to-spec` turns the thread into a spec, and `/to-tickets` or `/to-issues` applies `docs/agents/ticket-writing-policy.md` to create compact tracer-bullet slices.

**Do not triage tickets that the ticket-writing skill produced.** They are already agent-ready. Triage is for work you did not create.

## The PRD areas must reach release, not feature-complete

`/to-spec` writes one spec. It does not decide how many specs the application needs — that is the decomposition in `/plan-app`, and getting it wrong is how a project arrives at "all features built" with no way to deploy it.

Nine generic areas to adapt: **Foundation** (toolchain, gate, CI, deployable skeleton) → **Identity & access** → **Core domain**, usually split into two to four verticals → **Data & persistence** → **Interface & navigation** → **Integrations** → **Observability** → **Security hardening** → **Release & operations**.

Merge freely for a small app; a five-PRD plan that ships beats a nine-PRD plan that stalls. But **observability, security hardening, and release are not optional and are not folded away.** Dropping them does not reduce the work — it moves it to the worst possible moment.

**Security appears twice, deliberately.** Every PRD carries its own security acceptance criteria, written when the PRD is written: which boundary this crosses, what must be authorised rather than merely authenticated, what input is untrusted, what it logs that it should not. *And* one PRD owns what no feature owns — the written threat model, authorisation tests against every reachable object from the wrong account, rate limits, secrets and rotation, dependency policy, retention and deletion. A PRD set with only the second has features nobody checked; with only the first, it has gaps nobody owns.

`{{BUILD_ORDER_LINE}}`

## The seam — what the pipeline requires of a ticket

The issue packet is the only implementation contract. Every ticket requires:

1. **`## Acceptance Criteria`.** Observable behavior and proof.
2. **`## Scenarios`.** Resolved boundary cases.
3. **`## Depends on`.** Ordering input.
4. **`## Relevant files`.** Change surface and concurrency input.
5. **`## Contract References`.** Exact path and heading, or `None`.
6. **`## Approved Technical Changes`.** Exact material additions, or `None`.

Screen work needs a fourth: a `## Visual Reference` with a tagged source. See `docs/agents/issue-tracker.md`.

A ticket that fails readiness never reaches the implementer. The read-only decision advisor prepares one layman question with a real-world scenario; the orchestrator puts it in `docs/INBOX.md`, marks the issue `needs-info`, and waits for the human to update the packet.

## Below the seam — which skill each role drives

| Role | Skill it runs | Why |
| --- | --- | --- |
| `implementer` | `/implement`, driving `/tdd` per slice | The ticket is the approved plan, so it executes rather than interviews |
| `implementer` | `/code-review`, as a **pre-flight self-check only** | Catches its own obvious misses before spending a review round. **Never a verdict** — see below |
| `reviewer` | the two axes of `/code-review`, Standards and Spec | Read-only by construction, so it cannot fix what it finds |
| `fixer` | `/diagnosing-bugs` when a finding is a defect | No feedback loop, no hypothesis — the rule that stops guess-fixing |
| `qa` | `/diagnosing-bugs` on anything it finds broken | Same rule; a defect QA cannot reproduce is not a finding |
| `decider` | no write skill; direct read/search only | Prepares one plain-language human question; never decides or writes a record |
| orchestrator | `/resolving-merge-conflicts` at merge time | Finds each side's original intent before resolving either |
| everyone designing a module | `/codebase-design` vocabulary | Shared words for depth, seams, and adapters, so "this is shallow" is a claim and not a mood |

## Why the implementer's self-check is not a review

Upstream `/implement` closes out by running `/code-review` before committing. In this pipeline it must not, because the reviewer is a **separate agent with no write tools at all** — that is what makes "fix" unable to quietly mean "delete the failing test."

So the implementer may run `/code-review` on its own diff, and must fix what it finds, but **its output is never a verdict and never ends the loop.** Only the `reviewer` returns PASS, and only the orchestrator acts on it. An implementer reporting "code-review passed" has reported a self-assessment, and the orchestrator treats it as exactly that.

## Vendored skills and the pin

The skills above are vendored into this repo at a pinned commit, recorded as `ORC2_SKILLS_PIN` in `.orc2/config.env`. `zen doctor` reports when upstream has moved. Re-pin deliberately with `zen render` after clearing the value — never mid-run, because a role prompt and the skill it cites should not change under a lane that is already building.

One skill is modified on the way in: upstream ships `/implement` as user-only, which an agent cannot invoke, so the flag is stripped and the file records that it was.
