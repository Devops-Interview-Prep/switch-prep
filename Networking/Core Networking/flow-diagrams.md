# Browser → Route53 → ALB → Kubernetes Service → Pod
```
Browser
  │
  │ 1. DNS Query (frontend.example.com)
  ▼
Local DNS Cache
  │
  ▼
Recursive Resolver
  │
  ▼
Route53 (Authoritative DNS)
  │
  │  CNAME → alb-123.elb.amazonaws.com
  ▼
AWS ALB (Public)
  │
  │  HTTP / HTTPS
  ▼
ALB Target Group
  │
  │  (IP mode)
  ▼
Kubernetes Service (ClusterIP)
  │
  │  kube-proxy (iptables / ipvs)
  ▼
Pod (Frontend App)
  │
  │  Response
  ▲
  └─────────────────────────────────
```

1️⃣ Browser DNS Resolution

- Browser → OS → Recursive DNS

- Route53 returns:
    - frontend.example.com → alb-xyz.elb.amazonaws.com



- TTL cached at multiple levels.

2️⃣ Browser → ALB

-   TCP handshake

-   TLS handshake (HTTPS)

-   ALB terminates TLS (usually)

3️⃣ ALB → Kubernetes

- ALB target type = ip

- Forwards traffic to Service-backed Pod IPs

- Health checks already verified

4️⃣ Service → Pod

- kube-proxy load balances

- Packet lands on pod

5️⃣ Response Path
- Pod → Service → ALB → Browser


# Microservice → Microservice (Same Cluster)

```
Pod A
  │
  │ 1. DNS Query (service-b.namespace.svc.cluster.local)
  ▼
CoreDNS
  │
  │  Watches K8s API
  ▼
Service B (ClusterIP)
  │
  │  kube-proxy
  ▼
Pod B
  │
  │  Response
  ▲
  └──────────────────────────────

```


# Microservice → Public URL / Another VPC

```
Pod
  │
  │ 1. DNS Query (api.external.com)
  ▼
CoreDNS
  │
  │  forward → /etc/resolv.conf
  ▼
Recursive Resolver
  │
  ▼
Authoritative DNS
  │
  │  A / CNAME
  ▼
External IP
  │
  │
Pod
  │
  │  TCP / TLS
  ▼
CNI
  │
  ▼
Node
  │
  │  SNAT
  ▼
NAT Gateway / VPC Peering / TGW
  │
  ▼
External Service
```



