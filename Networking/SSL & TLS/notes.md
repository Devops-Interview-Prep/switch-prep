- SSL/TLS are cryptographic protocols that secure communication over a network
- They provide:
    - 🔐 Encryption – data cannot be read
    - 🧾 Authentication – you know who you’re talking to
    - 🛡 Integrity – data cannot be modified


# SSL (Secure Sockets Layer)

- What it is
    - Invented by Netscape (1990s)
    - Versions: SSL 2.0, SSL 3.0

- Status

❌ Deprecated
❌ Insecure
❌ Must NOT be used

- If you hear “SSL” today, people usually mean TLS.

# TLS (Transport Layer Security)

- What it is

    - Successor to SSL
    - Secure, modern protocol

| Version | Status           |
| ------- | ---------------- |
| TLS 1.0 | Deprecated       |
| TLS 1.1 | Deprecated       |
| TLS 1.2 | Widely used      |
| TLS 1.3 | Latest & fastest |


# SSL vs TLS (Clear Difference)

| Aspect    | SSL        | TLS    |
| --------- | ---------- | ------ |
| Security  | Weak       | Strong |
| Status    | Deprecated | Active |
| Handshake | Vulnerable | Secure |
| Use today | ❌          | ✅      |


# How TLS Works (Simplified Handshake)

1️⃣ Client → Server: Hello (supported ciphers)
2️⃣ Server → Client: Certificate (public key)
3️⃣ Client verifies certificate (CA trust)
4️⃣ Client generates session key
5️⃣ Session key encrypted with server public key
6️⃣ Secure communication starts


# Certificates

- A digital identity document containing:
    - Public key
    - Owner (domain / service)
    - Issuer (CA)
    - Expiry date

# Where Do We Use TLS? (Real World)

| Usage     | Example             |
| --------- | ------------------- |
| HTTPS     | Browsers ↔ Websites |
| APIs      | Client ↔ Backend    |
| Email     | SMTP over TLS       |
| Databases | App ↔ DB            |


☁ Cloud & Kubernetes

| Area           | Usage                |
| -------------- | -------------------- |
| kube-apiserver | kubectl ↔ API        |
| kubelet        | Node ↔ Control plane |
| etcd           | mTLS                 |
| Ingress        | HTTPS                |
| Service mesh   | mTLS                 |


# mTLS (2-way authentication)

```
Client ─────► Server
  ▲            ▲
  │ verifies    │ verifies
  │ server cert │ client cert

```

**MTLS Usecase**
- kube-apiserver ↔ etcd     - > mTLS
    - etcd contains ALL secrets
    - Must block unauthorized access

- Service Mesh

