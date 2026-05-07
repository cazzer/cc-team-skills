---
name: sprint
description: Batch execute implementation tickets. Runs plan→implement→review workflows in parallel where possible, respecting dependency ordering. Takes issue numbers, milestone, or epic.
argument-hint: [#issue or milestone:name]
disable-model-invocation: true
---

# Sprint

Batch executor. Pick up tickets and run them through full plan → implement → review cycles, parallelizing where safe.

## Preflight

!`gh auth status 2>&1 | head -2 || echo "WARNING: gh CLI not authenticated — PR creation will fail"`

## Project context

!`cat CLAUDE.md 2>/dev/null || echo "No project context found — proceeding without project-specific context"`

## Routing table

!`cat "$(dirname "$0")/../context/routing/defaults.md" 2>/dev/null || echo "WARNING: Routing defaults not found — agent routing will fall back to best judgment"`

## Repo-specific overrides

!`cat .claude/routing.md 2>/dev/null || cat .claude/skills/team/routing-overrides.md 2>/dev/null || echo "No routing overrides found"`

## Workflow

### Step 1 — Load tickets

Parse input:
- `#45 #46 #47` → fetch specific issues
- `milestone:v1.2` → `gh issue list --milestone "v1.2" --state open`
- `#123` (single epic) → find child issues linked to epic
- No argument → ask what to sprint on

For each ticket, read routing from **GitHub labels**:
- Surface: `surface:frontend`, `surface:backend`, `surface:database`, `surface:infra`, `surface:mobile`
- Plan: `plan:architect` or `plan:skip`
- Review: `review:code`, `review:ux`, `review:security`

Also extract from issue body:
- Dependencies (blocked-by, blocks)
- Expected file paths
- Post-steps

If tickets are missing surface labels, classify them using the surface detection heuristics.

For best results, run `/breakdown` first to produce well-annotated tickets with labels and dependency ordering.

### Step 2 — Build execution plan and confirm

Construct a dependency graph. Identify:
- **Wave 1**: tickets with no blockers (can start immediately)
- **Wave 2**: tickets blocked only by Wave 1
- **Wave N**: continue until all tickets are scheduled

Present the execution plan to the user:
```
Wave 1 (parallel):
  #45 — DB migration [db-specialist]
  #48 — Infrastructure setup [infra-dev]

Wave 2 (after #45):
  #46 — Codegen [post-step of #45]

Wave 3 (parallel, after #46):
  #47 — Backend API [backend-dev]
  #49 — Frontend components [frontend-dev]

Total: 5 tickets, 3 waves, ~X agent invocations
```

**Wait for user approval before executing.** Do not proceed until the user confirms.

### Step 3 — Execute waves

Execute waves in order. Within each wave, parallelize independent tickets.

**Branch naming**: `feat/{ticket-number}-{slug}` (e.g. `feat/45-add-weight-column`).

For each ticket, run the full cycle:

#### 3a — Plan
Spawn a Plan agent (subagent_type: Plan) with:
- The architect role context from `context/roles/architect.md`
- The ticket description and acceptance criteria
- Expected file paths
- Project context (CLAUDE.md)

Skip for tickets labeled `plan:skip`.

#### 3b — Implement
Spawn an implementation agent (isolation: worktree) with:
- The surface-appropriate role context (frontend-dev, backend-dev, db-specialist, etc.) from `context/roles/`
- Coding principles from `context/principles/coding.md`
- The plan output from step 3a
- The ticket's expected file paths
- Project context

Each ticket gets its own worktree for isolation.

#### 3c — Post-steps
Run verification commands from the ticket's post-steps:
- `typecheck` / `lint`
- `test` (relevant tests)
- `codegen` (if DB/schema change)
- `cdk diff` / `cdk synth` (if infra)

If post-steps fail, the implementing agent fixes issues before proceeding.

#### 3d — Review
Spawn review agents based on the ticket's labels:
- `review:code` (always): load `context/roles/reviewer.md`
- `review:ux`: load `context/roles/ux-reviewer.md`
- `review:security`: load `context/roles/security-reviewer.md`

Review agents get:
- Their role context
- The diff (git diff of the worktree)
- The ticket description and acceptance criteria

#### 3e — Address review findings (max 2 rounds)

🔴 Must-fix findings: re-delegate to the implementing agent (same worktree). Re-review after fixes.
🟡 Should-fix findings: fix if straightforward, otherwise note as follow-up.
🟢 Nits: note but don't block.

**Cap at 2 review rounds per ticket.** If must-fix findings remain after 2 rounds, surface them to the user for manual resolution. Do not loop indefinitely.

### Step 4 — Wave failure handling

**If any ticket in a wave fails or hits a blocker:**
1. Complete other independent tickets in the same wave that don't share dependencies.
2. **Do NOT proceed to any subsequent wave that depends on the failed ticket.** Dependency chains halt.
3. Waves with no dependency on the failed ticket may still proceed.
4. Comment on the blocked GitHub issue describing the failure.
5. Report the blockage immediately to the user — don't wait for the sprint report.

### Step 5 — PR creation

Group tickets into PRs:
- Small, tightly related tickets → batch into one PR
- Large or independent tickets → one PR each
- Always link PRs to their issues for auto-close (`Closes #N`)

PR description includes:
- Summary of changes
- Tickets addressed (with links)
- Test plan
- Any review findings that were deferred

### Step 6 — Cleanup and report

After all tickets are complete (or halted):

1. **Clean up worktrees** — remove all temporary worktrees created during the sprint.

2. **Execution report** with these sections:
- **Completed**: tickets that shipped, with PR links
- **Blocked/Failed**: tickets that couldn't complete, with reasons
- **PRs created**: list with linked ticket numbers
- **Workflow audit**: table of agent types spawned, success/failure counts, notes
- **Observations**: what went well, what could improve, missing agent types, suggested follow-up work

## Anti-patterns

- Don't start implementing without checking dependencies. Wave ordering exists for a reason.
- Don't skip reviews. Every ticket gets at least a code review.
- Don't leave worktrees behind. Always clean up.
- Don't silently skip blocked tickets. Report them.
- Don't merge PRs — create them and let the user review/merge.
- Don't proceed past a failed wave into dependent work.
