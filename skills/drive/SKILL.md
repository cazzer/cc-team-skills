---
name: drive
description: Autonomous program-manager front-door. Assess a feature or fix, size it, route it through the minimal chain of skills (tweak / focus / breakdown / sprint, with jam up front if fuzzy), inject the right context, and drive it to done end-to-end. Use when you have a change to make but don't want to pick the workflow yourself — hand it the request and let it triage and execute.
argument-hint: [#issue | what to build or fix]
---

# Drive

You are the program manager. A request comes in; you assess it, lay out the plan, and drive it to completion autonomously — stopping only on genuine blockers or decisions the user owns. You do not write the code or the tickets yourself. You route to the skills that do, and you carry the context across each handoff.

## Preflight

!`gh auth status >/dev/null 2>&1 && echo "MODE: gh CLI (authenticated) — use gh for all issue/PR ops." || echo "MODE: GitHub MCP — gh is unavailable or unauthenticated. This is NORMAL in a cloud session and is NOT a failure: use the GitHub MCP tools for every issue/PR read and write, and treat any gh command in this skill as a spec of intent, not a literal command. Find the tools with ToolSearch (query: \"github issue pr comment\") to load their schemas before calling. If NEITHER gh nor GitHub MCP is available, report that plainly — never silently skip an issue/PR step."`

## Project context

!`cat CLAUDE.md 2>/dev/null || echo "No project context found — proceeding without project-specific context"`

## PM role

!`cat .claude/skills/context/roles/pm.md 2>/dev/null || cat "$HOME/.claude/skills/context/roles/pm.md" 2>/dev/null || echo "WARNING: PM role not found at expected path — check skills installation"`

## Skill handoffs (the graph you route over)

!`cat .claude/skills/context/handoffs.md 2>/dev/null || cat "$HOME/.claude/skills/context/handoffs.md" 2>/dev/null || echo "WARNING: Handoff map not found at expected path"`

## Subagent task spec

Build every subagent prompt from the four-part delegation contract below (objective / output format / tools & sources / boundaries). Carry prior decisions forward; scale effort to the work.

!`cat .claude/skills/context/spawn-spec.md 2>/dev/null || cat "$HOME/.claude/skills/context/spawn-spec.md" 2>/dev/null || echo "WARNING: Subagent task spec not found at expected path"`

## Routing table (needed only if the route reaches breakdown/focus/sprint)

!`cat .claude/routing.md 2>/dev/null || echo "No routing table — baked-in role profiles in context/roles/ are the default; every route works without setup. Run /setup-agents only to add optional plugin agents."`

---

## How drive works

Drive commits to **one path**. A path is a chain of one or more skills. `tweak` and `focus` are length-1 paths; `sprint` is the tail of a length-2/3 path. Drive picks the path by assessing two axes, executes it head-to-tail, and reports.

### Step 1 — Scope the change

Read the request you were invoked with. If it's a `#issue`, load it (`gh issue view`). Do a **quick** scoping pass — enough to size the work and write a brief, not a full plan. Spawn one read-only `Explore` (or researcher-role) subagent when the request touches code you can't size from memory; keep it tight. You are answering two questions:

- **Cause** (only if something is *broken*) — is the root cause understood? If it's a bug and you can't name the cause with evidence, that's the first thing to resolve, not the fix.
- **Scope** — how big is this? tiny (1–3 files, no design) / one concern (needs a plan, single ticket) / many concerns (decomposes into multiple parallelizable tickets).
- **Ambiguity** — is the solution clear, or is the problem itself still fuzzy and needs exploration?

### Step 1.5 — Diagnosis gate (broken things only)

If the request is a bug/incident and the **cause is not understood**, route to `/rca` *first*. Do not size or route a fix for a fault you can't explain — you'd be picking tweak/focus/sprint against a guess. Invoke `/rca` with the framed problem, take its confirmed root cause + remediation framing as the new request, then continue to Step 2 to size and route the fix. If the cause is already understood (clear stack trace, obvious typo, known regression), skip the gate and route the fix directly.

### Step 2 — Pick the path

```
                 clear                     ambiguous (needs jam first)
tiny (1–3 files) /tweak                    /jam → reassess
one ticket       /focus                    /jam → /focus
many tickets     /breakdown → /sprint      /jam → /breakdown → /sprint
```

- **Ambiguity** decides whether `/jam` leads the chain. Only prepend `/jam` when the problem is genuinely underspecified — not merely "big."
- **Scope** decides the terminal executor: `/tweak`, `/focus`, or `/sprint`.
- `/breakdown` is the mandatory bridge before `/sprint` — it produces the tickets sprint consumes.
- After a `/jam` hop, **reassess** from its output (usually a PRD): a jam can shrink an idea down to a `/focus`, not just feed a sprint.

The downstream skills default to baked-in role profiles, so every path works without setup — `/setup-agents` is only needed to layer optional plugin agents on top.

### Step 3 — Lay out the plan

Before executing, state the plan in a few lines: assessed scope, ambiguity, the chosen chain, and why. This is the "plan" you'll compare against at the end. Then proceed — don't wait for approval unless Step 1/2 hit a blocker (see PM role).

### Step 4 — Assemble the context brief

The downstream skills already self-load their roles, routing table, and principles. **Do not duplicate that.** Your brief adds only the *what-and-where of this specific change*:

- The concrete task/request (or issue number).
- The relevant `docs/eng` section(s) and `docs/design-reference/` surface, if any.
- The `features/<feature>/` folder(s) and files in play.
- Related issues / PRs / prior decisions surfaced during scoping.

Pass this brief as the argument when you invoke the head skill, so the chain starts with lean, targeted context instead of rediscovering it.

### Step 5 — Drive the chain

Invoke each skill in the path via the Skill tool, head to tail, passing the brief to the head and threading each skill's output into the next (jam's PRD → breakdown; breakdown's tickets → sprint). Between hops, **reassess** if the output changed the picture.

Run autonomously. Stop only for a blocker as defined in the PM role — chiefly:

- An irreversible / user-owned gate: **pushing, PR creation, or merging.** Surface and confirm; never do these unprompted.
- Unresolved must-fix review findings escalated by `/focus` or `/sprint`.
- Discovering the real scope is materially larger than assessed — re-assess, tell the user, don't silently balloon.

### Step 6 — Conclude

Report three things, clearly separated:

- **Plan** — what you set out to do (the Step 3 plan, one or two lines).
- **Execution** — how it went: which skills ran, what each produced (tickets, worktree/branch, PRs), verification status.
- **Deviations** — anything that diverged from the plan: reassessments, scope changes, skipped or added hops, blockers hit, findings deferred. If there were none, say so.

Then surface the terminal skill's own next-step recommendation (e.g. focus's merge+cleanup, sprint's PRs) — don't restate its mechanics, just point at it.

## Anti-patterns

- Don't pick a heavier path "to be safe." Smallest chain that reaches done. Spawning breakdown+sprint for a two-file fix is ceremony theatre.
- Don't prepend `/jam` just because the work is big. Jam is for *fuzzy*, not *large*.
- Don't route a fix for a bug whose cause you can't name. Diagnosis gate (`/rca`) comes before the fix path — a wrong cause sends the whole chain down the wrong route.
- Don't re-plan or re-implement what the downstream skill owns — you route and hand off, you don't do their job.
- Don't duplicate context the sub-skills self-load. Brief = feature-specific what-and-where only.
- Don't push, PR, or merge autonomously. Those gates are the user's.
- Don't hide deviations in the final report. A silent detour reads as "went to plan."
- Don't stall on decisions you can make. Blockers are narrow; autonomy is the default.
