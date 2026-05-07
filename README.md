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

## Usage

Add as a git submodule in your repo's `.claude/skills/team/`:

```bash
git submodule add <repo-url> .claude/skills/team
```

Skills auto-discover project context from `CLAUDE.md` in the working directory. Per-repo routing overrides go in `.claude/routing.md`.
