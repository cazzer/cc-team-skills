# Skill Handoffs

Canonical map of the workflow skills and when to move between them. Every skill injects this so each stays aware of the whole set. Keep handoff logic here — don't re-derive it per skill.

## The skills

- **/jam** — brainstorm a fuzzy idea → PRD. Diverge then converge.
- **/breakdown** — PRD/epic → ordered, routable tickets.
- **/sprint** — batch-execute many tickets in parallel waves.
- **/focus** — one ticket/change through plan → implement → review (worktree).
- **/tweak** — tiny surgical change (1–3 files, no design).
- **/rca** — diagnose an unknown-cause bug → remediation plan. No implementation.
- **/drive** — front door. Assess (cause known? scope? ambiguity?) then route through the right chain autonomously.

## When to hand off

**Diagnosis gate — check FIRST for anything broken:**
- Bug whose **cause is not understood** → `/rca` before any fix path. Routing an undiagnosed fault to tweak/focus/sprint means fixing a guess. Once the cause is confirmed, route the fix by scope below.

**By scope & clarity (change is understood):**
- Fuzzy problem, no clear solution → `/jam`.
- PRD/epic in hand, needs tickets → `/breakdown`.
- Many tickets → `/sprint`. One ticket → `/focus`. Tiny (1–3 files, no design) → `/tweak`.
- Not sure which → `/drive` assesses and routes.

**Forward handoffs — advertise your consumer when you finish:**
- jam (PRD produced) → `/breakdown` (to tickets) or `/drive` (to route). If it shrank to a tiny change → `/tweak`.
- breakdown (tickets produced) → `/sprint` (many) or `/focus` (collapsed to one) or `/drive`.
- rca (cause confirmed) → `/drive` (recommend, wait for approval).

**Escalation — mid-flight, stop and hand off:**
- In tweak/focus/sprint and you hit a bug you **can't explain** → stop, suggest `/rca`. Don't flail at an unknown cause.
- In tweak and it's bigger than 1–3 files: single concern → `/focus`; multi-ticket → `/breakdown`; fuzzy → `/jam`.

## Rules

- Handoffs are **user-facing suggestions**. Only `/drive` invokes other skills itself; everything else names the next skill and stops.
- A skill invoked *by* `/drive` should not bounce the user back to `/drive` — drive already assessed.
- Never auto-run `/drive`, PRs, pushes, or merges — those are the user's call.
