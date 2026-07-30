**Issues live on GitHub and you drive them with `gh`.** Triage state is carried by labels, mapped in `docs/agents/triage-labels.md`. Read an issue with `gh issue view <N> --comments`, set state with `gh issue edit <N> --add-label / --remove-label`, and record outcomes with `gh issue comment <N>`.

Two things do not change just because there is a remote:

- **CI is not your gate.** You still run {{GATE_LIST}} locally, before you push. CI tells you what a second machine thinks; the local gate is what you are accountable for, and waiting on CI to find what the gate would have found costs a round each time.
- **A green PR is not a closed issue.** Merge only after the reviewer returns PASS on top of a green local gate. `gh pr merge` is the last step of the merge sequence below, never the first.

Reference the issue as `#<N>` in commit subjects. Comments and outcomes go on the issue, not only in your terminal report — the issue is the record a human reads later.
