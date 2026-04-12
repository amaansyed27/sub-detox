# Cloud Run Deployment Guide (FastAPI AA Emulator)

This guide deploys the FastAPI backend as the primary AA-style emulator API while Firebase continues to handle auth and persistence.

## 1. Prerequisites

- Google Cloud project with billing enabled
- Firebase project linked to same GCP project
- gcloud CLI authenticated
- Artifact Registry or Container Registry access
- Firestore database available in the target project

## 2. Required APIs

Enable required Google Cloud APIs:

```powershell
gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com firestore.googleapis.com
```

## 3. Set Project and Region

```powershell
$PROJECT_ID="subdetox-20260412-8514"
$REGION="asia-south1"
gcloud config set project $PROJECT_ID
```

## 4. Build and Push Container

From repo root:

```powershell
cd C:\Users\Amaan\Downloads\sub-detox
gcloud builds submit --tag gcr.io/$PROJECT_ID/subdetox-api:latest
```

## 5. Deploy Cloud Run Service

```powershell
gcloud run deploy subdetox-api `
  --image gcr.io/$PROJECT_ID/subdetox-api:latest `
  --region $REGION `
  --platform managed `
  --allow-unauthenticated `
  --set-env-vars FIREBASE_PROJECT_ID=$PROJECT_ID,USE_FIRESTORE_EMULATOR=false,AUTH_BYPASS_ENABLED=false,PUBLIC_BASE_URL=https://subdetox-api-<hash>-$REGION.a.run.app
```

Notes:

- Keep `AUTH_BYPASS_ENABLED=false` in cloud.
- Cloud Run service account must have Firestore read/write permissions.
- Firebase Admin SDK uses Application Default Credentials in Cloud Run.

## 6. Verify Deployment

Health check:

```powershell
$API_URL="https://subdetox-api-<hash>-$REGION.a.run.app"
Invoke-RestMethod -Uri "$API_URL/health" -Method Get
```

Expected:

- status is `ok`
- service is `subdetox-cloudrun-fastapi`

## 7. Flutter Cutover to Cloud Run

Run Flutter with cloud backend mode:

```powershell
cd C:\Users\Amaan\Downloads\sub-detox\subdetox_flutter
flutter run `
  --dart-define=BACKEND_MODE=fastapi-cloud `
  --dart-define=CLOUD_RUN_URL=https://subdetox-api-<hash>-asia-south1.a.run.app `
  --dart-define=FIREBASE_USE_EMULATOR=false `
  --dart-define=FIREBASE_PROJECT_ID=subdetox-20260412-8514 `
  --dart-define=FIREBASE_API_KEY=<api-key> `
  --dart-define=FIREBASE_APP_ID=<app-id> `
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=<sender-id> `
  --dart-define=FIREBASE_AUTH_DOMAIN=<auth-domain> `
  --dart-define=FIREBASE_STORAGE_BUCKET=<storage-bucket>
```

## 8. Post-Deploy Smoke Checklist

- `GET /health` returns `ok`
- Authenticated `POST /api/analyze-transactions` succeeds
- Authenticated `GET /api/analysis/latest` returns latest run
- Authenticated `POST /api/revoke-mandate` persists resolve state
- v2 consent/session lifecycle endpoints work end-to-end

## 9. Rollback Plan

If Cloud Run regression occurs:

1. Switch Flutter temporarily to `BACKEND_MODE=functions-cloud`.
2. Keep Firebase Auth unchanged.
3. Re-run smoke checks after FastAPI hotfix and redeploy.
