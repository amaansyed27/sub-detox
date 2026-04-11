# SubDetox FastAPI Backend

A modular backend prototype for SubDetox, an AI-powered financial auditor that identifies hidden recurring subscription leakage from Account Aggregator transaction feeds.

## Project Structure

```text
sub-detox/
  app/
    api/
      router.py
      v1/
        endpoints/
          analysis.py
          mock_data.py
    core/
      settings.py
    schemas/
      aa.py
      analysis.py
    services/
      analysis_service.py
      mock_aa_service.py
    main.py
  requirements.txt
```

## Setup

```bash
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
```

## Run

```bash
uvicorn app.main:app --reload
```

## Key Endpoints

1. `GET /health`
2. `GET /api/mock-aa-data/`
3. `POST /api/analyze-transactions/`

### Analyze Endpoint Usage

Analyze generated mock data (no request body required):

```bash
curl -X POST http://127.0.0.1:8000/api/analyze-transactions/
```

Analyze custom payload:

```bash
curl -X POST http://127.0.0.1:8000/api/analyze-transactions/ \
  -H "Content-Type: application/json" \
  -d '{"aa_payload": {"ver": "1.1.3", "timestamp": "2026-04-11T09:00:00Z", "txnid": "TXN-EXAMPLE", "Consent": {"id": "CONSENT-EXAMPLE", "status": "ACTIVE", "FIDataRange": {"from": "2026-01-11", "to": "2026-04-11"}}, "FI": []}}'
```
