# SubDetox End User Guide (Use + Full Feature Testing)

This guide is written for an end user who wants to run the app and verify every major feature.

## 1. What You Will Validate

By the end of this guide, you will have tested:

- Account creation and login
- Analysis generation from transaction data
- Risk grouping and subscription reasoning
- Mandate revoke flow
- Persisted resolved state after re-scan
- Session persistence after logout/login
- AA-style API lifecycle simulation

## 2. Choose Your Usage Mode

### Mode A: Live Cloud Backend (recommended for normal usage)

Run the app against Cloud Run:

```powershell
cd C:\Users\Amaan\Downloads\sub-detox\subdetox_flutter
flutter run --dart-define=BACKEND_MODE=fastapi-cloud --dart-define=CLOUD_RUN_URL=https://subdetox-api-wiz4yigmpq-el.a.run.app --dart-define=FIREBASE_USE_EMULATOR=false
```

### Mode B: Local Full Stack (recommended for deep testing)

Terminal 1:

```powershell
cd C:\Users\Amaan\Downloads\sub-detox
npx -y firebase-tools@latest emulators:start --only auth,firestore --project subdetox-20260412-8514
```

Terminal 2:

```powershell
cd C:\Users\Amaan\Downloads\sub-detox
$env:USE_FIRESTORE_EMULATOR='true'
$env:FIRESTORE_EMULATOR_HOST='127.0.0.1:8081'
c:/Users/Amaan/Downloads/sub-detox/.venv/Scripts/python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

Terminal 3:

```powershell
cd C:\Users\Amaan\Downloads\sub-detox\subdetox_flutter
flutter run --dart-define=BACKEND_MODE=fastapi-local --dart-define=FASTAPI_LOCAL_PORT=8000 --dart-define=FIREBASE_USE_EMULATOR=true
```

If you are using a physical phone, also pass `--dart-define=LOCAL_API_HOST=<your_pc_lan_ip>`.

## 3. End-to-End Feature Testing Checklist

### Test 1: Sign Up and Login

1. Open the app.
2. Create a new account with email and password.
3. Log in.

Pass criteria:

- App moves from login screen to dashboard.

### Test 2: Start Analysis

1. Tap Start AI Analysis.
2. Wait for analysis to complete.

Pass criteria:

- Dashboard shows detected subscriptions.
- You can see threat/risk grouping and reasoning.

### Test 3: Validate Risk Sections

1. Review all subscription cards.
2. Confirm confidence score, merchant, and estimated monthly amount are visible.

Pass criteria:

- At least one detected item appears.
- Grouping is visible and understandable.

### Test 4: Revoke a Subscription

1. Select one high-priority subscription.
2. Tap Revoke Mandate.
3. Complete the flow.

Pass criteria:

- Revoke completes successfully.
- Subscription is marked resolved.

### Test 5: Re-Scan Behavior

1. Tap Re-scan.
2. Wait for refresh.

Pass criteria:

- Previously revoked merchant remains resolved.
- Remaining active subscriptions still show correctly.

### Test 6: Logout and Resume

1. Log out.
2. Log in again with the same user.

Pass criteria:

- Latest analysis loads automatically.
- Resolved state is preserved.

### Test 7: API Lifecycle Coverage (AA emulator)

Run:

```powershell
powershell -ExecutionPolicy Bypass -File C:\Users\Amaan\Downloads\sub-detox\scripts\manual_api_smoke.ps1
```

Pass criteria:

- `health` is `ok`
- `consentStatus` is `PENDING`
- `approvedStatus` is `ACTIVE`
- `fetchStatus` is `PARTIAL` or `COMPLETED`
- `revokeStatus` is `resolved`

## 4. Quick Troubleshooting

If app cannot connect to API:

- Check `BACKEND_MODE` value in the run command.
- For local mode, confirm FastAPI is running on `127.0.0.1:8000`.
- For device testing, set `LOCAL_API_HOST`.

If login fails in local mode:

- Confirm Firebase emulators are running.
- Try creating a fresh user.

If analysis does not appear:

- Tap Re-scan.
- Check backend logs for request errors.

## 5. Optional Full Regression Command

For a one-command automated health pass:

```powershell
powershell -ExecutionPolicy Bypass -File C:\Users\Amaan\Downloads\sub-detox\scripts\run_automated_tests.ps1
```
