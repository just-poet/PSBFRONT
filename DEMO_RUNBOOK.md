# FINIX demo runbook — app on the demo banking API

End-to-end demo: real flows, real risk engine, real device binding, backed by
the demo API with seeded users. Nothing in the payment path is faked.

---

## 1. Start the backend

```bash
cd D:/FINIX_PRODUCTION/backend

# Mandatory or the server refuses to boot
export FINIX_JWT_SECRET="local-dev-secret-1234567890"
export FINIX_DATA_ENCRYPTION_KEY="0000000000000000000000000000000000000000000000000000000000000001"  # 64 hex chars
export FINIX_AADHAAR_HASH_KEY="local-demo-key"
export GROQ_API_KEY="disabled"          # sentinel: disables the live LLM
export FINIX_INTERNAL_TOKEN="local-internal-token"

# Demo pacing: a blocked transaction otherwise locks payments for 4h
export FINIX_COOLOFF_BASE_MINUTES=1

go run ./cmd/server
```

Confirm: `curl http://localhost:8080/healthz` → `{"status":"ok", ...}`
and the log line `[SEED] Seeded 10 demo users with full portfolios`.

## 2. Point the app at the backend

| Target | Base URL | Notes |
|---|---|---|
| Android emulator | `http://10.0.2.2:8080` | **default** — `localhost` on an emulator is the phone itself |
| Physical device | `http://<your-LAN-IP>:8080` | also add that IP to `android/app/src/main/res/xml/network_security_config.xml` |
| Chrome / desktop | `http://localhost:8080` | default |

Override at runtime with `ApiService.instance.setBaseUrl(...)`.

## 3. Run the app

```bash
cd "D:/PSB forged/PSBFRONT"
flutter pub get          # required: new camera/picker/permission packages
flutter run              # emulator or device
```

> `flutter run -d chrome` works for UI, but the **camera QR scanner is
> mobile-only**. Use an emulator/device for the scan demo.

Connectivity check: `ApiService.isConnected` drives the dashboard badge. If it
shows offline, every screen silently renders built-in mock data — so verify the
badge before demoing.

---

## 4. Demo script

### 4.1 Sign in or onboard
The app opens on the **cKYC login screen**. For a new identity, tap
"Complete eKYC": register → eKYC verify → biometric → PIN → login.
Backed by `/v1/auth/register`, `/v1/auth/ekyc/verify`,
`/v1/auth/biometric/register`, `/v1/auth/login/pin/set`, `/v1/auth/login/pin`.
The returned JWT is stored and used for every later call.

Or sign in on the **cKYC login screen** (the app's entry point) as one of the
10 seeded users. Sign-in uses the **10-digit Central KYC number + 6-digit PIN**
— no phone number anywhere:

| cKYC | Name | Net worth |
|---|---|---|
| `2000000001` | Jiyad | +₹85,00,000 |
| `2000000002` | Venkat | +₹45,00,000 |
| `2000000003` | RD Shubham | +₹1,20,00,000 |
| `2000000004` | Arjun Reddy | +₹15,00,000 |
| `2000000005` | Priya Sharma | +₹55,00,000 |
| `2000000006` | Karthik Iyer | +₹28,00,000 |
| `2000000007` | Sneha Patel | +₹72,00,000 |
| `2000000008` | Ravi Kumar | +₹8,00,000 |
| `2000000009` | Ananya Gupta | +₹95,00,000 |
| `2000000010` | Mohammed Ali | +₹38,00,000 |

PIN for all ten is `123456`. The backend also prints this table at startup, and
the login screen has a **Fill** button for the first account. Accounts created
through eKYC get their own cKYC allocated from `3000000001` upward.

### 4.2 Dashboard — live data
Net worth, health score, accounts and transactions all come from the API.
Seeded user Jiyad: net worth **+₹85,00,000**, SBI account, 6 investments,
2 insurance policies, 1 home loan.

### 4.3 Scan QR — camera, gallery, real payment
1. Open **Scan QR**. Android prompts for camera on first use.
   - Deny once → in-app explainer + "Allow camera" retry.
   - Deny permanently → "Open settings" deep link.
   - Gallery stays available either way.
2. Point at any **UPI QR** (`upi://pay?pa=...&pn=...&am=...`). Generate one at
   any QR site with, e.g.
   `upi://pay?pa=starbucks@okhdfcbank&pn=Starbucks%20Coffee&am=250&cu=INR`
3. Or tap the gallery icon and pick a saved QR screenshot — decoded with the
   same engine.
4. Amount fixed by the QR is read-only; open-amount QRs let the user type it.
5. PIN → the payment goes to `POST /v1/transactions/initiate`.

Non-UPI QR codes are ignored by design, so a random QR cannot start a payment.

### 4.4 Fraud block (the money shot)
Pay a recipient containing `unknown`, `urgent` or `lottery` (e.g.
`unknown_urgent_99@upi`) for a large amount. The risk engine returns
**riskLevel high, score ~93, status blocked, stepUpRequired true** and the app
surfaces the block instead of a success screen.

Immediately after, further payments return **HTTP 423 cooling-off** — the
on-ledger protection. With `FINIX_COOLOFF_BASE_MINUTES=1` it clears in a minute
so the demo can continue; production uses the 240-minute spec default.

### 4.5 Security controls
Security screen → **Freeze** (`/v1/security/emergency-freeze`) → the state is
read back from `/v1/security/health` (`is_frozen: true`) → **Unfreeze**.

### 4.6 Other live screens
Goals (create / contribute / pause / resume), Portfolio (investments,
insurance, loans), Tax centre (dashboard + old-vs-new regime), Chatbot
(`/v1/chatbot/query`).

---

## 5. Android data sources and permissions

| Data source | Permission | Used by | Status |
|---|---|---|---|
| Backend API | `INTERNET`, `ACCESS_NETWORK_STATE` | every screen | **added** — was missing from the release manifest, so release builds could never reach the API |
| Cleartext HTTP to dev host | `network_security_config.xml` | demo API over `http://` | **added** — Android 9+ blocks cleartext by default |
| Camera | `CAMERA` (runtime) | Scan QR live scanning | **added** |
| Gallery image | `READ_MEDIA_IMAGES` (API 33+), `READ_EXTERNAL_STORAGE` (≤32) | Scan QR from a saved image | **added** — Android 13+ photo picker needs no grant |
| Device fingerprint | none (ANDROID_ID) | session/device binding | **implemented natively** — previously a hardcoded constant shared by every install |
| Biometric | `USE_BIOMETRIC`, `USE_FINGERPRINT` | step-up auth / key signing | **implemented natively** — Keystore/StrongBox P-256 key gated by BiometricPrompt |
| Contacts | none | Pay Anyone uses an in-app list, not device contacts | n/a |
| Location / SMS | none | not read by the app | n/a |

## 6. Known simulated pieces

Everything else in the payment path is real; these are not:

- **Biometric on a bare emulator.** The native channel is now real: keys are
  generated in the Android Keystore (StrongBox when present), require a
  biometric to use, and are invalidated if biometrics are re-enrolled. If the
  device/emulator has **no biometric enrolled**, registration returns
  `NO_BIOMETRIC` and the Dart layer falls back to a simulated key —
  `BiometricKeyPair.hardwareBacked` reports which happened. Enroll a
  fingerprint in the emulator (Settings → Security) to exercise the real path.
- **Step-up OTP** is hardcoded `123456` in the client override call.
- **Add proof / document upload** screens are still UI-only.
- **finix-RAG** is not required: the chatbot is answered in-process unless
  `AI_PROVIDER=remote` is set and the Python service is running.

## 7. Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Everything shows demo numbers, badge offline | app can't reach API | emulator must use `10.0.2.2`, not `localhost`; check the backend is up |
| `CLEARTEXT_NOT_PERMITTED` in logcat | HTTP blocked | host must be listed in `network_security_config.xml` |
| Login 401 `invalid credentials` | wrong cKYC or PIN | use a number from the table, PIN `123456` |
| Login 401 `ckyc number must be exactly 10 digits` | short/long input | cKYC is exactly 10 digits |
| All payments 423 | cooling-off from an earlier blocked txn | wait it out, or set `FINIX_COOLOFF_BASE_MINUTES=1` and restart |
| Payments 400 over ₹10,00,000 | per-transaction ceiling | expected; the app blocks it client-side too |
| Camera screen stuck black | permission granted mid-session | leave and re-enter the screen (it restarts on resume) |
