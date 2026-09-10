# APIService — Kubernetes API Aggregation Layer

> APIService is how you teach the Kubernetes API server to **proxy requests to a completely external API server** you run yourself. It's the senior-level counterpart to CRDs — where CRDs extend Kubernetes by adding stored resources, APIService extends it by adding a live, separately-running API server behind the same `/apis/` URL tree.

---

## What APIService Actually Is

The Kubernetes API is not a monolith. The main `kube-apiserver` knows about core resources (`Pod`, `Deployment`, etc.), but it also acts as a **reverse proxy** for additional API groups served by extension API servers.

An **`APIService`** object registers one such extension with the aggregation layer:

```yaml
apiVersion: apiregistration.k8s.io/v1
kind: APIService
metadata:
  name: v1beta1.metrics.k8s.io         # always <version>.<group>
spec:
  service:
    name: metrics-server                # the Service in front of your API server
    namespace: kube-system
    port: 443
  group: metrics.k8s.io                # the API group being served
  version: v1beta1                     # the version being served
  insecureSkipTLSVerify: false         # production: always false
  caBundle: <base64-encoded-CA>        # CA that signed the extension server's cert
  groupPriorityMinimum: 100            # priority when multiple versions of same group exist
  versionPriority: 100
```

Once this is applied:
- `kubectl get --raw /apis/metrics.k8s.io/v1beta1` → proxied to `metrics-server`
- `kubectl top pods` → hits `kube-apiserver` → proxied to `metrics-server` → returns live metrics
- `kube-apiserver` handles **authn/authz** first (RBAC applies!), then proxies the request

---

## How the Aggregation Layer Works — Request Flow

```
kubectl top pods
      │
      ▼
kube-apiserver (port 6443)
      │
      ├── Is this a core/built-in resource? → handle directly
      │
      └── Is there an APIService registered for this group/version?
              │
              ▼
        Look up APIService "v1beta1.metrics.k8s.io"
              │
              ▼
        Proxy request → metrics-server.kube-system.svc:443
              │
              ▼
        metrics-server returns JSON → kube-apiserver passes it back
              │
              ▼
        kubectl displays output
```

**Key point:** The main `kube-apiserver` still handles:
- **Authentication** — who are you? (service account token, client cert, etc.)
- **Authorization** — are you allowed to do this? (RBAC ClusterRole for `metrics.k8s.io`)

Your extension server only needs to handle the business logic of the actual request. Auth is already done by the time the request reaches it.

---

## Real-World Examples

| APIService | What it serves | Who registers it |
|---|---|---|
| `v1beta1.metrics.k8s.io` | Node/Pod CPU + memory (used by `kubectl top` and HPA) | `metrics-server` deployment |
| `v1beta1.custom.metrics.k8s.io` | Custom application metrics for HPA | Prometheus Adapter |
| `v1beta1.external.metrics.k8s.io` | External metrics (Datadog, CloudWatch) for HPA | Datadog Cluster Agent / KEDA |
| `v1alpha1.wardle.example.com` | Kubernetes sample extension (used in docs) | sample-apiserver |

**This is why HPA on custom metrics requires Prometheus Adapter:** HPA calls `/apis/custom.metrics.k8s.io/v1beta1/...` — that endpoint only exists if Prometheus Adapter is installed and registers its `APIService`.

---

## APIService vs CRD — When to Use Which

| Concern | CRD | APIService (Aggregated API) |
|---|---|---|
| **Storage** | Always etcd — standard K8s storage | Anywhere — your own DB, in-memory, external system |
| **Data persistence** | Objects persist in etcd between restarts | You decide (metrics-server stores nothing — live queries only) |
| **Business logic in request path** | Not possible — pure CRUD + webhooks | Full control — compute anything on every GET/LIST/WATCH |
| **Operational complexity** | Low — one YAML, zero additional infra | High — you run, secure (TLS), and HA your own API server |
| **`kubectl` compatibility** | Full — discovery works automatically | Full — clients see it as native K8s API |
| **Subresources (e.g. `/pods/exec`)** | Only status/scale subresources | Arbitrary subresources — define your own |
| **Watch semantics** | Built in (etcd watches) | You must implement watch yourself |
| **When to choose** | Default for everything | Only when CRD's `etcd + CRUD` model structurally can't work |

**Practical rule:** If you're asking "should I use CRD or APIService?" — use a CRD. The only times you genuinely need APIService:
1. The data is **never stored** — it's computed live every request (like metrics)
2. The data **lives in an external system** that isn't Kubernetes-aware
3. You need **custom subresources** beyond `/status` and `/scale`

---

## TLS and Authentication Requirements

Extension servers MUST use TLS (HTTPS on port 443) because `kube-apiserver` proxies requests using mutual TLS:

```
kube-apiserver ──(mTLS)──► extension-server
```

**What the extension server must do:**
1. Serve on HTTPS — obtain a certificate signed by a CA
2. Provide that CA in the `APIService.spec.caBundle` field (so the aggregator can verify)
3. Trust the aggregator's client certificate for request auth (the aggregator presents a cert when proxying)

**Generating certs for a custom extension server:**

```bash
# Option 1: Use cert-manager to issue a cert for your service
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: my-apiserver-cert
  namespace: my-system
spec:
  secretName: my-apiserver-tls
  dnsNames:
    - my-apiserver.my-system.svc
    - my-apiserver.my-system.svc.cluster.local
  issuerRef:
    name: cluster-issuer
    kind: ClusterIssuer

# Option 2: Use kube-apiserver's built-in signing (simpler for dev)
# Request a CertificateSigningRequest and approve with kubectl
```

---

## Checking APIService Status

```bash
# List all registered APIServices
kubectl get apiservice

# Output:
# NAME                              SERVICE                      AVAILABLE   AGE
# v1.                               Local                        True        45d
# v1beta1.metrics.k8s.io            kube-system/metrics-server   True        45d
# v1beta2.custom.metrics.k8s.io     monitoring/prometheus-adapter True       20d
# v1alpha1.broken.example.com       my-ns/my-apiserver           False       5m

# Get details of a specific APIService
kubectl describe apiservice v1beta1.metrics.k8s.io
# Shows: Status, Conditions (Available/Unavailable + reason)

# Why is an APIService unavailable?
kubectl describe apiservice v1beta1.metrics.k8s.io | grep -A5 Conditions
# Conditions:
#   Type:    Available
#   Status:  False
#   Reason:  ServiceNotFound  ← the Service it points to doesn't exist
#   Message: service/metrics-server in kube-system does not exist
```

**Common `AVAILABLE=False` reasons:**

| Reason | Meaning | Fix |
|---|---|---|
| `ServiceNotFound` | The `spec.service` doesn't exist | Deploy the extension server |
| `EndpointNotFound` | Service exists but no ready Pods behind it | Check the Pod logs + readiness probe |
| `FailedDiscoveryCheck` | kube-apiserver can't reach the extension server | Check NetworkPolicy, TLS cert, port |
| `MissingEndpoints` | No endpoints registered on the Service | Scaling/crash issue with the extension Pod |

---

## Local APIServices (Built-in Groups)

Some `APIService` objects have `Service: Local` — these are served directly by `kube-apiserver` itself, not proxied:

```bash
kubectl get apiservice | grep Local
# v1.                    Local    True    45d   ← core/v1 (Pods, Services, etc.)
# v1.apps                Local    True    45d   ← Deployments, StatefulSets
# v1.batch               Local    True    45d   ← Jobs, CronJobs
```

These are automatically created and managed by the API server itself — you never create or modify them.

---

## Writing a Custom Extension Server

For advanced use cases, you can build your own:

```go
// The Kubernetes project provides a library: k8s.io/apiserver
// It handles: authentication delegation, authorization delegation,
// discovery, OpenAPI schema generation, admission webhooks

// Minimal custom apiserver structure:
import (
    "k8s.io/apiserver/pkg/server"
    "k8s.io/apiserver/pkg/server/options"
)

func main() {
    opts := options.NewRecommendedOptions(etcdPath, codec)
    // configure TLS, auth delegation, etc.
    
    config, _ := opts.Config()
    server, _ := config.Complete().New("my-apiserver", server.NewEmptyDelegate())
    server.GenericAPIServer.Run(stopCh)
}
```

Most teams use [`apiserver-builder`](https://github.com/kubernetes-sigs/apiserver-builder-alpha) or the [sample-apiserver](https://github.com/kubernetes/sample-apiserver) as a starting point rather than building from scratch.

---

## Diagnosing "kubectl top" Not Working

`kubectl top` is one of the most common places where APIService issues surface:

```bash
kubectl top pods
# Error from server (ServiceUnavailable): the server is currently unable
# to handle the request (get pods.metrics.k8s.io)

# Step 1: Is the APIService registered?
kubectl get apiservice v1beta1.metrics.k8s.io
# NAME                        SERVICE                    AVAILABLE   AGE
# v1beta1.metrics.k8s.io     kube-system/metrics-server  False      5m

# Step 2: Why is it unavailable?
kubectl describe apiservice v1beta1.metrics.k8s.io
# Reason: FailedDiscoveryCheck
# Message: no response from https://10.96.10.45:443/apis/metrics.k8s.io/v1beta1

# Step 3: Is metrics-server Pod running?
kubectl get pods -n kube-system -l k8s-app=metrics-server
# NAME                             READY   STATUS    RESTARTS
# metrics-server-7d98d5f9-x2k4n   0/1     Running   0    ← 0/1 = not ready

# Step 4: Why is it not ready?
kubectl describe pod -n kube-system metrics-server-7d98d5f9-x2k4n
# Readiness probe failing: HTTP probe failed: x509: certificate signed by unknown authority
# ← needs --kubelet-insecure-tls flag (or proper cert config)

# Fix (dev/test only — not for production):
kubectl patch deployment metrics-server -n kube-system \
  --type='json' \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
```

---

## Interview Q&A

**Q: What is an APIService in Kubernetes?**
An `APIService` object registers an external API server with the Kubernetes aggregation layer. Once registered, the main `kube-apiserver` proxies any request for that API group/version to the registered extension server. This lets you extend the Kubernetes API with custom endpoints that serve live-computed data, not just stored objects. The classic example is `metrics-server`, which registers `v1beta1.metrics.k8s.io` so that `kubectl top` and HPA can get live CPU/memory data.

**Q: What's the difference between CRDs and APIService?**
CRDs let the built-in API server store and serve custom objects in etcd — zero additional infrastructure, pure CRUD plus optional webhooks. APIService runs a genuinely separate API server that you build, deploy, and operate — it can serve any data from any source, but it costs you significant operational overhead (TLS, HA, auth delegation). Use CRDs by default; use APIService only when CRD's storage model structurally doesn't fit — like serving live metrics that are never persisted.

**Q: Why does HPA on custom metrics need Prometheus Adapter?**
HPA fetches metrics by calling the Kubernetes API at `/apis/custom.metrics.k8s.io/v1beta1/...`. That API group doesn't exist by default — it only exists if something registers an `APIService` for `custom.metrics.k8s.io`. Prometheus Adapter is that something — it runs a small extension API server that queries Prometheus on each request and translates the result into Kubernetes metrics API format. Without it, HPA has no endpoint to call and can't scale on custom metrics.

**Q: An APIService shows `AVAILABLE=False`. How do you debug it?**
`kubectl describe apiservice <name>` shows the condition with a reason and message. Common reasons: `ServiceNotFound` (deploy the extension server), `EndpointNotFound` (Pod not ready — check logs and readiness probe), `FailedDiscoveryCheck` (TLS cert issue or network policy blocking the aggregator from reaching the extension server — check if `kube-apiserver` can reach the Service, check cert CA bundle in APIService spec). Always start with the Pod logs of the extension server — it usually logs the exact error.

**Q: Does RBAC apply to extension APIs registered via APIService?**
Yes — `kube-apiserver` handles authentication and authorization before proxying. So RBAC ClusterRoles and RoleBindings referencing the extension API group work exactly like for built-in resources. The extension server itself does NOT need to re-implement authn/authz — it receives requests with the user's identity already verified. It can implement additional authorization if needed, but the Kubernetes RBAC layer is always the first check.
