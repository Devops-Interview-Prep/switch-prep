# AWS Load Balancers

> AWS Elastic Load Balancing (ELB) distributes incoming traffic across multiple targets — EC2 instances, containers, Lambda, or IP addresses. Selecting the right load balancer type is a common architecture decision in AWS interviews.

---

## How Load Balancing Works

```
Request flow:
1. Client sends request to load balancer's DNS name
2. Load balancer checks health of registered targets
3. Routes traffic to a healthy target using chosen algorithm (round-robin, least connections, etc.)
4. Target processes request and returns response
5. Load balancer monitors health and auto-removes unhealthy targets
```

---

## Types of AWS Load Balancers

| Feature | ALB | NLB | GWLB | CLB |
|---------|-----|-----|------|-----|
| OSI Layer | 7 (Application) | 4 (Transport) | 3 (Network) | 4 + 7 |
| Protocol | HTTP/HTTPS/gRPC | TCP/UDP/TLS | All IP traffic | HTTP/HTTPS/TCP |
| Routing | Host/path/header | IP/Port | Transparent | Basic |
| Static IP | No | Yes | Yes | No |
| Source IP preserve | No (X-Forwarded-For) | Yes | Yes | No |
| Use case | Web apps, APIs | High perf, non-HTTP | Firewall appliances | Legacy |

---

## Application Load Balancer (ALB) — Layer 7

```
Best for: HTTP/HTTPS traffic, REST APIs, microservices

Key features:
- URL-based routing: /api/* → Service A, /admin/* → Service B
- Host-based routing: api.example.com vs admin.example.com
- Header-based routing: route by User-Agent, custom headers
- Query string routing: ?version=v2 → v2 service
- Native WebSocket and HTTP/2 support
- WAF (Web Application Firewall) integration
- Authentication via Cognito or OIDC (before the request hits the app)
- Lambda functions as targets
- Sticky sessions via cookie

ALB with Kubernetes (AWS Load Balancer Controller):
- Creates ALB per Ingress resource automatically
- Target type: ip (direct pod) or instance (via NodePort)
- TLS termination with ACM certificates
- Group multiple Ingresses into one ALB with annotation:
  alb.ingress.kubernetes.io/group.name: my-group

Limitations:
- HTTP/HTTPS only — no gRPC over plain HTTP, no custom TCP/UDP
- No static IP (ALB IPs change) — use NLB if you need fixed IPs
- No source IP preservation (use X-Forwarded-For header)
- 1 ALB per Ingress = expensive at scale
```

---

## Network Load Balancer (NLB) — Layer 4

```
Best for: high-throughput TCP/UDP traffic, non-HTTP protocols, static IPs

Key features:
- Millions of requests/second with ultra-low latency
- Static Elastic IP addresses (per AZ) — great for IP whitelisting
- Preserves client source IP — backend sees real client IP
- TLS termination (optional) — or pass-through to backend
- Zonal DNS failover support
- Target types: instance, ip, ALB (can place ALB behind NLB)

Protocols supported:
- TCP, UDP, TLS, gRPC, WebSocket, QUIC, HTTP/HTTPS (pass-through)

NLB with Kubernetes:
- Use when: gRPC, WebSocket, custom TCP, need static IP
- Ingress controller (nginx) exposed via LoadBalancer service type
- NLB routes to nginx pods, nginx does L7 routing

Limitations:
- No content-based routing (no path/host routing at NLB level)
- No WAF integration
- Cannot inspect or modify HTTP headers
```

---

## Kubernetes Ingress Architectures

### Option 1: DNS + nginx Controller (NodePort)

```
Route53 → public node IPs → NodePort → nginx ingress controller → pods

When to use:
- On-prem / bare metal clusters
- Lab/dev environments
- You manage your own edge (Cloudflare, HAProxy in front)

Cons:
- No health checking unless Route53 health checks configured
- Uneven load (DNS caching causes stickiness to one node)
- No connection draining, no WAF at edge
```

### Option 2: DNS + NLB + nginx Controller (LoadBalancer Service)

```
Route53 → NLB → nginx pods (LoadBalancer type Service) → application pods

When to use:
- Production on AWS with non-HTTP protocols (gRPC, WebSocket)
- Need static IP for IP whitelisting
- Cost-sensitive: fewer ALBs

Pros:
- gRPC, WebSocket, TCP all work
- NLB health-checks nginx pods directly
- Static Elastic IP per AZ

Cons:
- No WAF (add Cloudflare or AWS WAF behind NLB separately)
- Cannot manipulate HTTP headers like nginx can (NLB is transparent L4)
```

### Option 3: DNS + ALB + AWS Load Balancer Controller

```
Route53 → ALB (provisioned by LBC) → pods (ip target mode)

When to use:
- HTTP/HTTPS only workloads on EKS
- Need WAF, Cognito auth, native AWS integration
- Most common EKS production pattern

Pros:
- Full L7 routing (path, host, header)
- WAF, ACM TLS, Cognito auth
- Direct pod targeting (ip mode) = lowest latency

Cons:
- HTTP/HTTPS only — no gRPC without HTTPS, no custom TCP/UDP
- 1 ALB per Ingress = costly at scale (use group.name annotation to share)
- Cannot rewrite URLs or do advanced nginx tricks
```

---

## Interview Q&A

**Q: When would you choose NLB over ALB?**
Choose NLB when: (1) you need ultra-low latency (< 100 microseconds vs ALB's milliseconds), (2) you need a static IP per AZ (ALB IPs are dynamic), (3) the protocol isn't HTTP/HTTPS — gRPC without TLS, raw TCP/UDP, custom protocols, (4) you need source IP preservation at layer 4, (5) handling millions of concurrent connections (NLB scales to 10M+ simultaneously). Choose ALB for: web apps, REST APIs, content-based routing, WAF, authentication middleware, and Lambda targets.

**Q: What is the AWS Load Balancer Controller and how does it work?**
It's a Kubernetes controller that runs in your EKS cluster and watches Ingress resources. When you create an Ingress with `kubernetes.io/ingress.class: alb` annotation, the controller automatically provisions an AWS ALB, creates target groups, registers pods (ip mode) or nodes (instance mode) as targets, and configures routing rules from the Ingress spec. It also handles deregistration during pod termination. This replaces the classic approach of manually creating ALBs — everything is declarative and driven by Kubernetes resources.

**Q: What is the difference between ALB target type "ip" vs "instance"?**
`target type: ip` registers pod IP addresses directly as targets — requires AWS VPC CNI plugin (pod IPs must be VPC-routable). ALB bypasses the NodePort+kube-proxy chain, reducing latency and providing pod-level health checks. `target type: instance` registers node:nodePort — works with any CNI plugin but adds kube-proxy hop and node-level health checks (less granular). For EKS with VPC CNI, `ip` mode is preferred. For self-managed clusters or Karpenter nodes, `instance` mode may be needed.
