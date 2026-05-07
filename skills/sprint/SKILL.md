---
name: sprint
description: Batch execute implementation tickets. Runs plan→implement→review workflows in parallel where possible, respecting dependency ordering. Takes issue numbers, milestone, or epic.
argument-hint: [#issue or milestone:name]
disable-model-invocation: true
---

# Sprint

Batch executor. Pick up tickets and run them through full plan → implement → review cycles, parallelizing where safe.

## Project context

!`cat CLAUDE.md 2>/dev/null | head -100 || echo "No project context found"`

## Routing table

!`cat "$(dirname "$0")/../context/routing/defaults.md" 2>/dev/null || echo "Routing defaults not found"`

## Repo-specific overrides

!`cat .claude/routing.md 2>/dev/null || cat .claude/skills/team/routing-overrides.md 2>/dev/null || echo "No routing overrides found"`

## Workflow

### Step 1 — Load tickets

Parse input:
- `#45 #46 #47` → fetch specific issues
- `milestone:v1.2` → `gh issue list --milestone "v1.2" --state open`
- `#123` (single epic) → find child issues linked to epic
- No argument → ask what to sprint on

For each ticket, extract:
- Surface label
- Dependencies (blocked-by, blocks)
- Expected file paths
- Routing metadata (plan/implement/review agents)
- Post-steps

If tickets are missing surface labels or routing metadata, classify them using the surface detection heuristics.

### Step 2 — Build execution plan

Construct a dependency graph. Identify:
- **Wave 1**: tickets with no blockers (can start immediately)
- **Wave 2**: tickets blocked only by Wave 1
- **Wave N**: continue until all tickets are scheduled

Present the execution plan:
```
Wave 1 (parallel):
  #45 — DB migration [db-specialist]
  #48 — Infrastructure setup [infra-dev]

Wave 2 (after #45):
  #46 — Codegen [post-step of #45]
  
Wave 3 (parallel, after #46):
  #47 — Backend API [backend-dev]
  #49 — Frontend components [frontend-dev]
```

### Step 3 — Execute waves

For each ticket in a wave, run the full cycle:

#### 3a — Plan
Read the role prompt for the ticket's plan agent:
!`ls "$(dirname "$0")/../context/roles/" 2>/dev/null || echo "Roles directory not found"`

Spawn a Plan agent (subagent_type: Plan) with:
- The architect role context
- The ticket description and acceptance criteria
- Expected file paths
- Project context (CLAUDE.md)

Skip planning for tickets marked "plan: skip" in their routing metadata.

#### 3b — Implement
Spawn an implementation agent (isolation: worktree) with:
- The surface-appropriate role context (frontend-dev, backend-dev, db-specialist, etc.)
- The plan output from step 3a
- The ticket's expected file paths
- Coding principles
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
Spawn review agents based on the ticket's routing:
- **Always**: reviewer (code review)
- **If frontend/mobile**: + ux-reviewer
- **If DB/infra/auth**: + security-reviewer

Review agents get:
- Their role context
- The diff (git diff of the worktree)
- The ticket description and acceptance criteria

#### 3e — Address review findings

🔴 Must-fix findings: re-delegate to the implementing agent (same worktree). Re-review after fixes.
🟡 Should-fix findings: fix if straightforward, otherwise note as follow-up.
🟢 Nits: note but don't block.

### Step 4 — PR creation

Group tickets into PRs:
- Small, tightly related tickets → batch into one PR
- Large or independent tickets → one PR each
- Always link PRs to their issues for auto-close

PR description includes:
- Summary of changes
- Tickets addressed (with links)
- Test plan
- Any review findings that were deferred

### Step 5 — Handle blockers

When a ticket is blocked by something that requires human input:
- Comment on the GitHub issue describing the blocker
- Assign to a human if possible
- Continue executing non-blocked tickets
- Report the blocker in the final summary

### Step 6 — Cleanup and report

After all tickets are complete:

1. **Clean up worktrees** — remove all temporary worktrees created during the sprint.

2. **Execution report:**

```markdown
## Sprint Report

### Completed
- #45 — DB migration ✅ (PR #XX)
- #46 — Codegen ✅ (included in PR #XX)
- #47 — Backend API ✅ (PR #YY)

### Blocked
- #49 — Frontend components ⏸ (needs design clarification, commented on issue)

### PRs created
- PR #XX — Database and codegen changes (#45, #46)
- PR #YY — Backend API (#47)

### Workflow audit
| Agent type | Spawned | Succeeded | Notes |
|---|---|---|---|
| Plan (architect) | 3 | 3 | |
| Implement (frontend-dev) | 1 | 0 | Blocked — design question |
| Implement (backend-dev) | 1 | 1 | |
| Implement (db-specialist) | 1 | 1 | |
| Review (reviewer) | 2 | 2 | |
| Review (security) | 1 | 1 | Found 1 🟡, fixed |

### Observations
- {What went well}
- {What could improve}
- {Missing agent types or workflows that would have helped}
- {Suggested follow-up work}
```

## Anti-patterns

- Don't start implementing without checking dependencies. Wave ordering exists for a reason.
- Don't skip reviews. Every ticket gets at least a code review.
- Don't leave worktrees behind. Always clean up.
- Don't silently skip blocked tickets. Report them.
- Don't merge PRs — create them and let the user review/merge.
