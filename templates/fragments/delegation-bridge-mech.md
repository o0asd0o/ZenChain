## Delegation — `implementer`, `fixer`, `explorer` run on `{{RUNNER_MECH}}`, not on this CLI

These three mechanical roles are delegated to cheaper models on `{{RUNNER_MECH}}` through the bridge `.orc2/bin/orc2-agent`. **Do not spawn them as native subagents** — that runs them on this CLI's model and defeats the point. Everywhere below that says "spawn `implementer`/`fixer`/`explorer`", it means: call the bridge with the Bash tool.

```bash
.orc2/bin/orc2-agent explorer     "<one bounded question>"
.orc2/bin/orc2-agent implementer  --cwd {{WORKTREE_DIR}}/<slug> "Implement <issue path>"
.orc2/bin/orc2-agent fixer        --cwd {{WORKTREE_DIR}}/<slug> "<reviewer findings>"
```

The bridge reads each role's model, tools, and system prompt from `.orc2/agents/<name>.md`; change a model by editing that file's `model:` line.

`reviewer`, `qa` and `decider` — the judgement roles — stay native subagents on this CLI, spawned with the `Agent` tool from `.claude/agents/`. Return to a running one with `SendMessage` rather than spawning a fresh one; that is what lets a reviewer verify its own findings instead of re-deriving them.

Every bridge dispatch starts cold — there is no conversation to return to. Give each dispatch the full context in its prompt: paths, not references to "the issue we discussed". When a fixer needs the reviewer's findings, paste them.

**The bridge's output is a claim, not ground truth.** You still run the gate yourself, own every merge, and count the rounds.

**Watch for a dead backend.** An external provider that has run out of credit or lost its auth can exit zero with an empty report, which reads as a clean run that found nothing to do. The bridge fails with exit 3 on empty output specifically to stop that. If you see it, fix the backend — do not respawn into the same wall, and do not treat the silence as a result.

