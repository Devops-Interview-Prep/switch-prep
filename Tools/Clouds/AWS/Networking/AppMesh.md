# AWS App Mesh

> Managed service mesh built on Envoy proxy. Provides application-level networking for microservices — traffic management, observability, and mTLS without changing application code.

## Service Mesh Concepts

A service mesh adds a **sidecar proxy** (Envoy) to every pod/task. All traffic goes through the proxy — no changes to application code:

```mermaid
graph LR
    PodA["Service A\n+ Envoy sidecar"] -->|TCP/HTTP\nthrough proxy| PodB["Service B\n+ Envoy sidecar"]
    PodA -->|stats| CW["CloudWatch"]
    PodA -->|traces| XRay["X-Ray"]
    CP["App Mesh\nControl Plane"] -->|config (xDS)| Envoy_A["Envoy in Pod A"]
    CP -->|config (xDS)| Envoy_B["Envoy in Pod B"]
```

## Core Resources

| Resource | Role |
|----------|------|
| **Mesh** | Top-level container for all App Mesh resources |
| **Virtual Node** | Logical pointer to a service (ECS task, K8s Deployment) |
| **Virtual Router** | Defines routing rules for a virtual service |
| **Virtual Service** | Abstract name (DNS hostname) that maps to a virtual router |
| **Route** | Traffic rule (weight, headers, path prefix) within a virtual router |

## Example: Canary Deployment

```yaml
# Virtual Router with weighted routes (canary 10% to v2)
apiVersion: appmesh.k8s.aws/v1beta2
kind: VirtualRouter
metadata:
  name: payment-service-vr
spec:
  listeners:
    - portMapping:
        port: 8080
        protocol: http
  routes:
    - name: payment-route
      httpRoute:
        match:
          prefix: /
        action:
          weightedTargets:
            - virtualNodeRef:
                name: payment-v1
              weight: 90
            - virtualNodeRef:
                name: payment-v2
              weight: 10      # 10% canary traffic
---
# Virtual Node pointing to v1 deployment
apiVersion: appmesh.k8s.aws/v1beta2
kind: VirtualNode
metadata:
  name: payment-v1
spec:
  podSelector:
    matchLabels:
      app: payment
      version: v1
  listeners:
    - portMapping:
        port: 8080
        protocol: http
      healthCheck:
        path: /health
        protocol: http
        healthyThreshold: 2
        intervalMillis: 5000
  serviceDiscovery:
    dns:
      hostname: payment-v1.payment.svc.cluster.local
```

## mTLS Between Services

App Mesh supports mutual TLS using ACM Private CA:

```yaml
spec:
  listeners:
    - tls:
        mode: STRICT     # DISABLED, PERMISSIVE, or STRICT
        certificate:
          acm:
            certificateArn: arn:aws:acm:us-east-1:123:certificate/abc
        validation:
          trust:
            acm:
              certificateAuthorityArns:
                - arn:aws:acm-pca:us-east-1:123:certificate-authority/xyz
```

`STRICT` mode: both services must present valid certificates — mutual authentication.
`PERMISSIVE` mode: accept both TLS and plaintext — for gradual mTLS rollout.

## App Mesh Controller (EKS)

The App Mesh Controller for Kubernetes translates CRDs to App Mesh API calls and automatically injects Envoy sidecars:

```bash
helm repo add eks https://aws.github.io/eks-charts
helm install appmesh-controller eks/appmesh-controller \
  --namespace appmesh-system \
  --set region=us-east-1 \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=arn:aws:iam::123:role/AppMeshRole
```

Label namespace for auto-injection:

```bash
kubectl label namespace my-app appmesh.k8s.aws/sidecarInjectorWebhook=enabled
```

## Observability

Envoy emits metrics and traces automatically — no code changes:

**Metrics** → CloudWatch (via `ENABLE_ENVOY_STATS_TAGS=1`)
**Traces** → X-Ray (via `ENABLE_ENVOY_XRAY_TRACING=1`)

Example: `envoy.cluster.payment-service.upstream_rq_total` — total requests to payment-service.

## App Mesh vs Istio

| Feature | App Mesh | Istio |
|---------|---------|-------|
| Data plane | Envoy | Envoy |
| Control plane | AWS managed | Self-managed (istiod) |
| mTLS | ACM PCA | cert-manager / built-in CA |
| Operational complexity | Low | High |
| Features | Core traffic management | Advanced (circuit breaker, fault injection, mTLS, Wasm plugins) |
| Multi-cluster | Limited | ✅ Multi-cluster support |
| AWS integration | Native (CloudWatch, X-Ray, ACM) | Manual setup |
| Community | AWS-specific | Large CNCF community |

**Choose App Mesh** if: AWS-only, want managed control plane, need quick setup.
**Choose Istio** if: need circuit breakers, fault injection, advanced security policies, or multi-cloud.

## App Mesh vs VPC Lattice

AWS VPC Lattice is the newer alternative — simpler, no sidecars required:
- VPC Lattice provides service-to-service connectivity at the VPC layer
- No Envoy sidecar injection required
- Supports cross-VPC and cross-account routing natively
- Integrates with ALB/NLB target groups

## Common Interview Questions

**Q: How does Envoy sidecar injection work in EKS?**
The App Mesh Controller installs a Mutating Webhook. When a pod is created in a mesh-enabled namespace, the webhook intercepts the pod creation request and injects an `envoy` init container (sets up iptables rules to redirect traffic) and an `envoy` sidecar container (the actual proxy). All traffic in/out of the pod's main container flows through Envoy.

**Q: What does mTLS do and why does it matter?**
Mutual TLS means both the client service and the server service present certificates and verify each other's identity. This prevents a compromised service inside the cluster from making requests to other services (it won't have a valid certificate). App Mesh handles certificate lifecycle via ACM PCA — no manual cert management.

**Q: App Mesh vs Istio — which would you recommend?**
For AWS-focused teams: App Mesh is simpler (managed control plane, native CloudWatch/X-Ray integration). For teams needing advanced features (circuit breakers with `outlierDetection`, fault injection for chaos testing, Wasm plugins for custom logic) or multi-cloud: Istio. Istio has much richer features but higher operational complexity.

**Q: How do you do a canary deployment with App Mesh?**
Create two Virtual Nodes (v1 and v2 pods). Create a Virtual Router with a weighted route: 90% to v1, 10% to v2. Update the Virtual Service to use this router. Monitor error rates and latency per version via CloudWatch metrics. Gradually shift weight to v2, then set 100% to v2 and decommission v1.
