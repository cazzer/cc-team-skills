# Ticket Template

Use this structure when breakdown creates implementation tickets. Render as GitHub issues linked to the parent epic/PRD. Routing metadata goes in GitHub labels, not the issue body.

## Labels to apply

- **Surface** (one): `surface:frontend`, `surface:backend`, `surface:database`, `surface:infra`, `surface:mobile`
- **Plan** (one): `plan:architect` or `plan:skip`
- **Review** (one+): `review:code` (always), `review:ux`, `review:security`

## Issue body template

---

## Title
{Verb} {what} {where} — e.g. "Add weight column to personas table"

## Parent
Closes #{epic_number} (partial)

## Description
One paragraph: what this ticket accomplishes and why it's a separate unit of work.

## Expected file paths
- `path/to/file1.ts`
- `path/to/file2.tsx`

## Acceptance criteria
- [ ] {Specific, testable criterion}
- [ ] {Another criterion}

## Dependencies
- Blocked by: #{ticket_number} (if any)
- Blocks: #{ticket_number} (if any)
- Parallel with: #{ticket_number} (if any)

## Post-steps
- {typecheck, test, codegen, cdk diff — as applicable}

## Notes
{Any context the implementing agent needs that isn't obvious from the description or acceptance criteria}
