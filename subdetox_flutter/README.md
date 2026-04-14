# SubDetox Flutter Frontend

Premium fintech mobile dashboard for analyzing recurring transaction leakage from the SubDetox FastAPI backend.

## Run

1. Ensure backend is running on `http://127.0.0.1:8000`.
2. Install dependencies:
   - `flutter pub get`
3. Start app:
   - `flutter run`

Optional overrides for custom environments:

- `--dart-define=BACKEND_MODE=fastapi-local`
- `--dart-define=LOCAL_API_HOST=<your-lan-ip>`
- `--dart-define=CLOUD_RUN_URL=<your-cloud-run-url>`

## Auth To Analysis Flow

1. User signs in with Email/Google/Phone OTP.
2. If the user has a verified phone and no saved account selection, app loads linked banks via `POST /api/v2/account-availability`.
3. User selects one or more linked accounts and saves them via `POST /api/v2/account-selection`.
4. User lands on dashboard and can run analysis using selected account context.

If account selection already exists for the same mobile number, the app directly opens dashboard.

## App Shell

The authenticated app now uses a bottom tab layout:

1. Home - AI analysis and detected subscriptions
2. Accounts - linked bank account selection and updates
3. Upload - manual statement upload workflow
4. Chat - Gemini banking assistant with grounded search when enabled
5. Settings - profile, runtime info, account refresh, and sign-out

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
- `POST /api/manual-upload`
- `POST /api/chat/assist`
- `POST /api/chat/tickets`
- `POST /api/chat/requests`
