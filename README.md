# IronClashS (vertical slice)

Este repo contiene un **vertical slice** mínimo:
- **Godot 4.5**: Hub (casa placeholder) → tocar personaje → ver stats/gear → botón **Pelear** → muestra replay.
- **FastAPI**: simula combate autoritativo (ATB + Dodge→Block→Crit→Daño) y devuelve **replay JSON** determinista por `seed`.

## Backend (FastAPI)

### 1) Setup (Windows PowerShell)
```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

### 2) Run
```powershell
uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

### 3) Test rápido
- `GET /health` debe devolver `{ "status": "ok" }`

## Cliente (Godot)

1) Abrí el proyecto (`project.godot`) con **Godot 4.5**.
2) Ejecutá Play.
3) Si el backend está corriendo, arriba a la derecha vas a ver **Backend: OK**.
4) Tocá el personaje → **Pelear** → se llena el panel con el replay.

### Config backend URL
La URL se define en `src/config/game_config.gd` (`BACKEND_BASE_URL`).

