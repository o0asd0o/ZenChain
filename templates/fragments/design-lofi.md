### The design is lo-fi, so every screen issue is triaged before it is built

The mocks in `{{LOFI_DIR}}/` are intent, not a contract. They fix layout, hierarchy, and content order. They do **not** fix spacing, type scale, exact colour, or interaction states — a lo-fi mock read as pixel-exact produces a build that is confidently wrong in the details nobody drew.

**Triage a screen issue before implementing it.** For each screen the PRD covers, check the issue answers all of:

- Which mock file is the reference, and at which viewport widths.
- Which values come from the project's existing design tokens rather than from the mock.
- Every interaction state the mock does not draw: hover, focus, disabled, loading, empty, error.
- What the screen does at the narrowest supported width, if the mock is desktop-only.

Anything unanswered is an open question, and it goes to the `decider` — not to the implementer as a guess, and not to the human unless the decider refuses it. The decider's record then becomes the missing part of the contract, and the issue links it. That record is why a lo-fi pipeline can run unattended at all: the ambiguity is resolved once, in writing, instead of re-invented by every agent that reads the mock.

### Capture the reference before QA starts

Copy every mock this PRD's screens need into `{{REF_DIR}}/`, named for the screen and width (`home-1440.png`, `home-375.png`), and commit them. QA compares against these files on disk, and against the decider records that filled the gaps.

QA judges a lo-fi build on **structure, order, presence, state coverage, and accessibility** — never on spacing or proportion, which the mock never specified. A fidelity finding against a value the mock does not contain is not a finding; it is an open question, and it is routed as one.

