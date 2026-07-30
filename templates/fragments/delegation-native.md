## Delegation — every role is a native subagent

Spawn all six roles with the `Agent` tool, using the role name as `subagent_type`. Their definitions live in `.claude/agents/`; each one pins its own model and effort so a change to the session's settings cannot quietly lower a judgement role.

`implementer` and `fixer` spawn `explorer` themselves, so you only launch the top role for a piece of work. The `reviewer` deliberately cannot delegate at all.

Return to an already-running agent with `SendMessage` rather than spawning a fresh one — that is what makes the fix loop cheap and what lets a reviewer verify its own findings instead of re-deriving them.

