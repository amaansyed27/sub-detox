# SubDetox Flutter Frontend

Premium fintech mobile dashboard for analyzing recurring transaction leakage from the SubDetox FastAPI backend.

## Run

1. Ensure backend is running on `http://127.0.0.1:8000`.
2. Install dependencies:
   - `flutter pub get`
3. Start app:
   - `flutter run`

## API Host Mapping

The app automatically switches host values based on platform:

- Android emulator: `10.0.2.2`
- iOS simulator / desktop / web: `127.0.0.1`

Endpoint consumed:

- `POST /api/analyze-transactions/`
