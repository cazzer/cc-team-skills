# cc-team-skills

Shared Claude Code skills for product development workflows.

## Skills

Ordered simplest first — roughly the order you'd reach for them as a change gets bigger.

| Skill | Invoke | Purpose |
|---|---|---|
| **jam** | `/team:jam` | Brainstorm a fuzzy idea. Diverge then converge. May produce a PRD. Conversation only — no code. |
| **tweak** | `/team:tweak [change]` | Tiny surgical change (1–3 files, no design). Scope-checks first and exits if it's bigger. |
| **rca** | `/team:rca [what's broken]` | Diagnose an unknown-cause bug. Parallel read-only investigators → verified root cause + remediation plan. Never implements. |
| **focus** | `/team:focus [change \| #issue]` | One ticket end-to-end: plan → implement → review, routed subagents in a worktree. |
| **breakdown** | `/team:breakdown [#issue]` | PRD/epic → ordered, routable tickets. Deep research, dependency graph, surface tagging. |
| **sprint** | `/team:sprint [#issues \| milestone]` | Batch-execute tickets in parallel waves, respecting dependency order. |
| **drive** | `/team:drive [#issue \| request]` | Front door. Assesses cause/scope/ambiguity, then routes the request through the minimal chain of the above and drives it to done. |

Plus one setup skill:

| Skill | Invoke | Purpose |
|---|---|---|
| **setup-agents** | `/team:setup-agents` | **Optional.** Baked-in role profiles work with no setup. Run this only to layer wshobson plugin agents on top — detects stack, installs plugins at project scope, writes `.claude/routing.md`. Idempotent. |

The `team:` prefix is the plugin namespace. Vendored into a repo or installed user-scope, the names are bare — `/jam`, `/drive`.

## Typical flow

```
/team:drive add dark mode   → assesses and routes the whole chain itself

# or drive it by hand:
/team:jam                   → explore ideas, produce PRD
/team:breakdown #42         → decompose PRD into tickets
/team:sprint #43 #44 #45    → execute tickets (or entire epics) in parallel
/team:focus #43             → or run a single ticket

/team:tweak fix the button  → quick one-off
/team:rca checkout 500s     → diagnose before fixing anything
```

The handoff map in `context/handoffs.md` is loaded by every skill, so each one knows what it consumes and what it hands off to.

## Structure

```
.claude-plugin/
  plugin.json    → plugin manifest
  marketplace.json → self-hosted marketplace entry
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

## Why GitHub Issues?

These skills use GitHub Issues as the connective tissue between stages. `/team:jam` produces a PRD issue, `/team:breakdown` decomposes it into ticket issues, `/team:sprint` executes those tickets.

Two reasons:

1. **Durable artifacts.** Decisions, context, and rationale survive beyond any single conversation. When you come back in a week, the trail is there.
2. **Scoped agent context.** Each issue becomes a narrow, deep context window for a specialized agent. Instead of feeding an agent your entire project vision, you hand it one well-defined ticket with just enough context to execute. Smaller scope = better results.

You can swap in a different tracker, but you'll need to adapt the templates and skill prompts accordingly.

In cloud sessions where `gh` isn't authenticated, the skills fall back to the GitHub MCP tools automatically.

## Install

This repo is a Claude Code plugin and hosts its own marketplace.

```
/plugin marketplace add cazzer/cc-team-skills
/plugin install team@cc-team-skills
```

The marketplace is named after the repo; the plugin inside it is named `team`, which is where the `/team:` prefix on every skill comes from. Update later with `/plugin marketplace update cc-team-skills`.

**Optional:** run `/team:setup-agents` if you want wshobson plugin agents layered on top of the baked-in role profiles. Skip it and everything still works.

### Mobile and web

Plugins are machine-local — they load on CLI, desktop, and IDE extensions, but **not** on mobile or claude.ai/code. Those clients only see skills committed into the repo at `.claude/skills/<name>/SKILL.md`.

To cover them, vendor the skills into the project:

```bash
git clone --depth 1 https://github.com/cazzer/cc-team-skills.git /tmp/cc-team-skills
rsync -a --delete /tmp/cc-team-skills/skills/ .claude/skills/
rsync -a --delete /tmp/cc-team-skills/context/ .claude/skills/context/
```

Vendored skills are **not** namespaced — they invoke as `/jam`, `/drive`, without the `team:` prefix.

Commit the result and re-run after pulling updates. Don't do both on the same repo — a vendored copy shadows the plugin (see resolution order below).

### Context resolution

Skills auto-discover project context from `CLAUDE.md` in the working directory. Shared context resolves in this order, first hit wins:

1. `.claude/skills/context/` — vendored or per-repo override
2. `${CLAUDE_PLUGIN_ROOT}/context/` — this plugin
3. `~/.claude/skills/context/` — user-scope install

So a repo can override a single role profile or principles file by dropping it at path 1 without forking the plugin.
