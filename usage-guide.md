# SubDetox Usage Guide (Hackathon Demo)

This guide is optimized for the current architecture:

- Firebase: auth + persistence
- FastAPI: full AA-style emulator API

## 1. Goal

Show these outcomes in one flow:

- Authenticated onboarding
- AI recurring-charge detection
- Real backend revoke behavior
- Persisted resume behavior on next login
- AA-style consent and data-session emulator capability

## 2. Demo Environment Setup

Open three terminals.

### Terminal A: Firebase emulators

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

## 3. First Run (New User)

1. Create a user with Email and Password.
2. Confirm app transitions from login to dashboard.
3. First-time user should see Start AI Analysis.

Suggested narration:

"Firebase secures identity and stores state. FastAPI emulates AA lifecycle and analysis APIs."

## 4. Core Product Walkthrough

### Step A: Analyze

1. Tap Start AI Analysis.
2. Wait for results.
3. Show risk-tiered sections and confidence/reasoning.

### Step B: Revoke

1. Revoke one high-risk merchant.
2. Wait for modal sequence completion.
3. Confirm card resolves.

Suggested narration:

"Revocation is server-backed and persisted, not a client-only flag."

### Step C: Persistence

1. Tap Re-scan.
2. Confirm revoked merchant remains resolved.
3. Sign out and sign in again.
4. Confirm latest analysis auto-resumes.

## 5. Optional API Demonstration (AA Emulator)

Run this in a fourth terminal to show non-UI API realism:

```powershell
powershell -ExecutionPolicy Bypass -File C:\Users\Amaan\Downloads\sub-detox\scripts\manual_api_smoke.ps1
```

This exercises consent creation, simulated approval, data session creation/fetch, and app-compat analyze/revoke.

## 6. Suggested 7-Minute Hackathon Script

1. 0:00 to 1:00: Problem statement and architecture split (Firebase + FastAPI)
2. 1:00 to 2:30: Login gate and Start AI Analysis
3. 2:30 to 4:00: Results explanation and leakage prioritization
4. 4:00 to 5:00: Revoke and immediate resolved state
5. 5:00 to 6:00: Re-scan and login-resume persistence
6. 6:00 to 7:00: Optional API smoke output for AA-style lifecycle proof

## 7. Quick Recovery During Live Demo

If app cannot reach backend:

- Verify FastAPI terminal is running at `127.0.0.1:8000`
- Verify Flutter started with `BACKEND_MODE=fastapi-local`
- For physical device, pass `LOCAL_API_HOST=<LAN_IP>`

If auth fails:

- Confirm auth emulator is running (`:9099`)
- Create a fresh demo user

If data looks stale:

- Re-run analysis
- Check Firestore emulator UI for fresh writes

## 8. Presenter Checklist

- Firebase emulator visible
- FastAPI terminal visible
- Flutter app running and warm
- Backup demo account available
- [self-testing-guide.md](self-testing-guide.md) open for QA follow-ups
- [cloud-run-deploy-guide.md](cloud-run-deploy-guide.md) ready for deployment questions
