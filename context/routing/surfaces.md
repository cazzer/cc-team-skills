# Surface Detection

How to classify tickets by surface type when labels are missing.

## Heuristic: file path patterns

| Surface | Path patterns | File types |
|---|---|---|
| **Frontend** | `src/components/`, `src/pages/`, `src/hooks/`, `src/styles/`, `src/assets/` | `.tsx`, `.css`, `.scss` |
| **Backend API** | `src/api/`, `src/services/`, `supabase/functions/`, `server/`, `api/` | `.ts`, `.js` |
| **Database** | `supabase/migrations/`, `migrations/`, `prisma/`, `drizzle/` | `.sql`, `schema.prisma` |
| **Infrastructure** | `infrastructure/`, `cdk/`, `terraform/`, `pulumi/`, `.github/workflows/` | `.ts` (CDK), `.tf`, `.yml` |
| **Mobile** | `ios/`, `android/`, `app/`, `src/screens/` | `.tsx`, `.swift`, `.kt` |

## Heuristic: content signals

| Surface | Content signals |
|---|---|
| **Frontend** | JSX/TSX, CSS classes, component props, React hooks, event handlers |
| **Backend API** | Route handlers, middleware, service classes, API response shapes |
| **Database** | CREATE TABLE, ALTER TABLE, RLS policies, migrations, SQL queries |
| **Infrastructure** | CDK constructs, Terraform resources, IAM policies, CloudFormation |
| **Mobile** | Platform.select, SafeAreaView, navigation stacks, native modules |

## Multi-surface indicators

A ticket is multi-surface when:
- File paths span multiple surface categories
- The description mentions both "UI" and "API" (or similar cross-boundary terms)
- It involves a new data field end-to-end (DB → API → UI)

Multi-surface tickets should be flagged during breakdown for potential splitting.
