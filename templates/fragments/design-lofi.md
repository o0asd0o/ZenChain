### Capture the reference before QA starts

Copy every mock this PRD's screens need into `{{REF_DIR}}/`, named for the screen and width (`home-1440.png`, `home-375.png`), and commit them. QA compares against these files and the explicit issue contracts that resolved any gaps.

QA does not demand pixel fidelity from a sketch. It judges **intent, visual coherence, hierarchy, spacing rhythm, responsive composition, state coverage, and accessibility** against the issue, the product's design language, and the rendered result. A craft weakness may be a finding without pretending the mock specified exact pixels. A new product behavior still requires contract authority.
