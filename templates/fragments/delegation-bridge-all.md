## Delegation — roles are dispatched headlessly through the bridge

This CLI has no native subagent mechanism, so every role runs as a fresh headless process through `.zenchain/bin/zenchain-agent`. Call it with the shell:

```bash
.zenchain/bin/zenchain-agent explorer     "<one bounded question>"
.zenchain/bin/zenchain-agent implementer  --cwd {{WORKTREE_DIR}}/<slug> "Implement <issue path>"
.zenchain/bin/zenchain-agent reviewer     "<issue path, diff, changed files, gate results>"
.zenchain/bin/zenchain-agent fixer        --cwd {{WORKTREE_DIR}}/<slug> "<reviewer findings>"
.zenchain/bin/zenchain-agent qa           "<PRD path and reference directory>"
.zenchain/bin/zenchain-agent decider      "<the question, the issue path, the context>"
```

The bridge reads each role's model, tools, and system prompt from `.zenchain/agents/<name>.md`; change a model by editing that file's `model:` line.

Three consequences of headless dispatch you have to work around, because they are not optional:

- **No conversation to return to.** There is no `SendMessage`. Where the pipeline says "return to the same reviewer", you re-dispatch the reviewer and **paste its own previous report into the prompt** along with the fixer's report and the new diff. Say explicitly that it is verifying its own prior findings, not re-deriving them. Skipping this is what makes a fix loop expensive and lets round three re-litigate round one.
- **No enforced tool restrictions.** The `reviewer`'s read-only construction is a prompt instruction here, not a capability boundary. It is the one role where you must check the outcome: if a reviewer dispatch produced a diff, discard the run and re-dispatch. A reviewer that fixed something has approved its own work.
- **Every dispatch starts cold.** Give each role the full context it needs in the prompt — paths, not references to "the issue we discussed". The role prompts assume this.

**The bridge's output is a claim, not ground truth.** You still run the gate yourself, own every merge, and count the rounds.

**An empty report is a dead dispatch.** The bridge exits 3 when a backend produces nothing, which happens on lost auth, exhausted credit, or a transport error. Fix the backend; do not respawn into the same wall, and never read silence as "nothing to do".

