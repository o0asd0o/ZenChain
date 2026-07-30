**Issues live on GitHub and you drive them with `gh`.** Triage state is carried by labels, mapped in `docs/agents/triage-labels.md`. Read an issue with `gh issue view <N> --comments`, set state with `gh issue edit <N> --add-label / --remove-label`, and record outcomes with `gh issue comment <N>`.

Two things do not change just because there is a remote:

- **CI is not your gate.** You still run {{GATE_LIST}} locally, before you push. CI tells you what a second machine thinks; the local gate is what you are accountable for, and waiting on CI to find what the gate would have found costs a round each time.
- **A green PR is not a closed issue.** Merge only after the reviewer returns PASS on top of a green local gate.

**Where the PR fits the merge sequence.** The merge section below is written locally-first, and that does not change: you still merge `{{MAIN_BRANCH}}` into the lane branch, resolve conflicts in the worktree, and re-run the gate there. The PR is how the proven branch reaches `{{MAIN_BRANCH}}`, and it replaces the local fast-forward step:

1. Do the merge section's steps 1–5 in the worktree, exactly as written.
2. `git push -u origin <branch>` — the implementer never pushes; you do, and only now.
3. `gh pr create --fill --base {{MAIN_BRANCH}}`, then `gh pr checks <N> --watch` if the repo runs CI.
4. **`gh pr merge <N> --merge`**, not `--squash` and not `--rebase`. Squashing rewrites the commits you proved in the worktree, so what lands on `{{MAIN_BRANCH}}` is not what the gate passed. If the repo's policy requires squash, say so in the cycle report — the tested-artifact guarantee is weaker under it.
5. `git checkout {{MAIN_BRANCH}} && git pull`, then run the gate on `{{MAIN_BRANCH}}` — the merge section's "prove `{{MAIN_BRANCH}}` itself" step. CI passing is not a substitute; you run it.

Green CI is not the merge condition either — a reviewer PASS on a green local gate is.

Reference the issue as `#<N>` in commit subjects. Comments and outcomes go on the issue, not only in your terminal report — the issue is the record a human reads later.
