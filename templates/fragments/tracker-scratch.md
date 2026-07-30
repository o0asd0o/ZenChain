**Never use `gh` or any remote tracker command.** Issues are markdown files under `{{ISSUE_ROOT}}/`, tracked by the `Status:` line described in `docs/agents/triage-labels.md`. Any skill step that says "open a pull request", "wait for CI", or "comment on the issue" means: commit to the branch, and append to the issue file. The implementer is instructed to skip the PR-and-CI closeout.

Issue paths are `{{ISSUE_GLOB}}`. The PRD is `{{ISSUE_ROOT}}/<feature-slug>/PRD.md`. Comments append under a `## Comments` heading at the bottom of the issue file.
