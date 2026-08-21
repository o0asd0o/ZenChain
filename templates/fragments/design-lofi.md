### Capture the reference before QA starts

Copy every mock this PRD's screens need into `{{REF_DIR}}/`, named for the screen and width (`home-1440.png`, `home-375.png`), and commit them. QA compares against these files and the explicit issue contracts that resolved any gaps.

QA judges a lo-fi build on **structure, order, presence, state coverage, and accessibility** — never on spacing or proportion, which the mock never specified. A fidelity finding against a value the mock does not contain is not a finding; it is an open question, and it is routed as one.
