### The design is lo-fi, so every screen issue is triaged before it is built

The mocks in `{{LOFI_DIR}}/` are intent, not a contract. They fix layout, hierarchy, and content order. They do **not** fix spacing, type scale, exact colour, or interaction states — a lo-fi mock read as pixel-exact produces a build that is confidently wrong in the details nobody drew.

**Triage a screen issue before implementing it.** For each screen the PRD covers, check the issue answers all of:

- Which mock file is the reference, and at which viewport widths.
- Which values come from the project's existing design tokens rather than from the mock.
- Every interaction state the mock does not draw: hover, focus, disabled, loading, empty, error.
- What the screen does at the narrowest supported width, if the mock is desktop-only.

Anything material that remains unanswered makes the ticket not ready. The read-only decision advisor prepares one plain-language question and real-world scenario; the orchestrator appends it to `docs/INBOX.md`, sets `needs-info`, and stops the lane. After the human answers, write the result into the issue's acceptance criteria, scenarios, or exact contract references before implementation.
