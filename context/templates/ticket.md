# Ticket Template

Use this structure when breakdown creates implementation tickets. Render as GitHub issues linked to the parent epic.

---

## Title
{Verb} {what} {where} — e.g. "Add weight column to personas table"

## Parent
Closes #{epic_number} (partial)

## Surface
{frontend | backend | database | infrastructure | mobile}

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

## Routing
- **Plan**: {architect | skip}
- **Implement**: {frontend-dev | backend-dev | db-specialist | infra-dev | mobile-dev}
- **Review**: {reviewer, ux-reviewer, security-reviewer — as applicable}
- **Post-steps**: {typecheck, test, codegen, cdk diff, etc.}

## Notes
{Any context the implementing agent needs that isn't obvious from the description or acceptance criteria}
