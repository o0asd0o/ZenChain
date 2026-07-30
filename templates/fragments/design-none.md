### No visual contract

This project has no design reference, so **there is no reference to capture and no fidelity to verify.** Skip the capture step entirely. QA verifies behaviour, accessibility, and the PRD's user stories, and reports fidelity as `NOT APPLICABLE — no design contract`, never as PASS and never as UNVERIFIED.

That is not a licence to improvise UI. Where a screen has no reference, the existing components and tokens in the codebase are the contract: match what is already shipped rather than introducing a second visual language. A new pattern with no reference behind it is a finding for the reviewer and an open question for the `decider`, not a decision for the implementer.

