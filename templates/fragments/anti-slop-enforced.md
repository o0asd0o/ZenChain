## 6. Anti-slop preserves evidence in TypeScript and JavaScript

The gate runs the project-vendored anti-slop Oxlint plugin. Its diagnostics are blocking. Do not suppress or launder a finding to make the gate green.

- Preserve inferred keys and concrete types; do not widen a known value and assert it back later.
- Parse untrusted data at its boundary; do not spread `unknown`, `any`, `{}`, `object`, `typeof`, or reflection through application code as a substitute for validation.
- Use real dependency seams in tests instead of module mocking.
- Prefer `satisfies`, `as const`, and named contracts. A necessary non-const assertion requires a specific `SAFETY:` comment naming the checked invariant.
- Apply the Effect rule group only when `effect` is a direct project dependency.

Installation is project-owned at `tools/oxlint/anti-slop/`. A Foundation ticket must list `oxlint`, `@oxlint/plugins`, and the vendored plugin under `## Approved Technical Changes`; neither an implementation agent nor `zen render` may add them silently.
