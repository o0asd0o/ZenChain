---
name: figma-to-code
description: Convert a Figma node or frame into production code that matches it exactly. Use when an issue or reviewer finding says 'match the Figma', when a component's visual output disagrees with the reference, or when building new UI from a Figma frame. Covers extracting design context from the Figma MCP, translating the output into this project's markup, wiring design tokens, and verifying against a screenshot.
---

# Figma to code

Convert one Figma node into production markup that matches the reference exactly. Never approximate — read the node's literal output from the Figma MCP and translate it mechanically.

## The reference is the contract

The design authority is Figma file `{{FIGMA_FILE_KEY}}`{{FIGMA_ROOT_CLAUSE}}. The project's design document is the *derived* system — the reference wins when they conflict. Where the project has recorded a conflict as deliberately accepted, it stays accepted; do not silently correct it.

## Setup

The Figma MCP server runs at `http://127.0.0.1:3845/mcp`, started from the Figma desktop app's "Dev Mode MCP" toggle. Before first use, confirm it is reachable:

```bash
curl -sS -m 3 -o /dev/null -w '%{http_code}\n' http://127.0.0.1:3845/mcp
```

The tools that matter:

- `get_design_context` — framework markup for a node. **This is the primary tool.**
- `get_screenshot` — a rendered PNG of the node, for verifying the output
- `get_metadata` — coordinates, sizes, and nesting of child nodes
- `get_variable_defs` — design tokens and colour variables defined in Figma

**Tool calls are rate-limited per account, and exhausting the budget mid-task is the most common way a screen ships unverified.** Fetch each node once, save what you get, and work from that. Do not re-fetch to re-read something you already have.

## Before coding

1. **Read the project's design system** — the design document for the visual vocabulary, and the token file for the actual values (every custom property). You cannot map a Figma variable without it.
2. **Read the component you are about to change, and its neighbours.** Conventions beat inference.
3. **Get the node id.** It is in the URL when you select something in Figma (`node-id=1-307`), or in the `data-node-id` attribute of `get_design_context` output.
4. **Read the component's docblock, if it has one.** Where a project records design rationale in the component, that rationale must stay true to what the component does after your change.

## Extract

1. **`get_design_context`** on the node. This returns markup with every colour as `var(--token, #fallback)`, every size as an explicit pixel value, every gap as a number. This is your single source of truth for what to build.
2. **`get_screenshot`** on the same node. This is what it should look like. Compare after implementing.
3. **`get_metadata`** on the parent frame, when the design context flattens layout into absolute positioning and you need real coordinates to derive a responsive layout.
4. **`get_variable_defs`**, only when a colour looks wrong. Where Figma's value and the project's token differ, **the project's token wins** — it is what actually ships.

## Convert

**Translate mechanically, do not reinterpret.** Map the framework idioms one for one: the class attribute name, the element set, the expression syntax, the style attribute form. Drop `data-node-id` — it is dead weight outside Figma. Where the output wraps everything in a component function, take the markup body and discard the wrapper.

**Tokens.** Map every `var(--token)` in the output to the project's own token, and use the project's utility class for it rather than an inline `var()`. If a token clearly should have a utility and does not, add it.

**Typography.** Map font family, weight, and size to the project's named text tokens where the Figma value matches one exactly. Where it does not, use the explicit value — the Figma is the reference, and the design system gets extended rather than the design adjusted to fit.

**Spacing and layout.** Keep values exact. A Figma value that happens to equal a utility's value may use the utility; a value that is one pixel off may not. `43px` is not `44px`, and rounding it is a defect, not a tidy-up.

**Images and SVGs.** Download assets from the MCP's asset URLs into the project's asset directory, with a provenance comment naming the Figma node. Convert hardcoded stroke and fill colours to `currentColor` so the consumer controls colour. **Never hand-draw an icon** — capture it, always.

**Structure.**

- **Show, don't hide, for breakpoints.** Desktop and mobile are separate frames at separate node ids. When both exist, implement both. When only one exists, the other is your best-faith translation of the same visual logic — and you say so.
- **One component, one responsibility.** A chunk that repeats becomes its own component.
- **Keep the markup order.** The design context lists children in DOM order, which is also the screen-reader order. Preserve it.

## Verify

1. **Visual comparison** against the screenshot you already fetched. Every sizing, spacing, and colour mismatch is a bug.
2. **Contrast audit** — every text and background pair must clear {{A11Y}}. Where the reference's own colours fail, **accessibility wins**: substitute an audited pair and record why in the component.
3. **Responsive check** at every width the reference covers. Both must match the corresponding frame.
4. **The gate** — {{GATE_LIST}}. Document any pre-existing failure; never claim a clean gate when one was already failing.

## When the design context is wrong

The MCP occasionally emits classes that cannot combine, or layout that contradicts the metadata. When that happens: trust the metadata's coordinates and sizes over the class names, derive the correct markup from them, and note the discrepancy in the component so the next person knows it was deliberate.

## Report

Name the node id, the widths you built, every token you mapped, anything you had to derive from metadata rather than read directly, and every place you departed from the reference with the rule that justified it.
