---
name: run-prd
description: Run every issue in one {{PROJECT}} PRD through the pipeline in dependency order, then per-PRD QA, then stop at the human checkpoint. Takes a PRD name.
---

# Run one PRD

Drive every issue under one PRD to completion, run QA over the whole thing, then stop for a human.

## Resolve the argument

The argument is a PRD name. If it matches nothing, list what exists rather than guessing at the closest name.

## Check before starting

- The working tree is clean. If not, stop — worktrees and merges are unsafe over uncommitted work.
- The PRD has issues. If it has never been sliced, say so and suggest the `to-issues` skill rather than inventing slices.
- Every PRD this one depends on is complete. Individual issues may also be gated on a specific slice of another PRD; the PRDs name those. Starting a PRD whose dependencies are unbuilt wastes a full run. The build order is: {{BUILD_ORDER_LINE}}

## Run

Read `{{PIPELINE_DIR}}/ORCHESTRATOR.md` and follow it exactly.

Work the PRD's issues in dependency order, lowest number first among those unblocked. Each goes through the full per-issue cycle. Everything in the orchestrator applies — you run the gate yourself, and agents do not self-limit so you count the rounds.

**Concurrency: {{LANES}}.** {{LANES_PRD_CLAUSE}}

**Merges are serialized regardless.** One at a time, `{{MAIN_BRANCH}}` merged into the branch rather than the reverse, conflicts resolved and re-gated inside the worktree, and `{{MAIN_BRANCH}}` proven green before the next merge starts. The orchestrator's merge section is the procedure; follow it exactly.

Stay inside this PRD. Do not start the next one, even when its issues become unblocked.

## When every issue is closed

Follow the orchestrator's per-PRD section exactly. In short: capture the reference frames to `{{REF_DIR}}/` first and commit them, then run QA↔fixer for at most {{ROUND_CAP}} rounds, then **stop**. This is a designed human checkpoint, not a formality.

- **PASS** — record it at the top of the PRD and stop.
- **FAIL** — spawn `fixer` with QA's findings, re-run the gate yourself, then return to the same QA agent and count the round.
- **{{ROUND_CAP}} rounds, still failing** — escalate to a human with the outstanding findings. Do not record a PASS.

Capture the reference before QA runs, never during. A loop that re-fetches per round will exhaust the design tool's rate limit mid-run and leave fidelity unverified. If capture itself hits the limit, stop and say which frames you got — do not run QA against a missing reference and report the result as fidelity.

Never auto-accept QA's "needs human eyes" list, and never hand it to the fixer. It goes to the human, always — that list exists because screenshot comparison cannot reliably judge spacing, proportion, or type, and quietly accepting it would defeat the point of separating the two buckets.

## Blockers go to the human through one queue

Route material blockers, open questions, and binding contradictions to the read-only `decider`. It prepares one layman question with a real-world scenario. Append it to `docs/INBOX.md`, set the issue to `needs-info`, and stop that lane.

After the human answers, update the controlling acceptance criterion, scenario, PRD direction, or explicitly approved ADR; remove the INBOX entry; return the issue to `ready-for-agent`; then resume. Never implement directly from chat or the queue entry.

At the PRD checkpoint, list remaining INBOX entries. An escalated PRD is a working pipeline. A PRD marked done that does not do what it claims is a failed one.

## Report

As each issue closes: issue, outcome, rounds used, gate results. Keep it to a line or two. When two lanes ran, say which issues shared a window and whether their merge needed conflict resolution — a clean pair and a pair you had to reconcile are different outcomes worth distinguishing.

At the end: issues completed, issues escalated, the QA verdict in full including its needs-human-eyes list, total approximate token cost, and any risk you noticed that no requirement covers.
