# Authentication & Multi-Tenancy

> How users authenticate and how tenant isolation works

## Authentication Strategy

### Provider
- **Choice:** [Clerk / Auth0 / Supabase Auth / NextAuth.js / Custom]
- **Rationale:** [Why this provider]

### Supported Auth Methods
- [ ] Email/Password
- [ ] Magic Link (passwordless)
- [ ] Google OAuth
- [ ] Microsoft/Azure AD (for enterprise)
- [ ] SAML SSO (enterprise)
- [ ] API Keys (for integrations)

## Authentication Flow

### Sign Up Flow
```
1. User visits /signup
2. User enters email + password (or OAuth)
3. Auth provider creates user
4. Webhook/callback creates:
   - Organization record (new tenant)
   - User record (as owner)
   - Default settings
5. User redirected to /dashboard
```

### Sign In Flow
```
1. User visits /login
2. User authenticates via provider
3. Session/JWT issued
4. User redirected to /dashboard
5. App loads user's organization context
```

### Invite Flow (Team Members)
```
1. Admin visits /settings/team
2. Admin enters email to invite
3. System creates:
   - Invitation record (with token)
   - Sends invite email
4. Invitee clicks link → /invite/[token]
5. Invitee creates account
6. System links user to organization
7. Invitation marked as accepted
```

## Session Management

### Session Strategy
- **Type:** [JWT / Server Session / Hybrid]
- **Storage:** [Cookie / LocalStorage / Memory]
- **Duration:** [e.g., 7 days, sliding window]
- **Refresh:** [How tokens are refreshed]

### Session Data Structure
```typescript
interface Session {
  user: {
    id: string;
    email: string;
    name: string;
  };
  organization: {
    id: string;
    slug: string;
    role: 'owner' | 'admin' | 'member' | 'viewer';
    plan: string;
  };
  expiresAt: Date;
}
```

## Multi-Tenancy Model

### Tenancy Approach
**Selected:** [Shared Database with Tenant ID Column]

| Approach | Pros | Cons |
|----------|------|------|
| **Shared DB + Tenant Column** ✓ | Simple, cost-effective | Query discipline required |
| Separate Schemas | Better isolation | Migration complexity |
| Separate Databases | Full isolation | Operational overhead |

### Tenant Resolution

**How we determine current tenant:**

```typescript
// Option 1: From subdomain
// acme.yourapp.com → organization.slug = 'acme'

// Option 2: From URL path
// yourapp.com/org/acme → organization.slug = 'acme'

// Option 3: From user's default org (stored in session)
// User logs in → session includes organization_id

// Option 4: From header (API)
// X-Organization-ID: uuid
```

**Implementation:**
```typescript
// Middleware example (Next.js)
export async function middleware(request: NextRequest) {
  const session = await getSession(request);
  
  if (!session) {
    return NextResponse.redirect('/login');
  }
  
  // Add org context to request
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set('x-organization-id', session.organization.id);
  
  return NextResponse.next({
    request: { headers: requestHeaders }
  });
}
```

### Data Isolation

**Every query MUST be scoped to tenant:**

```typescript
// ✅ CORRECT - Always filter by organization
const resources = await db.resource.findMany({
  where: {
    organizationId: currentOrg.id,  // REQUIRED
    // ... other filters
  }
});

// ❌ WRONG - Never query without tenant filter
const resources = await db.resource.findMany({
  where: {
    // Missing organizationId!
  }
});
```

**Database-level enforcement (Postgres RLS):**
```sql
-- All queries automatically filtered
CREATE POLICY "tenant_isolation" ON resources
  USING (organization_id = current_setting('app.current_org_id')::uuid);
```

## Roles & Permissions

### Role Hierarchy
```
owner (full access)
  └── admin (manage team, settings)
        └── member (create/edit resources)
              └── viewer (read-only)
```

### Permission Matrix

| Action | Owner | Admin | Member | Viewer |
|--------|-------|-------|--------|--------|
| View resources | ✅ | ✅ | ✅ | ✅ |
| Create resources | ✅ | ✅ | ✅ | ❌ |
| Edit resources | ✅ | ✅ | ✅ | ❌ |
| Delete resources | ✅ | ✅ | ❌ | ❌ |
| Invite members | ✅ | ✅ | ❌ | ❌ |
| Remove members | ✅ | ✅ | ❌ | ❌ |
| Change roles | ✅ | ✅ | ❌ | ❌ |
| Billing/subscription | ✅ | ❌ | ❌ | ❌ |
| Delete organization | ✅ | ❌ | ❌ | ❌ |

### Permission Check Implementation

```typescript
// lib/auth/permissions.ts
type Role = 'owner' | 'admin' | 'member' | 'viewer';
type Permission = 'read' | 'write' | 'delete' | 'manage_team' | 'billing';

const rolePermissions: Record<Role, Permission[]> = {
  owner: ['read', 'write', 'delete', 'manage_team', 'billing'],
  admin: ['read', 'write', 'delete', 'manage_team'],
  member: ['read', 'write'],
  viewer: ['read'],
};

export function hasPermission(role: Role, permission: Permission): boolean {
  return rolePermissions[role]?.includes(permission) ?? false;
}

// Usage in API route
export async function DELETE(req: Request) {
  const session = await getSession();
  
  if (!hasPermission(session.organization.role, 'delete')) {
    return new Response('Forbidden', { status: 403 });
  }
  
  // ... proceed with deletion
}
```

## API Authentication

### For Web App
- Session cookie (httpOnly, secure, sameSite)
- CSRF protection via double-submit cookie

### For External Integrations
```typescript
// API Key authentication
interface ApiKey {
  id: string;
  organizationId: string;
  key: string;          // Hashed, prefix visible (e.g., sk_live_xxx...)
  name: string;         // User-defined label
  permissions: string[]; // Scoped permissions
  lastUsedAt: Date;
  createdAt: Date;
}
```

**API Key Usage:**
```bash
curl https://api.yourapp.com/v1/resources \
  -H "Authorization: Bearer sk_live_xxxxxxxxxxxxx"
```

## Security Checklist

- [ ] Passwords hashed with bcrypt/argon2 (if not using external auth)
- [ ] Sessions invalidated on password change
- [ ] Rate limiting on auth endpoints
- [ ] Account lockout after failed attempts
- [ ] Secure password reset flow
- [ ] Email verification required
- [ ] HTTPS enforced everywhere
- [ ] Sensitive actions require re-authentication
- [ ] Audit log for auth events
- [ ] API keys can be revoked
