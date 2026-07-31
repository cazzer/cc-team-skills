# cc-team-skills

Shared Claude Code skills for product development workflows.

## Skills

Ordered simplest first — roughly the order you'd reach for them as a change gets bigger.

| Skill | Invoke | Purpose |
|---|---|---|
| **jam** | `/jam` | Brainstorm a fuzzy idea. Diverge then converge. May produce a PRD. Conversation only — no code. |
| **tweak** | `/tweak [change]` | Tiny surgical change (1–3 files, no design). Scope-checks first and exits if it's bigger. |
| **rca** | `/rca [what's broken]` | Diagnose an unknown-cause bug. Parallel read-only investigators → verified root cause + remediation plan. Never implements. |
| **focus** | `/focus [change \| #issue]` | One ticket end-to-end: plan → implement → review, routed subagents in a worktree. |
| **breakdown** | `/breakdown [#issue]` | PRD/epic → ordered, routable tickets. Deep research, dependency graph, surface tagging. |
| **sprint** | `/sprint [#issues \| milestone]` | Batch-execute tickets in parallel waves, respecting dependency order. |
| **drive** | `/drive [#issue \| request]` | Front door. Assesses cause/scope/ambiguity, then routes the request through the minimal chain of the above and drives it to done. |

Plus one setup skill:

| Skill | Invoke | Purpose |
|---|---|---|
| **setup-agents** | `/setup-agents` | **Optional.** Baked-in role profiles work with no setup. Run this only to layer wshobson plugin agents on top — detects stack, installs plugins at project scope, writes `.claude/routing.md`. Idempotent. |

## Typical flow

```
/drive add dark mode      → assesses and routes the whole chain itself

# or drive it by hand:
/jam                      → explore ideas, produce PRD
/breakdown #42            → decompose PRD into tickets
/sprint #43 #44 #45       → execute tickets (or entire epics) in parallel
/focus #43                → or run a single ticket

/tweak fix the button     → quick one-off
/rca checkout 500s        → diagnose before fixing anything
```

The handoff map in `context/handoffs.md` is loaded by every skill, so each one knows what it consumes and what it hands off to.

## Structure

```
skills/          → SKILL.md files invoked by Claude Code
context/
  handoffs.md    → which skill hands off to which, and when
  spawn-spec.md  → four-part delegation contract for every subagent prompt
  roles/         → agent role profiles (frontend-dev, db-specialist, reviewer, etc.)
  principles/    → product and coding principles seeded into skills
  routing/       → surface-to-role-slot mapping and detection heuristics
  templates/     → PRD and ticket templates for GitHub issues
```

Role profiles are one-line **Focus:** statements plus directive bodies — they set a lens, not a persona. `context/spawn-spec.md` supplies the task shape (objective / output format / tools & sources / boundaries) that every spawn is built from.

## Why a submodule and not a plugin?

Claude Code plugins (`~/.claude/plugins/`) are machine-local — they only work on desktop and CLI. Skills in `.claude/skills/` live in the repo and work on every client: mobile, web, CLI, and IDE extensions.

This repo is designed as a submodule so your team's workflows are available everywhere, not just on machines where someone remembered to install a plugin.

| | Plugin | Skill (submodule) |
|---|---|---|
| Mobile | No | Yes |
| Web | No | Yes |
| CLI / IDE | Yes | Yes |
| Per-repo versioning | No | Yes (pinned commit) |
| Requires local install | Yes | No |

## Why GitHub Issues?

These skills use GitHub Issues as the connective tissue between stages. `/jam` produces a PRD issue, `/breakdown` decomposes it into ticket issues, `/sprint` executes those tickets.

Two reasons:

1. **Durable artifacts.** Decisions, context, and rationale survive beyond any single conversation. When you come back in a week, the trail is there.
2. **Scoped agent context.** Each issue becomes a narrow, deep context window for a specialized agent. Instead of feeding an agent your entire project vision, you hand it one well-defined ticket with just enough context to execute. Smaller scope = better results.

You can swap in a different tracker, but you'll need to adapt the templates and skill prompts accordingly.

In cloud sessions where `gh` isn't authenticated, the skills fall back to the GitHub MCP tools automatically.

## Usage

**Step 1:** Add as a git submodule:

```bash
git submodule add <repo-url> .claude/skills/team
```

**Step 2:** Run the sync script to copy skills into place:

```bash
.claude/skills/team/sync-skills.sh
```

Claude Code only discovers skills one level deep (`.claude/skills/<name>/SKILL.md`). The submodule nests them too deeply, so the sync script flattens them into the right location. Re-run after pulling submodule updates.

Skills auto-discover project context from `CLAUDE.md` in the working directory. They resolve their shared context from `.claude/skills/context/` and fall back to `~/.claude/skills/context/`, so a user-scope install works too.

**Step 3 (optional):** Run `/setup-agents` if you want plugin agents layered on top of the baked-in role profiles. Skip it and everything still works.
