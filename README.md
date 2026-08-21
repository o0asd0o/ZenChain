# ZenChain — a portable six-agent implementation pipeline

Installs an unattended implement→review→fix→QA pipeline into any git repository. Extracted from a project that ran it for nine PRDs; every rule in the templates is there because breaking it cost a real round.

```bash
git clone https://github.com/o0asd0o/ZenChain.git ~/.local/share/zenchain
mkdir -p ~/.local/bin
ln -sfn ~/.local/share/zenchain/zen ~/.local/bin/zen
cd ~/code/my-project                   # then, from inside any project folder:
zen init                               # interview, then render
zen doctor                             # check the install and its backends
```

`zen init` with no argument targets the current directory. On a fresh repo it will **not** tell you to run the pipeline — there is nothing to run. It points at `/plan-app` → `/grill-with-docs` → `/to-spec` → `/to-tickets` first, and `zen doctor` re-reads the repo's state every time to print the step you are actually on. **Symlink it, never copy it** — the script resolves its own location back through the link to find `templates/`, and a copy has no way to reach them. It refuses to write anything at all rather than half-render if it cannot.

### Windows

Install [Git for Windows](https://git-scm.com/download/win), open PowerShell, and run:

```powershell
irm https://raw.githubusercontent.com/o0asd0o/ZenChain/main/install.ps1 | iex
```

The installer clones ZenChain into `%LOCALAPPDATA%\ZenChain`, creates `zen.cmd` and `zen.ps1` in `%USERPROFILE%\bin`, and adds that directory to your user `PATH`. Open a new terminal, then run `zen doctor`. The command uses Git Bash under the hood; pure PowerShell execution is not supported because ZenChain is a Bash pipeline.

## What gets installed

| Path                                | What it is                                                      |
| ----------------------------------- | --------------------------------------------------------------- |
| `.zenchain/config.env`                   | every answer from the interview — the re-render source           |
| `<pipeline-dir>/ORCHESTRATOR.md`    | the pipeline itself; the orchestrator reads this and follows it   |
| `.claude/agents/*.md`               | role prompts, for roles running as native Claude subagents        |
| `.zenchain/agents/*.md`                  | role prompts, for roles dispatched through the bridge             |
| `.zenchain/bin/zenchain-agent`                | the bridge — runs a role headlessly on claude, codex, or pi       |
| `.zenchain/bin/zenchain-ticket-check`         | tracker-neutral, fail-closed ticket readiness gate                |
| `.zenchain/bin/zenchain-anti-slop-check`      | verifies enforced TypeScript/JavaScript anti-slop lint setup       |
| `.claude/skills/run-issue`          | entry point: one issue, then stop                                 |
| `.claude/skills/run-prd`            | entry point: one PRD, then stop at the human checkpoint           |
| `.codex/prompts/run-{issue,prd}.md` | the same two entry points, when the orchestrator runs on Codex    |
| `docs/agents/*.md`                  | tracker, triage, domain, flow, and code-standards conventions      |
| `docs/INBOX.md`                    | tracker-neutral queue of unanswered human questions; never overwritten |
| `<skills-dir>/{code-review,diagnosing-bugs,tdd,research,…}` | Matt Pocock's engineering skills, vendored at a pinned commit |
| `AGENTS.md`                         | an `## Agent skills` block between markers, so the skills find their config |
| `CLAUDE.md`                         | a single line, `@AGENTS.md`, importing the above                            |

Nothing is written outside those paths. Generated role/docs files are re-rendered; `docs/INBOX.md` is initialised only when absent and never overwritten. Existing legacy ADR/decision files are preserved but are not implementation authority.

**The agent file stays a pointer, not a rulebook.** It loads into every session and every subagent, so anything inlined there is paid for by roles that cannot use it. Coding standards live in `docs/agents/code-standards.md` and are **routed**: read by `implementer`, `fixer`, and `reviewer`, and by none of `explorer`, `qa`, `decider` — which never write product code. The test asserts both halves of that, so a future edit cannot quietly broadcast it again.

**Why two files.** `AGENTS.md` is the cross-tool convention and holds the block; `CLAUDE.md` is the file Claude Code is documented to load, and gets `@AGENTS.md`. Relying on `AGENTS.md` alone under `runner=claude` risks a perfectly good config the model never sees, so `zen doctor` **fails** when the import is missing, and fails again if both files end up carrying the block. A repo where an earlier version wrote the block straight into `CLAUDE.md` is migrated on the next render. Set `ZENCHAIN_AGENTS_FILE` to put the block somewhere else verbatim, with no import wiring.

## Where this sits in a longer flow

ZenChain is the **unattended half**. The interactive half — idea → grilled → spec → tickets — belongs to [Matt Pocock's engineering skills](https://github.com/mattpocock/skills), and ZenChain does not automate it: most of those skills are user-only by design, because they exist to interview a human.

```
  /plan-app ──→ /grill-with-docs ──→ /to-spec ──→ /to-tickets ═══╬══>  /run-prd  (ZenChain)
   (agenda +     (one app-wide       (one per     (per PRD)      ║
    PRD areas)    session)            area)                      ║
  /research /prototype /wayfinder /triage ───────────────────────┘
                                             the seam: agent-ready tickets exist
```

`/plan-app` is rendered by ZenChain and is the front door: the app-wide grilling agenda (stack, domain vocabulary, trust boundaries, operations) plus the decomposition into PRD areas that reaches **release, not feature-complete** — Foundation → Identity → Core domain → Data → Interface → Integrations → Observability → Security hardening → Release & operations. Security appears twice on purpose: as acceptance criteria on every PRD, and as one PRD owning what no feature owns.

Below the seam, each role drives a skill: `implementer` → `/implement` + `/tdd`; `reviewer` → the two axes of `/code-review`; `fixer` and `qa` → `/diagnosing-bugs` on anything broken; the orchestrator → `/resolving-merge-conflicts`. The compatible `decider` role is a read-only decision advisor: it prepares a human question and never writes a record. Skills are pinned by `ZENCHAIN_SKILLS_PIN`; `zen doctor` reports drift.

Two things `zenchain` handles that a plain copy would get wrong:

- **User-only skills cannot be invoked by an agent.** Upstream ships `/implement` with `disable-model-invocation: true`, so a role prompt citing it dangles. ZenChain strips the flag on the way in and records in the file that it did. `zen doctor` fails if any cited skill is still user-only.
- **`/implement` closes out by running `/code-review`, which would be self-approval.** zenchain's reviewer is a separate agent with no write tools — that is what stops "fix" meaning "delete the failing test". So the implementer runs `/code-review` as a **pre-flight self-check whose output is never a verdict**, and only the reviewer returns PASS.

## The six roles

| Role          | Reads | Writes | Job                                                              |
| ------------- | ----- | ------ | ---------------------------------------------------------------- |
| `implementer` | ✓     | ✓      | builds one issue, test-first, in its own worktree                 |
| `reviewer`    | ✓     | ✗      | judges it against acceptance criteria; **no tools that could fix** |
| `fixer`       | ✓     | ✓      | applies findings; cannot approve its own work                      |
| `qa`          | ✓     | ✓      | exercises a whole PRD end to end, once every issue has passed      |
| `decider`     | ✓     | ✗      | prepares plain-language human questions; never decides             |
| `explorer`    | ✓     | ✗      | one bounded lookup, cheap; for everyone except the reviewer        |

The separation is the point. The reviewer physically cannot fix, so "fix" can never quietly mean "delete the failing test." The fixer cannot approve, so nothing self-certifies. The orchestrator runs the gate itself, so no agent's claim about tests is ever load-bearing.

## What the interview decides

- **Tracker** — `scratch` (markdown issues in-repo, no remote) or `github` (issues + labels + `gh`)
- **Design contract** — `figma` (pixel-exact, MCP extraction), `lofi` (mocks are intent; material gaps enter `docs/INBOX.md`), or `none`
- **Runner** — `claude` (native subagents) or `codex` (headless dispatch through the bridge)
- **Mechanical backend** — run implementer/fixer/explorer on the same CLI, or offload them to `pi` or `codex` on cheaper models
- **Models** — one per tier: build, judge, PRD-gate, scan
- **The gate** — the commands the orchestrator runs itself, in order, as the only ground truth
- **Anti-slop** — `enforced` by default for repositories with `package.json`, or explicitly `off`
- **Concurrency** — 1 lane, or 2 paired by change surface
- **Database** — `none`, `sqlite` (a file per lane; isolation is a path), or `postgres` (a database per lane, created and dropped around the run). The saved config is the factual authority; no duplicate decision record is generated.
- **Generated artifacts and migrations** — whether a merge leaves stale output that must be regenerated before gating
- **Notification** — Slack webhook, push, or terminal-only, once per run at the checkpoint
- **Policy** — round cap, accessibility target, PRD build order

Answers land in `.zenchain/config.env`. Change any of them there and run `zen render` — no re-interview.

Non-interactive: `zen init --answers my-answers.env`, or `zen init --yes` for defaults. See `answers.example.env`.

## Prerequisites

**None.** `zen init` fetches every skill it names, at a pinned commit, so a fresh machine with nothing installed is fully working — including the planning half (`/grill-with-docs`, `/to-spec`, `/to-tickets`, `/triage`, `/wayfinder`) that `plan-app` tells you to run.

```
zen skills             # where each skill lives: a project path, global, or missing
zen skills --global    # install them into ~/.claude/skills, for every project
```

Two rules keep the copies honest:

- **A skill already in `~/.claude/skills` is never vendored locally.** A local copy would shadow yours and then go stale against it. Install globally and re-render, and zenchain *removes* the per-project copies it no longer needs.
- **The planning skills stay user-only.** They exist to interview a person, so an agent must not invoke them — that is how a pipeline ends up inventing the requirements it is meant to build against. Only the skills a role actually drives get their `disable-model-invocation` flag stripped, and `zen doctor` fails if a cited one is still user-only.

`zen init --vendor-skills` copies from `~/.claude/skills` instead of fetching, for an offline setup.

## See it in a terminal

Run the isolated preview to see `help`, `init`, and `doctor` provision a fresh
repository and report its next step:

```bash
./demo/terminal-preview.sh
```

The captured output and visual terminal capture live in [`docs/terminal-demo.md`](docs/terminal-demo.md).

## Design notes worth knowing before you change anything

**The gate is run by the orchestrator, never by an agent.** Agent reports are claims. This is the single rule the whole thing rests on.

**Anti-slop is enforced by default for TypeScript and JavaScript.** ZenChain does not silently install project dependencies. Its preflight requires the project-vendored [dmmulroy/anti-slop](https://github.com/dmmulroy/anti-slop) plugin, every generic rule enabled as an error, direct `oxlint` and `@oxlint/plugins` dependencies, and a lint command in `ZENCHAIN_GATE`. A direct `effect` dependency also requires the opt-in Effect rule group. Repositories without `package.json` are unaffected; set `ZENCHAIN_ANTI_SLOP=off` for a different local policy.

**An empty agent report is a dead dispatch, not an empty result.** A backend out of credit exits zero with empty stdout, which reads as "clean run, nothing to do." The bridge exits 3 on empty output to make that loud — it once looked like a seventeen-minute hang and was a dead process.

**Merge the integration branch into the lane, never the reverse.** Conflicts get resolved and re-gated inside the worktree, where failure is free. The integration branch only ever fast-forwards to something already proven.

**A merged migration is not an applied migration.** The lane migrated its own database; the human's is still on the old schema. That gap shipped green gates and stranded real orders.

**Generated files are why a clean fast-forward goes red.** They are untracked, so a merge cannot update them. Regenerate before gating, not after wondering why.

**Capture the design reference once, before QA.** Design-tool APIs are rate-limited per account. A loop that fetches per round exhausts the budget and reports "unverified" three times.

**No agent picks a new dependency or backend.** Existing manifest/config is factual authority. A new or replacement dependency, engine, service, provider, or major upgrade must be human-approved under the issue's `## Approved Technical Changes`; otherwise the lane stops with one question in `docs/INBOX.md`. The reviewer blocks an unapproved manifest/config change.

**Upstream planning skills stay untouched.** `docs/agents/grill-with-docs-policy.md` limits ADRs to 200 words/20 lines and requires human approval. `docs/agents/ticket-writing-policy.md` gives `/to-tickets` and `/to-issues` the same tracker-neutral packet and 120-line budget. `AGENTS.md` routes these local modifiers only when the matching skill runs.

**Escalation is success.** A blocked issue surfaced to a human is the pipeline working. A green issue that does not do what it claims is the pipeline failing.
