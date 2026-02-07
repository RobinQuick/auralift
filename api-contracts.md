# API Contracts

> API endpoints, request/response formats, and error handling

## API Overview

- **Base URL:** `https://api.[yourdomain].com/v1` or `https://[yourdomain].com/api/v1`
- **Format:** JSON
- **Authentication:** Bearer token (session) or API key
- **Versioning:** URL path (`/v1/`)

## Common Headers

### Request Headers
```
Content-Type: application/json
Authorization: Bearer <token>
X-Organization-ID: <uuid>  (optional, if not in session)
```

### Response Headers
```
Content-Type: application/json
X-Request-ID: <uuid>       (for debugging/support)
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1640000000
```

## Standard Response Format

### Success Response
```json
{
  "data": { ... },
  "meta": {
    "requestId": "req_abc123"
  }
}
```

### List Response (with pagination)
```json
{
  "data": [ ... ],
  "meta": {
    "total": 100,
    "page": 1,
    "perPage": 20,
    "totalPages": 5,
    "requestId": "req_abc123"
  }
}
```

### Error Response
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input",
    "details": [
      {
        "field": "email",
        "message": "Must be a valid email address"
      }
    ]
  },
  "meta": {
    "requestId": "req_abc123"
  }
}
```

## Error Codes

| HTTP Status | Code | Description |
|-------------|------|-------------|
| 400 | `VALIDATION_ERROR` | Invalid request body |
| 400 | `BAD_REQUEST` | Malformed request |
| 401 | `UNAUTHORIZED` | Missing or invalid auth |
| 403 | `FORBIDDEN` | Insufficient permissions |
| 404 | `NOT_FOUND` | Resource doesn't exist |
| 409 | `CONFLICT` | Resource already exists |
| 422 | `UNPROCESSABLE` | Valid syntax, invalid semantics |
| 429 | `RATE_LIMITED` | Too many requests |
| 500 | `INTERNAL_ERROR` | Server error |

---

## Endpoints

### Authentication

#### POST /auth/login
Authenticate user and create session.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "securepassword"
}
```

**Response (200):**
```json
{
  "data": {
    "user": {
      "id": "usr_xxx",
      "email": "user@example.com",
      "name": "John Doe"
    },
    "organization": {
      "id": "org_xxx",
      "name": "Acme Inc",
      "slug": "acme",
      "role": "admin"
    },
    "accessToken": "eyJ...",
    "expiresAt": "2024-01-15T00:00:00Z"
  }
}
```

#### POST /auth/logout
End current session.

**Response (200):**
```json
{
  "data": {
    "success": true
  }
}
```

#### GET /auth/me
Get current user and organization.

**Response (200):**
```json
{
  "data": {
    "user": {
      "id": "usr_xxx",
      "email": "user@example.com",
      "name": "John Doe"
    },
    "organization": {
      "id": "org_xxx",
      "name": "Acme Inc",
      "slug": "acme",
      "role": "admin",
      "plan": "pro"
    }
  }
}
```

---

### Organizations

#### GET /organizations/:id
Get organization details.

**Response (200):**
```json
{
  "data": {
    "id": "org_xxx",
    "name": "Acme Inc",
    "slug": "acme",
    "plan": "pro",
    "settings": {},
    "createdAt": "2024-01-01T00:00:00Z"
  }
}
```

#### PATCH /organizations/:id
Update organization.

**Request:**
```json
{
  "name": "Acme Corporation",
  "settings": {
    "timezone": "America/New_York"
  }
}
```

**Response (200):** Updated organization object

---

### Users / Team

#### GET /organizations/:orgId/members
List organization members.

**Query Parameters:**
- `page` (number, default: 1)
- `perPage` (number, default: 20, max: 100)
- `role` (string, optional): Filter by role

**Response (200):**
```json
{
  "data": [
    {
      "id": "usr_xxx",
      "email": "user@example.com",
      "name": "John Doe",
      "role": "admin",
      "joinedAt": "2024-01-01T00:00:00Z"
    }
  ],
  "meta": {
    "total": 5,
    "page": 1,
    "perPage": 20
  }
}
```

#### POST /organizations/:orgId/invitations
Invite a new member.

**Request:**
```json
{
  "email": "newuser@example.com",
  "role": "member"
}
```

**Response (201):**
```json
{
  "data": {
    "id": "inv_xxx",
    "email": "newuser@example.com",
    "role": "member",
    "status": "pending",
    "expiresAt": "2024-01-08T00:00:00Z"
  }
}
```

#### DELETE /organizations/:orgId/members/:userId
Remove a member.

**Response (204):** No content

---

### [Your Resource]

Replace with your domain-specific endpoints.

#### GET /[resources]
List resources.

**Query Parameters:**
- `page` (number)
- `perPage` (number)
- `sort` (string): Field to sort by
- `order` (string): `asc` or `desc`
- `search` (string): Search query
- `[filter]` (string): Filter by field

**Response (200):**
```json
{
  "data": [
    {
      "id": "res_xxx",
      "name": "Example Resource",
      "status": "active",
      "createdAt": "2024-01-01T00:00:00Z",
      "updatedAt": "2024-01-01T00:00:00Z"
    }
  ],
  "meta": {
    "total": 50,
    "page": 1,
    "perPage": 20
  }
}
```

#### POST /[resources]
Create a resource.

**Request:**
```json
{
  "name": "New Resource",
  "[field]": "[value]"
}
```

**Response (201):** Created resource object

#### GET /[resources]/:id
Get a single resource.

**Response (200):** Resource object

#### PATCH /[resources]/:id
Update a resource.

**Request:**
```json
{
  "name": "Updated Name"
}
```

**Response (200):** Updated resource object

#### DELETE /[resources]/:id
Delete a resource.

**Response (204):** No content

---

### Billing

#### GET /billing/subscription
Get current subscription.

**Response (200):**
```json
{
  "data": {
    "plan": "pro",
    "status": "active",
    "currentPeriodStart": "2024-01-01T00:00:00Z",
    "currentPeriodEnd": "2024-02-01T00:00:00Z",
    "cancelAtPeriodEnd": false
  }
}
```

#### POST /billing/checkout
Create checkout session for upgrade.

**Request:**
```json
{
  "plan": "pro",
  "successUrl": "https://app.example.com/billing/success",
  "cancelUrl": "https://app.example.com/billing"
}
```

**Response (200):**
```json
{
  "data": {
    "checkoutUrl": "https://checkout.stripe.com/..."
  }
}
```

#### POST /billing/portal
Create billing portal session.

**Response (200):**
```json
{
  "data": {
    "portalUrl": "https://billing.stripe.com/..."
  }
}
```

---

## Webhooks

### Webhook Payload Format
```json
{
  "id": "evt_xxx",
  "type": "resource.created",
  "data": { ... },
  "createdAt": "2024-01-01T00:00:00Z"
}
```

### Webhook Events
- `resource.created`
- `resource.updated`
- `resource.deleted`
- `subscription.updated`
- `subscription.canceled`

### Webhook Security
- Verify signature using `X-Webhook-Signature` header
- Timestamp validation to prevent replay attacks
