/**
 * SALT Cloud Functions
 * - Membership approval → activate user + welcome email + push
 * - Stripe webhook for dues payments
 * - Messaging helpers (unread counts + push on new message)
 * - New application notification to board
 */

import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";
import { getMessaging, MulticastMessage } from "firebase-admin/messaging";
import { onDocumentUpdated, onDocumentCreated } from "firebase-functions/v2/firestore";
import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as nodemailer from "nodemailer";
import Stripe from "stripe";

initializeApp();
const db = getFirestore();

// Secrets (set via: firebase functions:secrets:set STRIPE_SECRET_KEY etc.)
const stripeSecretKey = defineSecret("STRIPE_SECRET_KEY");
const stripeWebhookSecret = defineSecret("STRIPE_WEBHOOK_SECRET");
const smtpUser = defineSecret("SMTP_USER");
const smtpPass = defineSecret("SMTP_PASS");

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

async function sendPush(tokens: string[], title: string, body: string, data?: Record<string, string>) {
  if (!tokens.length) return;
  const message: MulticastMessage = {
    tokens,
    notification: { title, body },
    data: data ?? {},
    apns: {
      payload: {
        aps: { sound: "default", badge: 1 },
      },
    },
  };
  const res = await getMessaging().sendEachForMulticast(message);
  console.log(`Push sent: ${res.successCount} success, ${res.failureCount} failure`);
}

async function getUserFcmToken(uid: string): Promise<string | null> {
  const snap = await db.collection("fcmTokens").doc(uid).get();
  const token = snap.data()?.token;
  return typeof token === "string" ? token : null;
}

async function getBoardFcmTokens(): Promise<string[]> {
  const snap = await db.collection("users").where("isBoardMember", "==", true).get();
  const tokens = await Promise.all(snap.docs.map((doc) => getUserFcmToken(doc.id)));
  return tokens.filter((token): token is string => !!token);
}

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function createMailTransport(user: string, pass: string) {
  // Example uses Gmail / Google Workspace. Swap for SendGrid, Mailgun, etc.
  return nodemailer.createTransport({
    service: "gmail",
    auth: { user, pass },
  });
}

// ---------------------------------------------------------------------------
// 1. Membership Application Approved
//    Trigger: membershipApplications/{id} status → "approved"
// ---------------------------------------------------------------------------

export const onMembershipApproved = onDocumentUpdated(
  {
    document: "membershipApplications/{appId}",
    secrets: [smtpUser, smtpPass],
  },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;
    if (before.status === "approved" || after.status !== "approved") return;

    const userId = after.userId as string;
    const email = after.email as string;
    const fullName = after.fullName as string;

    // Ensure user profile is active (client also does this, but double-safe)
    await db.collection("users").doc(userId).set(
      { membershipStatus: "active" },
      { merge: true }
    );

    // Welcome email
    try {
      const transporter = createMailTransport(smtpUser.value(), smtpPass.value());
      await transporter.sendMail({
        from: `"SALT – Savannah Area Local Tours" <${smtpUser.value()}>`,
        to: email,
        subject: "Welcome to SALT – Your Membership is Approved!",
        html: `
          <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 560px; margin: 0 auto;">
            <h1 style="color: #6B2E8C;">Welcome to SALT</h1>
            <p>Hi ${escapeHtml(fullName)},</p>
            <p>Your membership application has been <strong>approved</strong> by the SALT Board of Directors.</p>
            <p>You now have full access to:</p>
            <ul>
              <li>Member Directory &amp; networking</li>
              <li>Events at member pricing</li>
              <li>Job Board (free postings)</li>
              <li>Resources &amp; advocacy updates</li>
              <li>Direct messaging with fellow members</li>
            </ul>
            <p>Tagline: <em>Connect • Network • Grow</em></p>
            <p>Open the SALT app to get started.</p>
            <p style="color: #888; font-size: 13px; margin-top: 32px;">
              SALT – Savannah Area Local Tours<br/>
              Independent, member-supported nonprofit founded in 2025
            </p>
          </div>
        `,
      });
      console.log(`Welcome email sent to ${email}`);
    } catch (err) {
      console.error("Email error:", err);
    }

    // Push notification
    const token = await getUserFcmToken(userId);
    if (token) {
      await sendPush(
        [token],
        "Membership Approved 🎉",
        "Welcome to SALT! Your application was approved. Open the app to connect.",
        { type: "membership_approved" }
      );
    }
  }
);

// ---------------------------------------------------------------------------
// 2. New Membership Application → notify Board
// ---------------------------------------------------------------------------

export const onNewApplication = onDocumentCreated(
  {
    document: "membershipApplications/{appId}",
  },
  async (event) => {
    const data = event.data?.data();
    if (!data || data.status !== "pending") return;

    const tokens = await getBoardFcmTokens();
    if (!tokens.length) return;

    await sendPush(
      tokens,
      "New Membership Application",
      `${data.fullName}${data.businessName ? ` (${data.businessName})` : ""} applied to join SALT.`,
      { type: "new_application", applicationId: event.params.appId }
    );
  }
);

// ---------------------------------------------------------------------------
// 3. New Chat Message → increment unread + push to recipient
// ---------------------------------------------------------------------------

export const onNewMessage = onDocumentCreated(
  {
    document: "messages/{messageId}",
  },
  async (event) => {
    const msg = event.data?.data();
    if (!msg) return;

    const conversationId = msg.conversationId as string;
    const senderId = msg.senderId as string;
    const text = (msg.text as string) || "";
    const senderName = (msg.senderName as string) || "Someone";
    const preview = text.startsWith("enc:v1:") ? "New encrypted message" : "New message";

    const convoRef = db.collection("conversations").doc(conversationId);
    const convoSnap = await convoRef.get();
    if (!convoSnap.exists) return;

    const convo = convoSnap.data()!;
    const participants: string[] = convo.participantIds || [];
    const recipientId = participants.find((id) => id !== senderId);
    if (!recipientId) return;

    // Increment unread for recipient
    await convoRef.update({
      [`unreadCount.${recipientId}`]: FieldValue.increment(1),
      lastMessage: preview,
      lastMessageAt: FieldValue.serverTimestamp(),
      lastSenderId: senderId,
    });

    // Push
    const token = await getUserFcmToken(recipientId);
    if (token) {
      await sendPush(
        [token],
        senderName,
        preview,
        {
          type: "new_message",
          conversationId,
        }
      );
    }
  }
);

// ---------------------------------------------------------------------------
// 4. Stripe Webhook – Dues Payment
//    Endpoint: https://<region>-<project>.cloudfunctions.net/stripeWebhook
// ---------------------------------------------------------------------------

export const stripeWebhook = onRequest(
  {
    secrets: [stripeSecretKey, stripeWebhookSecret],
    cors: false,
  },
  async (req, res) => {
    res.setHeader("Content-Security-Policy", CONTENT_SECURITY_POLICY);
    res.setHeader("X-Content-Type-Options", "nosniff");
    res.setHeader("Referrer-Policy", "no-referrer");
    res.setHeader("X-Frame-Options", "SAMEORIGIN");
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const stripe = new Stripe(stripeSecretKey.value(), {
      apiVersion: "2023-10-16",
    });

    const sig = req.headers["stripe-signature"] as string;
    let event: Stripe.Event;

    try {
      // rawBody is available on Cloud Functions gen2 when configured
      event = stripe.webhooks.constructEvent(
        (req as any).rawBody || req.body,
        sig,
        stripeWebhookSecret.value()
      );
    } catch {
      console.error("Webhook signature verification failed");
      res.status(400).send("Invalid webhook signature");
      return;
    }

    if (event.type === "payment_intent.succeeded") {
      const pi = event.data.object as Stripe.PaymentIntent;
      const userId = pi.metadata?.userId;
      const paymentDocId = pi.metadata?.paymentDocId;
      const year = pi.metadata?.year || String(new Date().getFullYear());

      if (userId) {
        // Mark payment as paid
        if (paymentDocId) {
          await db.collection("payments").doc(paymentDocId).set(
            {
              status: "paid",
              paidAt: FieldValue.serverTimestamp(),
              stripePaymentIntentId: pi.id,
              amount: (pi.amount || 0) / 100,
            },
            { merge: true }
          );
        }

        // Extend / confirm active membership
        await db.collection("users").doc(userId).set(
          {
            membershipStatus: "active",
            duesPaidThrough: year,
            lastPaymentAt: FieldValue.serverTimestamp(),
          },
          { merge: true }
        );

        // Thank-you push
        const token = await getUserFcmToken(userId);
        if (token) {
          await sendPush(
            [token],
            "Payment Received",
            `Thank you! Your SALT membership dues for ${year} are paid.`,
            { type: "payment_success" }
          );
        }

        console.log(`Dues payment succeeded for user ${userId}`);
      }
    }

    if (event.type === "payment_intent.payment_failed") {
      const pi = event.data.object as Stripe.PaymentIntent;
      const paymentDocId = pi.metadata?.paymentDocId;
      if (paymentDocId) {
        await db.collection("payments").doc(paymentDocId).set(
          { status: "failed" },
          { merge: true }
        );
      }
    }

    res.json({ received: true });
  }
);

// ---------------------------------------------------------------------------
// 5. Callable-style helper: create Stripe PaymentIntent for dues
//    Call from iOS via HTTPS or a thin callable wrapper
// ---------------------------------------------------------------------------

export const createDuesPaymentIntent = onRequest(
  {
    secrets: [stripeSecretKey],
    cors: false,
  },
  async (req, res) => {
    res.setHeader("Content-Security-Policy", CONTENT_SECURITY_POLICY);
    res.setHeader("X-Content-Type-Options", "nosniff");
    res.setHeader("Referrer-Policy", "no-referrer");
    res.setHeader("X-Frame-Options", "SAMEORIGIN");
    res.setHeader("Cache-Control", "no-store");
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const header = req.headers.authorization || "";
    if (!header.startsWith("Bearer ")) {
      res.status(401).json({ error: "Sign-in required" });
      return;
    }
    let userId = "";
    try {
      userId = (await getAuth().verifyIdToken(header.slice(7))).uid;
    } catch {
      res.status(401).json({ error: "Sign-in required" });
      return;
    }
    const userSnap = await db.collection("users").doc(userId).get();
    const tier = (userSnap.data()?.tier as string) || "individual";
    const duesByTier: Record<string, number> = {
      individual: 25,
      business: 75,
      sponsor: 150,
    };
    const amount = duesByTier[tier] ?? 25;
    const paymentDocId = typeof req.body?.paymentDocId === "string" ? req.body.paymentDocId : "";

    const stripe = new Stripe(stripeSecretKey.value(), {
      apiVersion: "2023-10-16",
    });

    try {
      const paymentIntent = await stripe.paymentIntents.create({
        amount: amount * 100,
        currency: "usd",
        automatic_payment_methods: { enabled: true },
        metadata: {
          userId,
          tier,
          paymentDocId,
          year: String(new Date().getFullYear()),
        },
        description: `SALT Membership Dues – ${tier}`,
      });

      res.json({
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
      });
      return;
    } catch {
      console.error("Payment intent failed");
      res.status(500).json({ error: "Payment could not be started" });
    }
  }
);

import { CONTENT_SECURITY_POLICY } from "./security";

export {
  CONTENT_SECURITY_POLICY,
  securityPolicy,
  loginAttempt,
  registerPasswordVerifier,
  saveMembershipNote,
  publishPublicPost,
  submitConsentReview,
  createGroupChat,
  requestGroupMember,
  decideGroupMember,
  groupKeyAttempt,
} from "./security";
