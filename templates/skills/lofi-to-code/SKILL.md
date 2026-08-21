---
name: lofi-to-code
description: Build a screen from a lo-fi mock or sketch. Use when an issue's visual reference is an image in the lo-fi directory rather than a pixel-exact design file. Covers what the mock does and does not decide, how to fill the gaps from existing tokens, and what to flag rather than invent.
---

# Lo-fi to code

A lo-fi mock fixes **what is on the screen and in what order**. It does not fix how it looks. Building it as though it were pixel-exact produces a screen that is confidently wrong in every detail nobody drew.

## What the mock decides, and what it does not

| The mock decides                        | The mock does not decide                          |
| --------------------------------------- | ------------------------------------------------- |
| Which sections exist, and in what order | Spacing, padding, gap values                      |
| Hierarchy — what is primary, secondary  | Type scale, weight, line height                   |
| Which controls exist and roughly where  | Exact colour                                      |
| Content and copy, where written in      | Hover, focus, disabled, loading, empty, error     |
| Rough grouping and column counts        | Behaviour at widths the mock does not draw        |

The right column is the builder's creative surface. Existing tokens and shipped components are the visual vocabulary, not a stencil that every screen must copy. Measuring a lo-fi mock still produces precise numbers that mean nothing; compose an intentional screen from the system instead.

## Before coding

1. **Read the mock at full size.** `{{LOFI_DIR}}/` holds them. Note which widths exist — if only one, the others are your translation, and you must say so.
2. **Read the design system.** Extract its visual principles, tokens, primitives, and accessibility conventions.
3. **Read up to two relevant existing screens.** Learn the product's visual language and recurring interaction patterns. Do not clone the nearest screen or treat precedent as the only permitted composition.
4. **Separate product gaps from craft gaps.** Product gaps can change what the user may do or what the system means. Craft gaps are visual and interaction execution inside behavior the issue already fixes.

## Creative surface

The ticket defines what must be true, not the exact visual implementation. Ordinary craft decisions are yours: composition, spacing rhythm, type treatment, colour roles within the design system, responsive adaptation that preserves task order, standard interaction states, and new local components built from established primitives.

Before coding, silently consider 2–3 viable visual directions. Compare them for hierarchy, coherence with the product, responsive strength, accessibility, and how directly they serve the task. Implement the strongest direction. Do not create a design-options file, decision record, or long report; this is working thought, not project documentation.

Tokens are defaults, not handcuffs. Prefer them. A local value is allowed when no token expresses an intentional relationship and the result remains coherent; keep it local and mention the reason briefly. Do not silently introduce a global token or a second design language.

## Human boundary

Escalate only when the missing answer changes product behavior or meaning: workflow, permissions, destructive action, data semantics, control purpose, new content policy, brand direction the project does not establish, or an accessibility conflict with a binding reference. The orchestrator routes that question to `docs/INBOX.md`; the human-updated issue remains the contract.

Craft decisions are not product decisions. Do not block on token selection, ordinary focus/loading/error treatment, responsive composition that preserves the journey, or whether a local component should be visually quiet or prominent when the hierarchy already answers it.

## Build

Preserve the content, hierarchy, control meaning, and user journey. Refine the composition rather than tracing the boxes. Then:

- **Implement every state**, not just the one drawn. A control with no focus style is not done.
- **Implement the narrowest supported width**, even when the mock is desktop-only. Preserve task order, legibility, and control reachability; choose the composition that serves them rather than applying a universal single-column or horizontal-scroll recipe.
- **Semantics before appearance.** Headings are headings, buttons are buttons, lists are lists. A lo-fi mock cannot tell you this, and getting it wrong is the accessibility failure that survives review.

## Verify

1. **Intent** against the mock: content, hierarchy, flow, and control meaning at every width it covers.
2. **Craft** in the rendered result: clear focal point, consistent spacing rhythm, deliberate typography, coherent component treatment, and no accidental-looking dead space or crowding.
3. **Contrast against {{A11Y}}** for every text and background pair you used. Accessibility outranks anything drawn.
4. **Keyboard** — reach every control, see focus on each one, complete the flow without a mouse.
5. **The gate** — {{GATE_LIST}}. Document any pre-existing failure; never claim a clean gate when one was already failing.

## Report

Name the mock, widths, chosen visual direction, and only material deviations or new local values. Do not inventory every token or reproduce the directions you rejected. Keep the report short; the rendered screen and verification are the evidence.
