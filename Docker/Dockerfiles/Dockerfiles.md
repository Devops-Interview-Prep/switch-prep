A Dockerfile is a text file containing instructions to build a Docker image. It defines:

- Base image (FROM)

- Dependencies (RUN, COPY, etc.)

- Application code (COPY)

- Working directory (WORKDIR)

- Build commands (RUN)

- Startup command (CMD or ENTRYPOINT)

Multi-stage builds use multiple FROM instructions in one Dockerfile. Each stage has its own base image. You build your app in one stage (with dependencies), then copy only the final artifacts (binaries, JARs, etc.) into a smaller runtime image.

- Smaller final images

- No build tools in production container

- More secure and efficient


**CMD**
- Specifies the default arguments to the container's entrypoint.
- Can be overridden	when you run docker run myapp ...

```
FROM python:3.11
COPY app.py .
CMD ["python", "app.py"]

# override using 
docker run my-python-app python other.py
```

**ENTRYPOINT**
- Defines the main executable (i.e., the actual command to run).
  
```
FROM python:3.11
COPY app.py .
ENTRYPOINT ["python", "app.py"]

# When you run 
docker run my-python-app other.py

# becomes python app.py other.py (you can’t replace the ENTRYPOINT command)

```

**ENTRYPOINT + CMD**

- ENTRYPOINT is the base command
- CMD is the default argument
```
FROM python:3.11
ENTRYPOINT ["python"]
CMD ["app.py"]

# when you run 
docker run my-python-app other.py

# it will be 
python other.py
```

**Shell vs Exec Form**

- Exec form (recommended):
  - `ENTRYPOINT ["python", "app.py"]`
  - No shell involved.
  - Signals (e.g., CTRL+C) are passed correctly to child process.

- Shell form:
  - `ENTRYPOINT python app.py`
  - Runs via /bin/sh -c
  - Signal handling and quoting can be tricky

---

## Multi-Stage Build — Full Example

```dockerfile
# Stage 1: Build
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download                       # cache deps layer
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o server .

# Stage 2: Minimal runtime (scratch = empty OS)
FROM scratch
COPY --from=builder /app/server /server
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
EXPOSE 8080
ENTRYPOINT ["/server"]
```

Result: **~8MB** image instead of ~300MB with full Go toolchain.

## Python Best-Practice Dockerfile

```dockerfile
FROM python:3.12-slim

WORKDIR /app

# Copy requirements first for cache efficiency
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Non-root user for security
RUN groupadd -r appuser && useradd -r -g appuser appuser
USER appuser

COPY . .
EXPOSE 8000
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "app:app"]
```

## Node.js Best-Practice Dockerfile

```dockerfile
FROM node:20-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev    # install only production deps

FROM node:20-alpine
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser
EXPOSE 3000
CMD ["node", "server.js"]
```

## Key Dockerfile Instructions

| Instruction | Purpose | Note |
|------------|---------|------|
| `FROM` | Base image | Use specific tags, not `latest` |
| `WORKDIR` | Set working directory | Creates if not exists |
| `COPY` | Copy files from build context | Prefer over `ADD` |
| `ADD` | Copy + extract tar, supports URLs | Only for tar extraction |
| `RUN` | Execute command in build | Creates a new layer |
| `ENV` | Set environment variable | Persists in container |
| `ARG` | Build-time variable | Not in final image |
| `EXPOSE` | Document port | Doesn't actually publish |
| `VOLUME` | Mount point declaration | Data persists outside container |
| `HEALTHCHECK` | Health monitoring | Used by orchestrators |
| `USER` | Run as non-root | Security best practice |

## Layer Caching Strategy

```dockerfile
# BAD — code change invalidates deps cache
COPY . .
RUN pip install -r requirements.txt

# GOOD — deps cache survives code changes
COPY requirements.txt .
RUN pip install -r requirements.txt  # cached unless requirements.txt changes
COPY . .
```

Rule: put things that change LESS OFTEN first. Dependencies before source code.

## .dockerignore

```
# .dockerignore — excludes from build context
.git
.gitignore
*.md
node_modules/         # prevents huge context upload
__pycache__/
.env                  # never include secrets!
.DS_Store
*.test.go
dist/
```

## Common Interview Questions

**Q: ENTRYPOINT vs CMD — when to use each?**
ENTRYPOINT: the main executable that never changes (e.g., `python`, `nginx`). CMD: default arguments that can be overridden at `docker run`. Use both together for a flexible CLI pattern: `ENTRYPOINT ["python"] CMD ["app.py"]` lets you run `docker run myimage other.py` to override the script while keeping the interpreter. Use only CMD for scripts where the user might override the whole command.

**Q: How do multi-stage builds reduce image size?**
Each `FROM` starts a fresh image. You build in a heavy image (golang:1.22 ~300MB) with all build tools, then `COPY --from=builder` only the compiled binary into a scratch (0MB) or alpine image. Build tools, source code, and intermediate artifacts don't exist in the final image. Result: 10-50x smaller images, smaller attack surface, faster pushes/pulls.

**Q: Why does layer order matter for caching?**
Docker caches each layer. Any change to a layer invalidates all subsequent layers. If source code (`COPY . .`) is before `RUN pip install`, every code change rebuilds the entire dependency installation. Moving the less-frequently-changing `COPY requirements.txt` + `RUN pip install` before `COPY . .` means dependencies cache unless `requirements.txt` changes. This can save 30-120 seconds per build.





