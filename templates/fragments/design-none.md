### No visual contract

This project has no design reference, so **there is no reference to capture and no fidelity to verify.** Skip the capture step entirely. QA verifies behaviour, accessibility, and the PRD's user stories, and reports fidelity as `NOT APPLICABLE — no design contract`, never as PASS and never as UNVERIFIED.

That is not a licence to improvise UI. Where a screen has no reference, use an existing component/token pattern explicitly named by the issue. A genuinely new user-visible pattern makes the ticket `needs-info` and goes to the human through `docs/INBOX.md`; the implementer does not invent it.
