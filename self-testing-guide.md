# SubDetox Self Testing Guide

This guide helps you test the full stack locally: FastAPI backend plus Flutter app.

## 1. Prerequisites

- Python 3.10+ installed
- Flutter SDK installed
- Android emulator, iOS simulator, or desktop target available

## 2. One-Time Setup

### Backend setup

```powershell
cd C:\Users\Amaan\Downloads\sub-detox
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

### Frontend setup

```powershell
cd C:\Users\Amaan\Downloads\sub-detox\subdetox_flutter
flutter pub get
```

## 3. Run the App

Open two terminals.

### Terminal A: Start FastAPI

```powershell
cd C:\Users\Amaan\Downloads\sub-detox
.\.venv\Scripts\Activate.ps1
uvicorn app.main:app --reload
```

Expected startup URL: `http://127.0.0.1:8000`

### Terminal B: Start Flutter

```powershell
cd C:\Users\Amaan\Downloads\sub-detox\subdetox_flutter
flutter run
```

## 4. Backend API Smoke Tests

Run this in a new PowerShell terminal:

```powershell
# 1) Health
$health = Invoke-RestMethod -Uri "http://127.0.0.1:8000/health" -Method Get
$health

# 2) Mock AA payload
$mock = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/mock-aa-data/" -Method Get
$mock.ver
$mock.FI.Count

# 3) Analysis endpoint
$analysis = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/analyze-transactions/" -Method Post -ContentType "application/json" -Body "{}"
$analysis.total_monthly_leakage
$analysis.scanned_transaction_count
$analysis.detected_subscriptions | Select-Object display_name, threat_level, estimated_monthly_amount
```

Expected outcomes:

- Health returns status = ok
- Analyze response includes:
  - `total_monthly_leakage` greater than 0
  - `detected_subscriptions` with high, medium, and low threat entries
- Typical seeded values should include items similar to:
  - Gymcult AutoPay
  - VIL HelloTune VAS
  - Credit Shield Add-On
  - Netflix Standard

## 5. Frontend UI Test Scenarios

### Scenario A: Initial state

1. Launch the app.
2. Confirm you see the hero landing panel with a Start AI Analysis action.

Pass criteria:
- Screen loads without crash
- CTA is visible and tappable

### Scenario B: Analyzing state

1. Tap Start AI Analysis.
2. Confirm loading state appears.

Pass criteria:
- Loading panel appears immediately
- No freeze or jank while waiting for API response

### Scenario C: Results state and data quality

1. Wait for results to load.
2. Validate top action hero card:
   - Animated leakage amount counts up
   - Annualized leakage text is shown
3. Validate scan confidence card:
   - Scanned transactions metric shown
   - Flagged and resolved metrics shown

Pass criteria:
- Counter animation runs once per fresh analysis
- Metrics are non-empty and plausible

### Scenario D: Threat grouping and ordering

1. Scroll through sections.
2. Confirm grouping:
   - Immediate Action Required (HIGH)
   - Monitor Closely (MEDIUM)
   - Known Subscriptions (LOW)
3. Confirm high-risk cards render before low-risk cards.

Pass criteria:
- Threat badges use distinct colors
- High-risk entries appear in top section

### Scenario E: Expandable reasoning

1. Tap chevron on any subscription card.
2. Validate expanded panel text under Why did we flag this?

Pass criteria:
- Expand/collapse animation works
- Reasoning content is readable

### Scenario F: Revoke mandate flow

1. Tap Revoke Mandate on an unresolved card.
2. Verify bottom sheet step sequence:
   1. Authenticating via Account Aggregator...
   2. Intercepting e-NACH mandate ID...
   3. Mandate Revoked. ₹[amount] saved annually!
3. Let modal auto-close.
4. Verify the card transitions to Resolved state.

Pass criteria:
- Sequence advances step by step, not all at once
- Final step shows green completion styling
- Resolved card appears grayed with Resolved badge
- Hero/metrics update to reflect reduced active leakage

## 6. Regression Checklist

- [ ] Backend boots without import/runtime errors
- [ ] `POST /api/analyze-transactions/` succeeds consistently
- [ ] Flutter app runs on target device/emulator
- [ ] No red-screen/runtime exception during full flow
- [ ] Revoke flow completes and updates provider state
- [ ] Pull-to-refresh triggers a new analysis run

## 7. Platform Networking Notes

The app maps host automatically:

- Android emulator uses `10.0.2.2`
- iOS simulator/desktop/web uses `127.0.0.1`

If requests fail on a physical device, replace localhost host mapping with your machine LAN IP in `lib/services/api_config.dart`.

## 8. Helpful Commands

```powershell
# Backend quick check
Invoke-RestMethod -Uri "http://127.0.0.1:8000/health" -Method Get

# Flutter static checks
cd C:\Users\Amaan\Downloads\sub-detox\subdetox_flutter
flutter analyze
```
