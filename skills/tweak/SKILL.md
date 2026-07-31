---
name: tweak
description: Quick, focused iteration on a specific change. Use for small adjustments, bug fixes, styling tweaks, and minor improvements that don't need full planning or delegation.
argument-hint: [what to change]
---

# Tweak

Fast iteration mode. Make a focused change, verify it works, move on.

## Project context

!`cat CLAUDE.md 2>/dev/null || echo "No project context found — proceeding without project-specific context"`

## Coding principles

!`cat .claude/skills/context/principles/coding.md 2>/dev/null || cat "$HOME/.claude/skills/context/principles/coding.md" 2>/dev/null || echo "WARNING: Coding principles not found at expected path — check cc-team-skills installation"`

## Skill handoffs

!`cat .claude/skills/context/handoffs.md 2>/dev/null || cat "$HOME/.claude/skills/context/handoffs.md" 2>/dev/null || echo "WARNING: Handoff map not found at expected path"`

## Workflow

### Step 1 — Assess scope

Before touching code, determine if this is actually a tweak:

**It's a tweak if:**
- Touches 1-3 files
- Single concern (fix a bug, adjust styling, rename, add a field)
- No new architectural decisions needed
- No new dependencies
- Can be verified with typecheck + existing tests

**It's NOT a tweak if:**
- Requires new database migrations
- Touches auth, RLS, or security boundaries
- Needs new API endpoints or contracts
- Affects multiple unrelated surfaces
- Requires design decisions or tradeoffs

**If not a tweak:**
- Too ambiguous → suggest `/jam` to explore the problem first
- Single concern but bigger than 1–3 files / needs design → suggest `/focus`
- Multi-concern, decomposes into several tickets → suggest `/breakdown`
- A bug whose cause you can't explain → suggest `/rca` to diagnose before touching code
- Not sure which → suggest `/drive` to assess and route
- State this clearly and stop. Don't half-implement something that needs proper planning.

### Step 2 — Implement

- Make the minimal change that achieves the goal.
- Don't refactor surrounding code. Don't add features. Don't "improve while you're here."
- If you notice adjacent issues, mention them but don't fix them.

### Step 3 — Verify

Always run after changes:
```
!`cat CLAUDE.md 2>/dev/null | grep -A5 "Key Commands" | head -6 || echo "Check project for typecheck/test commands"`
```

- Typecheck must pass.
- Run relevant tests. If no tests cover the change, note it.
- If the change is user-facing and a dev server is available, test in browser.

### Step 4 — Offer to commit

Ask if the user wants to commit. Don't auto-commit. If yes, write a concise commit message that captures the what and why.

## Anti-patterns

- Don't scope-creep. The user asked for one thing. Do that thing.
- Don't skip verification. "It should work" is not verification.
- Don't refactor. Tweak mode is surgical.
