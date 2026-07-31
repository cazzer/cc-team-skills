---
name: focus
description: Sequential single-ticket pipeline. Plan → implement → review with routed subagents and worktree isolation, for one focused change that's too big for tweak but doesn't need sprint's batch machinery. Optionally takes a GitHub issue (#N) to preserve ticket context.
argument-hint: [what to change | #issue]
---

# Focus

Sequential pipeline for one focused change. Subagent handoffs preserve context across phases; worktree isolates the implementation. No batch ticket loading, no DAG, no parallelization — that's `/sprint`.

## Project context

!`cat CLAUDE.md 2>/dev/null || echo "No project context found — proceeding without project-specific context"`

## Coding principles

!`cat .claude/skills/context/principles/coding.md 2>/dev/null || cat "$HOME/.claude/skills/context/principles/coding.md" 2>/dev/null || echo "WARNING: Coding principles not found at expected path"`

## Skill handoffs

!`cat .claude/skills/context/handoffs.md 2>/dev/null || cat "$HOME/.claude/skills/context/handoffs.md" 2>/dev/null || echo "WARNING: Handoff map not found at expected path"`

## Subagent task spec

Build every subagent prompt from the four-part delegation contract below (objective / output format / tools & sources / boundaries). Carry prior decisions forward; scale effort to the work.

!`cat .claude/skills/context/spawn-spec.md 2>/dev/null || cat "$HOME/.claude/skills/context/spawn-spec.md" 2>/dev/null || echo "WARNING: Subagent task spec not found at expected path"`

## Routing table

!`cat .claude/skills/context/routing/defaults.md 2>/dev/null || cat "$HOME/.claude/skills/context/routing/defaults.md" 2>/dev/null || echo "WARNING: Routing defaults not found"`

## Subagent mapping (per-repo — required)

!`cat .claude/routing.md 2>/dev/null || echo "No routing table — use the baked-in role profiles in context/roles/ (the default). Optionally run /setup-agents to layer wshobson plugin agents on top."`

## Installed plugins (staleness check)

!`cat ~/.claude/plugins/installed_plugins.json 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print('\n'.join(sorted({k.split('@')[0] for k in d.get('plugins',{})})))" 2>/dev/null || echo "(could not read installed plugins)"`

## Subagent resolution rule

**Routing — baked-in role profiles are the default.** No routing table, or a table whose slots are all `—`, is normal — not an error. Spawn each subagent with the local role context from `context/roles/<slot>.md`. Plugins are optional: only when `.claude/routing.md` binds a slot to a concrete `plugin:agent` AND that plugin is installed do you prefer it, passing the local role context alongside. Never hard-stop for a missing table or plugin — proceed with baked-in roles.

**Staleness check.** Cross-check the routing table's "Required plugins" list against the Installed plugins list above. If any required plugin is missing, warn the user once: "routing table references uninstalled plugin(s) X — run /setup-agents to install." Then proceed using the mappings whose plugins are present; rows whose plugin is missing fall back to local role context.

For every role spawn below, check the **Subagent mapping** table:
- Role slot has a subagent name AND its plugin is installed → spawn `Task(subagent_type=<name>, prompt=<role context + task>)`.
- Subagent is `—` or its plugin missing → spawn with the role's local context file only (legacy path).
- The local role context (`context/roles/<slot>.md`) is the primary prompt for every spawn; when an optional plugin agent is bound and installed, its domain expertise layers on top.

## Workflow

### Step 1 — Assess scope

Before doing anything, decide focus is the right tool. Be honest. Wrong tool = wasted subagent spins.

**It's a focus if:**
- Single concern, one ticket's worth of work
- Touches ~3–10 files OR crosses a meaningful boundary (auth, schema, infra, public contract)
- Benefits from a Plan agent designing before implementation
- Benefits from a Review agent on the final diff
- No parallelizable subtasks — would still be one branch, one PR

**It's NOT a focus — nudge to another skill:**
- **Ambiguous problem, no clear solution** → suggest `/jam` to explore first.
- **Multi-concern, decomposes into >1 ticket** → suggest `/breakdown` to produce tickets, then `/sprint` to execute.
- **Multiple existing tickets** → suggest `/sprint`. Focus runs one ticket at a time on purpose.
- **One concern, touches 1–3 files, no design needed** → suggest `/tweak`. Spawning subagents for a one-line change is overhead theatre.
- **A bug whose root cause isn't understood** → suggest `/rca` to diagnose first. Focus implements a known change; it's not a diagnosis tool.
- **Open-ended "improve X"** → ask the user to narrow before proceeding.
- **Not sure which of these applies** → `/drive` will assess and route it for you.

State the mismatch clearly and stop. Don't half-run focus on a task that wants a different shape.

### Step 2 — Load task context

Parse input:
- `#N` → `gh issue view N --json title,body,labels,comments` and use ticket as source of truth. Preserve ticket context end-to-end (pass to Plan, Impl, Review).
- Prose → treat as the task description. Offer to create a ticket if the change is non-trivial and the user wants tracking — but don't require it.

Extract (from ticket or prose):
- Goal + acceptance criteria
- Expected file paths (if known)
- Surface (frontend / backend / db / infra / mobile / observability) — derive from labels or content
- Review flags (security, ux) — derive from labels or content
- Post-steps (codegen, migrations, lint)

### Step 3 — Plan

Spawn one Plan agent. Use the `architect` slot from the routing table.

Inputs to the Plan agent:
- `context/roles/architect.md`
- Project context (CLAUDE.md)
- Coding principles
- The task description + acceptance criteria
- Surface and expected file paths

Plan agent returns: design summary, file-by-file change list, risks, test strategy. No implementation.

Skip only if the user explicitly says "skip plan" or the task is purely mechanical (rename, version bump) — and in that case reconsider whether this is actually a `/tweak`.

### Step 4 — Implement

Spawn one implementation agent. Use the surface-mapped slot from the routing table (`backend-dev`, `frontend-dev`, `db-specialist`, `infra-dev`, `mobile-dev`, `observability`, etc.).

Spawn with `isolation: "worktree"` so the change is isolated from the main checkout and review agents can read a clean diff.

Inputs to the Impl agent:
- Surface role context from `context/roles/<slot>.md`
- Coding principles
- Plan output from Step 3
- Task description + expected file paths
- Project context

The Impl agent writes code in its worktree. It runs typecheck and tests itself before returning.

### Step 5 — Verify

Run task-relevant verification in the worktree:
- Typecheck / lint
- Relevant tests
- Codegen (if schema touched)
- `cdk diff` / `cfn validate` (if infra touched)

If verification fails, hand back to the Impl agent in the same worktree with the failure output. One repair round. If still failing, surface to the user — don't spin forever.

### Step 6 — Review

Always spawn `reviewer` (code review). Its charter carries a **best-practice / idiom lens** (`context/roles/reviewer.md`): a diff that satisfies the ticket but reaches it through an ill-fit primitive for the platform is a finding, not a pass. When the change has strong non-functional stakes (rendering/animation, concurrency, data access, accessibility), say so in the reviewer's prompt so it weights that lens.
Additionally spawn:
- `security-rev` if the task touches auth, secrets, RLS, public input, or live trading paths
- `ux-reviewer` if the task changes user-facing UI

Inputs to each reviewer:
- Their role context
- The diff (`git diff` from the worktree)
- The ticket description / acceptance criteria
- Plan output from Step 3 (so reviewer knows the intent, not just the diff)

### Step 7 — Address findings (max 2 rounds)

- 🔴 **Must-fix**: hand back to Impl agent in same worktree. Re-review after fixes.
- 🟡 **Should-fix**: fix if obvious, else note as follow-up.
- 🟢 **Nit**: note, don't block.

**Cap at 2 review rounds.** If must-fix findings remain, surface to user. Don't loop.

### Step 8 — Report + offer next step

Final report:
- What changed (1–2 sentence summary)
- Worktree path + branch name
- Agents spawned (role → subagent → outcome)
- Review findings: must-fix resolved / should-fix deferred / nits noted
- Verification status

Then **default-recommend merging the worktree branch into the current branch and cleaning up the worktree + feature branch**. State this as the recommended next step (option 1, marked "Recommended"). Orphan worktrees and zombie branches accumulate cruft fast.

Offer alternatives:
1. **Merge worktree into current branch + clean up worktree and feature branch** (Recommended). Standard `git merge --ff-only <branch>`, then `git worktree remove` + `git branch -D`. If the repo has a remote and uses PRs, also offer `/git-workflow` to push + PR.
2. Leave worktree for manual inspection — only if the user explicitly wants to poke at the change before merging.

Don't auto-PR. Don't auto-merge without confirmation — but DO recommend merge+cleanup as the default path so the user can say "yes" once instead of typing out cleanup commands.

## Anti-patterns

- Don't run focus when the task is actually a `/tweak`, `/sprint`, `/jam`, `/breakdown`, or `/rca` — nudge the user and stop.
- Don't let the Impl agent keep guessing at a failure nobody understands. If mid-flight you hit a bug whose cause is unexplained, stop and suggest `/rca` rather than burning review rounds on a guess.
- Don't skip the Plan step on non-mechanical work to "save time." The Plan output is what makes the Impl context lean.
- Don't skip Review. Sequential pipeline without a review pass = expensive tweak.
- Don't parallelize. If the task has parallel-able subtasks, it's a sprint candidate.
- Don't loop reviews past 2 rounds. Escalate to user.
- Don't auto-create PRs or auto-merge without confirmation. Final commit/push/PR is the user's call — but DO recommend merge+cleanup as the default next step (Step 8).
- Don't leave orphan worktrees. Recommend cleanup in the final report. Only leave the worktree alive if the user explicitly asks to inspect manually.
- Don't let the Impl agent push or merge on its own. Always include an explicit "no push, no merge, stop at commit on the worktree branch" constraint in the Impl prompt. Repo notes like "direct-to-main, no PRs" describe the user's eventual merge step — agents have been observed interpreting them as permission to push.
