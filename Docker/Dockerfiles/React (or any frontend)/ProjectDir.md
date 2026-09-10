# React (Frontend) — Docker Project Structure & Best Practices

> React apps are static files after build (HTML, CSS, JS). The Docker pattern: build in Node.js, serve static output with nginx. Final image: ~25MB with no Node.js in production.

---

## Project Structure

```
my-react-app/
├── Dockerfile                   # multi-stage: build + nginx serve
├── .dockerignore
├── docker-compose.yml
├── nginx.conf                   # custom nginx config for SPA routing
├── package.json
├── package-lock.json            # lock file (commit this, not node_modules)
├── tsconfig.json                # TypeScript config
├── vite.config.ts               # or craco/webpack.config.js
├── src/
│   ├── main.tsx                 # app entrypoint
│   ├── App.tsx
│   ├── components/
│   ├── pages/
│   ├── hooks/
│   ├── store/                   # Redux/Zustand state
│   └── api/                     # API client functions
├── public/                      # static assets served as-is
│   └── index.html
└── dist/                        # build output (gitignored — Docker generates this)
```

---

## Optimized Dockerfile — Build + nginx

```dockerfile
# ─── Stage 1: Install dependencies ──────────────────────────────
FROM node:20-alpine AS deps
WORKDIR /app
# Only copy package files — deps layer cached unless package*.json changes
COPY package.json package-lock.json ./
RUN npm ci                        # clean install using lockfile (faster + deterministic)

# ─── Stage 2: Build the React app ───────────────────────────────
FROM node:20-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules  # reuse deps from stage 1
COPY . .

# Build-time environment variables injected via ARG
ARG REACT_APP_API_URL=https://api.example.com
ARG REACT_APP_ENV=production
ENV REACT_APP_API_URL=$REACT_APP_API_URL
ENV REACT_APP_ENV=$REACT_APP_ENV

RUN npm run build                 # outputs to /app/dist (Vite) or /app/build (CRA)

# ─── Stage 3: Production nginx ───────────────────────────────────
FROM nginx:1.25-alpine AS final
# Remove default nginx content
RUN rm -rf /usr/share/nginx/html/*
# Copy built assets from builder stage
COPY --from=builder /app/dist /usr/share/nginx/html
# Copy custom nginx config for SPA (handles client-side routing)
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

---

## nginx.conf — SPA Routing

```nginx
# nginx.conf
server {
    listen 80;
    server_name _;

    root /usr/share/nginx/html;
    index index.html;

    # ─── Gzip compression ───────────────────────────────────────
    gzip on;
    gzip_types text/plain text/css application/json application/javascript
               text/xml application/xml application/xml+rss text/javascript;
    gzip_min_length 1000;

    # ─── Cache static assets ────────────────────────────────────
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff2?)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # ─── SPA fallback — all routes → index.html ─────────────────
    # Without this, refreshing on /dashboard returns 404
    location / {
        try_files $uri $uri/ /index.html;
    }

    # ─── Health check endpoint ───────────────────────────────────
    location /health {
        return 200 'OK';
        add_header Content-Type text/plain;
    }

    # ─── API proxy (optional — avoids CORS in dev-like setups) ──
    location /api/ {
        proxy_pass http://backend:3000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

## .dockerignore

```
# .dockerignore for React projects
node_modules/           # NEVER send — can be hundreds of MB
dist/                   # build output (will be rebuilt in Docker)
build/                  # CRA build output
.git/
.github/
*.md
.env                    # secrets — never in image
.env.local
.env.*.local
.DS_Store
coverage/
*.log
.eslintcache
.vite/
```

---

## docker-compose.yml — Full Dev Stack

```yaml
services:
  frontend:
    build:
      context: .
      target: final
      args:
        REACT_APP_API_URL: http://localhost:3000
    image: my-app-frontend:local
    ports:
      - "80:80"
    depends_on:
      - backend
    restart: unless-stopped

  backend:
    image: my-app-backend:local
    ports:
      - "3000:3000"
    environment:
      - DB_HOST=postgres
    depends_on:
      postgres:
        condition: service_healthy

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

volumes:
  pgdata:
```

---

## Build Commands

```bash
# ─── Local development (hot reload — no Docker) ──────────────────
npm install
npm run dev                                    # Vite dev server with HMR

# ─── Docker build ─────────────────────────────────────────────────
docker build -t my-app-frontend:local .

# Inject API URL at build time:
docker build \
  --build-arg REACT_APP_API_URL=https://api.prod.example.com \
  -t my-app-frontend:prod .

# Inspect build size:
docker image ls my-app-frontend
docker history my-app-frontend:local

# ─── docker-compose ───────────────────────────────────────────────
docker compose up -d
docker compose up -d --build                  # rebuild on code change
docker compose logs -f frontend
```

---

## Frontend-Specific Docker Best Practices

**1. Environment variables at build time vs runtime:**
```dockerfile
# ❌ Problem: React env vars are baked into the JS bundle at build time
# You cannot change REACT_APP_API_URL after the image is built
# Solution A: Use ARG + ENV (different image per environment)

# Solution B: Runtime config via window._env_ (one image for all envs)
# index.html injects: <script src="/config.js"></script>
# nginx serves a dynamic /config.js that reads from container env vars
# app reads: const apiUrl = window._env_?.API_URL || 'http://localhost:3000'
```

**2. Cache-busting — Vite/webpack handles it:**
```
dist/
├── index.html               # no hash — always fresh
├── assets/
│   ├── index-Bv3k9A2.js     # hash in filename → immutable → cache 1 year
│   └── index-Cv7m4B1.css    # hash changes when code changes
```
Your nginx caching config should set `Cache-Control: immutable` on hashed assets and no-cache on `index.html`.

**3. Multi-stage protects secrets:**
```dockerfile
# ARG values passed at build time APPEAR in docker history
# They do NOT appear in the final image's filesystem
# But they ARE visible in docker history of the builder stage
# For truly sensitive secrets: use BuildKit secret mounts
RUN --mount=type=secret,id=npm_token \
    NPM_TOKEN=$(cat /run/secrets/npm_token) npm install
```

**4. Use `npm ci` not `npm install` in Docker:**
- `npm install` can update package-lock.json (non-deterministic in Docker)
- `npm ci` reads package-lock.json exactly, fails if it doesn't match package.json
- Faster and reproducible — always prefer in Docker/CI

---

## Interview Q&A

**Q: How do you serve a React app in production with Docker?**
Multi-stage build: first stage uses `node:alpine` to run `npm ci && npm run build`, producing static HTML/CSS/JS in a `dist/` directory. Second stage is `nginx:alpine`, which copies just those static files and serves them with nginx. Final image is ~25MB with no Node.js, no package.json, no source code — just nginx and the built assets. Add a custom `nginx.conf` with `try_files $uri /index.html` for SPA client-side routing so refreshing `/dashboard` doesn't 404.

**Q: Why doesn't `react-router` work on page refresh in a containerized app?**
React Router handles routing client-side in JavaScript. When you first load the app, the server serves `index.html`, JavaScript runs, and React Router manages navigation. But if you refresh at `/dashboard`, the browser requests `/dashboard` directly from the server — nginx looks for a file at that path, finds nothing, and returns 404. Fix: configure nginx with `try_files $uri $uri/ /index.html` — if no file matches the path, always serve `index.html`, and React Router takes over from there.

**Q: How do you handle environment-specific API URLs in a Docker image?**
Two approaches: (1) Build-time injection — pass the API URL as a Docker ARG (`--build-arg REACT_APP_API_URL=...`); it's baked into the JS bundle. Downside: one image per environment. (2) Runtime config — ship a `/config.js` script with `window._env_` variables, served by nginx. The script's content is generated dynamically (e.g., via an entrypoint script that writes environment variables into it). The app reads `window._env_.API_URL`. One Docker image works for all environments; configuration is injected at runtime.
