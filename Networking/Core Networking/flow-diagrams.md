# Network Flow Diagrams

> Visual flow of how traffic moves through AWS networking layers — from browser to pod. Understanding these paths is essential for debugging connectivity issues and designing resilient architectures.

---

## Flow 1 — Browser → Route53 → ALB → Kubernetes Pod

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
  │  CNAME → alb-123.elb.amazonaws.com
  ▼
AWS ALB (Public, Layer 7)
  │  HTTP / HTTPS, TLS termination here
  ▼
ALB Target Group
  │  (IP mode — targets are pod IPs directly)
  ▼
Kubernetes Service (ClusterIP)
  │  kube-proxy (iptables / ipvs NAT rules)
  ▼
Pod (Frontend App)
  │  Response flows back the same path
  ▲
  └─────────────────────────────────────
```

### Step-by-Step Breakdown

```
Step 1: DNS Resolution
  Browser → OS → Recursive DNS resolver
  Route53 returns: frontend.example.com → alb-xyz.elb.amazonaws.com (CNAME)
  ALB DNS resolves to ALB's IP addresses
  TTL cached at multiple levels (browser, OS, resolver)

Step 2: Browser → ALB
  TCP handshake (3-way: SYN → SYN-ACK → ACK)
  TLS handshake (certificate from ACM)
  ALB terminates TLS — backend pods receive plain HTTP
  ALB evaluates listener rules (host/path routing)

Step 3: ALB → Kubernetes
  ALB target type = "ip" → forwards directly to pod IPs
  OR target type = "instance" → forwards to node:nodePort
  Health checks must pass before ALB routes to a target

Step 4: Service → Pod
  kube-proxy's iptables rules perform DNAT: Service ClusterIP → Pod IP
  Load balances across all healthy pods in the service

Step 5: Response Path
  Pod → Service (iptables SNAT restores original source)
  → ALB → TLS encrypt → Browser
```

---

## Flow 2 — Microservice to Microservice (Same Cluster)

```
Pod A (namespace: app)
  │
  │ 1. DNS Query: service-b.app.svc.cluster.local
  ▼
CoreDNS (cluster-internal DNS)
  │  Watches Kubernetes API for Service/Endpoint changes
  │  Returns: ClusterIP of Service B (e.g., 10.100.50.20)
  ▼
Service B (ClusterIP)
  │  kube-proxy iptables rules → DNAT to one of Pod B's IPs
  ▼
Pod B
  │  Response: Pod B → kube-proxy SNAT → Pod A
  ▲
  └──────────────────────────────────────
```

**Key points:**
- CoreDNS resolves `<service>.<namespace>.svc.cluster.local`
- No external network involved — stays within the cluster overlay
- ClusterIP is virtual — only reachable inside the cluster
- NetworkPolicy can block or allow this traffic at Pod level

---

## Flow 3 — Pod → External Public URL

```
Pod (namespace: app)
  │
  │ 1. DNS Query: api.external.com
  ▼
CoreDNS
  │  Forwards external queries to /etc/resolv.conf
  ▼
Recursive DNS Resolver (VPC DNS: .2 address e.g. 10.0.0.2)
  │
  ▼
Authoritative DNS → returns A record (external IP)
  │
  ▼
Pod makes TCP/TLS connection to external IP
  │
  ▼
CNI (Calico/VPC CNI) handles routing on node
  │
  ▼
Node (SNAT: pod IP → node IP, or via NAT Gateway)
  │
  ▼
NAT Gateway / VPC Peering / Transit Gateway
  │
  ▼
External Service (API, S3, RDS, etc.)
```

**Key points for private subnets:**
- Pods in private subnets can't reach the internet directly
- Traffic routes via NAT Gateway (pod IP → node IP → NAT Gateway public IP → internet)
- For AWS services, use VPC Endpoints (PrivateLink) to avoid NAT Gateway cost and keep traffic private

---

## Interview Q&A

**Q: What is the difference between ALB target type "ip" vs "instance"?**
With `target type: ip`, the ALB sends traffic directly to pod IP addresses (bypassing the NodePort + kube-proxy chain). This requires the AWS VPC CNI plugin (pods get VPC-routable IPs). Advantages: lower latency (one fewer hop), more accurate pod-level health checks, works with security groups at the pod level. With `target type: instance`, ALB sends to node:nodePort, then kube-proxy performs the final hop to the pod. More compatible with CNI plugins that use overlay networks (pod IPs not VPC-routable).

**Q: Why does a pod in a private subnet need a NAT Gateway to reach the internet?**
Private subnet nodes/pods have no public IPs and no route to the internet gateway. When a pod makes an outbound connection, the packet travels: pod IP (RFC-1918) → node → NAT Gateway. NAT Gateway performs SNAT: replaces the source IP with its own public IP. The external server sees the NAT Gateway's IP and responds to it. NAT Gateway tracks the connection and forwards the response back to the original pod. Without NAT Gateway, there's no route — packets are dropped at the VPC boundary.

**Q: What does CoreDNS do when a pod queries an external domain?**
CoreDNS's Corefile configures a forwarding policy. For internal cluster domains (`cluster.local`), CoreDNS answers from its own cache of Kubernetes Service and Endpoint records. For all other domains (`.` or specific external zones), CoreDNS forwards to the upstream resolver specified in the node's `/etc/resolv.conf` — typically the VPC's DNS server at the `.2` address (e.g., `10.0.0.2` in a `10.0.0.0/16` VPC). That VPC DNS server then performs normal recursive resolution.
