# SubDetox Self Testing Guide (FastAPI + Firebase)

This guide validates the revamp architecture:

- Firebase for auth and persistence
- FastAPI for full AA-style emulator APIs

## 1. Prerequisites

- Python virtual environment at `C:\Users\Amaan\Downloads\sub-detox\.venv`
- Firebase CLI access (`npx -y firebase-tools@latest`)
- Flutter SDK
- Node.js (for legacy Functions syntax check and tooling)

## 2. One-Time Setup

```powershell
cd C:\Users\Amaan\Downloads\sub-detox
c:/Users/Amaan/Downloads/sub-detox/.venv/Scripts/python.exe -m pip install -r requirements.txt
cd C:\Users\Amaan\Downloads\sub-detox\subdetox_flutter
flutter pub get
```

## 3. Start Local Stack

Open three terminals.

### Terminal A: Firebase emulators (auth + firestore)

```powershell
cd C:\Users\Amaan\Downloads\sub-detox
npx -y firebase-tools@latest emulators:start --only auth,firestore --project subdetox-20260412-8514
```

### Terminal B: FastAPI backend

```powershell
cd C:\Users\Amaan\Downloads\sub-detox
$env:USE_FIRESTORE_EMULATOR='true'
$env:FIRESTORE_EMULATOR_HOST='127.0.0.1:8081'
c:/Users/Amaan/Downloads/sub-detox/.venv/Scripts/python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

### Terminal C: Flutter app

```powershell
cd C:\Users\Amaan\Downloads\sub-detox\subdetox_flutter
flutter run --dart-define=BACKEND_MODE=fastapi-local --dart-define=FASTAPI_LOCAL_PORT=8000 --dart-define=FIREBASE_USE_EMULATOR=true
```

## 4. Automated Test Suite

Run all automated checks:

```powershell
powershell -ExecutionPolicy Bypass -File C:\Users\Amaan\Downloads\sub-detox\scripts\run_automated_tests.ps1
```

Coverage in this suite:

- v2 consent lifecycle (create, approve simulation, data session, fetch, revoke)
- app-compat analyze/latest/revoke flow
- FIP discovery and account-availability APIs
- Flutter static analysis
- legacy Functions syntax check

## 5. Manual API Smoke Test

With FastAPI running locally, run:

```powershell
powershell -ExecutionPolicy Bypass -File C:\Users\Amaan\Downloads\sub-detox\scripts\manual_api_smoke.ps1
```

Expected summary fields:

- health = ok
- consentStatus = PENDING
- approvedStatus = ACTIVE
- fetchStatus in PARTIAL/COMPLETED/FAILED
- detectedCount > 0
- revokeStatus = resolved

## 6. Frontend Manual Validation

### Scenario A: Auth gate

1. Launch app.
2. Confirm login screen appears first.
3. Create account and sign in.

Pass criteria:

- Auth state routes to dashboard.

### Scenario B: Analyze and grouping

1. Tap Start AI Analysis.
2. Confirm results in risk sections.

Pass criteria:

- Detected subscriptions render with confidence and reasoning.

### Scenario C: Revoke persistence

1. Revoke one merchant.
2. Trigger re-scan.
3. Restart app and sign in again.

Pass criteria:

- Merchant remains resolved across refresh and login.

### Scenario D: Sign out guard

1. Tap logout.
2. Verify protected dashboard cannot be accessed.

## 7. Firestore Data Checks

Use Emulator UI (`http://127.0.0.1:4000`) and verify:

- `users` updated per UID
- `consents` and `fi_sessions` created during v2 flows
- `analysis_runs` and `detected_subscriptions` created during analyze
- `revoke_actions` and `audit_events` recorded

## 8. Regression Checklist

- [ ] `pytest` passes
- [ ] Flutter analyzer passes
- [ ] FastAPI manual smoke script passes
- [ ] v2 consent/session endpoints behave as expected
- [ ] app-compat endpoints continue to work for Flutter
- [ ] Firestore persistence reflects lifecycle operations

## 9. Cloud Deploy Verification

After cloud deploy, repeat:

1. `GET /health`
2. Authenticated `POST /api/analyze-transactions`
3. Authenticated `GET /api/analysis/latest`
4. Authenticated `POST /api/revoke-mandate`
5. Consent + session flow via `/v2/*`

Deployment instructions are in [cloud-run-deploy-guide.md](cloud-run-deploy-guide.md).
