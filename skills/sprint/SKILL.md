---
name: sprint
description: Batch execute implementation tickets. Runs plan→implement→review workflows in parallel where possible, respecting dependency ordering. Takes issue numbers, milestone, or epic.
argument-hint: [#issue or milestone:name]
---

# Sprint

Batch executor. Pick up tickets and run them through full plan → implement → review cycles, parallelizing where safe.

## Preflight

!`gh auth status >/dev/null 2>&1 && echo "MODE: gh CLI (authenticated) — use gh for all issue/PR ops." || echo "MODE: GitHub MCP — gh is unavailable or unauthenticated. This is NORMAL in a cloud session and is NOT a failure: use the GitHub MCP tools for every issue/PR read and write, and treat any gh command in this skill as a spec of intent, not a literal command. Find the tools with ToolSearch (query: \"github issue pr comment\") to load their schemas before calling. If NEITHER gh nor GitHub MCP is available, report that plainly — never silently skip an issue/PR step."`

## Project context

!`cat CLAUDE.md 2>/dev/null || echo "No project context found — proceeding without project-specific context"`

## Skill handoffs

!`cat .claude/skills/context/handoffs.md 2>/dev/null || cat "${CLAUDE_PLUGIN_ROOT}/context/handoffs.md" 2>/dev/null || cat "$HOME/.claude/skills/context/handoffs.md" 2>/dev/null || echo "WARNING: Handoff map not found at expected path"`

## Subagent task spec

Build every subagent prompt from the four-part delegation contract below (objective / output format / tools & sources / boundaries). Carry prior decisions forward; scale effort to the work.

!`cat .claude/skills/context/spawn-spec.md 2>/dev/null || cat "${CLAUDE_PLUGIN_ROOT}/context/spawn-spec.md" 2>/dev/null || cat "$HOME/.claude/skills/context/spawn-spec.md" 2>/dev/null || echo "WARNING: Subagent task spec not found at expected path"`

## Routing table

!`cat .claude/skills/context/routing/defaults.md 2>/dev/null || cat "${CLAUDE_PLUGIN_ROOT}/context/routing/defaults.md" 2>/dev/null || cat "$HOME/.claude/skills/context/routing/defaults.md" 2>/dev/null || echo "WARNING: Routing defaults not found — agent routing will fall back to best judgment"`

## Subagent mapping (per-repo — required)

!`cat .claude/routing.md 2>/dev/null || echo "No routing table — use the baked-in role profiles in context/roles/ (the default). Optionally run /setup-agents to layer wshobson plugin agents on top."`

## Installed plugins (staleness check)

!`cat ~/.claude/plugins/installed_plugins.json 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print('\n'.join(sorted({k.split('@')[0] for k in d.get('plugins',{})})))" 2>/dev/null || echo "(could not read installed plugins)"`

## Subagent resolution rule

**Routing — baked-in role profiles are the default.** No routing table, or a table whose slots are all `—`, is normal — not an error. Spawn each subagent with the local role context from `context/roles/<slot>.md`. Plugins are optional: only when `.claude/routing.md` binds a slot to a concrete `plugin:agent` AND that plugin is installed do you prefer it, passing the local role context alongside. Never hard-stop for a missing table or plugin — proceed with baked-in roles.

**Staleness check.** Cross-check the routing table's "Required plugins" list against the Installed plugins list above. If any required plugin is missing, warn the user once: "routing table references uninstalled plugin(s) X — run /setup-agents to install." Then proceed using the mappings whose plugins are present; rows whose plugin is missing fall back to local role context.

For every role spawn below, check the **Subagent mapping** table:
- Role slot has a subagent name AND its plugin is installed → spawn `Task(subagent_type=<name>, prompt=<role context + ticket>)`.
- Subagent is `—` or its plugin missing → spawn with the role's local context file only (legacy path).
- The local role context (`context/roles/<slot>.md`) is the primary prompt for every spawn; when an optional plugin agent is bound and installed, its domain expertise layers on top.

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

**Always include this constraint block in every impl agent prompt** (sprint has burned this lesson — agents that hear "direct-to-main, no PRs" interpret it as "you may push direct to main"):

```
⚠️ CRITICAL — STOP-AT-COMMIT CONSTRAINTS
- DO NOT push to origin. No `git push` of any kind.
- DO NOT merge your branch into main or any other branch.
- DO NOT rebase main or fast-forward main onto your branch.
- Your worktree exists for ISOLATION. Stay in it. Commit, report, stop.
- House style notes like "direct-to-main, no PRs" describe the user's eventual merge step — NOT your job. Your job ends at "commit on the worktree branch."
- If you find yourself about to run `git push`, `git merge main <branch>`, or `git checkout main && git merge`, that's the sign you've misunderstood the workflow. Stop.
```

**Multi-repo workspaces**: if tickets target different repos (e.g. `/Users/caleb/dev/shlo/web-app` vs `/Users/caleb/dev/shlo/mobile-v2`), the spawning harness creates the worktree off the *current cwd*. Before each Agent spawn, change cwd to the target repo so the worktree lands in the right place. Worktrees in the wrong repo waste a full agent invocation when the impl agent correctly aborts.

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

`review:code`'s charter carries a **best-practice / idiom lens** — a ticket-satisfying diff built on an ill-fit primitive is still a finding. For tickets with strong non-functional stakes (rendering/animation, concurrency, data access, a11y), note it in the review prompt so that lens is weighted.

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
6. **If a ticket is blocked by a bug whose cause nobody understands** (impl agent is flailing at an unexplained failure, not a scoping problem), stop that ticket and suggest `/rca` to diagnose it before burning more agent rounds. Don't let an impl agent guess repeatedly at an undiagnosed fault.

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
- Don't omit the stop-at-commit constraint block (Step 3b) from impl agent prompts. Spawn agents have burned this in production — without explicit "no push, no merge" boilerplate they read repo house-style notes (e.g. "direct-to-main, no PRs") as permission to push.
- Don't spawn cross-repo agents without `cd`-ing to the target repo first. The harness creates worktrees off the current cwd; wrong cwd = wasted spawn when the agent correctly aborts.
