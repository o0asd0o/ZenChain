### Capture the reference first — once, before QA starts

Pull every Figma frame this PRD's screens need and save them to `{{REF_DIR}}/`, named for the frame (`home-1440.png`, `home-375.png`). Where an issue's `## Visual reference` points at an **image** rather than a Figma node, that file is a reference too — make sure it is committed under the same `reference/` directory so QA reads Figma-sourced and image-sourced references from one place. Commit them.

**This step exists because the Figma MCP is usually the binding constraint on the whole loop.** Tool-call limits are per-account and easy to exhaust — a PRD whose reference was fetched lazily, per QA round, can ship with its fidelity entirely unverified. Capturing up front, once, means every QA round and every fixer round works from files on disk instead of competing for the same budget.

The design authority is Figma file `{{FIGMA_FILE_KEY}}`{{FIGMA_ROOT_CLAUSE}}. A node id is a tight contract; a plain image is a looser one. Verify a node id before pinning it into an issue — a wrong id is trusted blindly and produces a confident wrong build.

If the limit is hit here, **stop and tell the human**, naming which frames you got and which you did not. Do not start QA and hope. A capped loop over a missing reference burns every round to produce the same "unverified" report.

