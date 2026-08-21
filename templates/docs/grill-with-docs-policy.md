# Local `/grill-with-docs` documentation policy

This project-local modifier changes documentation persistence only. Follow the installed `/grill-with-docs`, `/grilling`, and `/domain-modeling` skills for the interview. Do not edit, shadow, or copy those upstream skills.

## Keep the markdown small

- A glossary term is one or two sentences.
- An ADR is at most 200 words and 20 nonblank lines.
- An ADR contains only context, decision, reason, and a consequence or revisit trigger.
- No scoring tables, research narrative, code listing, transcript excerpt, implementation plan, or tutorial prose.
- Link source evidence instead of copying it.
- If the decision does not fit, narrow it; do not make the ADR longer.

## Create fewer ADRs

Collect candidates during the interview. Do not create an ADR after each answer. At completion, group related candidates by architectural concern and show each candidate to the human in layman's terms with one real-world scenario.

Create or update an ADR only after explicit human approval and only when all are true:

1. Reversal is expensive.
2. The constraint is cross-system or long-lived.
3. The choice is surprising without rationale.
4. Genuine alternatives existed.
5. An acceptance criterion, PRD direction, or code standard cannot carry it fully.

Default to zero ADRs. Reuse an existing ADR for the same concern. Keep the session synthesis in chat; never create a separate summary file.
