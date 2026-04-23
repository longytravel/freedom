# Development Workflow Setup — Freedom repo

**Date:** 2026-04-23
**Author:** Claude (Opus 4.7), for longytravel@gmail.com
**Status:** Draft — awaiting user review
**Scope:** How we work in this repo. *Not* the Fire Forex product itself.

---

## 1. Plain-English summary (read this first)

You want a development system that:

- **You push "on" and it runs** — without you needing to remember commands, read diffs, or visit GitHub.com.
- **Asks you design questions** at the right moments — not random, and not silent.
- **Is the quality gate itself** — because you are not a coder and cannot eyeball whether code is correct.
- **Doesn't repeat the last rebuild's mistakes** — where silent-no-op bugs shipped because only unit tests existed and there was no PR discipline.

This spec defines that system as a set of concrete files and settings. Once landed, the flow for every future change looks like this:

```
You say what you want in plain English
   ↓
I ask you clarifying questions (brainstorming skill — automatic)
   ↓
I write a spec + plan (auto), you approve the plan
   ↓
I write code on a branch, tests run locally via hooks
   ↓
Before opening a PR, I run the self-review checklist against my own diff
   ↓
I open a PR via `gh pr create`; self-review output is pasted in the PR body
   ↓
GitHub Actions runs: tests (unit/property/reference/metamorphic/integration),
                     lint, type checks, security scan, secret scan
   ↓
CodeRabbit (free tier) posts an independent review comment (advisory)
   ↓
You see: green checkmarks + plain-English summary + merge button
   ↓
You click merge (from terminal via `gh pr merge`)
```

No external paid API is used anywhere in this flow. Everything runs on your Max subscription (locally, via me) or free public-repo CI minutes on GitHub.

If *anything* fails — a test, a type check, the other Claude flags a concern — the merge button is **physically disabled** by GitHub. You cannot merge broken code even if you want to.

**Explicit non-goals:** This setup does NOT include any Fire Forex product code. Those nine subsystems (data, strategies, backtest, optimisation, validation, UI, deployment, monitoring, research) are each a future spec. This spec sets up the factory; the product comes later.

---

## 2. Architectural decisions (opinionated — the "what best people do")

These are chosen based on the research doc in the repo root and 2026 best practice. Rationale in parentheses.

### Language
- **Python 3.12+** for orchestration (data loading, configs, runners, tests, glue).
- **Rust 1.78+** for the backtest engine core — 10–50× faster than Python over million-bar sweeps; your old system used it for this reason. We set up the toolchain and an empty `core/` crate today so future PRs add Rust code without another setup session.
- **`uv`** for Python package management. (Fast, deterministic, 2026 standard; replaces pip/poetry/pipenv.)
- **`cargo`** for Rust (standard).
- **Python ↔ Rust bridge** via `pyo3` + `maturin`, added in a later PR when we ship the first Rust function. Not today.

### Code quality
- **Python:** `ruff` (lint + format, replaces black + flake8 + isort + pyupgrade) and `mypy --strict` (catches a huge class of silent bugs before tests).
- **Rust:** `rustfmt` (format) and `clippy -- -D warnings` (lint, warnings as errors).
- **`pre-commit`** runs all four on every local commit.

### Testing — the big one for your failure mode
Five test categories, all required to pass in CI:

1. **Unit tests** (`tests/unit/`) — classical per-function tests. pytest.
2. **Property tests** (`tests/property/`) — `hypothesis`-generated inputs asserting invariants that must always hold (P&L sums, no negative positions, no phantom fills, etc.). Catches "silent knob" bugs the old system shipped. Default seed fixed for reproducibility; a separate nightly CI job runs with randomized seeds to explore the space.
3. **Reference / parity tests** (`tests/reference/`) — fixed market fixtures in `tests/fixtures/` where *expected values* are asserted: expected trade list, fills at specific prices, commission and slippage applied correctly, equity curve, drawdown, final PnL. This is stronger than a hash snapshot — it tells you "wrong," not just "changed." This is the test category that would have caught the silent knob bugs from the last rebuild.
4. **Metamorphic tests** (`tests/metamorphic/`) — same market data shifted / scaled / timezone-normalised must preserve known invariants (total PnL unchanged by constant spread shift if spread is zero; trade count unchanged by timezone rename; etc.). Catches a whole class of subtle accounting bugs.
5. **Integration tests** (`tests/integration/`) — end-to-end smoke covering the pipeline stages together, not mocked.

Additional rule (enforced by `CLAUDE.md` and reviewed by self-review checklist): **never** compare floats with `==`. Always `pytest.approx(expected, rel=1e-9)` or explicit tolerances. Monetary values use `Decimal`, not `float`.

Edge cases that must be covered by fixtures for any new pipeline stage: no-trade, one-trade, many-trades, bad-data, missing-candles.

This testing taxonomy was absent from the research doc and expanded after a Codex second-opinion review. It directly addresses your documented failure mode.

### Git + GitHub
- **Branch protection on `main`:** no direct pushes, require CI green, require Claude review action approval, require linear history.
- **Conventional Commits** (`feat:`, `fix:`, `chore:`) as the commit message standard.
- **`release-please`** for auto-generated changelog + semantic version tags.
- **Squash merge, delete branch on merge** — clean linear history on main.

### CI / PR automation (zero-cost stack)
- **GitHub Actions** for all CI (free on public repos).
- **Self-review via Claude Code skills** — before every `gh pr create`, I invoke the `code-review` skill on my own diff and paste the output into the PR body. Uses your Max subscription tokens, no extra bill.
- **CodeRabbit AI** — free forever on public repositories (full Pro features). Independent second-eye review, advisory only (not merge-blocking). Configured via `.coderabbit.yaml` at repo root.
- **Gemini Code Assist (consumer)** — Google's free PR review agent, quota ~33 PRs/day (we never hit that). Installs as a GitHub App, no config file required. Third independent reviewer.
- **Dependabot** for automated dependency update PRs.
- **CodeQL** for free security scanning (public repo, GitHub-native).
- **`gitleaks-action`** for secret scanning on every PR (requires `GITHUB_TOKEN` env var).

**Explicit note:** Three layers of review cost nothing on a public repo: the self-review I run, CodeRabbit's independent review, and Gemini Code Assist's independent review. None is merge-blocking — the **mechanical gates** (tests, lint, type, security) are. The three reviews act as triage to surface things the tests didn't codify. If all three miss something, we add a test that would have caught it.

### Agent discipline (Claude Code — "Ring 1")
- **Superpowers plugin stays enabled.** The `brainstorming`, `writing-plans`, `executing-plans`, `verification-before-completion`, `test-driven-development`, and `systematic-debugging` skills are the discipline layer.
- **`code-simplifier`** plugin stays enabled — `/simplify` runs automatically after every PR merge (via hook).
- **Project-level hooks** in `.claude/settings.json` (see §4) enforce: auto-ruff on Python edits, block dangerous bash commands, update `PROGRESS.md` on session stop (async, so it doesn't block your typing).

### State across sessions
- **`PROGRESS.md`** — current state of the project, auto-updated by Stop hook.
- **`HANDOFF.md`** — what's next when the current session ends.
- **`CLAUDE.md`** — permanent instructions to the agent (me). Read at every session start.

### What is deliberately *not* included (YAGNI)
- **`pyo3`/`maturin` Rust↔Python bindings.** Added in the PR that ships the first cross-language function, not before.
- **Docker / testcontainers.** Not needed for solo backtest work.
- **Web UI / frontend.** Part of future Fire Forex spec, not this one.
- **VPS / live runner.** Part of future Fire Forex deployment spec.
- **Memory MCPs (Mem0, Zep), Spec Kit, Sequential Thinking MCP.** Research explicitly calls these redundant with Claude Code v2.1 native features. Keeping `claude-mem` installed (already on).
- **Multiple PR review bots (CodeRabbit etc.).** One bot (Claude) is enough. Add others only if we hit a specific gap.

---

## 3. Final directory structure after setup

```
freedom/
├── .claude/
│   ├── settings.json                # project hooks + permissions (committed)
│   ├── settings.local.json          # personal overrides (gitignored)
│   ├── rules/                       # path-scoped rule files (loaded on demand)
│   │   ├── python-style.md          # paths: ["**/*.py"]
│   │   ├── rust-style.md            # paths: ["core/**/*.rs"]
│   │   ├── testing.md               # paths: ["tests/**/*.py"]
│   │   └── execution-safety.md      # paths: to be added when execution code lands
│   ├── commands/                    # user-invokable slash commands
│   │   └── handoff.md               # /handoff — overwrites HANDOFF.md
│   └── hooks/
│       └── update-paperwork.sh      # Stop hook: rewrites HANDOFF.md, ticks PROGRESS.md
├── .github/
│   ├── workflows/
│   │   ├── ci.yml                   # tests + lint + type + security on PR
│   │   ├── nightly.yml              # randomized-seed property tests, weekly
│   │   ├── release-please.yml       # changelog + version tags
│   │   ├── codeql.yml               # security scanning
│   │   └── gitleaks.yml             # secret scanning
│   ├── dependabot.yml
│   ├── pull_request_template.md
│   ├── ISSUE_TEMPLATE/
│   │   ├── feature.md
│   │   └── bug.md
│   └── CODEOWNERS
├── .coderabbit.yaml                 # CodeRabbit free-tier config (advisory review)
├── CONTRIBUTING.md                  # how the AI workflow operates in this repo
├── docs/
│   ├── superpowers/
│   │   └── specs/
│   │       └── 2026-04-23-dev-workflow-setup-design.md  (this file)
│   └── adr/                         # Architecture Decision Records
│       ├── README.md                # numbered index of ADRs
│       └── 0001-template.md         # ADR template (copy for each new decision)
├── core/                            # Rust backtest engine (empty crate today)
│   ├── Cargo.toml
│   ├── rust-toolchain.toml
│   └── src/
│       └── lib.rs                   # empty stub
├── src/
│   └── freedom/
│       ├── __init__.py              # placeholder, version string
│       └── py.typed                 # marker so mypy treats package as typed
├── tests/
│   ├── fixtures/                    # deterministic sample datasets
│   │   └── README.md                # conventions; real fixtures added per-feature
│   ├── unit/
│   │   └── test_placeholder.py      # one trivial test so CI has green baseline
│   ├── property/
│   │   └── test_placeholder.py
│   ├── reference/
│   │   └── test_placeholder.py      # expected-value assertions, not hashes
│   ├── metamorphic/
│   │   └── test_placeholder.py
│   └── integration/
│       └── test_smoke.py
├── CLAUDE.md                        # agent instructions (see §5)
├── PROGRESS.md                      # live state (auto-updated)
├── HANDOFF.md                       # next-session hand-off
├── README.md                        # plain-English project description
├── pyproject.toml                   # uv, ruff, mypy, pytest config
├── .pre-commit-config.yaml
├── .gitignore
└── .python-version
```

---

## 4. `.claude/settings.json` — project hooks (committed)

```json
{
  "permissions": {
    "allow": [
      "Bash(uv *)",
      "Bash(gh *)",
      "Bash(git *)",
      "Bash(pytest *)"
    ],
    "deny": [
      "Bash(git push --force *main*)",
      "Bash(git push -f *main*)",
      "Bash(rm -rf /)",
      "Bash(rm -rf ~*)"
    ]
  },
  "hooks": {
    "PostToolUse": [{
      "matcher": "Write|Edit",
      "hooks": [{
        "type": "command",
        "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/format-on-edit.sh\" || true"
      }]
    }],
    "Stop": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "timeout": 5,
        "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/update-paperwork.sh\" || true"
      }]
    }]
  }
}
```

**Note on Stop hook timing:** 5-second timeout, blocking. The hook must finish before the session ends so paperwork cannot be skipped. It **rewrites** `HANDOFF.md` from the research's template (branch, status, goal, done, not-done, failed approaches, resume steps) and appends any ticked milestones to `PROGRESS.md`. Takes well under a second. The `claude-mem` plugin's separate Stop hook (outside our control) is what causes the long pauses the user noticed; our hook is independent and fast.

The hook also **refuses to end the session** if there are uncommitted code changes with no corresponding doc/state update — a belt-and-braces check on top of the self-review checklist.

---

## 5. State & memory architecture (three layers, per research consensus)

| Layer | Files | Behaviour | Size |
|---|---|---|---|
| **Permanent** | `CLAUDE.md` + `.claude/rules/*.md` | Rules that apply forever. Root stays ~150 lines, never grows. Detailed rules in `.claude/rules/` are **path-scoped** — each file has `paths:` frontmatter, so only files matching the current edit path get loaded. | Tight; path-scoping prevents bloat. |
| **Persistent** | `HANDOFF.md`, `PROGRESS.md`, `docs/adr/*` | Living project state. HANDOFF **overwritten every session**. PROGRESS is a checklist ticked as milestones ship. ADRs are numbered + immutable. | Bounded per file. |
| **Session-only** | Conversation + tool output | Disposable. `/compact` and `/clear` aggressively between tasks. | Irrelevant — discarded. |

**Why path-scoped rules in `.claude/rules/` and not a growing CLAUDE.md:** root CLAUDE.md loads on every session, so every rule there costs context forever. A rule in `.claude/rules/python-style.md` tagged `paths: ["**/*.py"]` only loads when I'm editing Python. Rust rules only load when I'm editing Rust. Execution-safety rules only load when I'm editing the execution folder. Root stays small even as the ruleset grows.

**Never add third-party memory plugins** (Mem0, Zep, MemPalace). The research cites benchmarks showing more memory layers *degrade* output past a point. `claude-mem` (already installed) + native auto-memory + HANDOFF.md is the proven combination. Anything more hurts.

## 5a. Root `CLAUDE.md` — stays small, loaded every session

```markdown
# Freedom — Agent Instructions

**The user is not a coder.** The system is the quality gate, not them.
Every safeguard here exists because of that fact.

## How to talk to the user

- Plain English only. No command transcripts, no yaml/json dumps, no long file paths in chat.
- Say what you're about to do in one short sentence — e.g. "I'll open a pull request and wait for the tests to pass" — not the raw commands behind it.
- Put technical detail in files and tool calls, not in the conversation.
- At most 5 short plain-English bullets when presenting a plan or a choice.
- Never paste a shell transcript. If the user needs the result, summarise it in one line.
- Technical names are fine (PR, CI, branch, hook) — shell incantations are not.

## Before writing any code
1. Invoke `superpowers:brainstorming` if the request is new work.
2. If a spec doesn't exist for this feature, write one under `docs/superpowers/specs/`.
3. Invoke `superpowers:writing-plans` to produce a step-by-step plan.
4. Summarise the plan in plain English, get user approval before executing.

## While coding
1. One feature = one branch: `git switch -c feat/<issue-number>-<slug>`.
2. Write the failing test first. (`superpowers:test-driven-development`.)
3. Make it pass.
4. Run `uv run pre-commit run --all-files` before every commit.
5. Commit format: `type(scope): subject\n\nBody. Closes #N.`

## Completing work
1. Invoke `superpowers:verification-before-completion` before claiming done.
2. `uv run pytest` — all four test categories must pass.
3. `git push -u origin HEAD`
4. `gh pr create --fill`
5. Wait for: CI green + Claude review action approval.
6. `gh pr merge --squash --delete-branch`

## Forbidden
- Committing to `main` directly.
- `git push --force` anywhere.
- Claiming "done" without evidence.
- Adding features not in the approved spec.
- Shipping code without tests.
- Comparing floats with `==`. Use `pytest.approx(expected, rel=1e-9)` or explicit tolerances.
- Holding money in `float`. Use `Decimal`.
- Merging a PR without the self-review checklist in §8a of the design spec being ticked off and pasted into the PR body.

## Domain-decision rule
Whenever a new domain choice is made (timezone handling, trading calendar, spread model, slippage assumption, commission formula, PnL calculation convention, broker execution semantics), write an ADR in `docs/adr/NNNN-short-name.md` using the template at `docs/adr/0001-template.md`. No domain choice lives only in code.

## Edge cases required for any pipeline-stage work
Every new pipeline stage (data loader, signal, filter, executor, etc.) must have fixtures and tests for:
- no-trade day
- single-trade day
- many-trade day
- bad data (NaN, negative prices, duplicate timestamps)
- missing candles (gap handling)

## Session state
- `HANDOFF.md` — **overwritten** every session by the Stop hook (or `/handoff` on demand). Template: current branch, status, goal, completed, not-yet-done, **failed approaches (DON'T REPEAT)**, exact resume steps.
- `PROGRESS.md` — **living checklist** of milestones with checkboxes. Tick off as they ship; don't rewrite.
- Read both at session start. If `HANDOFF.md` says "in the middle of X" — finish X before starting anything new.

## Root CLAUDE.md discipline
This file stays under 150 lines, forever. When a new rule is needed:
1. If it's universal (applies to all files), it may go here — but think twice.
2. If it's path-scoped (Python-only, Rust-only, a specific folder), add it to `.claude/rules/<topic>.md` with a `paths:` frontmatter. Never add it here.
3. If it's a domain decision (calendar, spread model), write an ADR under `docs/adr/`. Never put domain facts in the rule layer.
```

---

## 6. `pyproject.toml` — tooling config

```toml
[project]
name = "freedom"
version = "0.1.0"
description = "Forex strategy research, optimisation and deployment platform"
requires-python = ">=3.12"
dependencies = []

[dependency-groups]
dev = [
  "pytest>=8",
  "pytest-cov",
  "hypothesis>=6.100",
  "ruff>=0.6",
  "mypy>=1.11",
  "pre-commit>=3.8",
]

[tool.ruff]
line-length = 100
target-version = "py312"

[tool.ruff.lint]
select = ["E", "F", "I", "B", "UP", "N", "SIM", "TID", "PL"]

[tool.mypy]
strict = true
files = ["src"]

[[tool.mypy.overrides]]
module = "tests.*"
disallow_untyped_defs = false
disallow_incomplete_defs = false
check_untyped_defs = true

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "-v --strict-markers --strict-config"
markers = [
  "integration: end-to-end pipeline tests",
  "slow: tests that take >1s",
]
```

---

## 7. `.github/workflows/ci.yml`

```yaml
name: CI
on:
  push:
    branches: [main]
  pull_request:

jobs:
  python:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v4
      - run: uv sync --all-groups
      - name: Ruff lint
        run: uv run ruff check .
      - name: Ruff format check
        run: uv run ruff format --check .
      - name: Type check
        run: uv run mypy src
      - name: Unit tests
        run: uv run pytest tests/unit/ -v
      - name: Property tests (fixed seed)
        run: uv run pytest tests/property/ --hypothesis-seed=0
      - name: Reference / parity tests
        run: uv run pytest tests/reference/
      - name: Metamorphic tests
        run: uv run pytest tests/metamorphic/
      - name: Integration tests
        run: uv run pytest tests/integration/ -m integration

  rust:
    runs-on: ubuntu-latest
    defaults: { run: { working-directory: core } }
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
        with: { components: rustfmt, clippy }
      - run: cargo fmt --check
      - run: cargo clippy --all-targets -- -D warnings
      - run: cargo test --all-targets
```

Both jobs must pass for the PR to be mergeable (enforced by branch protection).

---

## 8. PR review — zero-cost approach

No paid Claude Action. Three layers replace it:

### 8a. Self-review checklist (primary — runs before every `gh pr create`)

Before opening any PR, I must run the `code-review` skill on the diff and paste the output into the PR description. The self-review checks:

- [ ] Every changed function has a test (unit, property, or reference).
- [ ] No `==` on floats; `pytest.approx` or `Decimal` used for money.
- [ ] Edge cases covered: no-trade, one-trade, many-trades, bad-data, missing-candles (if applicable).
- [ ] No `print()` or debug logging left in.
- [ ] No silently-changed defaults; if a parameter default changed, note it explicitly.
- [ ] No TODOs / FIXMEs added — either do the thing, or open an issue.
- [ ] Spec, CLAUDE.md, PROGRESS.md updated to reflect the change.
- [ ] If a domain choice was made (timezone, calendar, spread model, slippage model), a new ADR exists under `docs/adr/`.
- [ ] `uv run pytest` green locally on all five categories.
- [ ] `cargo test` green locally if Rust touched.
- [ ] `uv run pre-commit run --all-files` green.

If any box is unchecked, I do not open the PR.

### 8b. CodeRabbit AI (secondary — advisory)

Free-forever on public repositories. Auto-reviews every PR and posts comments. **Advisory, not merge-blocking.** Catches things a second brain might spot. Configured via `.coderabbit.yaml`:

```yaml
language: en
early_access: false
reviews:
  profile: chill
  request_changes_workflow: false
  high_level_summary: true
  review_status: true
  auto_review:
    enabled: true
    drafts: false
chat:
  auto_reply: true
```

### 8c. Gemini Code Assist (tertiary — advisory)

Google's free PR review agent. Installed as a GitHub App on `longytravel/freedom`. Quota: 33 PR reviews per day (never hit in practice). **Advisory, not merge-blocking.** Posts an independent review comment on every PR, distinct from CodeRabbit's brain.

No config file required for default behaviour. If per-repo customisation is wanted, a `.gemini/config.yaml` can be added.

### 8d. Why three layers, all zero-cost

On PR #11 (the first real PR in this repo), CodeRabbit and Gemini each flagged a real issue the self-review missed. The overlap is useful: one missing something doesn't mean all three miss it. Total cost remains zero.

### 8e. Kill-switch & upgrade path

If in future we find all three miss a specific bug class, the escape hatch is (a) add a targeted test category or property test, or (b) enable the paid Claude Action as `.github/workflows/claude-review.yml` — one-line workflow addition, not built today.

---

## 9. Branch protection (applied via `gh api`)

On `main`:
- Require PR before merging.
- Require status checks: `python`, `rust`, `CodeQL`, `gitleaks` (exact names read from GitHub after the **first successful CI run** — see §10 for the ordering fix).
- Require linear history.
- Require conversation resolution.
- Block force pushes.
- Block deletions.
- Include administrators (you, so you can't accidentally bypass either).

Configured via `gh api -X PUT repos/longytravel/freedom/branches/main/protection ...` **only after** PR #1's CI run proves the check names. Otherwise we lock ourselves into non-existent required checks.

**Emergency escape hatch** (documented, to be used only if genuinely stuck):
1. Temporarily disable protection via GitHub web UI (Settings → Branches → `main`).
2. Fix the blocking issue.
3. Re-enable protection.
4. Record the incident in `PROGRESS.md` with date + reason.

---

## 10. First PRs in order (the walking skeleton)

1. **Initial commit (on `main`, once, direct, BEFORE branch protection)** — everything in §3 including all five test directories, `.coderabbit.yaml`, `CONTRIBUTING.md`, ADR template, every workflow. This is the only direct-to-main commit in this project's history.
2. **First CI run on that commit must pass.** This gives us the exact required-check names (`python`, `rust`, `CodeQL`, `gitleaks`, etc.) as they appear in GitHub.
3. **Apply branch protection** via `gh api` using those real check names. From this point on, `main` is locked.
4. **PR #1 — throwaway "verify PR loop"** — trivial README subtitle change. Purpose: prove the full PR loop end-to-end: self-review posts to PR body, CodeRabbit posts an advisory comment, every CI check is green, squash-merge works, branch is auto-deleted.

After PR #1 merges, the workbench is complete and the Fire Forex subsystem specs begin. Everything else mentioned in this design — Stop hook, paperwork automation, CodeRabbit config, Dependabot, CodeQL, gitleaks, release-please workflow, all test placeholders, ADR template, CONTRIBUTING.md — all lands in the **initial commit**, not in later PRs. A single batched setup is cleaner than splitting mechanical setup across five artificial PRs.

---

## 11. What success looks like

- You type `what next?` and a new feature cycle begins without you remembering any commands.
- You never see a diff. You only see a PR summary in plain English + a set of checkmarks.
- You never visit github.com except out of curiosity.
- A test suite is the first thing that runs on any change, not the last thing a human remembers to do.
- Rolling back any merged PR is one command: `gh pr revert <N>`.
- Cross-session memory (via `claude-mem`) means future-me reads `PROGRESS.md` + recent commits + claude-mem observations and picks up where we left off, instead of asking you to re-explain.

---

## 12. Known risks + mitigations

| Risk | Mitigation |
|---|---|
| `claude-mem` Stop hook still blocks for 2min | Our Stop hook is `async: true`; plugin hook still runs but our own work never waits on it. Option to disable plugin later if unacceptable. |
| Self-review + CodeRabbit miss bugs a paid Claude Action would catch | Stronger tests (5 categories incl. reference/parity + metamorphic) + explicit self-review checklist in §8a. If a bug still slips through, enable paid Claude Action as a one-line workflow addition. |
| Branch protection locks out admin (you) in emergency | Escape hatch documented in §9 (disable → fix → re-enable → record in PROGRESS.md). Use is rare-to-never. |
| Tests take too long, become annoying, get skipped | Integration + metamorphic tests marked `-m slow` can be excluded locally. CI still runs everything. |
| Non-coder user cannot debug when hook fails silently | All hooks log to `.claude/hooks/log.txt` with timestamp. Every hook has `|| true` as last resort so it never blocks. |
| Branch protection locks in wrong required check names | §10 ordering fix: land the initial commit → first CI run green → read real check names → then apply protection. |
| Float-precision bugs in financial calculations | CLAUDE.md rule: never `==` on floats, always `pytest.approx` or `Decimal`. Enforced by self-review checklist. |

---

## 13. Review prompts for the user

Before approving this spec, confirm:

1. The plain-English summary in §1 matches what you asked for.
2. Language mix: Python for orchestration + Rust for backtest engine (toolchain ready today, first functional Rust code in a later PR). `pyo3`/`maturin` bridge deferred to the PR that needs it.
3. You're OK with `main` being fully protected after first CI run (including for you — escape hatch documented in §9).
4. You're OK with **zero paid API use** — review via session self-review (uses Max subscription tokens only) + CodeRabbit free tier advisory. No `ANTHROPIC_API_KEY` needed.
5. The "PR #1 is a throwaway hello-world" plan is fine.
6. Five-category test taxonomy (unit, property, reference, metamorphic, integration) is acceptable — stronger than the research doc prescribed, informed by Codex second opinion on what a trading system needs.

If any of those are "no", say which and I'll revise before executing.
