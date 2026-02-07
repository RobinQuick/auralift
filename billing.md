# Billing & Subscriptions

> Pricing strategy, Stripe integration, and subscription lifecycle

## Pricing Strategy

### Pricing Model
**Selected:** [Choose one]
- [ ] **Flat-rate** — Single price, all features
- [ ] **Tiered** — Multiple plans with feature gates
- [ ] **Per-seat** — Price per user
- [ ] **Usage-based** — Pay for what you use
- [ ] **Hybrid** — Base fee + usage/seats

### Pricing Tiers

| Plan | Price | Billing | Target |
|------|-------|---------|--------|
| **Free** | $0 | - | Individual / Trial |
| **Starter** | $[X]/mo | Monthly | Small teams |
| **Pro** | $[X]/mo | Monthly/Annual | Growing teams |
| **Enterprise** | Custom | Annual | Large organizations |

### Feature Matrix

| Feature | Free | Starter | Pro | Enterprise |
|---------|------|---------|-----|------------|
| [Feature 1] | ✅ | ✅ | ✅ | ✅ |
| [Feature 2] | ❌ | ✅ | ✅ | ✅ |
| [Feature 3] | ❌ | ❌ | ✅ | ✅ |
| [Feature 4] | ❌ | ❌ | ❌ | ✅ |
| Users | 1 | 5 | 20 | Unlimited |
| [Resource] limit | 10 | 100 | 1,000 | Unlimited |
| Support | Community | Email | Priority | Dedicated |
| SSO/SAML | ❌ | ❌ | ❌ | ✅ |
| SLA | ❌ | ❌ | ❌ | ✅ |

### Usage Limits (if applicable)

| Metric | Free | Starter | Pro | Enterprise |
|--------|------|---------|-----|------------|
| API calls/month | 1,000 | 10,000 | 100,000 | Unlimited |
| Storage | 100MB | 1GB | 10GB | Custom |
| [Custom metric] | X | X | X | Custom |

## Stripe Integration

### Stripe Products Setup

```javascript
// stripe-products.js - Reference for Stripe dashboard setup

const products = {
  starter: {
    name: '[Product] Starter',
    prices: {
      monthly: 'price_xxx', // $X/month
      annual: 'price_xxx',  // $X/year (X months free)
    }
  },
  pro: {
    name: '[Product] Pro',
    prices: {
      monthly: 'price_xxx',
      annual: 'price_xxx',
    }
  }
};
```

### Environment Variables

```bash
# .env.local
STRIPE_SECRET_KEY=sk_test_xxx
STRIPE_PUBLISHABLE_KEY=pk_test_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx

# Price IDs
STRIPE_PRICE_STARTER_MONTHLY=price_xxx
STRIPE_PRICE_STARTER_ANNUAL=price_xxx
STRIPE_PRICE_PRO_MONTHLY=price_xxx
STRIPE_PRICE_PRO_ANNUAL=price_xxx
```

### Webhook Events to Handle

| Event | Action |
|-------|--------|
| `checkout.session.completed` | Create/update subscription record |
| `customer.subscription.updated` | Update plan, status, period |
| `customer.subscription.deleted` | Mark subscription as canceled |
| `invoice.paid` | Record payment, extend access |
| `invoice.payment_failed` | Notify user, update status |

### Webhook Handler

```typescript
// app/api/webhooks/stripe/route.ts

import Stripe from 'stripe';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);

export async function POST(req: Request) {
  const body = await req.text();
  const signature = req.headers.get('stripe-signature');
  
  let event: Stripe.Event;
  
  try {
    event = stripe.webhooks.constructEvent(
      body,
      signature,
      process.env.STRIPE_WEBHOOK_SECRET
    );
  } catch (err) {
    return new Response('Webhook signature verification failed', { status: 400 });
  }
  
  switch (event.type) {
    case 'checkout.session.completed':
      await handleCheckoutComplete(event.data.object);
      break;
    case 'customer.subscription.updated':
      await handleSubscriptionUpdate(event.data.object);
      break;
    case 'customer.subscription.deleted':
      await handleSubscriptionCanceled(event.data.object);
      break;
    case 'invoice.payment_failed':
      await handlePaymentFailed(event.data.object);
      break;
  }
  
  return new Response('OK', { status: 200 });
}
```

## Subscription Lifecycle

### New Subscription Flow
```
1. User clicks "Upgrade" 
2. Create Stripe Checkout Session
3. Redirect to Stripe Checkout
4. User completes payment
5. Stripe sends webhook: checkout.session.completed
6. Create/update subscription in database
7. User redirected to success page
8. Access to new features enabled
```

### Upgrade/Downgrade Flow
```
1. User selects new plan in billing settings
2. Create Stripe Checkout (for upgrade) or update subscription (for downgrade)
3. For upgrade: immediate access, prorated charge
4. For downgrade: access until period end, then reduced
5. Webhook updates database
```

### Cancellation Flow
```
1. User clicks "Cancel subscription"
2. Confirm cancellation intent
3. Call Stripe: cancel at period end (not immediately)
4. Update database: cancelAtPeriodEnd = true
5. User retains access until period end
6. At period end: webhook fires, access revoked
```

### Failed Payment Flow
```
1. Stripe attempts charge → fails
2. Webhook: invoice.payment_failed
3. Send notification email to user
4. Update subscription status to 'past_due'
5. Stripe retries (Smart Retries)
6. If all retries fail: subscription canceled
7. Grace period (optional): X days before access revoked
```

## Implementation Checklist

### Stripe Setup
- [ ] Create Stripe account
- [ ] Create Products and Prices
- [ ] Configure Customer Portal
- [ ] Set up Webhook endpoint
- [ ] Test with Stripe CLI locally

### Database
- [ ] `subscriptions` table created
- [ ] Link to organizations
- [ ] Store Stripe IDs (customer, subscription)

### Frontend
- [ ] Pricing page
- [ ] Checkout button/flow
- [ ] Billing settings page
- [ ] Plan comparison display
- [ ] Usage display (if applicable)

### Backend
- [ ] Checkout session creation endpoint
- [ ] Billing portal session endpoint
- [ ] Webhook handler
- [ ] Feature gating middleware
- [ ] Usage tracking (if applicable)

### Emails
- [ ] Payment successful
- [ ] Payment failed
- [ ] Subscription canceled
- [ ] Trial ending (if applicable)
- [ ] Plan upgraded/downgraded

## Feature Gating

```typescript
// lib/billing/features.ts

type Plan = 'free' | 'starter' | 'pro' | 'enterprise';
type Feature = 'advanced_analytics' | 'api_access' | 'sso' | 'priority_support';

const planFeatures: Record<Plan, Feature[]> = {
  free: [],
  starter: ['api_access'],
  pro: ['api_access', 'advanced_analytics'],
  enterprise: ['api_access', 'advanced_analytics', 'sso', 'priority_support'],
};

export function hasFeature(plan: Plan, feature: Feature): boolean {
  return planFeatures[plan]?.includes(feature) ?? false;
}

// Usage limits
const planLimits: Record<Plan, Record<string, number>> = {
  free: { users: 1, resources: 10 },
  starter: { users: 5, resources: 100 },
  pro: { users: 20, resources: 1000 },
  enterprise: { users: Infinity, resources: Infinity },
};

export function getLimit(plan: Plan, resource: string): number {
  return planLimits[plan]?.[resource] ?? 0;
}
```

## Testing

### Test Cards
```
Success: 4242 4242 4242 4242
Decline: 4000 0000 0000 0002
Requires Auth: 4000 0025 0000 3155
```

### Stripe CLI (local webhook testing)
```bash
stripe listen --forward-to localhost:3000/api/webhooks/stripe
```
