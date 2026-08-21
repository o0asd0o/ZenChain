## One issue at a time

This pipeline runs serially. One issue, start to merge, before the next is selected.

Each issue still gets its own worktree and its own branch off the current `{{MAIN_BRANCH}}`:

```
git worktree add -b <branch> {{WORKTREE_DIR}}/<slug> {{MAIN_BRANCH}}
```

The worktree matters even without parallelism: it keeps a failed or abandoned issue from leaving the main checkout dirty, and it makes "throw this away and start again" a one-line operation.

**A new worktree has no gitignored files.** `.env`, local config, and anything else untracked does **not** come across from the parent checkout. Create what the lane needs before spawning the implementer, and never edit the repo root's copies to do it.

**Tools may not be on `PATH` in a non-interactive shell.** Whatever `PATH` export your toolchain needs, put it in every agent brief — agents hit `command not found` otherwise, and report it as a code error.

If you later want two lanes, re-run `zen render` after setting `ZENCHAIN_LANES="2"` in `.zenchain/config.env`. The parallel section carries rules that do not apply serially and are dangerous to improvise.
