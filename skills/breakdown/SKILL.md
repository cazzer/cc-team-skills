---
name: breakdown
description: Decompose a PRD or epic into implementable tickets, or produce a PRD from loose ideas. Takes a GitHub issue number or works from conversation context. Deep codebase research, dependency ordering, surface tagging.
argument-hint: [#issue-number]
disable-model-invocation: true
---

# Breakdown

Assess input, produce a PRD if needed, then decompose into the smallest reasonable implementation tickets ordered for maximum parallelization with minimum risk.

## Preflight

!`gh auth status 2>&1 | head -2 || echo "WARNING: gh CLI not authenticated — issue creation will fail"`

## Project context

!`cat CLAUDE.md 2>/dev/null || echo "No project context found — proceeding without project-specific context"`

## Researcher role

When spawning research subagents, include this context in their prompt:
!`cat "$(dirname "$0")/../context/roles/researcher.md" 2>/dev/null || echo "WARNING: Researcher role not found"`

## Routing table

!`cat "$(dirname "$0")/../context/routing/defaults.md" 2>/dev/null || echo "WARNING: Routing defaults not found — agent routing will fall back to best judgment"`

## Surface detection

!`cat "$(dirname "$0")/../context/routing/surfaces.md" 2>/dev/null || echo "WARNING: Surface detection not found"`

## Templates

PRD template:
!`cat "$(dirname "$0")/../context/templates/prd.md" 2>/dev/null || echo "WARNING: PRD template not found"`

Ticket template:
!`cat "$(dirname "$0")/../context/templates/ticket.md" 2>/dev/null || echo "WARNING: Ticket template not found"`

## Workflow

### Step 1 — Load and assess input

- If given `#issue-number`: fetch with `gh issue view <number>`.
- If no argument: look for a PRD or epic in recent conversation context.
- If neither: ask the user what to break down.

Read the full input and classify it:

**Ready for decomposition** (skip to Step 2):
- Has clear goals and acceptance criteria
- Scope is well-defined (in-scope and out-of-scope stated)
- Key decisions are made, not open questions
- Structured as a PRD or detailed epic

**Needs a PRD first** (produce one before decomposing):
- Loose idea, rough notes, or conversation context
- Missing acceptance criteria or success metrics
- Scope is unclear or unbounded
- Key decisions are still open

When a PRD is needed: use the PRD template above, fill it out based on available context, and create it as a GitHub issue with `gh issue create --label prd`. Ask the user to review the PRD before proceeding to decomposition. If the user approves, continue to Step 2 using the PRD as input.

### Step 2 — Deep research

Spawn subagents (Explore type) with the researcher role context above to investigate:

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

### Step 5 — Tag with labels

Each ticket gets GitHub labels for routing (applied via `--label` on `gh issue create`):

**Surface** (exactly one):
`surface:frontend`, `surface:backend`, `surface:database`, `surface:infra`, `surface:mobile`

**Plan routing**:
`plan:architect` or `plan:skip`

**Review routing** (one or more):
`review:code` (always), `review:ux` (frontend/mobile), `review:security` (DB/infra/auth)

The ticket body contains: description, expected file paths, acceptance criteria, dependency links, and post-step commands. Routing lives in labels, not in the body.

### Step 6 — Idempotency check

Before creating issues, search for existing tickets linked to this epic/PRD:
```
gh issue list --search "label:epic-{number}" --state open
```

If tickets already exist, warn the user and list them. Ask whether to skip duplicates, update existing tickets, or create fresh.

### Step 7 — Create issues

Check for any labels that need creating first. If new labels needed, list them and ask for approval before creating.

Create each ticket as a GitHub issue using `gh issue create` with appropriate `--label` flags. Link all tickets back to the parent epic/PRD.

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
- Don't create duplicate tickets. Always check for existing issues first.
