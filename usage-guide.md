# SubDetox Usage Guide (Hackathon Demo)

This guide is a practical runbook to use SubDetox live, test the core flows, and present a clean hackathon demo.

## 1. Goal

Use this guide to show:

- Authenticated onboarding
- AI-style recurring subscription detection
- Risk prioritization on dashboard
- Real revoke execution flow with persistence
- Latest-analysis resume on next login

## 2. Demo Environment Setup

### Terminal A: Firebase emulators

```powershell
cd C:\Users\Amaan\Downloads\sub-detox
npx -y firebase-tools@latest emulators:start --only auth,firestore,functions --project subdetox-20260412-8514
```

Wait until you see:

- Functions endpoint at `http://127.0.0.1:5001/subdetox-20260412-8514/asia-south1/api`
- Emulator UI at `http://127.0.0.1:4000`

### Terminal B: Flutter app

```powershell
cd C:\Users\Amaan\Downloads\sub-detox\subdetox_flutter
flutter run --dart-define=FIREBASE_USE_EMULATOR=true
```

## 3. First Run (New User)

1. Open app and create a user with Email and Password.
2. Confirm app moves from login to dashboard.
3. For a brand new account, dashboard should show Start AI Analysis first.

What to say during demo:

"The app is fully auth-gated. Each user gets isolated analysis and revoke history in Firestore."

## 4. Core Product Walkthrough

### Step A: Run analysis

1. Tap Start AI Analysis.
2. Wait for loading sequence.
3. Review results sections:
   - Immediate Action Required
   - Monitor Closely
   - Known Subscriptions

Demo talking points:

- Confidence score and reasoning per merchant
- Estimated monthly leakage summary
- Risk-tiered prioritization

### Step B: Revoke one subscription

1. Tap Revoke Mandate on a high-risk card.
2. Let modal flow run end-to-end.
3. Confirm card becomes Resolved.

Demo talking point:

"Revocation is not a fake UI toggle. The modal triggers a real backend revoke call before success is shown."

### Step C: Validate persistence

1. Tap Re-scan.
2. Confirm revoked merchant remains resolved.
3. Sign out.
4. Sign in again with same account.
5. Confirm latest analysis auto-loads and resolved state is preserved.

Demo talking point:

"The app restores the latest saved analysis using authenticated user context and backend state."

## 5. Suggested 6-Minute Hackathon Script

1. 0:00 to 1:00 - Problem statement and login gate
2. 1:00 to 2:30 - Run AI analysis and explain leak detection
3. 2:30 to 4:00 - Revoke one mandate in modal sequence
4. 4:00 to 5:00 - Re-scan and show resolved persistence
5. 5:00 to 6:00 - Sign out/sign in and show latest-analysis resume

## 6. Quick Recovery if Something Fails Live

If analysis fails:

- Check Emulator terminal for Functions errors
- Verify Flutter run used `--dart-define=FIREBASE_USE_EMULATOR=true`
- Retry analysis from dashboard

If revoke fails:

- Use Retry button in revoke modal
- Verify emulator is still running and auth session is active

If login fails:

- Recreate user with a different email
- Check Auth emulator is running on port 9099

## 7. Optional Reset Between Demo Runs

Use Emulator UI (`http://127.0.0.1:4000`) to clean test user data if you want a fresh start:

- Delete the demo user from Auth emulator
- Remove user-linked documents from Firestore emulator collections

## 8. Presenter Checklist

- Emulator terminal visible
- Flutter app hot and ready on target device
- One backup demo account available
- Network-independent flow confirmed (all local emulators)
- Keep [self-testing-guide.md](self-testing-guide.md) open for deeper QA questions
