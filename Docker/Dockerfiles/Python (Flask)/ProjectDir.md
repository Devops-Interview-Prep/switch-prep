# Python (Flask/FastAPI) — Docker Project Structure & Best Practices

> Python apps need the interpreter and all packages in the image. Use `python:slim` or `alpine` as base (not the full image). Pin dependency versions. Run as a non-root user with a production WSGI server (gunicorn/uvicorn).

---

## Project Structure

```
my-python-app/
├── Dockerfile
├── .dockerignore
├── docker-compose.yml
├── requirements.txt             # pinned dependencies (generate: pip freeze > requirements.txt)
├── requirements-dev.txt         # dev-only deps (pytest, black, mypy, etc.)
├── setup.py                     # optional — for installable packages
├── pyproject.toml               # modern packaging config (replaces setup.py)
├── .env                         # local secrets (git-ignored)
├── app/
│   ├── __init__.py
│   ├── main.py                  # Flask app factory or FastAPI app
│   ├── routes/
│   ├── models/
│   ├── services/
│   └── config.py                # config from env vars
├── tests/
│   └── test_main.py
├── migrations/                  # Alembic DB migrations
└── run.py                       # local dev entrypoint (not used in Docker)
```

---

## requirements.txt — Pin Exact Versions

```
# requirements.txt — ALWAYS pin exact versions in production
Flask==3.0.2
gunicorn==21.2.0
SQLAlchemy==2.0.25
psycopg2-binary==2.9.9
redis==5.0.1
pydantic==2.5.3
python-dotenv==1.0.1
prometheus-client==0.19.0
```

```bash
# Generate locked requirements from current venv:
pip freeze > requirements.txt

# Use pip-tools for better dep management:
pip install pip-tools
# Write requirements.in with just direct deps (no versions):
#   Flask
#   gunicorn
#   SQLAlchemy
# Then compile to locked versions:
pip-compile requirements.in   # generates requirements.txt with all transitive deps pinned
pip-sync requirements.txt     # install exactly what's in requirements.txt
```

---

## Optimized Dockerfile — Flask/FastAPI

```dockerfile
# ─── Stage 1: Install dependencies ──────────────────────────────
FROM python:3.12-slim AS deps
WORKDIR /app

# Install system deps needed by some Python packages (libpq for psycopg2)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Install Python deps into a separate layer — cached unless requirements.txt changes
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# ─── Stage 2: Production image ───────────────────────────────────
FROM python:3.12-slim AS final
WORKDIR /app

# Install only runtime system libraries (no build tools)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Non-root user (security)
RUN groupadd -r appgroup && useradd -r -g appgroup -d /app appuser

# Copy installed packages from deps stage
COPY --from=deps /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=deps /usr/local/bin/gunicorn /usr/local/bin/gunicorn

# Copy application code last (changes most frequently)
COPY --chown=appuser:appgroup . .

USER appuser
EXPOSE 8000

# gunicorn: production WSGI server
# -w: number of workers (2 * CPUs + 1 is the rule of thumb)
# --bind: listen on all interfaces
# --timeout: worker timeout in seconds
CMD ["gunicorn", "--bind", "0.0.0.0:8000", \
     "--workers", "4", \
     "--timeout", "120", \
     "--access-logfile", "-", \
     "--error-logfile", "-", \
     "app.main:app"]

# For FastAPI (async), use uvicorn with gunicorn as process manager:
# CMD ["gunicorn", "-k", "uvicorn.workers.UvicornWorker", \
#      "--bind", "0.0.0.0:8000", "--workers", "4", "app.main:app"]
```

---

## .dockerignore

```
# .dockerignore for Python projects
__pycache__/
*.pyc
*.pyo
*.pyd
.Python
venv/                   # virtual environment — never send to Docker
.venv/
env/
*.egg-info/
dist/
build/
.git/
.github/
*.md
.env                    # secrets
.env.*
.pytest_cache/
.mypy_cache/
.coverage
htmlcov/
tests/                  # test files don't belong in production image
.DS_Store
migrations/versions/    # optional: exclude if you run migrations separately
```

---

## docker-compose.yml

```yaml
services:
  api:
    build:
      context: .
      target: final
    image: my-api:local
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://postgres:secret@postgres:5432/myapp
      - REDIS_URL=redis://redis:6379/0
      - SECRET_KEY=${SECRET_KEY:-dev-secret-change-in-prod}
      - DEBUG=false
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_started
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 5s
      retries: 3
    restart: unless-stopped

  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: secret
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s

  redis:
    image: redis:7-alpine
    volumes:
      - redisdata:/data

volumes:
  pgdata:
  redisdata:
```

---

## Flask App — Production-Ready Pattern

```python
# app/main.py
from flask import Flask, jsonify
from app.config import Config

def create_app(config=None):
    """App factory pattern — enables testing with different configs."""
    app = Flask(__name__)
    app.config.from_object(config or Config)

    # Register blueprints
    from app.routes.users import users_bp
    app.register_blueprint(users_bp, url_prefix='/api/v1')

    # Health check endpoint — used by Docker HEALTHCHECK and K8s probes
    @app.route('/health')
    def health():
        return jsonify({'status': 'ok'})

    return app

# app/config.py
import os

class Config:
    DATABASE_URL = os.environ['DATABASE_URL']   # required — fail loudly if missing
    SECRET_KEY = os.environ.get('SECRET_KEY', 'dev-only-not-for-prod')
    DEBUG = os.environ.get('DEBUG', 'false').lower() == 'true'
    REDIS_URL = os.environ.get('REDIS_URL', 'redis://localhost:6379/0')
```

---

## Build Commands

```bash
# ─── Local development ────────────────────────────────────────────
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt -r requirements-dev.txt
flask run --debug --port 5000

# ─── Docker build ─────────────────────────────────────────────────
docker build -t my-api:local .
docker build --target deps -t my-api:deps .   # debug: inspect deps stage
docker run --rm -it my-api:deps sh            # inspect what's installed

# Run with environment:
docker run -p 8000:8000 \
  -e DATABASE_URL=postgresql://localhost/myapp \
  -e SECRET_KEY=my-secret \
  my-api:local

# ─── Gunicorn worker tuning ───────────────────────────────────────
# Rule: (2 × CPU count) + 1 workers for CPU-bound
# For I/O-bound apps with async: fewer processes, more threads/coroutines
# Sync worker (default): 1 request per worker at a time
# Async worker: gunicorn -k gevent --worker-connections 1000
```

---

## Python Docker Best Practices

**1. `python:slim` vs `python:alpine`:**
```
python:3.12          → ~900MB (full Debian) — avoid in production
python:3.12-slim     → ~130MB (Debian slim) — recommended (has glibc)
python:3.12-alpine   → ~50MB (Alpine/musl)  — smaller, but musl libc can cause issues
                                               with binary wheels (numpy, psycopg2, etc.)
                                               → must compile from source or use special wheels
```

**2. `--no-cache-dir` in pip install:**
```dockerfile
RUN pip install --no-cache-dir -r requirements.txt
# Removes the pip download cache after install
# Without it: cache stays in the layer, inflating image size
```

**3. Never run gunicorn as root:**
```dockerfile
RUN useradd -r -u 1001 appuser
USER appuser
# Even inside a container, running as root is a security risk
# If container is compromised, root = host root (if not using user namespaces)
```

**4. Handle SIGTERM in gunicorn:**
```bash
# gunicorn handles SIGTERM gracefully by default:
# 1. Stops accepting new connections
# 2. Waits for in-flight requests to complete (--timeout window)
# 3. Workers exit cleanly
# docker stop → SIGTERM → gunicorn graceful shutdown → all workers exit
```

---

## Interview Q&A

**Q: Why use gunicorn instead of Flask's development server in Docker?**
Flask's built-in server (`flask run`) is single-threaded and not production-safe — it handles one request at a time, doesn't handle errors gracefully, and has no worker management. Gunicorn is a production WSGI server that: (1) spawns multiple worker processes (typically 2×CPUs+1), so it handles concurrent requests; (2) restarts workers that crash without the whole app dying; (3) handles signals (SIGTERM) gracefully; (4) integrates with NGINX for static files and load balancing. For async frameworks (FastAPI), use `uvicorn` workers with gunicorn as the process manager.

**Q: What's the difference between `python:slim` and `python:alpine`?**
Both are minimal Python images. `slim` strips non-essential packages from Debian but keeps glibc. `alpine` uses musl libc instead of glibc — it's ~50-130MB smaller, but musl libc can cause issues with Python packages that include compiled C extensions (numpy, psycopg2, cryptography) — these packages distribute pre-compiled binary wheels that link against glibc, so on Alpine they must compile from source, which requires build tools and can fail. For most web services, `python:slim` is the better trade-off: smaller than full image, compatible with all packages, no musl surprises.

**Q: How do you avoid reinstalling packages on every Docker build?**
Copy only `requirements.txt` and run `pip install` before copying the application code. Since `COPY requirements.txt .` + `RUN pip install` are separate layers that come BEFORE `COPY . .`, they're cached until `requirements.txt` changes. A code change only invalidates the `COPY . .` layer and later — not the pip install layer. This makes rebuilds for code changes take seconds instead of minutes. In multi-stage builds, you can even use a separate `deps` stage that caches the install independently of the build stage.
