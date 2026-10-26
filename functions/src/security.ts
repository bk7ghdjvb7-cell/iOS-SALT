/**
 * Live-facing controls for SALT.
 *
 * Symmetric encryption is AES-256-GCM. Password verifiers use scrypt
 * (memory-hard) and SHA-512. AES-256 and SHA-512 are the primitives that
 * remain appropriate against Grover's algorithm; RSA and elliptic-curve
 * key exchange are not used for chat contents or notes.
 *
 * The server never stores a chat encryption key. It stores only ciphertext.
 */
import * as crypto from "crypto";
import { getApps, initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";
import { onRequest } from "firebase-functions/v2/https";
import { defineSecret, defineString } from "firebase-functions/params";

if (!getApps().length) {
  initializeApp();
}

const db = getFirestore();
const vaultSecret = defineSecret("DURABLE_VAULT_KEY");
const trustedProxySecret = defineSecret("TRUSTED_PROXY_SECRET");
const allowedHosts = defineString("SALT_ALLOWED_HOSTS", { default: "" });
const moderationWebhook = defineString("MODERATION_WEBHOOK", { default: "" });

export const CONTENT_SECURITY_POLICY = [
  "default-src 'self'",
  "script-src 'self' 'unsafe-inline'",
  "style-src 'self' 'unsafe-inline'",
  "img-src 'self' blob: data: https://images.unsplash.com",
  "font-src 'self'",
  "connect-src 'self'",
  "form-action 'self'",
  "base-uri 'self'",
  "object-src 'none'",
  "frame-ancestors 'self'",
].join("; ");

const LOGIN_LIMIT = 5;
const LOGIN_WINDOW_MS = 15 * 60 * 1000;
const POST_LIMIT = 3;
const POST_WINDOW_MS = 60 * 60 * 1000;
const KEY_DELAY_MS = 15 * 60 * 1000;

function applySecurityHeaders(res: { setHeader: (name: string, value: string) => void }) {
  res.setHeader("Content-Security-Policy", CONTENT_SECURITY_POLICY);
  res.setHeader("X-Content-Type-Options", "nosniff");
  res.setHeader("Referrer-Policy", "no-referrer");
  res.setHeader("X-Frame-Options", "SAMEORIGIN");
  res.setHeader("Cache-Control", "no-store");
}

function assertHost(req: { hostname?: string; get?: (name: string) => string | undefined }) {
  const configured = allowedHosts.value().split(",").map((h) => h.trim()).filter(Boolean);
  if (!configured.length) return;
  const host = (req.get?.("host") || req.hostname || "").split(":")[0];
  if (!configured.includes(host)) {
    throw Object.assign(new Error("Untrusted host"), { status: 421 });
  }
}

/**
 * Ignore X-Forwarded-For unless the request presents the proxy shared secret.
 * A reverse proxy in front of an attacker cannot mint that header value.
 */
function clientAddress(req: {
  ip?: string;
  headers: Record<string, string | string[] | undefined>;
  socket?: { remoteAddress?: string };
}): string {
  const supplied = req.headers["x-salt-proxy-secret"];
  const proxyOk = typeof supplied === "string" && supplied.length > 0 && supplied === trustedProxySecret.value();
  if (proxyOk) {
    const forwarded = req.headers["x-forwarded-for"];
    const raw = Array.isArray(forwarded) ? forwarded[0] : forwarded;
    const first = raw?.split(",")[0]?.trim();
    if (first) return first;
  }
  return req.ip || req.socket?.remoteAddress || "unknown";
}

function sha512(value: string): string {
  return crypto.createHash("sha512").update(value).digest("hex");
}

function sha512Buffer(value: Buffer): string {
  return crypto.createHash("sha512").update(value).digest("hex");
}

function loginSalt(email: string): Buffer {
  return crypto.createHash("sha512").update(`salt-login:${email}`).digest().subarray(0, 16);
}

function presentedProofHash(value: unknown): string | null {
  if (typeof value !== "string" || value.length === 0) return null;
  const raw = Buffer.from(value, "base64");
  if (raw.length !== 64) return null;
  return sha512Buffer(raw);
}

function proofsMatch(expected: string, presented: string | null): boolean {
  if (!presented || expected.length !== presented.length || expected.length === 0) return false;
  return crypto.timingSafeEqual(Buffer.from(expected), Buffer.from(presented));
}

function vaultKey(): Buffer {
  const raw = vaultSecret.value();
  return crypto.createHash("sha512").update(raw).digest().subarray(0, 32);
}

function encryptJson(payload: unknown): { ciphertext: string; iv: string; tag: string } {
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv("aes-256-gcm", vaultKey(), iv);
  const plaintext = Buffer.from(JSON.stringify(payload), "utf8");
  const ciphertext = Buffer.concat([cipher.update(plaintext), cipher.final()]);
  const tag = cipher.getAuthTag();
  return {
    ciphertext: ciphertext.toString("base64"),
    iv: iv.toString("base64"),
    tag: tag.toString("base64"),
  };
}

async function durablePut(kind: string, id: string, payload: unknown) {
  const sealed = encryptJson({ kind, id, payload, storedAt: new Date().toISOString() });
  const record = { kind, ...sealed, digest: sha512(sealed.ciphertext), updatedAt: FieldValue.serverTimestamp() };
  const batch = db.batch();
  batch.set(db.collection("durableVault").doc(id), record);
  batch.set(db.collection("durableVaultMirror").doc(id), record);
  await batch.commit();
}

async function verifyUser(req: { headers: Record<string, string | string[] | undefined> }): Promise<string> {
  const header = req.headers.authorization;
  const value = Array.isArray(header) ? header[0] : header;
  if (!value?.startsWith("Bearer ")) {
    throw Object.assign(new Error("Sign-in required"), { status: 401 });
  }
  const decoded = await getAuth().verifyIdToken(value.slice(7));
  return decoded.uid;
}

async function assertNotBlocked(address: string, uid?: string) {
  const addressId = sha512(`addr:${address}`);
  const addressDoc = await db.collection("blockedAddresses").doc(addressId).get();
  if (addressDoc.exists && addressDoc.data()?.blocked === true) {
    throw Object.assign(new Error("This network address is blocked"), { status: 403 });
  }
  if (uid) {
    const userDoc = await db.collection("blockedAccounts").doc(uid).get();
    if (userDoc.exists && userDoc.data()?.blocked === true) {
      throw Object.assign(new Error("This account is blocked"), { status: 403 });
    }
  }
}

async function consumeLimit(id: string, limit: number, windowMs: number) {
  const ref = db.collection("rateLimits").doc(id);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const now = Date.now();
    const start = (snap.data()?.windowStart as number) || 0;
    const count = (snap.data()?.count as number) || 0;
    const fresh = now - start >= windowMs;
    const next = fresh ? 1 : count + 1;
    if (!fresh && count >= limit) {
      throw Object.assign(new Error("Rate limit exceeded"), { status: 429, retryAt: start + windowMs });
    }
    tx.set(ref, { windowStart: fresh ? now : start, count: next, limit, windowMs });
  });
}

function sendError(res: { status: (code: number) => { json: (body: unknown) => void } }, err: unknown) {
  const status = (err as { status?: number }).status || 500;
  const retryAt = (err as { retryAt?: number }).retryAt;
  res.status(status).json({ error: err instanceof Error ? err.message : "Request failed", retryAt });
}

export const securityPolicy = onRequest({ cors: false, secrets: [trustedProxySecret] }, (req, res) => {
  applySecurityHeaders(res);
  try {
    assertHost(req);
  } catch (err) {
    sendError(res, err);
    return;
  }
  res.status(200).json({
    contentSecurityPolicy: CONTENT_SECURITY_POLICY,
    loginLimit: "5 per 15 minutes",
    publicPostLimit: "3 per hour",
    encryption: "AES-256-GCM",
    passwordVerifier: "scrypt + SHA-512",
    chatKeysStoredOnServer: false,
  });
});

export const loginAttempt = onRequest({ cors: false, secrets: [vaultSecret, trustedProxySecret] }, async (req, res) => {
  applySecurityHeaders(res);
  try {
    assertHost(req);
    if (req.method !== "POST") throw Object.assign(new Error("Method Not Allowed"), { status: 405 });
    if (req.body?.password) throw Object.assign(new Error("Send a scrypt proof, not a password"), { status: 400 });
    const address = clientAddress(req);
    const email = String(req.body?.email || "").toLowerCase();
    if (!email.includes("@")) throw Object.assign(new Error("Email required"), { status: 400 });
    await assertNotBlocked(address);
    const bucket = sha512(`login:${email}:${address}`);
    const presented = presentedProofHash(req.body?.passwordProof);
    const verifier = await db.collection("passwordVerifiers").doc(sha512(email)).get();
    const verified = proofsMatch(String(verifier.data()?.proofHash || ""), presented);
    await consumeLimit(bucket, LOGIN_LIMIT, LOGIN_WINDOW_MS);
    if (!verified) {
      const snap = await db.collection("rateLimits").doc(bucket).get();
      if ((snap.data()?.count as number) >= LOGIN_LIMIT) {
        const addressId = sha512(`addr:${address}`);
        await db.collection("blockedAddresses").doc(addressId).set({
          blocked: true,
          reason: "login-rate-limit",
          updatedAt: FieldValue.serverTimestamp(),
        });
        await durablePut("blocked-address", addressId, { addressHash: sha512(address), reason: "login-rate-limit" });
      }
    }
    await durablePut(`login:${bucket}:${Date.now()}`, `login-${bucket}-${Date.now()}`, {
      emailHash: sha512(email),
      addressHash: sha512(address),
      verified,
    });
    res.status(200).json({ ok: verified });
  } catch (err) {
    sendError(res, err);
  }
});

async function storeNote(kind: "membership" | "community", ownerId: string, noteId: string, note: unknown) {
  const sealed = encryptJson(note);
  await durablePut(`${kind}-note:${noteId}`, `${kind}-${noteId}`, { ownerId, ...sealed });
  await db.collection(kind === "membership" ? "membershipNotes" : "communityNotes").doc(noteId).set({
    ownerId,
    ...sealed,
    updatedAt: FieldValue.serverTimestamp(),
  });
}

export const registerPasswordVerifier = onRequest({ cors: false, secrets: [vaultSecret, trustedProxySecret] }, async (req, res) => {
  applySecurityHeaders(res);
  try {
    assertHost(req);
    if (req.method !== "POST") throw Object.assign(new Error("Method Not Allowed"), { status: 405 });
    if (req.body?.password) throw Object.assign(new Error("Send a scrypt proof, not a password"), { status: 400 });
    const uid = await verifyUser(req);
    const email = String(req.body?.email || "").toLowerCase();
    const presented = presentedProofHash(req.body?.passwordProof);
    if (!email.includes("@") || !presented) throw Object.assign(new Error("Email and scrypt proof required"), { status: 400 });
    const record = {
      uid,
      proofHash: presented,
      saltId: sha512Buffer(loginSalt(email)),
      kdf: "scrypt-N16384-r8-p1-sha512",
    };
    await db.collection("passwordVerifiers").doc(sha512(email)).set(record);
    await durablePut(`password-verifier:${sha512(email)}`, `verifier-${sha512(email)}`, record);
    res.status(200).json({ ok: true });
  } catch (err) {
    sendError(res, err);
  }
});

export const saveMembershipNote = onRequest({ cors: false, secrets: [vaultSecret, trustedProxySecret] }, async (req, res) => {
  applySecurityHeaders(res);
  try {
    assertHost(req);
    const uid = await verifyUser(req);
    const noteId = String(req.body?.noteId || crypto.randomUUID());
    await storeNote("membership", uid, noteId, { text: String(req.body?.text || ""), authorId: uid });
    res.status(200).json({ noteId });
  } catch (err) {
    sendError(res, err);
  }
});

export const publishPublicPost = onRequest({ cors: false, secrets: [vaultSecret, trustedProxySecret] }, async (req, res) => {
  applySecurityHeaders(res);
  try {
    assertHost(req);
    if (req.method !== "POST") throw Object.assign(new Error("Method Not Allowed"), { status: 405 });
    const uid = await verifyUser(req);
    const address = clientAddress(req);
    await assertNotBlocked(address, uid);
    await consumeLimit(sha512(`post:${uid}`), POST_LIMIT, POST_WINDOW_MS);
    if (req.body?.image || req.body?.unblurred || req.body?.original) {
      throw Object.assign(new Error("Unblurred images are not accepted"), { status: 400 });
    }
    const text = String(req.body?.text || "");
    const verdict = await classifyPublicText(text);
    const postId = crypto.randomUUID();
    if (verdict.illegal) {
      await db.collection("moderationReports").doc(postId).set({
        authorId: uid,
        digest: sha512(text),
        category: verdict.category,
        action: "blocked-deleted",
        createdAt: FieldValue.serverTimestamp(),
      });
      await durablePut(`moderation:${postId}`, `moderation-${postId}`, {
        authorId: uid,
        digest: sha512(text),
        category: verdict.category,
      });
      res.status(422).json({ blocked: true, reported: true, postId });
      return;
    }
    const sealed = encryptJson({ text, authorId: uid });
    await db.collection("posts").doc(postId).set({
      authorId: uid,
      ...sealed,
      blurApplied: req.body?.blurApplied === true,
      createdAt: FieldValue.serverTimestamp(),
    });
    await durablePut(`community-note:${postId}`, `community-${postId}`, { authorId: uid, ...sealed });
    res.status(200).json({ postId });
  } catch (err) {
    sendError(res, err);
  }
});

async function classifyPublicText(text: string): Promise<{ illegal: boolean; category: string }> {
  const endpoint = moderationWebhook.value();
  if (!endpoint) {
    return { illegal: false, category: "classifier-not-configured" };
  }
  const response = await fetch(endpoint, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ text }),
  });
  if (!response.ok) {
    return { illegal: true, category: "classifier-unavailable" };
  }
  const body = (await response.json()) as { illegal?: boolean; category?: string };
  return { illegal: body.illegal === true, category: body.category || "unspecified" };
}

export const submitConsentReview = onRequest({ cors: false, secrets: [vaultSecret, trustedProxySecret] }, async (req, res) => {
  applySecurityHeaders(res);
  try {
    assertHost(req);
    const uid = await verifyUser(req);
    const image = req.body?.imageBase64;
    if (typeof image !== "string" || image.length < 32) {
      throw Object.assign(new Error("Review image required"), { status: 400 });
    }
    const reviewId = crypto.randomUUID();
    await durablePut(`consent-review:${reviewId}`, `consent-${reviewId}`, {
      authorId: uid,
      imageBase64: image,
      purpose: "consent-verification",
    });
    res.status(200).json({ reviewId });
  } catch (err) {
    sendError(res, err);
  }
});

export const createGroupChat = onRequest({ cors: false, secrets: [vaultSecret, trustedProxySecret] }, async (req, res) => {
  applySecurityHeaders(res);
  try {
    assertHost(req);
    const uid = await verifyUser(req);
    const chatId = crypto.randomUUID();
    const wrappedKey = String(req.body?.wrappedKey || "");
    const proofHash = presentedProofHash(req.body?.keyProof);
    if (!wrappedKey.startsWith("enc:v1:") || !proofHash) {
      throw Object.assign(new Error("Wrapped group key and key proof required"), { status: 400 });
    }
    await db.collection("chatKeyVerifiers").doc(chatId).set({ proofHash });
    await db.collection("groupChats").doc(chatId).set({
      creatorId: uid,
      memberIds: [uid],
      pendingMemberIds: [],
      wrappedKeys: { [uid]: wrappedKey },
      createdAt: FieldValue.serverTimestamp(),
    });
    await durablePut(`group-chat:${chatId}`, `group-${chatId}`, { creatorId: uid, memberIds: [uid] });
    res.status(200).json({ chatId });
  } catch (err) {
    sendError(res, err);
  }
});

export const requestGroupMember = onRequest({ cors: false, secrets: [trustedProxySecret] }, async (req, res) => {
  applySecurityHeaders(res);
  try {
    assertHost(req);
    const uid = await verifyUser(req);
    const chatId = String(req.body?.chatId || "");
    const memberId = String(req.body?.memberId || "");
    const ref = db.collection("groupChats").doc(chatId);
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const data = snap.data();
      if (!data || !data.memberIds?.includes(uid)) throw Object.assign(new Error("Members only"), { status: 403 });
      const pending = new Set<string>(data.pendingMemberIds || []);
      pending.add(memberId);
      tx.update(ref, { pendingMemberIds: Array.from(pending) });
    });
    res.status(200).json({ ok: true });
  } catch (err) {
    sendError(res, err);
  }
});

export const decideGroupMember = onRequest({ cors: false, secrets: [vaultSecret, trustedProxySecret] }, async (req, res) => {
  applySecurityHeaders(res);
  try {
    assertHost(req);
    const uid = await verifyUser(req);
    const chatId = String(req.body?.chatId || "");
    const memberId = String(req.body?.memberId || "");
    const approve = req.body?.approve === true;
    const wrappedKey = String(req.body?.wrappedKey || "");
    const ref = db.collection("groupChats").doc(chatId);
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const data = snap.data();
      if (!data || data.creatorId !== uid) throw Object.assign(new Error("Only the chat creator can change members"), { status: 403 });
      const members = new Set<string>(data.memberIds || []);
      const pending = new Set<string>(data.pendingMemberIds || []);
      pending.delete(memberId);
      const wrappedKeys = { ...(data.wrappedKeys || {}) };
      if (approve) {
        if (!wrappedKey.startsWith("enc:v1:")) throw Object.assign(new Error("Wrapped key required"), { status: 400 });
        members.add(memberId);
        wrappedKeys[memberId] = wrappedKey;
      } else {
        members.delete(memberId);
        delete wrappedKeys[memberId];
      }
      tx.update(ref, { memberIds: Array.from(members), pendingMemberIds: Array.from(pending), wrappedKeys });
    });
    await durablePut(`group-members:${chatId}`, `group-members-${chatId}`, { chatId, changedBy: uid });
    res.status(200).json({ ok: true });
  } catch (err) {
    sendError(res, err);
  }
});

export const groupKeyAttempt = onRequest({ cors: false, secrets: [vaultSecret, trustedProxySecret] }, async (req, res) => {
  applySecurityHeaders(res);
  try {
    assertHost(req);
    const uid = await verifyUser(req);
    const chatId = String(req.body?.chatId || "");
    const presented = presentedProofHash(req.body?.keyProof);
    const ref = db.collection("chatKeyAttempts").doc(sha512(`${chatId}:${uid}`));
    const verifierRef = db.collection("chatKeyVerifiers").doc(chatId);
    const chatRef = db.collection("groupChats").doc(chatId);
    const result = await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const chat = await tx.get(chatRef);
      const verifier = await tx.get(verifierRef);
      const members = (chat.data()?.memberIds as string[]) || [];
      if (!members.includes(uid)) throw Object.assign(new Error("Members only"), { status: 403 });
      const now = Date.now();
      const lockedUntil = (snap.data()?.lockedUntil as number) || 0;
      if (lockedUntil > now) {
        throw Object.assign(new Error("Key entry is delayed"), { status: 429, retryAt: lockedUntil });
      }
      if (snap.data()?.blocked === true) {
        throw Object.assign(new Error("Key access is blocked"), { status: 403 });
      }
      const matched = proofsMatch(String(verifier.data()?.proofHash || ""), presented);
      if (matched) {
        tx.set(ref, { phase: "initial", failures: 0, lockedUntil: 0, blocked: false });
        return { ok: true };
      }
      const phase = (snap.data()?.phase as string) || "initial";
      const failures = ((snap.data()?.failures as number) || 0) + 1;
      if (phase === "initial" && failures >= 3) {
        tx.set(ref, { phase: "after-delay", failures: 0, lockedUntil: now + KEY_DELAY_MS, blocked: false });
        return { delayed: true };
      }
      if (phase === "after-delay" && failures >= 2) {
        const wrappedKeys = { ...(chat.data()?.wrappedKeys || {}) };
        delete wrappedKeys[uid];
        const members = new Set<string>(chat.data()?.memberIds || []);
        members.delete(uid);
        tx.set(ref, { phase: "blocked", failures, lockedUntil: 0, blocked: true });
        if (chat.exists) tx.update(chatRef, { wrappedKeys, memberIds: Array.from(members) });
        return { blocked: true };
      }
      tx.set(ref, { phase, failures, lockedUntil: 0, blocked: false });
      return { failures };
    });
    if ((result as { blocked?: boolean }).blocked) {
      await durablePut(`key-block:${chatId}:${uid}`, `key-block-${chatId}-${uid}`, { chatId, uid, blocked: true });
    }
    res.status(200).json(result);
  } catch (err) {
    sendError(res, err);
  }
});
