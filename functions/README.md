# SALT Cloud Functions

Backend for the SALT iOS app.

## Functions included

| Function | Trigger | Purpose |
|----------|---------|---------|
| `onMembershipApproved` | Firestore update on `membershipApplications` | Sets user to `active`, sends welcome email + push |
| `onNewApplication` | Firestore create on `membershipApplications` | Pushes notification to all board members |
| `onNewMessage` | Firestore create on `messages` | Increments unread count + pushes to recipient |
| `stripeWebhook` | HTTPS | Handles Stripe `payment_intent.succeeded` / `failed` for dues |
| `createDuesPaymentIntent` | HTTPS | Creates a Stripe PaymentIntent for membership dues |

## Prerequisites

- Node.js 20
- Firebase CLI (`npm i -g firebase-tools`)
- A Firebase project with Blaze plan (required for Cloud Functions + secrets)

## Setup

```bash
cd functions
npm install
```

### 1. Login & select project

```bash
firebase login
firebase use --add   # select your SALT project
```

### 2. Set secrets

```bash
firebase functions:secrets:set STRIPE_SECRET_KEY
firebase functions:secrets:set STRIPE_WEBHOOK_SECRET
firebase functions:secrets:set SMTP_USER
firebase functions:secrets:set SMTP_PASS
```

- **STRIPE_SECRET_KEY** – from Stripe Dashboard → Developers → API keys  
- **STRIPE_WEBHOOK_SECRET** – from Stripe Dashboard → Developers → Webhooks (after you add the endpoint)  
- **SMTP_USER / SMTP_PASS** – Gmail or Google Workspace app password (or swap transport for SendGrid)

### 3. Deploy

```bash
npm run build
firebase deploy --only functions,firestore
```

### 4. Stripe webhook

After deploy, copy the function URL:

```
https://<region>-<project-id>.cloudfunctions.net/stripeWebhook
```

In Stripe Dashboard → Webhooks → Add endpoint → paste URL → select events:
- `payment_intent.succeeded`
- `payment_intent.payment_failed`

Copy the signing secret into `STRIPE_WEBHOOK_SECRET`.

## Local emulation

```bash
npm run serve
```

## iOS integration notes

### Creating a dues PaymentIntent

```swift
// POST to createDuesPaymentIntent
let body: [String: Any] = [
  "userId": user.id,
  "tier": user.tier.rawValue,
  "amount": user.tier.annualDues,
  "paymentDocId": paymentDocId
]
// Use URLSession → decode clientSecret → present Stripe PaymentSheet
```

### Push deep links

Notification `data` payload contains:
- `type`: `membership_approved` | `new_application` | `new_message` | `payment_success`
- `conversationId` (for messages)
- `applicationId` (for board)

Handle in `FirebaseManager` / `UNUserNotificationCenterDelegate` to navigate.

## Email template

Welcome email is plain HTML. Swap `nodemailer` + Gmail for:
- SendGrid
- Mailgun
- Amazon SES
- Firebase Extensions “Trigger Email”

just by changing the transport in `createMailTransport`.
