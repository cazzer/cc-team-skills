---
name: rca
description: Root cause analysis for a bug or incident. Fans out debuggers and researchers in parallel to find what's actually causing a problem, converges on a verified root cause with evidence, and sketches a remediation plan — without implementing it. Ends by recommending /drive if there's a reasonable fix approach. Use when something is broken and you need to understand WHY before touching code.
argument-hint: [what's broken | #issue | error text]
---

# RCA — Root Cause Analysis

You are running a root cause investigation. Your job is to understand *why* a problem is happening — deeply, with evidence — and to hand off a remediation plan. **You do not fix it.** No edits, no implementation. Investigation and planning only.

## Preflight

!`gh auth status >/dev/null 2>&1 && echo "MODE: gh CLI (authenticated) — use gh for all issue/PR ops." || echo "MODE: GitHub MCP — gh is unavailable or unauthenticated. This is NORMAL in a cloud session and is NOT a failure: use the GitHub MCP tools for every issue/PR read and write, and treat any gh command in this skill as a spec of intent, not a literal command. Find the tools with ToolSearch (query: \"github issue pr comment\") to load their schemas before calling. If NEITHER gh nor GitHub MCP is available, report that plainly — never silently skip an issue/PR step."`

## Project context

!`cat CLAUDE.md 2>/dev/null || echo "No project context found — proceeding without project-specific context"`

## Researcher role (inject into research subagents)

!`cat .claude/skills/context/roles/researcher.md 2>/dev/null || cat "${CLAUDE_PLUGIN_ROOT}/context/roles/researcher.md" 2>/dev/null || cat "$HOME/.claude/skills/context/roles/researcher.md" 2>/dev/null || echo "WARNING: Researcher role not found"`

## Skill handoffs

!`cat .claude/skills/context/handoffs.md 2>/dev/null || cat "${CLAUDE_PLUGIN_ROOT}/context/handoffs.md" 2>/dev/null || cat "$HOME/.claude/skills/context/handoffs.md" 2>/dev/null || echo "WARNING: Handoff map not found at expected path"`

## Subagent mapping (resolve investigator slots)

!`cat .claude/routing.md 2>/dev/null || echo "No routing table — baked-in role profiles in context/roles/ are the default; investigation works with local roles + Explore. Run /setup-agents only to add optional plugin agents."`

---

## How RCA works

Parallel investigation → converge on a verified cause → sketch remediation → hand off. Read-only throughout.

### Step 1 — Frame the problem

Capture the symptom precisely before theorizing:

- If given a `#issue`, load it (`gh issue view`). If given error text or a stack trace, quote it exactly.
- Nail down: what's the observed behavior vs expected, when did it start, what's the blast radius (one user / one surface / systemic), is it reproducible, what changed recently (`git log`, recent PRs).
- Restate the problem in one or two lines so the investigators share a target.

If the symptom is too vague to investigate (no repro, no error, no signal), that itself is the finding — say what's needed to make it investigable, and stop. Don't fan out on a guess.

### Step 2 — Form distinct hypotheses

List 2–4 **candidate causes**, each a different angle — not restatements of the same guess. Each becomes an investigator. Typical angles:

- **Code path** — trace the logic; where could it produce this behavior? (debugger)
- **Regression** — did a recent change introduce it? `git log`/blame/bisect the suspect range. (debugger)
- **Data / logs / traces** — what do error signatures, logs, or runtime data say? (error-detective / observability)
- **Environment / contract** — schema, RLS, env vars, API contract, dependency version drift. (researcher / db / backend)

### Step 3 — Fan out investigators (parallel, read-only)

Spawn one subagent per hypothesis **in a single message** so they run concurrently. Resolve each slot via the routing table above (`debugger` → debugging-toolkit:debugger, `researcher` → Explore, error/log angle → incident-response:error-detective, data-layer → db-specialist).

Every investigator prompt MUST include:

- The framed problem (Step 1) + the specific hypothesis this agent owns.
- The relevant `docs/eng` section(s), `features/<feature>/` folder(s), and files in play.
- A hard constraint: **read-only. Investigate and report evidence for/against this hypothesis with file:line citations and a confidence level. Do NOT edit any files, do NOT implement a fix.**

Ask each to return: verdict (supported / refuted / inconclusive), the evidence, and any adjacent cause it stumbled on.

### Step 4 — Converge on the root cause

Synthesize the returns. Then **try to disprove your leading candidate** — a plausible-but-wrong cause that survives to remediation is the failure mode here. Distinguish:

- **Root cause** — the actual origin, with evidence (file:line, commit, log).
- **Contributing factors** — what made it worse or masked it.
- **Confidence** — high / medium / low, and what would raise it.

If investigators conflict or all come back inconclusive, spawn a targeted second round on the gap rather than guessing.

### Step 5 — Sketch the remediation plan (do not implement)

For the confirmed cause, outline the fix — approach only, no code:

- The fix approach (and 1–2 alternatives if there's a real tradeoff), with a recommendation.
- Scope / blast radius: which surfaces and files, how big.
- Risk and what could regress; what tests or verification the fix needs.
- Any prerequisite (data migration, backfill, config) before the code change.

### Step 6 — Hand off

- **If there's a reasonable approach** (confidence not low, scope understood): **recommend** launching **`/drive`** with a one-line remediation framing, e.g. *"Recommended next step: `/drive fix <root cause> in <feature> — <approach>`."* Then **stop and wait for the user to approve.** Do NOT invoke `/drive` yourself — surface it as the suggested next step and let the user pull the trigger. Drive will size and route it (tweak/focus/sprint) once they do.
- **If confidence is low or the fix is unclear**: say so plainly. Recommend what's needed first — more repro, more logging, a spike — not a fix. Do not push to `/drive` on a guess.

Never implement the fix from within RCA, and never auto-launch `/drive`. The handoff — a verified cause plus a recommended path — is the deliverable; running it is the user's call.

## Anti-patterns

- Don't edit code or implement the fix. RCA stops at the plan.
- Don't stop at the first plausible cause. Verify — try to refute it before you trust it.
- Don't fan out investigators on the same guess worn three ways. Distinct hypotheses only.
- Don't let investigator subagents modify files — they're read-only; state that constraint in every prompt.
- Don't hand off to `/drive` on a low-confidence guess. A wrong root cause sends drive down the wrong path.
- Don't theorize past a missing repro. No signal → say what's needed to get one, and stop.
