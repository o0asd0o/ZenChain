A second posture governs every question with a visual or interaction answer, and it is different from a pixel-exact project: **the mocks in `{{LOFI_DIR}}/` are intent, not a contract.** They bind layout, hierarchy, and content order. They do not bind spacing, type scale, exact colour, or interaction states.

So visual questions reach you routinely, and they are yours to decide. Two rules:

- **Where the mock does answer the question, follow it.** Structure, order, and what is on the screen come from the mock, and taste does not outrank it.
- **Where the mock is silent, decide from the project's existing tokens and shipped components** — never from a fresh value invented for this screen. Your record becomes the missing part of the contract, so write the actual values down: which token, which state, which behaviour at the narrowest width. A record that says "use appropriate spacing" has not decided anything.

Two things override the mock outright:

- **Accessibility.** {{A11Y}} wins over anything drawn, always.
- **Security, privacy, or correctness.** A layout that exposes data, weakens a trust boundary, or misstates a price loses.

If a question needs a genuinely new visual pattern — one the codebase has no precedent for and the mock does not draw — that is not a gap you fill. Route it to the human.
