# SubDetox Flutter Frontend

Premium fintech mobile dashboard for analyzing recurring transaction leakage from the SubDetox FastAPI backend.

## Run

1. Ensure backend is running on `http://127.0.0.1:8000`.
2. Install dependencies:
   - `flutter pub get`
3. Start app:
   - `flutter run --dart-define=FIREBASE_PROJECT_ID=<your-firebase-project-id> --dart-define=BACKEND_MODE=fastapi-local`

## Auth To Analysis Flow

1. User signs in with Email/Google/Phone OTP.
2. If the user has a verified phone and no saved account selection, app loads linked banks via `POST /api/v2/account-availability`.
3. User selects one or more linked accounts and saves them via `POST /api/v2/account-selection`.
4. User lands on dashboard and can run analysis using selected account context.

If account selection already exists for the same mobile number, the app directly opens dashboard.

## API Host Mapping

The app automatically switches host values based on platform:

- Android emulator: `10.0.2.2`
- iOS simulator / desktop / web: `127.0.0.1`

Endpoint consumed:

- `GET /api/me`
- `POST /api/v2/account-availability`
- `POST /api/v2/account-selection`
- `GET /api/analysis/latest`
- `POST /api/analyze-transactions`
- `POST /api/revoke-mandate`
