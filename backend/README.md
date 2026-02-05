# IronClash Backend (dev)

## Requisitos
- Python 3.11+ recomendado

## Setup
```bash
cd backend
python -m venv .venv
. .venv/bin/activate  # Windows PowerShell: .\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

## Run
```bash
uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

## Endpoints
- `GET /health`
- `POST /combat/simulate`

