## Backend and third-party choices are decisions, not implementation details

**No agent adds a dependency or picks a backend service on its own.** A third-party library, a database engine, a queue, a cache, a hosting target, a payment or mail provider — each one is a decision with a reversal cost, and it goes to the `decider` before any code assumes it.

This is not bureaucracy. A dependency chosen mid-issue by an implementer is invisible to review (it compiles), invisible to QA (it works), and expensive at exactly the point someone wants it gone. The record is what makes it reversible.

Route it to the decider when:

- An issue needs capability the codebase does not have and no existing dependency covers.
- Two libraries could serve the same purpose and the issue does not name one.
- The issue names a library, but it is not already in the project's manifest.
- A backend service, engine, or provider would be introduced, swapped, or version-bumped across a major.

Do **not** route it when the issue explicitly names a dependency that is already installed, or when the standard library or an installed dependency covers the need. Those are implementation, and the implementer decides them. A decider invoked on a question already answered by the manifest is wasted spend.

**Existing records are binding.** Before selecting anything, read `{{DECISIONS_DIR}}/` — the stack choices made so far are recorded there, including the ones `orc2` seeded at setup. A record on the area is as binding as an ADR until it is overturned. An issue that assumes a different engine, library, or provider than the record names is a **contradiction**, and it routes to the decider as one rather than being quietly reconciled by whoever noticed.

**The record is what the reviewer checks against.** A new entry in the manifest with no decision record behind it is a blocking finding, regardless of how good the choice was. The reviewer is instructed to look for exactly this.

