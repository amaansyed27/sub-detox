# SubDetox Self Testing Guide (Firebase Path)

This guide validates the current Firebase implementation (Auth + Firestore + Functions + Flutter).

## 1. Prerequisites

- Node.js and npm
- Firebase CLI access (`npx firebase-tools`)
- Flutter SDK
- Android emulator, iOS simulator, or desktop target

## 2. One-Time Setup

```powershell
cd C:\Users\Amaan\Downloads\sub-detox
npm --prefix functions install
cd C:\Users\Amaan\Downloads\sub-detox\subdetox_flutter
flutter pub get
```

## 3. Start Local Stack

Open two terminals.

### Terminal A: Firebase emulators

```powershell
cd C:\Users\Amaan\Downloads\sub-detox
npx -y firebase-tools@latest emulators:start --only auth,firestore,functions --project subdetox-20260412-8514
```

Expected:
- Functions API served on `http://127.0.0.1:5001/subdetox-20260412-8514/asia-south1/api`
- Emulator UI on `http://127.0.0.1:4000`

### Terminal B: Flutter app

```powershell
cd C:\Users\Amaan\Downloads\sub-detox\subdetox_flutter
flutter run --dart-define=FIREBASE_USE_EMULATOR=true
```

## 4. API Smoke Tests (Authenticated)

The API now requires Firebase ID tokens for most routes.

Quick health check:

```powershell
Invoke-RestMethod -Uri "http://127.0.0.1:5001/subdetox-20260412-8514/asia-south1/api/health" -Method Get
```

Expected:
- `{ status: "ok", service: "subdetox-firebase-api" }`

## 5. Frontend Flow Validation

### Scenario A: Auth gate

1. Launch app.
2. Confirm login screen appears first.
3. Test Email mode:
   1. Create account
   2. Sign in

Pass criteria:
- Auth state changes route to dashboard
- No crash in transition

### Scenario B: Analyze with authenticated call

1. Tap Start AI Analysis.
2. Confirm analyzing state appears.
3. Wait for results.

Pass criteria:
- Results payload loads
- Hero leakage card animates
- Threat sections render

### Scenario C: Revoke persistence path

1. Tap Revoke Mandate on one card.
2. Complete modal sequence.
3. Trigger re-scan.

Pass criteria:
- Revoke API call succeeds
- Card is marked resolved after reload via backend-resolved state

### Scenario D: Sign out security

1. Tap logout icon.
2. Confirm app returns to login screen.
3. Try navigating back.

Pass criteria:
- Protected dashboard is not accessible without auth

## 6. Firestore Rule Checks

Use Emulator UI (`http://127.0.0.1:4000`) to verify:

- User documents are scoped by UID
- Analysis runs are created per user
- Revoke actions and audit events are persisted

## 7. Regression Checklist

- [ ] Flutter analyzer clean (`flutter analyze`)
- [ ] Functions load in emulator without syntax failures
- [ ] Authenticated analyze call works
- [ ] Unauthorized calls return 401
- [ ] Revoke action persists and is reflected on next analysis

## 8. Helpful Commands

```powershell
# Validate Flutter
cd C:\Users\Amaan\Downloads\sub-detox\subdetox_flutter
flutter analyze

# Validate Function syntax
node --check C:\Users\Amaan\Downloads\sub-detox\functions\src\index.js

# Deploy auth/rules/indexes (already executed once)
cd C:\Users\Amaan\Downloads\sub-detox
npx -y firebase-tools@latest deploy --only auth,firestore:rules,firestore:indexes --project subdetox-20260412-8514
```
