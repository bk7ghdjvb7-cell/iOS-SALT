# SALT – Complete Setup Guide (Steps 1–4)

## Step 1 — Create Firebase project & add GoogleService-Info.plist

1. Go to [Firebase Console](https://console.firebase.google.com)
2. **Add project** → name it `SALT Savannah` (or similar)
3. Disable Google Analytics if you prefer (optional)
4. **Add app** → iOS
   - Bundle ID: `org.salt.savannah.SALT`
   - App nickname: SALT
5. Download **GoogleService-Info.plist**
6. Drag it into Xcode under the `SALT` group (target membership = SALT)
7. Enable these products in Firebase Console:
   - **Authentication** → Sign-in method → Email/Password → Enable
   - **Firestore Database** → Create database (production mode) → location closest to you
   - **Cloud Messaging** (enabled by default)
   - **Storage** (optional, for profile photos later)

---

## Step 2 — Add Firebase (and Stripe) packages in Xcode

**File → Add Package Dependencies…**

### Firebase
- URL: `https://github.com/firebase/firebase-ios-sdk`
- Version: 11.0.0 or later
- Add to target **SALT**:
  - FirebaseAuth
  - FirebaseFirestore
  - FirebaseStorage
  - FirebaseMessaging
  - FirebaseAnalytics (optional)

### Stripe (for PaymentSheet)
- URL: `https://github.com/stripe/stripe-ios`
- Add:
  - StripePaymentSheet
  - StripePayments

After packages resolve, **uncomment** the Stripe code in  
`Views/Payments/DuesPaymentView.swift`.

---

## Step 3 — Deploy Cloud Functions + Firestore rules

```bash
# From the SALT/ directory (repo root that contains functions/)
cd functions
npm install
firebase login
firebase use --add          # select your SALT project

# Set secrets (you will be prompted to paste values)
firebase functions:secrets:set STRIPE_SECRET_KEY
firebase functions:secrets:set STRIPE_WEBHOOK_SECRET
firebase functions:secrets:set SMTP_USER
firebase functions:secrets:set SMTP_PASS

npm run build
firebase deploy --only functions,firestore
```

Copy the deployed function URL for `createDuesPaymentIntent` and paste it into:

```swift
// PaymentService.swift
var createIntentURL = URL(string: "https://REGION-PROJECT.cloudfunctions.net/createDuesPaymentIntent")!
```

Also set your Stripe **publishable** key:

```swift
var stripePublishableKey = "pk_test_..."
```

### Stripe Webhook
1. Stripe Dashboard → Developers → Webhooks → Add endpoint  
2. URL: `https://REGION-PROJECT.cloudfunctions.net/stripeWebhook`  
3. Events: `payment_intent.succeeded`, `payment_intent.payment_failed`  
4. Copy signing secret →  
   `firebase functions:secrets:set STRIPE_WEBHOOK_SECRET`

---

## Step 4 — Connect secrets & finish configuration

| Secret | Where to get it |
|--------|-----------------|
| `STRIPE_SECRET_KEY` | Stripe → API keys → Secret key |
| `STRIPE_WEBHOOK_SECRET` | Stripe → Webhooks → Signing secret |
| `SMTP_USER` | Gmail address (or SendGrid later) |
| `SMTP_PASS` | Gmail App Password (not normal password) |

### APNs for push (required for real devices)
1. Apple Developer → Keys → Create APNs key  
2. Upload to Firebase Console → Project Settings → Cloud Messaging → APNs

### Info.plist / capabilities in Xcode
- Signing & Capabilities → **+ Push Notifications**
- **+ Background Modes** → Remote notifications

---

## Verify everything works

| Test | Expected |
|------|----------|
| Login with real Firebase user | Auth succeeds, profile loads |
| Apply for membership | Document appears in `membershipApplications` |
| Board member opens Board Review | Sees pending apps, Approve works → user becomes `active` + email/push |
| Message a member | Conversation created, messages sync, recipient gets push |
| Tap push for new message | App opens Messages tab → that conversation |
| Tap push for new application | App opens Profile → Board Review |
| Pay dues | PaymentIntent created → Stripe sheet → webhook marks paid |

---

## Mock mode

If `GoogleService-Info.plist` is **not** present, the app automatically runs in **mock mode** (local data, demo login).  
Add the plist and rebuild to switch to live Firebase.
