---
name: breakdown
description: Decompose a PRD or epic into implementable tickets. Takes a GitHub issue number or works from conversation context. Deep codebase research, dependency ordering, surface tagging.
argument-hint: [#issue-number]
disable-model-invocation: true
---

# Breakdown

Decompose a PRD or epic into the smallest reasonable implementation tickets, ordered for maximum parallelization with minimum risk.

## Project context

!`cat CLAUDE.md 2>/dev/null | head -100 || echo "No project context found"`

## Routing table

!`cat "$(dirname "$0")/../context/routing/defaults.md" 2>/dev/null || echo "Routing defaults not found"`

## Surface detection

!`cat "$(dirname "$0")/../context/routing/surfaces.md" 2>/dev/null || echo "Surface detection not found"`

## Ticket template

!`cat "$(dirname "$0")/../context/templates/ticket.md" 2>/dev/null || echo "Ticket template not found"`

## Workflow

### Step 1 — Load the spec

- If given `#issue-number`: fetch with `gh issue view <number>`.
- If no argument: look for a PRD or epic in recent conversation context.
- If neither: ask the user what to break down.

Read the full spec. Identify: goals, constraints, acceptance criteria, open questions.

### Step 2 — Deep research

Spawn subagents (Explore type) to investigate:

1. **Existing patterns** — how does the codebase handle similar features today? What conventions exist?
2. **Boundaries** — which layers/surfaces does this work touch? Where are the seams?
3. **Dependencies** — what existing code will this interact with? What types, APIs, schemas are involved?
4. **Risk areas** — what's fragile? What has complex test coverage? Where have past changes caused regressions?

Research should identify specific file paths that each ticket will likely touch.

### Step 3 — Decompose

Break the work into tickets where each ticket:
- Is completable by one agent workflow (plan → implement → review)
- Has a single surface type (frontend, backend, DB, infra, mobile)
- Has clear acceptance criteria that can be verified
- Links to expected file paths from the research phase

**Splitting heuristics:**
- New DB schema/migration = its own ticket. Always.
- Codegen steps after DB changes = its own ticket or explicit post-step.
- Frontend and backend for the same feature = separate tickets unless trivially coupled.
- Each new page/route = its own ticket.
- Shared utilities needed by multiple tickets = extract as a prerequisite ticket.

### Step 4 — Order and parallelize

Build a dependency graph:
- **Sequential**: DB → codegen → backend → frontend (when they share new schema)
- **Parallel**: independent tickets on different surfaces with no shared contracts
- **Minimize risk**: don't let frontend work proceed based on guessed codegen output

Present the graph visually:
```
#1 DB migration
  → #2 Codegen (blocked by #1)
    → #3 Backend API (blocked by #2)
    → #4 Frontend components (blocked by #2)
#5 Infrastructure (parallel — no dependencies)
```

### Step 5 — Tag and annotate

Each ticket gets:
- **Surface label**: `surface:frontend`, `surface:backend`, `surface:database`, `surface:infra`, `surface:mobile`
- **Dependency links**: "blocked by #X", "blocks #Y", "parallel with #Z"
- **Routing metadata**: which plan/implement/review agents apply (from routing table)
- **Expected file paths**: specific files the implementing agent should focus on
- **Post-steps**: verification commands (typecheck, test, codegen, cdk diff)

### Step 6 — Create issues

Check for any labels that need creating first. If new labels needed, list them and ask for approval before creating.

Create each ticket as a GitHub issue using `gh issue create`, following the ticket template. Link all tickets back to the parent epic.

Present a final summary: ticket count, dependency graph, estimated parallelization (e.g. "3 tickets can run in parallel after the DB migration lands").

## Repo-specific overrides

Check for routing overrides:
!`cat .claude/routing.md 2>/dev/null || cat .claude/skills/team/routing-overrides.md 2>/dev/null || echo "No routing overrides found — using defaults"`

## Anti-patterns

- Don't create tickets that span multiple surfaces unless they're trivially coupled.
- Don't create tickets without acceptance criteria. "Implement X" is not a ticket.
- Don't guess at implementation details — research the codebase first.
- Don't create more tickets than necessary. If two things always change together, they're one ticket.
- Don't skip the dependency graph. Unordered tickets lead to merge conflicts and rework.
