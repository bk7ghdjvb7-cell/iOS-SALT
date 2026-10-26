# SALT security audit

This pass treats the app as a public service. It covers the iOS targets, the Android module, Cloud Functions, and Firestore rules.

## What is enforced

- Login attempts are limited to 5 per 15 minutes per email and network address. A client cannot skip the counter by claiming success. After five unverified attempts the address hash is blocked. The raw password is rejected if it is posted to the login endpoint. The verifier is scrypt (N=16384, r=8, p=1, 64 bytes) and the server stores only SHA-512 of that output.
- Membership and community public posts are limited to 3 per hour. Clients cannot create those Firestore documents. `publishPublicPost` is the write path.
- Membership notes, community posts, login records, blocked addresses, and consent images are stored as AES-256-GCM ciphertext in `durableVault` and copied to `durableVaultMirror`. The key is the `DURABLE_VAULT_KEY` secret, stretched with SHA-512. A wipe of one collection still leaves the other. A wipe of the whole Firebase project removes both. Keep an offline copy of the ciphertext mirror if the records must survive that.
- Group chats did not exist as a product feature. Direct chats did. Both now require a passphrase of at least 12 characters. The server stores a wrapped key (`enc:v1:` AES-256-GCM) and a SHA-512 of an HMAC-SHA-512 proof. It does not store the passphrase or the message key. App admins can read ciphertext and still cannot read a message without the chat creator's key.
- Key attempts are counted per person. Three failures start a 15 minute delay. Two failures after that delete that person's wrapped key, remove them from the chat, and block further attempts. The server checks the proof. It does not trust an "unlocked" flag.
- Members may request an add. Only the chat creator can approve or remove someone.
- Photos are face-scanned before they are attached. Videos are refused. The unblurred image is not written into the post. If the scan fails, the upload is discarded. An optional consent action seals a separate copy for an admin. That copy is ciphertext, not a log line.
- Public text is sent to `MODERATION_WEBHOOK` when that setting exists. An illegal verdict, or an error from a configured classifier, blocks the post, deletes it, and writes a report containing a SHA-512 digest rather than the text. If the webhook is unset, the function does not pretend the text was scanned.
- `X-Forwarded-For` and similar proxy headers are ignored unless `x-salt-proxy-secret` matches `TRUSTED_PROXY_SECRET`. The Android app trusts only the system certificate store and refuses cleartext, so a user-installed intercepting proxy certificate is not accepted.
- Firestore clients cannot grant themselves board access, change a membership status, write payment status, read another person's push token, or write plaintext chat. Push previews say that a message arrived and do not include the message. The welcome email escapes HTML. Stripe amounts come from the server, and the webhook error page does not echo the verifier's message.

## Content security policy

Use this policy on every web response. It is set on the Cloud Functions responses and in `firebase.json` hosting headers.

```
default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' blob: data: https://images.unsplash.com; font-src 'self'; connect-src 'self'; form-action 'self'; base-uri 'self'; object-src 'none'; frame-ancestors 'self'
```

`'unsafe-inline'` is part of the requested policy. It weakens script and style isolation. A stricter follow-up would remove it and use nonces.

## Encryption choices

AES-256-GCM and SHA-512 are the symmetric tools that remain appropriate when Grover's algorithm is considered. Passphrases are stretched with scrypt, which is memory-hard. RSA and elliptic-curve key exchange are not used for notes or chats. Nothing here is a magic "quantum proof" password hash. A short passphrase can still be guessed offline by someone who steals the wrapped key, because the server never sees the passphrase and therefore cannot stop an offline guess. Use a long key.

## Secrets that must be set outside the repo

`STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `SMTP_USER`, `SMTP_PASS`, `DURABLE_VAULT_KEY`, `TRUSTED_PROXY_SECRET`. Optional: `MODERATION_WEBHOOK`, `SALT_ALLOWED_HOSTS`.

The iOS target still runs its local mock sign-in until Firebase Auth is configured. The mock path enforces the 12 character minimum, the scrypt work factor, and the 5 per 15 minute device limit. It does not prove a live identity.
