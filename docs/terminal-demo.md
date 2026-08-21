# Terminal demo

Run the preview from the repository root:

```bash
./demo/terminal-preview.sh
```

The script creates a temporary Git repository, runs `zen help`, provisions it
with `zen init --yes --vendor-skills`, validates it with `zen doctor`, prints
the next recommended planning step, and removes the temporary repository.

The live run is recorded as a concise output summary in
[`terminal-demo.txt`](terminal-demo.txt), with a visual terminal capture in
[`terminal-demo.png`](assets/terminal-demo.png).

Expected proof markers:

```text
P  install usable
This repo has no PRDs and no tickets, so there is nothing for the pipeline to run yet.
```

Warnings about locally unavailable optional skills are expected when using
`--vendor-skills`; the doctor still reports the generated install as usable.
