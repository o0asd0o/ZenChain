#!/usr/bin/env bash
# Smoke test: every setup combination must render with no unexpanded {{VAR}},
# no missing fragment, and no unresolved include. Run after editing anything
# under templates/.
#
#   ~/orc2/test.sh
set -euo pipefail
export LC_ALL=C   # same reason as in `orc2`: ASCII patterns over UTF-8 files
ORC2_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="$(mktemp -d -t orc2-test.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT
fail=0

bash -n "$ORC2_HOME/orc2"          || { echo "FAIL  orc2 has a syntax error"; exit 1; }
bash -n "$ORC2_HOME/bin/orc2-agent" || { echo "FAIL  orc2-agent has a syntax error"; exit 1; }
bash -n "$ORC2_HOME/bin/orc2-ticket-check" || { echo "FAIL  orc2-ticket-check has a syntax error"; exit 1; }
if [[ -f "$ORC2_HOME/bin/orc2-anti-slop-check" ]]; then
  bash -n "$ORC2_HOME/bin/orc2-anti-slop-check" || { echo "FAIL  orc2-anti-slop-check has a syntax error"; exit 1; }
else
  echo "FAIL  orc2-anti-slop-check source missing"; fail=1
fi
echo "PASS  existing scripts parse"

# Every combination that changes which fragments get pulled in.
combos=(
  "defaults|"
  "figma-pi-2lane-postgres-codegen-slack|ORC2_TRACKER=scratch ORC2_DESIGN=figma ORC2_RUNNER=claude ORC2_RUNNER_MECH=pi ORC2_LANES=2 ORC2_DB=postgres ORC2_CODEGEN=yes ORC2_NOTIFY=slack"
  "github-lofi-codex-1lane-sqlite-push|ORC2_TRACKER=github ORC2_DESIGN=lofi ORC2_RUNNER=codex ORC2_RUNNER_MECH=codex ORC2_LANES=1 ORC2_DB=sqlite ORC2_CODEGEN=no ORC2_NOTIFY=push"
  "github-none-claude-2lane-nodb|ORC2_TRACKER=github ORC2_DESIGN=none ORC2_RUNNER=claude ORC2_RUNNER_MECH=claude ORC2_LANES=2 ORC2_DB=none ORC2_CODEGEN=yes ORC2_NOTIFY=none"
  "scratch-figma-codexmech-2lane-sqlite|ORC2_TRACKER=scratch ORC2_DESIGN=figma ORC2_RUNNER=claude ORC2_RUNNER_MECH=codex ORC2_LANES=2 ORC2_DB=sqlite ORC2_CODEGEN=no ORC2_NOTIFY=slack"
  "legacy-yesno-db-still-renders|ORC2_TRACKER=scratch ORC2_DESIGN=none ORC2_LANES=2 ORC2_DB=yes ORC2_CODEGEN=no"
  # Engine set, dependent values omitted — must derive from the project name,
  # never render an empty guard.
  "db-set-without-names|ORC2_DB=postgres ORC2_NOTIFY=slack ORC2_LANES=2"
  # A dashed project name must not become a dashed PostgreSQL identifier:
  # createdb quotes it, raw SQL does not, so teardown breaks and provisioning
  # does not. Rendered under a target directory whose basename has a dash.
  "my-zebra-shop|ORC2_DB=postgres ORC2_LANES=2"
  "sqlite-set-without-names|ORC2_DB=sqlite ORC2_LANES=2"
  "anti-slop-off|ORC2_ANTI_SLOP=off"
)

for combo in "${combos[@]}"; do
  name="${combo%%|*}"; vars="${combo#*|}"
  dir="$WORK/$name"; mkdir -p "$dir"; git -C "$dir" init -q .
  env_file="$WORK/$name.env"; : >"$env_file"
  for kv in $vars; do echo "${kv%%=*}=\"${kv#*=}\"" >>"$env_file"; done

  if ! "$ORC2_HOME/orc2" init "$dir" --answers "$env_file" >"$WORK/$name.log" 2>&1; then
    echo "FAIL  $name — init exited non-zero"; sed 's/^/      /' "$WORK/$name.log"; fail=1; continue
  fi

  bad="$(grep -rl '{{\|MISSING FRAGMENT\|orc2:include' "$dir" --include='*.md' 2>/dev/null || true)"
  if [[ -n "$bad" ]]; then
    echo "FAIL  $name — unresolved template markers in:"; sed "s|$dir/|      |" <<<"$bad"; fail=1; continue
  fi

  # Every role must exist exactly once, in one location or the other.
  for role in implementer reviewer fixer qa decider explorer; do
    [[ -f "$dir/.claude/agents/$role.md" || -f "$dir/.orc2/agents/$role.md" ]] \
      || { echo "FAIL  $name — role $role not rendered"; fail=1; }
  done
  [[ -x "$dir/.orc2/bin/orc2-ticket-check" ]] \
    || { echo "FAIL  $name — ticket readiness checker not rendered executable"; fail=1; }

  # Anti-slop is enforced by default, but remains explicitly disableable for a
  # repository whose TypeScript/JavaScript policy differs.
  anti_slop="$(sed -n 's/^ORC2_ANTI_SLOP="\{0,1\}\([a-z]*\)"\{0,1\}$/\1/p' "$dir/.orc2/config.env" | head -1)"
  expected_anti_slop=enforced; [[ "$name" == anti-slop-off ]] && expected_anti_slop=off
  [[ "$anti_slop" == "$expected_anti_slop" ]] \
    || { echo "FAIL  $name — anti-slop mode is '$anti_slop', expected '$expected_anti_slop'"; fail=1; }
  [[ -x "$dir/.orc2/bin/orc2-anti-slop-check" ]] \
    || { echo "FAIL  $name — anti-slop gate checker not rendered executable"; fail=1; }
  orch="$(ls "$dir"/{.orc2,docs/pipeline}/ORCHESTRATOR.md 2>/dev/null | head -1 || true)"
  if [[ "$anti_slop" == enforced ]]; then
    grep -q '^\.orc2/bin/orc2-anti-slop-check$' "$orch" \
      || { echo "FAIL  $name — enforced anti-slop is absent from the gate"; fail=1; }
    grep -q '^## 6\. Anti-slop' "$dir/docs/agents/code-standards.md" \
      || { echo "FAIL  $name — enforced anti-slop is absent from coding standards"; fail=1; }
  else
    grep -q '^\.orc2/bin/orc2-anti-slop-check$' "$orch" \
      && { echo "FAIL  $name — disabled anti-slop still runs in the gate"; fail=1; }
    grep -q '^## 6\. Anti-slop' "$dir/docs/agents/code-standards.md" \
      && { echo "FAIL  $name — disabled anti-slop still renders coding standards"; fail=1; }
  fi

  # An orchestrator that lost its gate block is useless and easy to break.
  grep -q 'You run the gate, not the agents' "$dir"/{.orc2,docs/pipeline}/ORCHESTRATOR.md 2>/dev/null \
    || { echo "FAIL  $name — orchestrator missing the gate rule"; fail=1; }

  # Database selection is already factual configuration. Rendering it again as
  # a numbered decision creates a second authority and makes every builder scan
  # a history directory before doing the issue in front of it.
  db="$(sed -n 's/^ORC2_DB="\{0,1\}\([a-z]*\)"\{0,1\}$/\1/p' "$dir/.orc2/config.env" | head -1)"
  if [[ -n "$db" && "$db" != none ]]; then
    find "$dir" -path '*/decisions/*-database-engine.md' -print -quit | grep -q . \
      && { echo "FAIL  $name — database choice was duplicated as a decision record"; fail=1; }
    # The dev-database guard must render at ANY lane count. It used to live only
    # inside the two-lane fragment, so a serial project with a database got no
    # guard at all.
    orch="$(ls "$dir"/{.orc2,docs/pipeline}/ORCHESTRATOR.md 2>/dev/null | head -1 || true)"
    grep -q 'development database' "$orch" \
      || { echo "FAIL  $name — orchestrator has no development-database guard"; fail=1; }

    # An empty guard prefix renders "only if its name begins ``", which matches
    # every database including the human's. This must be impossible.
    grep -q 'begins `\{1,2\}`' "$orch" \
      && { echo "FAIL  $name — EMPTY database guard prefix rendered"; fail=1; }
    grep -q 'point a lane at `\{1,2\}`' "$orch" \
      && { echo "FAIL  $name — development database is unnamed in the guard"; fail=1; }

    # PostgreSQL identifiers must be safe unquoted, or teardown by raw SQL fails.
    if [[ "$db" == postgres ]]; then
      for k in ORC2_DEV_DB ORC2_LANE_PREFIX; do
        val="$(sed -n "s/^$k=\"\{0,1\}\([^\"]*\)\"\{0,1\}\$/\1/p" "$dir/.orc2/config.env" | head -1)"
        [[ "$val" =~ ^[a-z_][a-z0-9_]*$ ]] \
          || { echo "FAIL  $name — $k='$val' is not a safe unquoted PostgreSQL identifier"; fail=1; }
      done
    fi

  fi

  # One tracker-neutral queue is the only pipeline decision artifact. It is
  # transient and render must never overwrite a human's pending entries.
  inbox="$dir/docs/INBOX.md"
  [[ -f "$inbox" ]] || { echo "FAIL  $name — docs/INBOX.md not rendered"; fail=1; }
  grep -q 'unanswered questions only' "$inbox" 2>/dev/null \
    || { echo "FAIL  $name — INBOX does not state its transient contract"; fail=1; }
  find "$dir" -path '*/decisions/LOG.md' -print -quit | grep -q . \
    && { echo "FAIL  $name — decision LOG.md still generated"; fail=1; }

  # Every skill a role prompt cites must be vendored AND agent-invocable. A
  # skill carrying disable-model-invocation cannot be reached by an agent, so
  # citing it is a dangling reference.
  sk="$dir/.claude/skills"; [[ -d "$dir/.orc2/skills" ]] && sk="$dir/.orc2/skills"
  if [[ -d "$sk" ]]; then
    for s in code-review diagnosing-bugs tdd research resolving-merge-conflicts implement; do
      if [[ ! -f "$sk/$s/SKILL.md" ]]; then
        echo "FAIL  $name — skill $s not vendored"; fail=1
      elif grep -q '^disable-model-invocation: true' "$sk/$s/SKILL.md"; then
        echo "FAIL  $name — skill $s is user-only; an agent cannot invoke it"; fail=1
      fi
    done
    grep -q '^ORC2_SKILLS_PIN="[a-f0-9]\{40\}"$' "$dir/.orc2/config.env" \
      || { echo "FAIL  $name — no 40-char skills pin recorded"; fail=1; }
  else
    echo "      (skills not vendored — offline?)"
  fi

  # The two review axes must both reach the reviewer, and must not be merged.
  rv="$dir/.claude/agents/reviewer.md"; [[ -f "$rv" ]] || rv="$dir/.orc2/agents/reviewer.md"
  grep -q '^## Spec$' "$rv" && grep -q '^## Standards$' "$rv" \
    || { echo "FAIL  $name — reviewer missing a review axis"; fail=1; }
  grep -q 'never rerank across them' "$rv" \
    || { echo "FAIL  $name — reviewer missing the no-rerank rule"; fail=1; }

  # The implementer's self-check must be explicitly not a verdict.
  im="$dir/.claude/agents/implementer.md"; [[ -f "$im" ]] || im="$dir/.orc2/agents/implementer.md"
  grep -q 'not your verdict' "$im" \
    || { echo "FAIL  $name — implementer self-check is not marked as non-authoritative"; fail=1; }

  # A repo with no tickets must not be told to run the pipeline. That suggestion
  # was the original bug: `orc2 init` printed /run-prd on an empty repo, where
  # nothing had yet decided what to build.
  ns="$("$ORC2_HOME/orc2" doctor "$dir" 2>&1 || true)"
  if grep -q 'nothing for the pipeline to run yet' <<<"$ns"; then
    grep -q 'plan-app' <<<"$ns" \
      || { echo "FAIL  $name — empty repo not pointed at plan-app"; fail=1; }
    grep -q 'grill-with-docs' <<<"$ns" \
      || { echo "FAIL  $name — empty repo not pointed at the grilling"; fail=1; }
  else
    echo "FAIL  $name — empty repo was not detected as empty"; fail=1
  fi
  pa="$dir/.claude/skills/plan-app/SKILL.md"; [[ -f "$pa" ]] || pa="$dir/.codex/prompts/plan-app.md"
  [[ -f "$pa" ]] || { echo "FAIL  $name — plan-app entry point not rendered"; fail=1; }
  # The agenda must be batched, not serial: an interrogation loses the human
  # around question twelve, and most of the agenda has no dependencies at all.
  if [[ -f "$pa" ]]; then
    grep -q 'Ask in batches' "$pa" \
      || { echo "FAIL  $name — plan-app lost the batching rule"; fail=1; }
    b="$(grep -c '^#### Batch ' "$pa" || true)"
    [[ "$b" -ge 6 ]] || { echo "FAIL  $name — plan-app has $b batches, expected 6"; fail=1; }
    g="$(grep -c 'gate →' "$pa" || true)"
    [[ "$g" -ge 4 ]] || { echo "FAIL  $name — plan-app marks $g gates, expected the 5 real ones"; fail=1; }
  fi
  for area in Foundation 'Security hardening' 'Release & operations' Observability; do
    grep -q "$area" "$dir/docs/agents/flow.md" \
      || { echo "FAIL  $name — flow doc omits the '$area' area"; fail=1; }
  done

  # The seam must be documented, and the skills' config block written.
  [[ -f "$dir/docs/agents/flow.md" ]] || { echo "FAIL  $name — no flow doc"; fail=1; }
  # AGENTS.md is the single source and CLAUDE.md imports it. Exactly one copy of
  # the block, in AGENTS.md, and an import in CLAUDE.md — a repo with the block
  # only in AGENTS.md and no import can be invisible to Claude Code.
  # `|| true`: grep exits non-zero on an agent file that does not exist, and
  # pipefail would make the assignment fail the whole script.
  blocks="$( { grep -rc 'orc2:agent-skills:start' "$dir"/{CLAUDE.md,AGENTS.md} 2>/dev/null || true; } | awk -F: '{s+=$2} END{print s+0}')"
  [[ "$blocks" == 1 ]] || { echo "FAIL  $name — Agent skills block appears $blocks times, expected 1"; fail=1; }
  grep -q 'orc2:agent-skills:start' "$dir/AGENTS.md" 2>/dev/null \
    || { echo "FAIL  $name — the block is not in AGENTS.md"; fail=1; }
  grep -q '^@AGENTS\.md$' "$dir/CLAUDE.md" 2>/dev/null \
    || { echo "FAIL  $name — CLAUDE.md does not import AGENTS.md"; fail=1; }
  # Code standards live in their own file and are ROUTED, not broadcast. The agent
  # file loads into every session and every subagent, so the rules must not be
  # inlined there — explorer, qa and decider never write product code.
  cs="$dir/docs/agents/code-standards.md"
  [[ -f "$cs" ]] || { echo "FAIL  $name — docs/agents/code-standards.md not rendered"; fail=1; }
  if [[ -f "$cs" ]]; then
    for rule in 'One change, one problem' 'One component per file' 'helpers' 'Routes stay thin' 'not for a model reading it'; do
      grep -q "$rule" "$cs" || { echo "FAIL  $name — code standard missing: $rule"; fail=1; }
    done
    # Rule 5 must bind in both directions, or a reviewer turns it into a demand
    # for more prose — the opposite of what it is for.
    grep -q 'Default to no comment' "$cs" \
      || { echo "FAIL  $name — rule 5 lost its default"; fail=1; }
    grep -q 'is not a finding you may raise' "$rv" \
      || { echo "FAIL  $name — reviewer may still demand explanatory comments"; fail=1; }
  fi
  grep -q 'One component per file' "$dir/AGENTS.md" 2>/dev/null \
    && { echo "FAIL  $name — the standards are inlined in AGENTS.md; they must be a pointer"; fail=1; }
  grep -q 'code-standards.md' "$dir/AGENTS.md" 2>/dev/null \
    || { echo "FAIL  $name — AGENTS.md does not point at code-standards.md"; fail=1; }
  # Routed to the three roles that write or judge code...
  for role in implementer fixer reviewer; do
    rf="$dir/.claude/agents/$role.md"; [[ -f "$rf" ]] || rf="$dir/.orc2/agents/$role.md"
    grep -q 'code-standards.md' "$rf" 2>/dev/null \
      || { echo "FAIL  $name — $role is not routed to code-standards.md"; fail=1; }
  done
  # ...and to none of the three that do not.
  for role in explorer qa decider; do
    rf="$dir/.claude/agents/$role.md"; [[ -f "$rf" ]] || rf="$dir/.orc2/agents/$role.md"
    grep -q 'code-standards.md' "$rf" 2>/dev/null \
      && { echo "FAIL  $name — $role reads code-standards.md but never writes code"; fail=1; }
  done

  # The ticket packet is the only implementation contract. Builder and judge
  # must not discover hidden requirements by browsing PRDs, ADRs or records.
  for role in implementer fixer reviewer; do
    rf="$dir/.claude/agents/$role.md"; [[ -f "$rf" ]] || rf="$dir/.orc2/agents/$role.md"
    grep -q 'Contract References' "$rf" \
      || { echo "FAIL  $name — $role missing explicit contract-reference boundary"; fail=1; }
    grep -qi 'do not scan.*ADR\|never scan.*ADR' "$rf" \
      || { echo "FAIL  $name — $role may still scan ADRs"; fail=1; }
  done

  # Technical changes are authorised by the issue, not a numbered record.
  grep -q 'Approved Technical Changes' "$dir"/{.claude,.orc2}/agents/reviewer.md 2>/dev/null \
    || { echo "FAIL  $name — reviewer missing issue-authorised technical changes"; fail=1; }
  grep -q 'You do not choose dependencies' "$dir"/{.claude,.orc2}/agents/implementer.md 2>/dev/null \
    || { echo "FAIL  $name — implementer missing the dependency ladder"; fail=1; }

  # The compatible role id remains decider, but the role is a read-only advisor.
  dc="$dir/.claude/agents/decider.md"; [[ -f "$dc" ]] || dc="$dir/.orc2/agents/decider.md"
  grep -q 'You prepare questions; you do not decide' "$dc" \
    || { echo "FAIL  $name — decider is still authoritative"; fail=1; }
  grep -q '^tools:.*Write\|^tools:.*Edit' "$dc" \
    && { echo "FAIL  $name — decision advisor still has write tools"; fail=1; }
  grep -qi 'score and rank\|weighted table\|writes a record' "$dc" \
    && { echo "FAIL  $name — decision advisor still produces scored/file records"; fail=1; }
  grep -q 'Do not invoke `/research`' "$dc" \
    || { echo "FAIL  $name — decision advisor may still create research files"; fail=1; }

  # Local policy files modify behavior without shadowing or editing upstream skills.
  for policy in grill-with-docs-policy ticket-writing-policy; do
    pf="$dir/docs/agents/$policy.md"
    [[ -f "$pf" ]] || { echo "FAIL  $name — $policy not rendered"; fail=1; }
    grep -q "$policy.md" "$dir/AGENTS.md" \
      || { echo "FAIL  $name — AGENTS.md does not route $policy"; fail=1; }
  done
  grep -q '/to-tickets.*\/to-issues\|/to-issues.*\/to-tickets' "$dir/docs/agents/ticket-writing-policy.md" 2>/dev/null \
    || { echo "FAIL  $name — ticket policy does not cover both skill names"; fail=1; }

  # Re-rendering from the saved config must reproduce the same tree.
  cp -R "$dir" "$dir.first"
  "$ORC2_HOME/orc2" render "$dir" >/dev/null 2>&1 || { echo "FAIL  $name — render round trip exited non-zero"; fail=1; }
  if ! diff -r -x '.git' "$dir.first" "$dir" >/dev/null 2>&1; then
    echo "FAIL  $name — re-render from config.env is not idempotent"; fail=1; continue
  fi

  echo "PASS  $name"
done

# Readiness is a real gate, not prompt advice. The same checker accepts a local
# markdown file or a tracker body on stdin.
valid="$WORK/ticket-valid.md"
printf '%s\n' \
  '# Refund expired payment' \
  '## Acceptance Criteria' \
  '- [ ] A refund after 30 days is refused. Proof: focused refund test.' \
  '## Scenarios' \
  '| Given | When | Then |' \
  '| --- | --- | --- |' \
  '| A payment is 31 days old | Staff requests a refund | The request is refused |' \
  '## Depends on' \
  'None.' \
  '## Relevant files' \
  '- `src/refunds.ts`' \
  '## Contract References' \
  'None.' \
  '## Approved Technical Changes' \
  'None.' \
  '## Visual Reference' \
  '- Image · component: RefundForm · web: `docs/reference/refund-form.png`' >"$valid"
invalid="$WORK/ticket-invalid.md"
printf '%s\n' '# Refund' '## Acceptance Criteria' '- Return the money.' >"$invalid"
checker="$WORK/defaults/.orc2/bin/orc2-ticket-check"
if "$checker" "$invalid" >/dev/null 2>&1; then
  echo "FAIL  incomplete ticket passed readiness"; fail=1
elif "$checker" "$valid" >/dev/null 2>&1 \
  && "$checker" --ui "$valid" >/dev/null 2>&1 \
  && "$checker" - <"$valid" >/dev/null 2>&1; then
  echo "PASS  ticket readiness rejects incomplete and accepts complete file/stdin packets"
else
  echo "FAIL  complete ticket failed readiness"; fail=1
fi

# The anti-slop preflight is executable policy. It must verify the vendored
# plugin, direct dependencies, configuration, lint gate, and optional Effect
# group without applying TypeScript rules to non-JavaScript repositories.
anti_checker="$ORC2_HOME/bin/orc2-anti-slop-check"
if [[ ! -x "$anti_checker" ]]; then
  echo "FAIL  anti-slop behavior checks unavailable — source checker missing"; fail=1
else
  d="$WORK/anti-slop-valid"; mkdir -p "$d/.orc2" "$d/tools/oxlint/anti-slop"
  printf '%s\n' '{"devDependencies":{"oxlint":"1.78.0","@oxlint/plugins":"1.78.0"}}' >"$d/package.json"
  printf '%s\n' 'export default { jsPlugins: [{ name: "anti-slop", specifier: "./tools/oxlint/anti-slop/index.ts" }], rules: {' >"$d/oxlint.config.ts"
  while IFS= read -r rule; do printf '  "anti-slop/%s": "error",\n' "$rule" >>"$d/oxlint.config.ts"; done <<'RULES'
no-chained-type-assertions
no-conditional-empty-object-spread
no-known-value-widening
no-module-mocking
no-object-parameters
no-reflect-apply
no-reflect-get
no-runtime-typeof
no-shape-in-symbol-names
no-unknown-parameters
no-unknown-returns
no-unknown-type-aliases
no-unsafe-dictionary-type
no-widen-then-assert
require-safety-comment-for-type-assertion
RULES
  printf '%s\n' '} }' >>"$d/oxlint.config.ts"
  printf '%s\n' 'export const antiSlop = true' >"$d/tools/oxlint/anti-slop/index.ts"
  printf '%s\n' 'ORC2_ANTI_SLOP="enforced"' 'ORC2_GATE="npm run lint; npm test"' >"$d/.orc2/config.env"
  "$anti_checker" "$d" >/dev/null 2>&1 \
    && echo "PASS  anti-slop accepts a complete JS/TS setup" \
    || { echo "FAIL  anti-slop rejected a complete JS/TS setup"; fail=1; }

  d="$WORK/anti-slop-missing"; mkdir -p "$d/.orc2"
  printf '%s\n' '{"devDependencies":{"oxlint":"1.78.0","@oxlint/plugins":"1.78.0"}}' >"$d/package.json"
  cp "$WORK/anti-slop-valid/oxlint.config.ts" "$d/oxlint.config.ts"
  printf '%s\n' 'ORC2_ANTI_SLOP="enforced"' 'ORC2_GATE="npm test"' >"$d/.orc2/config.env"
  if "$anti_checker" "$d" >"$WORK/anti-slop-missing.log" 2>&1; then
    echo "FAIL  anti-slop accepted missing plugin and lint gate"; fail=1
  elif grep -q 'plugin source' "$WORK/anti-slop-missing.log" \
    && grep -q 'lint command' "$WORK/anti-slop-missing.log"; then
    echo "PASS  anti-slop rejects missing plugin and lint gate"
  else
    echo "FAIL  anti-slop missing-setup error is incomplete"; fail=1
  fi

  d="$WORK/anti-slop-effect"; mkdir -p "$d/.orc2" "$d/tools/oxlint/anti-slop"
  printf '%s\n' '{"dependencies":{"effect":"3.0.0"},"devDependencies":{"oxlint":"1.78.0","@oxlint/plugins":"1.78.0"}}' >"$d/package.json"
  cp "$WORK/anti-slop-valid/oxlint.config.ts" "$d/oxlint.config.ts"
  printf '%s\n' 'export const antiSlop = true' >"$d/tools/oxlint/anti-slop/index.ts"
  printf '%s\n' 'ORC2_ANTI_SLOP="enforced"' 'ORC2_GATE="npm run lint"' >"$d/.orc2/config.env"
  if "$anti_checker" "$d" >"$WORK/anti-slop-effect.log" 2>&1; then
    echo "FAIL  anti-slop accepted missing Effect rule group"; fail=1
  elif grep -q 'Effect' "$WORK/anti-slop-effect.log"; then
    echo "PASS  direct Effect dependency requires the Effect rule group"
  else
    echo "FAIL  missing Effect rule group gave no actionable error"; fail=1
  fi

  d="$WORK/anti-slop-non-js"; mkdir -p "$d/.orc2"
  printf '%s\n' 'ORC2_ANTI_SLOP="enforced"' 'ORC2_GATE="cargo test"' >"$d/.orc2/config.env"
  "$anti_checker" "$d" >/dev/null 2>&1 \
    && echo "PASS  anti-slop leaves non-JS repositories unaffected" \
    || { echo "FAIL  anti-slop blocked a non-JS repository"; fail=1; }

  d="$WORK/anti-slop-disabled"; mkdir -p "$d/.orc2"
  printf '%s\n' '{"devDependencies":{}}' >"$d/package.json"
  printf '%s\n' 'ORC2_ANTI_SLOP="off"' 'ORC2_GATE="npm test"' >"$d/.orc2/config.env"
  "$anti_checker" "$d" >/dev/null 2>&1 \
    && echo "PASS  explicit anti-slop off bypasses enforcement" \
    || { echo "FAIL  anti-slop off still enforced"; fail=1; }
fi

# A re-render must preserve live INBOX content byte-for-byte.
d="$WORK/inbox-preserve"; mkdir -p "$d"; git -C "$d" init -q .
"$ORC2_HOME/orc2" init "$d" --yes >/dev/null 2>&1
printf '\n## Refund while offline\n- Answer: pending\n' >>"$d/docs/INBOX.md"
before="$(shasum -a 256 "$d/docs/INBOX.md" | awk '{print $1}')"
"$ORC2_HOME/orc2" render "$d" >/dev/null 2>&1
after="$(shasum -a 256 "$d/docs/INBOX.md" | awk '{print $1}')"
[[ "$before" == "$after" ]] && echo "PASS  render preserves docs/INBOX.md" \
  || { echo "FAIL  render overwrote docs/INBOX.md"; fail=1; }

# A pending legacy queue must block before any generated file changes.
d="$WORK/legacy-inbox"; mkdir -p "$d/.scratch/decisions"; git -C "$d" init -q .
printf '# Decision inbox\n\n### Legacy question\n- **Answer:** pending\n' >"$d/.scratch/decisions/INBOX.md"
printf 'ORC2_PROJECT="legacy"\nORC2_TRACKER="scratch"\n' >"$d/.orc2-config.env"
mkdir -p "$d/.orc2"; cp "$d/.orc2-config.env" "$d/.orc2/config.env"
if "$ORC2_HOME/orc2" render "$d" >"$WORK/legacy-inbox.log" 2>&1; then
  echo "FAIL  pending legacy INBOX did not block render"; fail=1
elif [[ -e "$d/docs/INBOX.md" || -e "$d/.orc2/ORCHESTRATOR.md" ]]; then
  echo "FAIL  legacy guard wrote files before stopping"; fail=1
elif grep -q 'legacy INBOX' "$WORK/legacy-inbox.log"; then
  echo "PASS  pending legacy INBOX blocks before render"
else
  echo "FAIL  legacy INBOX guard gave no actionable error"; fail=1
fi

# The resolved pin must be refs/heads/main exactly. `ls-remote <url> main`
# matches by suffix and puts refs/heads/changeset-release/main first, so a
# first-line read silently pins a release bot's branch.
want_sha="$(git ls-remote "https://github.com/mattpocock/skills.git" refs/heads/main 2>/dev/null | awk '{print $1}' || true)"
got_sha="$(sed -n 's/^ORC2_SKILLS_PIN="\([a-f0-9]*\)"$/\1/p' "$WORK/defaults/.orc2/config.env" | head -1 || true)"
if [[ -z "$want_sha" ]]; then
  echo "SKIP  pin check (offline)"
elif [[ "$want_sha" == "$got_sha" ]]; then
  echo "PASS  pin is refs/heads/main (${got_sha:0:12})"
else
  echo "FAIL  pin is ${got_sha:0:12}, but refs/heads/main is ${want_sha:0:12} — wrong ref resolved"; fail=1
fi

# It is normally invoked through a symlink on PATH, where `dirname $BASH_SOURCE`
# is the symlink's directory rather than the kit's. That once sent TPL at a
# nonexistent templates/ and half-rendered before failing.
ln -sf "$ORC2_HOME/orc2" "$WORK/orc2-link"
lnk="$WORK/via-link"; mkdir -p "$lnk"; git -C "$lnk" init -q .
if "$WORK/orc2-link" init "$lnk" --yes >"$WORK/via-link.log" 2>&1 \
   && [[ -f "$lnk/.claude/agents/reviewer.md" && -f "$lnk/docs/agents/flow.md" ]]; then
  echo "PASS  works when invoked through a PATH symlink"
else
  echo "FAIL  symlinked invocation did not render fully"; sed 's/^/      /' "$WORK/via-link.log" | tail -5; fail=1
fi

# A kit whose templates cannot be found must refuse to write anything at all,
# rather than leaving a half-install that looks present.
cp "$ORC2_HOME/orc2" "$WORK/orphan-orc2"; chmod +x "$WORK/orphan-orc2"
orphan="$WORK/orphan"; mkdir -p "$orphan"; git -C "$orphan" init -q .
if "$WORK/orphan-orc2" init "$orphan" --yes >/dev/null 2>&1; then
  echo "FAIL  a copied (not symlinked) script rendered without its templates"; fail=1
elif [[ -e "$orphan/.orc2" ]]; then
  echo "FAIL  a template-less run still wrote into the target"; fail=1
else
  echo "PASS  refuses to write when the templates are unreachable"
fi

# The agent-file wiring has three cases worth pinning, because the original bug
# only appeared in the third: a repo with neither file, where the old code created
# AGENTS.md regardless of the runner and Claude Code may never have loaded it.
agentfile_case() { # agentfile_case <name> <setup-fn>
  local nm="$1" setup="$2" d="$WORK/af-$1"
  mkdir -p "$d"; git -C "$d" init -q .
  $setup "$d"
  "$ORC2_HOME/orc2" init "$d" --yes >"$d.log" 2>&1 || { echo "FAIL  agent-file/$nm — init failed"; fail=1; return; }
  local n
  n="$( { grep -rc 'orc2:agent-skills:start' "$d"/{CLAUDE.md,AGENTS.md} 2>/dev/null || true; } | awk -F: '{s+=$2} END{print s+0}')"
  if [[ "$n" != 1 ]]; then echo "FAIL  agent-file/$nm — $n blocks, expected exactly 1"; fail=1; return; fi
  grep -q 'orc2:agent-skills:start' "$d/AGENTS.md" 2>/dev/null || { echo "FAIL  agent-file/$nm — block not in AGENTS.md"; fail=1; return; }
  grep -q '^@AGENTS\.md$' "$d/CLAUDE.md" 2>/dev/null || { echo "FAIL  agent-file/$nm — CLAUDE.md lacks the import"; fail=1; return; }
  echo "PASS  agent-file/$nm"
}
setup_none()   { :; }
setup_human()  { printf '# app\n\nHuman notes I care about.\n' >"$1/CLAUDE.md"; }
setup_legacy() { printf '# legacy\n\nAbove.\n\n<!-- orc2:agent-skills:start -->\nSTALE\n<!-- orc2:agent-skills:end -->\n\nBelow.\n' >"$1/CLAUDE.md"; }
agentfile_case neither setup_none
agentfile_case existing-claude setup_human
agentfile_case legacy-inline setup_legacy
# Migration must not leave the old content behind, and must not eat the human's.
grep -q 'STALE' "$WORK/af-legacy-inline/CLAUDE.md" 2>/dev/null \
  && { echo "FAIL  agent-file/legacy-inline — stale block content survived"; fail=1; } \
  || echo "PASS  agent-file/legacy-inline drops the stale block"
grep -q 'Human notes I care about' "$WORK/af-existing-claude/CLAUDE.md" \
  && echo "PASS  agent-file preserves human content" \
  || { echo "FAIL  agent-file — human content in CLAUDE.md was lost"; fail=1; }
# Re-rendering must not duplicate the import.
"$ORC2_HOME/orc2" render "$WORK/af-existing-claude" >/dev/null 2>&1 || true
n="$(grep -c '^@AGENTS\.md$' "$WORK/af-existing-claude/CLAUDE.md" || true)"
[[ "$n" == 1 ]] && echo "PASS  import is not duplicated on re-render" \
  || { echo "FAIL  agent-file — $n imports after re-render, expected 1"; fail=1; }
# doctor must catch a missing import rather than passing a repo the model cannot see.
grep -v '^@AGENTS\.md$' "$WORK/af-existing-claude/CLAUDE.md" >"$WORK/af.tmp" && mv "$WORK/af.tmp" "$WORK/af-existing-claude/CLAUDE.md"
# Capture first: doctor exits non-zero by design when it finds a fault, and
# piping it straight into grep lets pipefail mask the match.
af_out="$("$ORC2_HOME/orc2" doctor "$WORK/af-existing-claude" 2>&1 || true)"
if grep -q 'does not import AGENTS.md' <<<"$af_out"; then
  echo "PASS  doctor catches a missing AGENTS.md import"
else
  echo "FAIL  doctor passed a repo whose CLAUDE.md does not import AGENTS.md"; fail=1
fi

# Static: every {{VAR}} a template uses must be exported, or it renders literally.
# The per-combo `{{` scan only covers the combos listed above; this covers all of
# them, including variables only reachable in a config nobody happens to test.
# Match the name anywhere in the script: many are exported on a continuation
# line of a multi-line `export A B C \`, which an `^export ORC2_X` pattern misses.
# `\b` is not portable under LC_ALL=C on BSD grep, so use an explicit delimiter class.
unexported=""
for v in $(grep -rho '{{[A-Z_0-9]*}}' "$ORC2_HOME/templates/" | tr -d '{}' | sort -u); do
  grep -qE "ORC2_$v[^A-Z_0-9]" "$ORC2_HOME/orc2" || unexported="$unexported $v"
done
[[ -z "$unexported" ]] && echo "PASS  every template variable is exported" \
  || { echo "FAIL  template variables never exported:$unexported"; fail=1; }

# --- regressions found by the kimi-k3 review, each verified before fixing ----

# An unbalanced marker pair must not splice: awk would set skip=1 and never clear
# it, deleting everything from the start marker to EOF. Verified: it did.
d="$WORK/markers"; mkdir -p "$d"; git -C "$d" init -q .
printf '# app\n\n<!-- orc2:agent-skills:start -->\nold\n\nHUMAN NOTES\n' >"$d/AGENTS.md"
"$ORC2_HOME/orc2" init "$d" --yes >/dev/null 2>&1 || true
grep -q 'HUMAN NOTES' "$d/AGENTS.md" \
  && echo "PASS  unbalanced markers do not delete the rest of the file" \
  || { echo "FAIL  DATA LOSS — content after an unpaired start marker was deleted"; fail=1; }

# mktemp+mv used to hand the destination mode 0600 and replace symlinks with
# regular files, silently detaching a dotfiles-managed AGENTS.md.
d="$WORK/perms"; mkdir -p "$d"; git -C "$d" init -q .
"$ORC2_HOME/orc2" init "$d" --yes >/dev/null 2>&1
chmod 644 "$d/AGENTS.md"; "$ORC2_HOME/orc2" render "$d" >/dev/null 2>&1
[[ "$(stat -f '%Lp' "$d/AGENTS.md" 2>/dev/null || stat -c '%a' "$d/AGENTS.md")" == 644 ]] \
  && echo "PASS  re-render preserves file mode" \
  || { echo "FAIL  re-render changed the file mode (mktemp 0600 leak)"; fail=1; }
mkdir -p "$d/real" && mv "$d/AGENTS.md" "$d/real/" && ln -s real/AGENTS.md "$d/AGENTS.md"
"$ORC2_HOME/orc2" render "$d" >/dev/null 2>&1
[[ -L "$d/AGENTS.md" ]] \
  && echo "PASS  re-render writes through a symlink" \
  || { echo "FAIL  re-render replaced a symlink with a regular file"; fail=1; }

# `render >"$dest"` truncated before running, so a bad enum destroyed the
# previous good file and left placeholders in everything rendered before it.
d="$WORK/badenum"; mkdir -p "$d"; git -C "$d" init -q .
"$ORC2_HOME/orc2" init "$d" --yes >/dev/null 2>&1
before="$(wc -c <"$d/docs/agents/issue-tracker.md")"
perl -pi -e 's/^ORC2_TRACKER=.*/ORC2_TRACKER="jira"/' "$d/.orc2/config.env"
"$ORC2_HOME/orc2" render "$d" >/dev/null 2>&1 || true
[[ "$(wc -c <"$d/docs/agents/issue-tracker.md")" == "$before" ]] \
  && echo "PASS  an invalid enum leaves existing files intact" \
  || { echo "FAIL  an invalid enum truncated an existing rendered file"; fail=1; }

# The tarball root is <repo-name>-<sha>; hardcoding "skills-" extracted nothing
# for any other repo, and the render still reported success.
grep -q 'ORC2_SKILLS_REPO##\*/' "$ORC2_HOME/orc2" \
  && echo "PASS  tar member path derives from the repo name" \
  || { echo "FAIL  tar member path is hardcoded; a renamed skills repo vendors nothing"; fail=1; }

# A zero-padded menu answer is an invalid octal literal: (( 08 )) aborts.
grep -q '10#\$ans' "$ORC2_HOME/orc2" \
  && echo "PASS  menu input is parsed base-ten" \
  || { echo "FAIL  zero-padded input still hits the octal error"; fail=1; }

# Only the first two --- close frontmatter; a horizontal rule in a role body was
# being dropped out of the system prompt.
grep -q 'n<2 && /\^---\$/' "$ORC2_HOME/bin/orc2-agent" \
  && echo "PASS  bridge frontmatter parser stops after two delimiters" \
  || { echo "FAIL  bridge still strips --- lines from the role body"; fail=1; }

# One authority per question: the reference-vs-accessibility collision is human-owned.
if grep -q 'Do not substitute a colour' "$ORC2_HOME/templates/skills/figma-to-code/SKILL.md" \
   && grep -q 'reference loses and the human picks the replacement' "$ORC2_HOME/templates/ORCHESTRATOR.md"; then
  echo "PASS  accessibility-vs-reference has a single authority"
else
  echo "FAIL  the a11y collision is routable to more than one authority"; fail=1
fi

# --- regressions the fixes themselves introduced, caught by the verify round ---

# Counting markers is not enough: with the end marker ABOVE the start, both counts
# are 1 and the splice still deletes from the start marker to EOF.
d="$WORK/revmark"; mkdir -p "$d"; git -C "$d" init -q .
printf '# app\n\n<!-- orc2:agent-skills:end -->\n\n<!-- orc2:agent-skills:start -->\n\nNOTES AFTER START\n' >"$d/AGENTS.md"
"$ORC2_HOME/orc2" init "$d" --yes >/dev/null 2>&1 || true
grep -q 'NOTES AFTER START' "$d/AGENTS.md" \
  && echo "PASS  reversed markers do not delete the tail" \
  || { echo "FAIL  DATA LOSS — end-above-start still deletes to EOF"; fail=1; }

# A write that cannot happen must fail loudly, not print "wrote" and exit 0.
d="$WORK/rodir"; mkdir -p "$d"; git -C "$d" init -q .
"$ORC2_HOME/orc2" init "$d" --yes >/dev/null 2>&1
chmod 555 "$d"
if "$ORC2_HOME/orc2" render "$d" >"$d.log" 2>&1; then
  echo "FAIL  render reported success into an unwritable directory"; fail=1
else
  echo "PASS  an unwritable destination fails loudly"
fi
chmod 755 "$d"

# Derived prose must not land in the hand-edited config, where derive() silently
# overwrites it on the next run.
d="$WORK/derived"; mkdir -p "$d"; git -C "$d" init -q .
"$ORC2_HOME/orc2" init "$d" --yes >/dev/null 2>&1
if grep -qE 'ORC2_(SKILL_HOW|EXPLORER_HOW|SKILLS_DIR|DB_RECORD_LINE)=' "$d/.orc2/config.env"; then
  echo "FAIL  derived variables leaked into config.env"; fail=1
else
  echo "PASS  derived variables stay out of config.env"
fi

# The write must stay atomic: a rename, never a truncate-then-write. Strip comments
# first — write_preserving explains the rejected `cat >` form in its own comment,
# and matching that made this guard fail on correct code.
# Assert the atomic form is present, rather than trying to prove the truncating
# form is absent: `cat "$src" >"$dest"` is quoted in write_preserving's own
# comment explaining why it was rejected, so matching on it flags correct code.
if grep -q 'if ! mv "\$src" "\$real"' "$ORC2_HOME/orc2"; then
  echo "PASS  writes are atomic renames"
else
  echo "FAIL  write_preserving no longer uses an atomic rename"; fail=1
fi

# --- round 3: regressions the round-2 fixes introduced -----------------------

# Every freshly rendered file must be readable, not mktemp's 0600. The mode was
# only captured when the destination already existed, so a first render shipped
# the entire kit as -rw-------.
d="$WORK/modes"; mkdir -p "$d"; git -C "$d" init -q .
"$ORC2_HOME/orc2" init "$d" --yes >/dev/null 2>&1
want="$(printf '%o' "$(( 0666 & ~0$(umask) ))")"
badmode=""
for f in .orc2/ORCHESTRATOR.md .claude/agents/reviewer.md docs/agents/flow.md AGENTS.md; do
  [[ -e "$d/$f" ]] || continue
  m="$(stat -f '%Lp' "$d/$f" 2>/dev/null || stat -c '%a' "$d/$f")"
  [[ "$m" == "$want" ]] || badmode="$badmode $f:$m"
done
[[ -z "$badmode" ]] && echo "PASS  fresh files render with the umask mode ($want)" \
  || { echo "FAIL  fresh files have the wrong mode (want $want):$badmode"; fail=1; }

# Both markers on ONE line balances the counts and passes a `>` order check,
# while the splice still deletes to EOF.
d="$WORK/sameline"; mkdir -p "$d"; git -C "$d" init -q .
printf '# app\n\nInline orc2:agent-skills:start and orc2:agent-skills:end mention.\n\nTAIL NOTES\n' >"$d/AGENTS.md"
"$ORC2_HOME/orc2" init "$d" --yes >/dev/null 2>&1 || true
grep -q 'TAIL NOTES' "$d/AGENTS.md" \
  && echo "PASS  same-line markers do not delete the tail" \
  || { echo "FAIL  DATA LOSS — markers on one line still delete to EOF"; fail=1; }

# mv into a directory succeeds by moving the file inside it: wrong place, and it
# used to report success.
d="$WORK/dirdest"; mkdir -p "$d"; git -C "$d" init -q .
"$ORC2_HOME/orc2" init "$d" --yes >/dev/null 2>&1
rm -f "$d/AGENTS.md"; mkdir "$d/AGENTS.md"
if "$ORC2_HOME/orc2" render "$d" >/dev/null 2>&1; then
  echo "FAIL  render reported success with a directory as the destination"; fail=1
else
  echo "PASS  a directory destination fails loudly"
fi

# Effort is pinned per role and must actually reach the backend. The bridge read
# model and tools but not effort, so every role dispatched through it ran at the
# backend's default — silently, since nothing in the output says what it used.
d="$WORK/effort"; mkdir -p "$d"; git -C "$d" init -q .
printf 'ORC2_RUNNER="claude"\nORC2_RUNNER_MECH="pi"\nORC2_MODEL_BUILD="stub/model"\n' >"$d/e.env"
"$ORC2_HOME/orc2" init "$d" --answers "$d/e.env" >/dev/null 2>&1
for role in implementer fixer; do
  rf="$d/.orc2/agents/$role.md"; [[ -f "$rf" ]] || rf="$d/.claude/agents/$role.md"
  grep -q '^effort: medium$' "$rf" \
    || { echo "FAIL  $role is not pinned to medium effort"; fail=1; }
done
stub="$WORK/stubbin"; mkdir -p "$stub"
for b in pi claude codex; do printf '#!/usr/bin/env bash\necho "ARGV: $*"\n' >"$stub/$b"; chmod +x "$stub/$b"; done
argv_pi="$(cd "$d" && PATH="$stub:$PATH" .orc2/bin/orc2-agent implementer "x" 2>&1 || true)"
argv_cl="$(cd "$d" && PATH="$stub:$PATH" .orc2/bin/orc2-agent implementer --backend claude "x" 2>&1 || true)"
argv_cx="$(cd "$d" && PATH="$stub:$PATH" .orc2/bin/orc2-agent implementer --backend codex  "x" 2>&1 || true)"
bad=""
grep -q -- '--thinking medium' <<<"$argv_pi" || bad="$bad pi"
grep -q -- '--effort medium'   <<<"$argv_cl" || bad="$bad claude"
grep -q 'model_reasoning_effort="medium"' <<<"$argv_cx" || bad="$bad codex"
[[ -z "$bad" ]] && echo "PASS  effort reaches every backend (implementer at medium)" \
  || { echo "FAIL  effort never reaches:$bad"; fail=1; }

# plan-app names /grill-with-docs, /to-spec, /to-tickets and friends. On a machine
# with none of them installed, those instructions dangle — and an uninstalled
# skill fails silently, which reads as "the step did not apply".
empty="$WORK/no-global-skills"; mkdir -p "$empty"
d="$WORK/frontend"; mkdir -p "$d"; git -C "$d" init -q .
ORC2_UPSTREAM_SKILLS="$empty" "$ORC2_HOME/orc2" init "$d" --yes >/dev/null 2>&1
sk="$d/.claude/skills"
fe_bad=""
for s in grill-with-docs grilling to-spec to-tickets triage wayfinder handoff; do
  [[ -f "$sk/$s/SKILL.md" ]] || fe_bad="$fe_bad $s"
done
[[ -z "$fe_bad" ]] && echo "PASS  planning skills vendored when nothing is installed globally" \
  || { echo "FAIL  planning skills missing on a bare machine:$fe_bad"; fail=1; }

# grill-with-docs is a two-line skill whose body is "Run a /grilling session".
# Vendoring it without grilling installs a pointer to nothing.
[[ -d "$sk/grilling" ]] \
  && echo "PASS  grill-with-docs's /grilling dependency is vendored too" \
  || { echo "FAIL  grilling missing — grill-with-docs points at nothing"; fail=1; }

# These are user-only BY DESIGN: they interview a human. Stripping that flag would
# let an agent invent the requirements it is supposed to be building against.
uo_bad=""
for s in grill-with-docs to-spec to-tickets triage wayfinder; do
  [[ -f "$sk/$s/SKILL.md" ]] || continue
  grep -q '^disable-model-invocation: true' "$sk/$s/SKILL.md" || uo_bad="$uo_bad $s"
done
[[ -z "$uo_bad" ]] && echo "PASS  planning skills stay user-only" \
  || { echo "FAIL  planning skills made agent-invocable:$uo_bad"; fail=1; }

# A skill already installed globally must not also be vendored locally, or the
# copy shadows the user's own and goes stale against it.
d2="$WORK/dedup"; mkdir -p "$d2"; git -C "$d2" init -q .
fakeglobal="$WORK/fakeglobal"; mkdir -p "$fakeglobal/triage" "$fakeglobal/grill-with-docs" "$fakeglobal/to-tickets"
printf -- '---\nname: triage\n---\nmine\n' >"$fakeglobal/triage/SKILL.md"
printf -- '---\nname: grill-with-docs\ndisable-model-invocation: true\n---\nupstream grill\n' >"$fakeglobal/grill-with-docs/SKILL.md"
printf -- '---\nname: to-tickets\ndisable-model-invocation: true\n---\nupstream tickets\n' >"$fakeglobal/to-tickets/SKILL.md"
grill_before="$(shasum -a 256 "$fakeglobal/grill-with-docs/SKILL.md" | awk '{print $1}')"
tickets_before="$(shasum -a 256 "$fakeglobal/to-tickets/SKILL.md" | awk '{print $1}')"
ORC2_UPSTREAM_SKILLS="$fakeglobal" "$ORC2_HOME/orc2" init "$d2" --yes >/dev/null 2>&1
[[ -d "$d2/.claude/skills/triage" ]] \
  && { echo "FAIL  a globally-installed skill was vendored locally anyway"; fail=1; } \
  || echo "PASS  globally-installed skills are not duplicated locally"
grill_after="$(shasum -a 256 "$fakeglobal/grill-with-docs/SKILL.md" | awk '{print $1}')"
tickets_after="$(shasum -a 256 "$fakeglobal/to-tickets/SKILL.md" | awk '{print $1}')"
if [[ "$grill_before" == "$grill_after" && "$tickets_before" == "$tickets_after" ]]; then
  echo "PASS  upstream planning skills remain byte-identical"
else
  echo "FAIL  upstream planning skill was modified"; fail=1
fi

# plan-app must tell the reader how to get what it names.
grep -q 'orc2 skills' "$d/.claude/skills/plan-app/SKILL.md" \
  && echo "PASS  plan-app routes the reader to orc2 skills" \
  || { echo "FAIL  plan-app names skills without saying how to install them"; fail=1; }

# doctor must actually run its checks. It once reported all nine skills as one
# unreachable name because an IFS set for the gate loop leaked into the skills
# loop — a green-looking pass that checked nothing.
d="$WORK/defaults"
if out="$("$ORC2_HOME/orc2" doctor "$d" 2>&1)"; then :; fi
grep -q 'cited skills reachable and agent-invocable' <<<"$out" \
  && echo "PASS  doctor verifies each skill individually" \
  || { echo "FAIL  doctor did not verify the skills (IFS leak?)"; echo "$out" | grep -i skill | sed 's/^/      /'; fail=1; }
grep -qc 'gate cmd' <<<"$out" \
  && echo "PASS  doctor checks the gate commands" \
  || { echo "FAIL  doctor did not check the gate"; fail=1; }
grep -q 'ticket readiness checker present' <<<"$out" \
  && grep -q 'routes both local modifiers' <<<"$out" \
  && echo "PASS  doctor checks readiness gate and local policy routing" \
  || { echo "FAIL  doctor missed readiness gate or local policy routing"; fail=1; }

# The bridge must refuse an unknown role rather than dispatching something.
bridge="$WORK/figma-pi-2lane-postgres-codegen-slack/.orc2/bin/orc2-agent"
# The path must exist, or the test passes vacuously: a nonexistent path exits 127,
# which is non-zero, which looked exactly like "the bridge rejected the role".
# It did that silently for several renames.
[[ -x "$bridge" ]] || { echo "FAIL  bridge not found at $bridge — the rejection test would pass vacuously"; fail=1; }
if [[ -x "$bridge" ]] && "$bridge" nosuchrole "x" 2>/dev/null; then
  echo "FAIL  bridge accepted an unknown role"; fail=1
else
  echo "PASS  bridge rejects an unknown role"
fi

[[ $fail -eq 0 ]] && echo && echo "P  all combinations render" || { echo; echo "R  see FAIL lines above"; exit 1; }
