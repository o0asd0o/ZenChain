### The design is lo-fi, so every screen issue is triaged before it is built

The mocks in `{{LOFI_DIR}}/` are intent, not pixel specifications. They fix content, hierarchy, task flow, control meaning, and rough grouping. They leave composition, spacing rhythm, type treatment, colour roles, responsive adaptation, and standard interaction treatment to the builder.

**Triage a screen issue before implementing it.** For each screen the PRD covers, check the issue answers the product questions:

- Which mock file is the reference, and at which viewport widths.
- What each control does, including any non-standard empty/error action whose meaning is not established elsewhere.
- Whether responsive adaptation may change task order or hide capability.
- Any brand direction or accessibility conflict the repository cannot answer.

Craft decisions are not blockers. The builder owns token selection, standard states, visual composition, local component treatment, and responsive layout that preserves the journey. Only a material product question makes the ticket not ready. The read-only decision advisor prepares one plain-language question and real-world scenario; the orchestrator appends it to `docs/INBOX.md`, sets `needs-info`, and stops the lane. After the human answers, write the result into the issue's acceptance criteria, scenarios, or exact contract references before implementation.
