---
name: setup-agents
description: Optional repo instrumentation for the workflow skills. Baked-in role profiles are the default and need no setup — run this only to layer optional wshobson plugin agents on top. Detects stack, installs matched plugins at PROJECT scope, and writes the per-repo `.claude/routing.md` (committed) plus a CLAUDE.md reference block. Idempotent — safe to re-run.
---

# Setup Agents

Single-pass repo instrumentation. Adds wshobson marketplace if missing, installs matched plugins, writes the per-repo routing table to **`.claude/routing.md`** (committed to the repo) and a generated reference block into the repo's **`CLAUDE.md`**. No external slash-command typing required — uses `claude plugin` CLI.

**This is per-repo.** Each repo gets its own committed `.claude/routing.md`. There is no global generated table and no hand-edited override layer — the file is fully generated and clobbered on every re-run. Workflow skills (`/breakdown`, `/sprint`, `/focus`) **work without this skill** — they default to the baked-in role profiles in `context/roles/`. This skill is **optional**: run it only when you want to layer wshobson plugin agents on top of those profiles. It never installs globally — plugins go in at **project scope** so they don't leak into unrelated sessions.

## Preflight — CLI + marketplace

!`command -v claude >/dev/null && echo "claude CLI: OK" || echo "claude CLI: MISSING — install first"`
!`claude plugin marketplace list 2>&1 | grep -q claude-code-workflows && echo "marketplace claude-code-workflows: OK" || echo "marketplace claude-code-workflows: MISSING — will add"`

## Currently installed plugins

!`cat ~/.claude/plugins/installed_plugins.json 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print('\n'.join(sorted({k.split('@')[0] for k in d.get('plugins',{})})))" 2>/dev/null || echo "(could not read installed plugins)"`

## Repo signals

!`cat CLAUDE.md 2>/dev/null | head -80 || echo "no CLAUDE.md"`
!`test -f package.json && python3 -c "import json; d=json.load(open('package.json')); deps={**d.get('dependencies',{}), **d.get('devDependencies',{})}; keys=['@anthropic-ai/sdk','react','vite','vitest','aws-cdk-lib','@apollo/client','@supabase/supabase-js','expo','next','typescript','playwright','vue','svelte','fastify','express','prisma','drizzle-orm','@aws-sdk/client-s3','@aws-sdk/client-sqs']; [print(f'  dep: {k}') for k in keys if k in deps]" 2>&1 || echo "no package.json"`
!`for d in supabase/functions runner infrastructure infra terraform cdk lambda k8s kubernetes; do test -d "$d" && echo "dir: $d"; done; true`
!`test -d .github/workflows && echo "ci: github-actions present" || true`

## Existing routing table (this repo)

!`cat .claude/routing.md 2>/dev/null | head -40 || echo "(no existing routing table — this repo is not yet instrumented)"`

## Stack → plugin lookup

Match signals to plugins. Cap at ~8 plugins per repo.

| Signal                                  | Plugin (marketplace `claude-code-workflows`) |
|-----------------------------------------|----------------------------------------------|
| `@anthropic-ai/sdk` or LLM edge fn      | `llm-application-dev`                        |
| `react` + `vite` or `next`              | `frontend-mobile-development`                |
| `expo` / React Native                   | `frontend-mobile-development` (ships `mobile-developer`) |
| `vitest` / `playwright`                 | `tdd-workflows`, `unit-testing`              |
| `aws-cdk-lib` / `infrastructure/`       | `cloud-infrastructure`                       |
| `kubernetes/` / `k8s/`                  | `kubernetes-operations`                      |
| Supabase / Postgres                     | `backend-api-security`, `database-design`    |
| Background workers (`runner/`)          | `observability-monitoring`, `incident-response` |
| `typescript`                            | `javascript-typescript`                      |
| Any repo                                | `git-pr-workflows`, `code-refactoring`, `comprehensive-review`, `debugging-toolkit` |

## Role → subagent lookup

After plugins installed, map role slots → subagent names. Verify each subagent actually
ships in the named plugin before recording it (the `subagent_type` registry is the source
of truth — a wrong plugin attribution produces a "required plugin missing" warning downstream).

| Role slot      | Subagent             | Plugin                         |
|----------------|----------------------|--------------------------------|
| researcher     | (built-in Explore)   | —                              |
| architect      | backend-architect    | backend-development            |
| frontend-dev   | frontend-developer   | frontend-mobile-development    |
| backend-dev    | backend-architect    | backend-development            |
| db-specialist  | database-optimizer   | observability-monitoring       |
| infra-dev      | cloud-architect      | cloud-infrastructure           |
| mobile-dev     | mobile-developer     | frontend-mobile-development    |
| reviewer       | code-reviewer        | comprehensive-review           |
| security-rev   | security-auditor     | comprehensive-review           |
| ux-reviewer    | ui-ux-designer       | ui-design                      |
| prompt-eng     | prompt-engineer      | llm-application-dev            |
| ai-engineer    | ai-engineer          | llm-application-dev            |
| debugger       | debugger             | debugging-toolkit              |
| test-author    | test-automator       | unit-testing                   |
| performance    | performance-engineer | backend-development            |
| incident       | incident-responder   | incident-response              |
| observability  | observability-engineer | observability-monitoring     |

If a role's plugin isn't installed, record the subagent as `—` (skill falls back to local
role context). Only roles whose plugin is in the installed set get a concrete subagent.

## Steps

1. **Add marketplace if missing.** If preflight shows MISSING:
   ```bash
   claude plugin marketplace add wshobson/agents
   ```

2. **Detect signals.** Read preflight output. List signals.

3. **Compute desired plugin set.** Apply lookup. Dedupe vs currently installed. Show plan to user:
   ```
   Will install: <list>
   Skipping (installed): <list>
   ```

4. **Choose the mode.** Present two paths and ask which:
   - **Baked-in (default, recommended).** Install nothing. Write a routing table with every
     slot `—` so skills use the local `context/roles/*.md` profiles. Portable, zero install,
     identical in every environment (local, cloud web, CI, teammate). Pick this unless there's
     a specific reason to add plugin agents. On this path, skip to step 8 and write the all-`—`
     table.
   - **Install plugins.** Layer wshobson agents on top for extra domain depth. Confirm before
     installing anything (Y/n). Note the tradeoffs: installs are **project-scoped**, require a
     Claude Code restart, and **do not travel with the repo** — every environment must install
     its own, or fall back to baked-in.

5. **Install plugins (install path only)** via Bash — **project scope, never `-s user`**:
   ```bash
   claude plugin install <plugin>@claude-code-workflows -s project
   ```
   Loop over each desired plugin. Continue past individual failures (warn, don't abort).
   Project scope is deliberate: user-scope (global) install leaks proactive plugin agents into
   every session and environment — the exact bug baked-in mode avoids.

6. **Verify installs.** Re-read `~/.claude/plugins/installed_plugins.json`, confirm all desired plugins present.

7. **Resolve mapping.** Build role → subagent table using only roles whose plugin is installed. Others → `—`. The set of plugins actually referenced becomes the **required-plugins manifest** for step 8.

8. **Write the routing table** to `.claude/routing.md` in the current repo (create `.claude/` if absent). This file is committed and fully generated — overwrite it wholesale on every run.

   ```markdown
   # Agent Routing (generated by /setup-agents — do not hand-edit)

   Generated: <ISO date>
   Repo: <basename of cwd>
   Stack signals: <comma list>

   Workflow skills (/breakdown, /sprint, /focus) resolve role slots via this
   table. Regenerate with /setup-agents — hand edits are clobbered on regeneration.

   ## Required plugins

   These plugins must be installed (user scope) for the mappings below to resolve.
   Skills cross-check this list against installed plugins and warn on mismatch.
   Run /setup-agents to install any that are missing.

   - <plugin>
   - <plugin>
   - ...

   ## Role → subagent

   | Role slot     | Subagent                              | Fallback context                   |
   |---------------|---------------------------------------|------------------------------------|
   | researcher    | Explore                               | context/roles/researcher.md        |
   | architect     | backend-development:backend-architect | context/roles/architect.md         |
   | ...           | ...                                   | ...                                |

   ## Resolution rule

   1. Role slot has a subagent name AND its plugin is installed → spawn
      `Task(subagent_type=<name>, prompt=<local role context + ticket>)`.
   2. Subagent is `—`, or its plugin is missing → spawn generic agent with
      `context/roles/<slot>.md` embedded.

   ## Notes

   - <generation notes: dominant roles, slots with no installed match and why, etc.>
   ```

   On the **baked-in path**, every slot is `—` and "Required plugins" is `None` — the table
   documents that skills use `context/roles/*.md`. On the **install path**, only roles with an
   installed plugin get a `plugin:agent`; the rest stay `—`, and "Required plugins" is exactly
   the set referenced by non-`—` rows. `researcher` stays `Explore` (built-in) either way.

9. **Write the CLAUDE.md reference block.** Open the repo's `CLAUDE.md` (create if absent).
   Insert or replace a generated, marker-delimited block — never duplicate the full table
   (the table lives only in `.claude/routing.md`; this is a pointer for humans and for plain
   Claude sessions not running a workflow skill). Replace the existing block if the markers
   are already present; otherwise append it at the end of the file. **Do not touch `AGENTS.md`** —
   agent routing is Claude-Code-specific plumbing and stays out of the portable manifest.

   ```markdown
   <!-- BEGIN agent-routing (generated by /setup-agents) -->
   ## Agent Routing

   This repo is instrumented for the workflow skills (`/breakdown`, `/sprint`, `/focus`).
   - Routing table: `.claude/routing.md` (generated — run `/setup-agents` to refresh).
   - Required plugins: <comma list>.
   - Last generated: <ISO date>.
   <!-- END agent-routing -->
   ```

10. **Restart note.** Print:
    ```
    Newly installed plugins require a Claude Code restart to load agents into the
    subagent_type registry. Restart, then the workflow skills will resolve agents.
    ```

11. **Report.** Print:
    - Marketplace status
    - Plugins installed/skipped/failed
    - Routing-table diff vs previous (`.claude/routing.md`)
    - CLAUDE.md block status (added / replaced / unchanged)
    - Reminder to `git add .claude/routing.md CLAUDE.md` so the team shares the routing
    - Restart reminder

## Idempotency rules

- Marketplace already added → skip step 1.
- Plugin already installed → skip in step 5, count as success.
- No new signals → routing table content unchanged except the regenerated timestamp; still rewrite.
- Re-running with zero changes = exit code 0, "no-op" report (table + CLAUDE.md block byte-identical apart from timestamp).
- Per-repo by construction: running in repo B never touches repo A's `.claude/routing.md`.

## Anti-patterns

- Don't default to installing. Baked-in is the default; install only when the user explicitly picks that path.
- Don't install at `-s user` (global). That's the proactive-agent leak. Project scope only.
- Don't install all 81 plugins. Stack-gated, cap ~8.
- Don't skip the confirmation prompt on the install path — install is project-scoped and needs a restart.
- Don't write any global generated table (`~/.claude/skills/context/routing/agents.md`). That path is dead — the per-repo `.claude/routing.md` replaced it. Last-write-wins across repos was the bug it caused.
- Don't preserve hand edits in `.claude/routing.md` — there are none by design; the file is fully generated.
- Don't inline the full role table into `CLAUDE.md` — only the marker-block pointer. Two copies drift.
- Don't write routing into `AGENTS.md` — keep that portable for other tools.
- Don't remove the `Fallback context` column — skills need it when a slot is `—`.

## Workflow skill integration

`/breakdown`, `/sprint`, and `/focus` read **`.claude/routing.md`** directly (via shell
injection at skill load). If it's absent, or every slot is `—`, they **default to the
baked-in role profiles** in `context/roles/` — no hard stop. When the table binds a slot to a
plugin agent, they cross-check that plugin against the installed set and warn (not fail) on
any missing, falling back to the baked-in role for that slot.

This skill manages plugins + the routing table + the CLAUDE.md pointer. It does not patch
the workflow skills. The global static `context/routing/defaults.md` and `surfaces.md`
(surface-detection taxonomy) remain global and untouched — only the role→subagent binding
is per-repo.
