---
name: delegate
description: Dispatch a pipeline role (implementer, fixer, explorer, reviewer, qa, decider) to its configured backend through the zenchain-agent bridge instead of spawning a native subagent. Use when the orchestrator needs a role that runs outside this CLI.
---

# Delegate a role through the bridge

The orchestrator (`{{PIPELINE_DIR}}/ORCHESTRATOR.md`) owns sequencing, the gate, the round cap, and every merge. Roles that run outside this CLI go through `.zenchain/bin/zenchain-agent`, which dispatches through the configured harness adapter.

## Invoke

Call it with the Bash tool.

```bash
# explorer — one bounded question, read-only
.zenchain/bin/zenchain-agent explorer "Where is the discount calculation defined and what does it round?"

# implementer — build one issue, in its worktree
.zenchain/bin/zenchain-agent implementer --cwd {{WORKTREE_DIR}}/<slug> "Implement <issue path>"

# fixer — apply findings, in the same worktree
.zenchain/bin/zenchain-agent fixer --cwd {{WORKTREE_DIR}}/<slug> "$FINDINGS"
```

`--cwd` sets the working directory — the lane's worktree for implementer and fixer, omitted for read-only roles. A long prompt can be piped on stdin instead of passed as an argument. `--backend <name>` overrides the configured backend for one call.

## What the bridge does

Reads `{{MECH_ROLE_DIR}}/<role>.md`, pulls `model`, `tools`, and `effort` from its frontmatter, and sends a normalized request to the configured adapter. The model is **never hardcoded in the bridge** — edit the role's `model:` line, or set `ZENCHAIN_AGENT_MODEL` for one run.

The adapter receives `ZENCHAIN_AGENT_ROLE`, `ZENCHAIN_AGENT_CWD`, `ZENCHAIN_AGENT_MODEL`, `ZENCHAIN_AGENT_TOOLS`, `ZENCHAIN_AGENT_EFFORT`, `ZENCHAIN_AGENT_SYSTEM_FILE`, and `ZENCHAIN_AGENT_PROMPT_FILE`. It writes the role report to stdout and supports `--check` for `zen doctor`.

The backend's stdout is the agent's report. **Treat it as a claim, not ground truth.**

## Three things the bridge cannot give you

- **No conversation.** Every dispatch starts cold. Where the pipeline says "return to the same reviewer", re-dispatch it and paste its own previous report into the prompt, saying explicitly that it is verifying its prior findings.
- **No enforced tool limits on some backends.** A role's read-only construction may be prompt-level only. Check the outcome for the reviewer specifically: if a reviewer dispatch produced a diff, discard the run.
- **No skills.** A backend without a skill mechanism cannot invoke `implement` or `tdd` by name. Either vendor them into the repo and cite them by path in the role prompt, or accept that the role runs on its prompt alone.

## Exit codes

`0` report on stdout · `2` usage or config error · `3` **the backend produced nothing**.

Exit 3 is the one that matters. A backend out of credit or with stale auth can exit zero with empty stdout, which reads to an orchestrator as a clean run that found nothing to do — that failure mode has cost real time, looking like a twenty-minute hang that was actually a dead process. Exit 3 exists to make it loud. Fix the backend; do not respawn into the same wall.
