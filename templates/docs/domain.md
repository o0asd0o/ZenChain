# Domain documentation

Domain glossaries and human-approved ADRs may exist, but implementation roles do not browse them. The issue packet is the implementation contract.

## Explicit routing only

An issue that depends on a glossary term or ADR must name the exact path and heading under `## Contract References`. Implementer, fixer, reviewer, and QA read only those citations. “Relevant domain docs” or “ADRs touching this area” is not a valid reference and makes the ticket not ready.

`CONTEXT.md` remains vocabulary only: project-specific concepts, one or two sentences each, no schemas, workflows, or implementation notes. Use its canonical term only when the ticket cites that heading.

ADRs are created only through the human approval gate in `docs/agents/grill-with-docs-policy.md`. They are short architecture constraints, not a running decision journal. The pipeline never creates numbered decision records.

When an issue contradicts an exact contract reference, stop. The read-only decision advisor prepares a plain-language question; the orchestrator places it in `docs/INBOX.md`; the human updates the controlling contract before work resumes.
