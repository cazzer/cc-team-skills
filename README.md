# cc-team-skills

Shared Claude Code skills for product development workflows.

## Skills

| Skill | Invoke | Purpose |
|---|---|---|
| **jam** | `/jam` or auto | Brainstorm and ideate. Diverge-then-converge. May produce a PRD. |
| **tweak** | `/tweak [change]` | Quick focused change. Scope-checks first, exits if too big. |
| **breakdown** | `/breakdown [#issue]` | PRD/epic → implementation tickets. Deep research, dependency ordering. |
| **sprint** | `/sprint [#issues]` | Batch execute tickets. Parallel agent workflows with wave ordering. |

## Typical flow

```
/jam                    → explore ideas, produce PRD
/breakdown #42          → decompose PRD into tickets
/sprint #43 #44 #45     → execute tickets in parallel

/tweak fix the button   → quick one-off (independent of the above)
```

## Structure

```
skills/          → SKILL.md files invoked by Claude Code
context/
  roles/         → agent persona prompts (frontend-dev, db-specialist, etc.)
  principles/    → product and coding principles seeded into skills
  routing/       → surface-to-workflow mapping and detection heuristics
  templates/     → PRD and ticket templates for GitHub issues
```

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

## Usage

Add as a git submodule in your repo's `.claude/skills/team/`:

```bash
git submodule add <repo-url> .claude/skills/team
```

Skills auto-discover project context from `CLAUDE.md` in the working directory. Per-repo routing overrides go in `.claude/routing.md`.

For repos that can't use submodules, `sync-skills.sh` copies skills directly:

```bash
./sync-skills.sh
```
