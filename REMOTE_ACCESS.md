# Running the demo for phones on other networks

Goal: someone installs the APK anywhere and it reaches your backend — no shared
Wi-Fi, no router configuration.

---

## How the app finds the backend

Resolution order, first match wins:

1. **Runtime setting** — the sign-in screen shows a **Connected / Set server**
   chip. Tap it, paste an address, and it is saved on the device.
2. **Build-time value** — `--dart-define=FINIX_BASE_URL=<url>`, baked into the
   APK so a shared build needs no setup.
3. **Platform default** — `10.0.2.2:8080` on Android (the emulator's alias for
   the host machine), `localhost:8080` elsewhere.

Build an APK that just works for other people:

```bash
flutter build apk --release --dart-define=FINIX_BASE_URL=https://your-public-host
```

> **Prefer https.** Android blocks cleartext HTTP by default; a plain-http host
> must be listed in `android/app/src/main/res/xml/network_security_config.xml`
> and only the local dev addresses are listed there. Any https URL works with no
> exemption.

---

## Publishing the backend

The backend binds `APP_ADDR` (default `0.0.0.0:8080`). For anything public,
bind **loopback only** and let a tunnel reach in:

```
APP_ADDR=127.0.0.1:8080
```

Nothing is then listening on the LAN or the internet — there is no open port to
scan. This is what `backend/scripts/demo-remote.ps1` does.

### Option A — Cloudflare Tunnel (script provided)

```powershell
cd D:\FINIX_PRODUCTION\backend
.\scripts\demo-remote.ps1
```

Generates fresh secrets, starts the backend on loopback, opens the tunnel and
prints an `https://<random>.trycloudflare.com` URL.

**Requires outbound TCP/UDP 7844.** Many campus, office and mobile-hotspot
networks block it — the tunnel then fails with
`dial tcp …:7844: i/o timeout` and the URL returns a Cloudflare 530 page.
Check first:

```powershell
Test-NetConnection 198.41.192.77 -Port 7844 -InformationLevel Quiet
```

`False` means Cloudflare quick tunnels cannot work on that network; use B or C.

### Option B — a tunnel that only needs 443/22

Useful when 7844 is blocked. All of these terminate TLS for you, so the app gets
an https URL:

| Tool | Command | Port | Notes |
|---|---|---|---|
| ngrok | `ngrok http 8080` | 443 | |
| localhost.run | `ssh -R 80:127.0.0.1:8080 nokey@localhost.run` | 22 | connected but issued no URL |
| localtunnel | `npx localtunnel --port 8080` | 443 | **verified working here** |
| VS Code dev tunnels | `devtunnel host -p 8080 --allow-anonymous` | 443 | |

Point the app at whatever hostname it prints.

**Pin the hostname if you are shipping an APK.** A random tunnel name changes on
every restart, which bricks a build that has the URL compiled in. localtunnel
takes a fixed subdomain:

```bash
npx localtunnel --port 8080 --subdomain finix-psb-demo   # https://finix-psb-demo.loca.lt
```

Restarting with the same `--subdomain` restores the same URL, so an installed
APK keeps working. (The name is first-come, first-served across all localtunnel
users — if it is taken you get a random one instead, so check the printed URL.)

On this machine only **localtunnel** produced a working URL: Cloudflare needs
the blocked 7844, localhost.run accepted the SSH connection but never issued a
hostname, and serveo.net connected silently without responding.

**Latency matters.** A first request through a tunnel measured ~9 seconds
(TLS + cold relay). `ApiService.connectionTimeout` is therefore 15s — the
original 2s health-check timeout marked a perfectly healthy remote backend as
offline, which silently switched every screen to mock data.

### Option C — deploy it (best for a demo people keep using)

A tunnel dies when your laptop sleeps and a quick-tunnel hostname changes every
run. For anything beyond a live demo, deploy the backend and use a fixed https
URL. It is a single static Go binary plus the `models/` directory; any container
host works. Set the same environment variables the script sets.

---

## Before exposing it publicly

The demo API is fully functional — real transfers, real balances on seeded
accounts. Once it is on the internet:

- **Rotate the secrets.** `FINIX_JWT_SECRET`, `FINIX_DATA_ENCRYPTION_KEY`,
  `FINIX_AADHAAR_HASH_KEY`, `FINIX_INTERNAL_TOKEN`, `FINIX_ADMIN_TOKEN`. The
  development values in the runbook are published in this repo; anyone could
  mint a valid session token with them. `demo-remote.ps1` generates fresh
  random values on every run.
- **The demo logins are public knowledge.** cKYC `2000000001`–`2000000010`,
  PIN `123456`. Anyone with the URL can sign in as those users. That is the
  point of a demo — just do not put anything real behind it.
- **Keep CORS tight.** `CORS_ALLOWED_ORIGINS` accepts exact origins and a
  `host:*` port wildcard (`http://localhost:*`). Native Android sends no
  `Origin` header and is unaffected, so there is no reason to widen it to `*`.
- **Rate limits are on** — 240 req/min globally, 20/min on auth, 10/min on
  registration.
- **Turn the strict gates on for anything non-demo:**
  `FINIX_REQUIRE_BIOMETRIC_CHALLENGE=true` (requires a signed biometric
  challenge and an OTP for unfreeze), `FINIX_REQUIRE_PQC=true`,
  `FINIX_PIN_ENFORCE=true`.
- **Take it down when finished.** Stop the tunnel; the URL dies with it.

---

## Verifying it works remotely

From another machine or a phone on mobile data:

```bash
curl https://your-public-host/healthz
```

Then run the app's own client against that URL — this is the same code path the
Android build uses:

```bash
flutter test test/live_backend_test.dart --dart-define=FINIX_BASE_URL=https://your-public-host
```

It signs in with cKYC, loads the dashboard, makes a payment through the risk
engine and round-trips an account freeze. All green means the phone build will
work too.
