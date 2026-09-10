# Docker for Node.js Projects

> Node.js projects need careful Dockerization: separate build-time deps from runtime, handle npm ci vs npm install, and set NODE_ENV=production for smaller installs. Use multi-stage builds to keep the final image lean.

---

## Project Structure

```
my-node-app/
├── src/
│   └── index.js              # Application entry point
├── package.json              # Dependencies + scripts
├── package-lock.json         # Exact locked versions (commit this!)
├── .env.example              # Template for env vars (never commit .env)
├── .dockerignore
└── Dockerfile
```

---

## package.json Reference

```json
{
  "name": "my-node-app",
  "version": "1.0.0",
  "main": "src/index.js",
  "scripts": {
    "start": "node src/index.js",
    "dev": "nodemon src/index.js",
    "build": "webpack --mode production",
    "test": "jest"
  },
  "dependencies": {
    "express": "^4.18.2"
  },
  "devDependencies": {
    "nodemon": "^3.0.1",
    "webpack": "^5.88.2",
    "jest": "^29.0.0"
  }
}
```

**Key distinction:**
- `dependencies` — needed at runtime (copied to production image)
- `devDependencies` — needed only during development/build (excluded by `NODE_ENV=production`)

---

## Dockerfile — Express/API Backend (No Build Step)

```dockerfile
# Single-stage for plain JS Node.js (no TypeScript, no bundler)
FROM node:20-alpine

# Set working directory
WORKDIR /app

# Copy package files FIRST (layer cache: only reinstall when these change)
COPY package.json package-lock.json ./

# npm ci: clean install from lockfile — reproducible, faster than npm install
# NODE_ENV=production: skips devDependencies install
RUN npm ci --only=production

# Copy application source
COPY src/ ./src/

# Non-root user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

EXPOSE 3000

# Use exec form for proper SIGTERM handling
CMD ["node", "src/index.js"]
```

---

## Dockerfile — TypeScript Backend (With Build Step)

```dockerfile
# ── Stage 1: Build ──────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

COPY package.json package-lock.json tsconfig.json ./
RUN npm ci                        # install ALL deps including devDependencies

COPY src/ ./src/
RUN npm run build                 # tsc → compiles to dist/

# ── Stage 2: Runtime ────────────────────────────────────
FROM node:20-alpine AS runtime

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --only=production      # only runtime deps in final image

COPY --from=builder /app/dist ./dist   # compiled JS only, no TypeScript source

RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

EXPOSE 3000
CMD ["node", "dist/index.js"]
```

---

## .dockerignore

```
node_modules/        # never copy — always install fresh inside container
.git/
*.log
.env                 # secrets — never bake into image
.env.local
dist/                # will be rebuilt inside container
coverage/
.nyc_output/
*.test.js
*.spec.js
README.md
.DS_Store
```

---

## npm ci vs npm install

| | `npm ci` | `npm install` |
|---|----------|---------------|
| Reads from | `package-lock.json` exactly | `package.json` (may upgrade) |
| Speed | Faster (no resolution) | Slower |
| Reproducible | Yes — exact versions | May differ |
| Creates lockfile | No — requires it to exist | Yes |
| **Use in Docker?** | **Yes — always** | Only for initial setup |

---

## When Do You Need `npm run build`?

| Project Type | Build needed? | What it does |
|---|---|---|
| **Plain JS Express** | No | Just `npm start` |
| **TypeScript backend** | Yes — `tsc` | Compiles `.ts` → `.js` in `dist/` |
| **React/Vue/Angular** | Yes — webpack/vite | Bundles to `build/` or `dist/` |
| **NestJS** | Yes — `nest build` | Compiles + bundles |

---

## Interview Q&A

**Q: Why do you copy `package.json` and `package-lock.json` before copying the rest of the source?**
Docker caches each layer. If you copy everything first and then `RUN npm ci`, any source file change invalidates the npm install layer — even though dependencies didn't change. Copying only `package.json` and `package-lock.json` first means: npm install is only re-run when dependencies actually change. All other source code changes skip the expensive install step and use the cached layer. This is the most impactful Docker optimization for Node.js.

**Q: What is the difference between `node:20-alpine` and `node:20`?**
`node:20` is based on Debian (~1GB image). `node:20-alpine` is based on Alpine Linux (~180MB). Alpine uses `musl` libc instead of `glibc`, which is incompatible with some npm packages that have native C bindings (e.g., `node-gyp` compiled packages). For most Express/NestJS apps without native addons, Alpine is fine and significantly reduces image size and attack surface. Use the full Debian-based image if you hit build errors related to `musl`/`glibc` incompatibility.

**Q: Why use `CMD ["node", "src/index.js"]` instead of `CMD "node src/index.js"`?**
The array (exec) form runs `node` directly as PID 1, so it receives signals like SIGTERM directly. The string (shell) form runs `sh -c "node src/index.js"`, making `sh` PID 1 — `sh` doesn't forward signals to child processes, so `docker stop` (which sends SIGTERM) won't reach your Node.js app, causing a 10-second timeout before SIGKILL. Always use exec form for graceful shutdown.
