## Running two issues at once

Run **at most two issues concurrently**. Two is the cap, not a target — one is correct whenever the second candidate is not cleanly separable.

### Each lane gets its own worktree and branch

```
git worktree add -b <branch> {{WORKTREE_DIR}}/<slug> {{MAIN_BRANCH}}
```

**A new worktree has no gitignored files.** `.env`, local config, credentials, and anything else untracked does **not** come across from the parent checkout — `git worktree add` copies tracked files only. Create what the lane needs by hand before spawning the implementer, and never edit the repo root's copies to do it.

**Tools may not be on `PATH` in a non-interactive shell.** Whatever `PATH` export your toolchain needs, put it in every agent brief — agents hit `command not found` otherwise, and report it as a code error rather than an environment one.

### Pick pairs by change surface, not by number

Two unblocked issues are not automatically two parallel issues. Read each candidate's list of files it expects to touch — that is what the section exists for — and **do not pair two issues that edit the same file.** A shared edit target is a merge conflict you scheduled on purpose.

When every unblocked candidate overlaps, run one. A serial issue that merges cleanly beats two that collide.

### Lanes are independent until they merge

Each lane runs the full per-issue cycle below — implement, gate, review, fix — on its own. A lane that fails its gate or exhausts its rounds is escalated on its own and does not stop the other lane.

Merging is the exception: it is serialized, and it has its own section.
