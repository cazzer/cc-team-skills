# Default Routing Table

Surface-to-workflow mapping. Repos can override by providing their own routing file.

## Surface types

| Surface | Plan agent | Implement agent | Review agents | Post-steps |
|---|---|---|---|---|
| **Frontend** | architect (skip for trivial) | frontend-dev | reviewer + ux-reviewer | typecheck, test |
| **Backend API** | architect | backend-dev | reviewer, +security if auth-touching | typecheck, test |
| **Database** | architect (always) | db-specialist | reviewer + security | migration test, codegen if applicable |
| **Infrastructure** | architect (always) | infra-dev | reviewer + security (always) | cdk diff/synth |
| **Mobile** | architect (skip for trivial) | mobile-dev | reviewer + ux-reviewer | typecheck, test, both platforms |
| **Cross-surface** | architect (always) | split into sub-tickets or serialize | all relevant reviewers | full test suite |

## Routing rules

1. **Single surface** — use the matching row directly.
2. **Multi-surface ticket** — if breakdown tagged multiple surfaces, prefer splitting. If tightly coupled (e.g. DB + codegen + backend in one migration), serialize in dependency order.
3. **Unknown surface** — agent classifies by reading ticket + scanning expected file paths. Default to backend-dev + reviewer if unclear.
4. **Security review triggers** — always for: infra, DB, auth/RLS changes, environment variables, external URL handling, secret management. Optional for: frontend-only, styling, copy changes.
5. **UX review triggers** — always for: user-facing UI changes, new pages/flows, form changes. Skip for: backend-only, infra, DB.

## Dependency ordering

When multiple tickets execute in parallel:
- DB migrations must complete + codegen must run before frontend/backend work that depends on new schema.
- API contract changes must land before consumers.
- Shared utility/type changes must land before dependents.
- Frontend and backend can parallelize when they share no new contracts.

## Override mechanism

Repos provide overrides in `.claude/routing.md` or `.claude/skills/team/routing-overrides.md`. Override format:

```markdown
## Additional surfaces

| Surface | Plan | Implement | Review | Post-steps |
|---|---|---|---|---|
| **Edge functions** | architect | backend-dev | reviewer + security | deploy test |

## Overrides

- Frontend: add `accessibility-audit` to post-steps
- Database: codegen step is `npm run graphql:codegen`
```
