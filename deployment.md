# Deployment & Infrastructure

> How to deploy, environments, and CI/CD setup

## Hosting Strategy

### Platform
**Selected:** [Vercel / Render / Railway / AWS / GCP / Fly.io]

**Rationale:** [Why this choice]

### Architecture
| Component | Service | Notes |
|-----------|---------|-------|
| Frontend | [Provider] | [Notes] |
| API/Backend | [Provider] | [Notes] |
| Database | [Provider] | [Notes] |
| File Storage | [Provider] | [Notes] |
| Background Jobs | [Provider] | [Notes] |

---

## Environments

| Environment | URL | Branch | Purpose |
|-------------|-----|--------|---------|
| Production | app.[domain].com | `main` | Live users |
| Staging | staging.[domain].com | `staging` | Pre-release testing |
| Preview | pr-[n].[domain].com | PRs | PR review |
| Development | localhost:3000 | local | Local dev |

### Environment Variables

#### All Environments
```bash
# App
NEXT_PUBLIC_APP_URL=https://[url]
NEXT_PUBLIC_APP_NAME=[name]

# Database
DATABASE_URL=postgresql://...

# Auth
[AUTH_PROVIDER]_SECRET=xxx
[AUTH_PROVIDER]_CLIENT_ID=xxx

# Stripe
STRIPE_SECRET_KEY=sk_[env]_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_[env]_xxx

# Email
[EMAIL_PROVIDER]_API_KEY=xxx

# Storage
[STORAGE_PROVIDER]_KEY=xxx
[STORAGE_PROVIDER]_SECRET=xxx
[STORAGE_PROVIDER]_BUCKET=xxx
```

#### Production-Only
```bash
# Analytics
[ANALYTICS]_ID=xxx

# Error tracking
SENTRY_DSN=xxx

# Feature flags
[FLAGS_PROVIDER]_KEY=xxx
```

#### Development-Only
```bash
# Debug
DEBUG=true
LOG_LEVEL=debug
```

---

## CI/CD Pipeline

### GitHub Actions Workflow

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, staging]
  pull_request:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm run lint
      - run: npm run type-check

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm run test

  e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npx playwright install --with-deps
      - run: npm run test:e2e

  deploy-preview:
    if: github.event_name == 'pull_request'
    needs: [lint, test]
    runs-on: ubuntu-latest
    steps:
      # Deploy to preview environment
      - name: Deploy to Preview
        run: echo "Deploy preview"

  deploy-production:
    if: github.ref == 'refs/heads/main'
    needs: [lint, test, e2e]
    runs-on: ubuntu-latest
    steps:
      # Deploy to production
      - name: Deploy to Production
        run: echo "Deploy production"
```

### Deploy Process

```
PR Created
    │
    ▼
┌─────────────┐
│    Lint     │──── Fail ──→ Block merge
└──────┬──────┘
       │ Pass
       ▼
┌─────────────┐
│    Test     │──── Fail ──→ Block merge
└──────┬──────┘
       │ Pass
       ▼
┌─────────────┐
│   Preview   │
│   Deploy    │
└──────┬──────┘
       │
       ▼
   PR Review
       │
       ▼
   Merge to main
       │
       ▼
┌─────────────┐
│   E2E Test  │──── Fail ──→ Alert team
└──────┬──────┘
       │ Pass
       ▼
┌─────────────┐
│  Production │
│   Deploy    │
└─────────────┘
```

---

## Database Migrations

### Strategy
- Migrations run automatically on deploy
- Always backwards-compatible (expand-contract)
- Never run destructive migrations in production without backup

### Commands
```bash
# Generate migration
npx prisma migrate dev --name [description]

# Apply migrations (production)
npx prisma migrate deploy

# Check migration status
npx prisma migrate status
```

### Pre-Deploy Checklist
- [ ] Migration tested locally
- [ ] Migration tested in staging
- [ ] Rollback plan documented
- [ ] Database backup taken (for breaking changes)

---

## Monitoring & Observability

### Error Tracking
- **Tool:** [Sentry / Bugsnag / Rollbar]
- **Integration:** Capture unhandled errors, log context

### Application Monitoring
- **Tool:** [Vercel Analytics / Datadog / New Relic]
- **Metrics:** Response times, error rates, throughput

### Logging
- **Tool:** [Built-in / Logtail / Axiom / Datadog]
- **Structure:** JSON logs with request ID, user ID

### Uptime Monitoring
- **Tool:** [BetterUptime / Pingdom / UptimeRobot]
- **Checks:** Health endpoint, critical paths

### Alerting
| Alert | Threshold | Channel |
|-------|-----------|---------|
| Error rate spike | >1% in 5min | Slack + PagerDuty |
| Response time | >2s p95 | Slack |
| Database CPU | >80% | Slack |
| Disk space | >90% | Slack |

---

## Scaling Considerations

### Current Limits
| Resource | Limit | Scale Path |
|----------|-------|------------|
| Database connections | [N] | Connection pooling |
| API rate limit | [N]/min | Caching, rate limiting |
| File storage | [N] GB | CDN, tiered storage |

### Horizontal Scaling
- Stateless API design ✓
- Session storage: [Redis / Database]
- File uploads: [Direct to S3/R2]
- Background jobs: [Queue-based]

---

## Security

### SSL/TLS
- [ ] All traffic over HTTPS
- [ ] HSTS enabled
- [ ] SSL certificates auto-renewed

### Headers
```typescript
// next.config.js or middleware
const securityHeaders = [
  { key: 'X-Frame-Options', value: 'DENY' },
  { key: 'X-Content-Type-Options', value: 'nosniff' },
  { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
  { key: 'Content-Security-Policy', value: "default-src 'self'" },
];
```

### Secrets Management
- [ ] Secrets in environment variables (not code)
- [ ] Rotate secrets periodically
- [ ] Different secrets per environment
- [ ] Access logged and audited

---

## Disaster Recovery

### Backups
| What | Frequency | Retention | Location |
|------|-----------|-----------|----------|
| Database | Daily | 30 days | [Provider] |
| File storage | Continuous | 90 days | [Provider] |
| Config/code | Git | Forever | GitHub |

### Recovery Procedures
1. **Database restore:** [Document steps]
2. **Rollback deploy:** [Document steps]
3. **Restore from backup:** [Document steps]

### RTO/RPO Targets
- **Recovery Time Objective (RTO):** [X] hours
- **Recovery Point Objective (RPO):** [X] hours
