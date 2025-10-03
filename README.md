# HorizCoin Platform (Foundation Bundle)

This commit introduces the complete initial foundation including:

- Next.js 15 App Router + TypeScript
- Prisma schema (Users, Orgs, Memberships, Projects, Items, Billing, Flags, Usage)
- Authentication: NextAuth (credentials) with JWT sessions
- Security: Rate limiting (Redis), strict security headers + CSP nonce
- Feature Flags: In-memory bootstrap + admin UI + API
- Organizations: Create & list orgs, membership model
- Projects & Items: Basic CRUD endpoints (list/create for now)
- Billing: Stripe stub (customer creation util placeholder, checkout session route, webhook placeholder) & plan enforcement (project limit on free plan)
- Caching: Redis-backed project list cache (60s) with invalidation on create
- Observability: OpenTelemetry initialization placeholder
- Infrastructure: CDK stack (Aurora Serverless Postgres, ECS, ALB), Dockerfile, docker-compose
- Tooling: Makefile, CI (lint / typecheck / build / test), Deploy workflow scaffold

Excluded by request:
- Password reset flow (model & endpoints not included)

Partially implemented (future expansion expected):
- Stripe full subscription lifecycle (only stub + endpoints placeholders)
- OpenTelemetry exporters (placeholder only, no deps installed yet)
- Feature flags persistence (currently in-memory bootstrap; DB model present but not wired for CRUD)

## Getting Started (Local)

```bash
docker compose up -d
cd app
cp ../.env.example .env
npm install
npx prisma migrate dev --name init
npm run dev
```

Seed a user (replace hash with generated one):
```bash
node -e "require('bcryptjs').hash('StrongPass123!',10).then(h=>console.log(h))"
```
Insert:
```sql
INSERT INTO "User" (id,email,"hashedPassword","createdAt") VALUES ('usr_demo','demo@example.com','$2a$10$REPLACE_HASH',NOW());
```

## Environment Variables
See `.env.example` for full list.

## Project List Caching
- Key: `user:projects:{userId}`
- TTL: 60 seconds (adjust in cache.ts)
- Invalidation triggered on project create

## Stripe Stub
Implements endpoints:
- POST `/api/billing/checkout` – creates a placeholder session (TODO real Stripe integration)
- POST `/api/webhooks/stripe` – webhook handler placeholder validating signature (no event handling yet)

## Deployment
- CI runs on PR / main
- Deploy workflow builds image → CDK deploy (HTTP only unless ACM cert env provided) → optional migration task

## Next Steps (Suggested)
1. Complete Stripe subscription lifecycle + webhook event handling
2. Persist feature flags (CRUD + caching)
3. Add invites + email service integration
4. Implement password reset if required
5. Add OTel dependencies & exporter configuration
6. Add Playwright E2E tests
7. Introduce project member role enforcement on endpoints
8. Add automated ECS migration success gating
