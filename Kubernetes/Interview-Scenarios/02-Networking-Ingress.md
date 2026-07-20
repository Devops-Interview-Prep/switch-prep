# 🎤 Networking & Ingress Incidents
**8 Slides · Service Endpoints, Ingress 502s, NetworkPolicy Traps, CNI Enforcement, externalTrafficPolicy + Q&A**

---

# 🔴 Slide 1 · Scenario: Ingress Returns 502/504 Despite All Pods Running

**🏗️ Setup**
> *A deploy finishes clean — `kubectl get pods` shows every replica `Running`, no restarts, no crash loops — but every request through the Ingress comes back as a Bad Gateway.*

**❓ The Question**
All pods are `Running`. Why is the Ingress still returning 502/504, and how do you find the actual cause?

```
$ curl -I https://api.example.com/v1/orders
HTTP/1.1 502 Bad Gateway
Server: nginx

$ kubectl get pods -n production -l app=orders
NAME                       READY   STATUS    RESTARTS   AGE
orders-7d9f8c6b5d-2xk9p    0/1     Running   0          4m
orders-7d9f8c6b5d-9mqwz    0/1     Running   0          4m
orders-7d9f8c6b5d-lz4rt    0/1     Running   0          4m
```

**🔍 Diagnosis**
1. `Running` only means the container process started — it says nothing about whether the app is ready to serve traffic. Check `READY` column: `0/1` means the readinessProbe is failing.
2. Confirm the Service has zero registered backends — this is the smoking gun:
   ```bash
   kubectl get endpoints orders-svc -n production
   # NAME         ENDPOINTS   AGE
   # orders-svc   <none>      12m
   ```
   An empty `ENDPOINTS` list means the Endpoints controller never added these pods — a pod is only added once it passes readiness, regardless of `Running` status.
3. Confirm it's the probe, not a selector mismatch, by inspecting pod events:
   ```bash
   kubectl describe pod orders-7d9f8c6b5d-2xk9p -n production
   # Warning  Unhealthy  30s (x8 over 4m)  kubelet  Readiness probe failed: Get "http://10.0.1.12:8080/health": dial tcp 10.0.1.12:8080: connect: connection refused
   ```
4. Check the controller logs to confirm it's seeing "no live upstreams," not a config/routing error:
   ```bash
   kubectl logs -n ingress-nginx deploy/ingress-nginx-controller --tail=50
   # 2026/07/20 10:14:02 [error] upstream sent no valid HTTP response, no live upstreams while connecting to upstream
   ```

**✅ Fix**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: orders
  namespace: production
spec:
  template:
    spec:
      containers:
        - name: orders
          image: orders:v3
          ports:
            - containerPort: 8080
          readinessProbe:
            httpGet:
              path: /health         # ← was pointed at "/" (returns 404) — app only serves /health
              port: 8080
            initialDelaySeconds: 10  # ← give the app time to finish DB connection pool warmup
            periodSeconds: 5
            failureThreshold: 3
```

**🛡️ Prevention**
- Always diagnose Service→Endpoints→Pod in that order for any 502/504 — don't start by reading Ingress YAML, the Ingress config is almost never the actual bug (see `../Components/Ingress/Ingress.md`)
- Set `readinessProbe` to a real health endpoint that reflects downstream dependency status (DB, cache), not just "process is alive" — that's what `livenessProbe` is for
- Alert on `kubectl get endpoints <svc>` returning empty for more than 1-2 minutes — this is a leading indicator that fires before user-facing error rates spike

> ⚠️ **Never:** Delete the readinessProbe entirely to "make the 502 go away" — you'll route real traffic to pods that are still warming up or mid-crash, trading a clean 502 for silent request failures and corrupted responses.

---

# 🔴 Slide 2 · Scenario: Default-Deny Egress Policy Breaks DNS Cluster-Wide

**🏗️ Setup**
> *A security engineer applies a "hardening" default-deny-egress NetworkPolicy to the `production` namespace ahead of an audit. Within seconds every service in that namespace starts throwing connection errors — nothing can reach anything, including the database it already had a live connection to.*

**❓ The Question**
Right after applying a default-deny NetworkPolicy, every pod in the namespace starts failing to resolve hostnames. What broke, and how do you fix it without abandoning the deny policy?

```
$ kubectl exec -n production orders-7d9f8c6b5d-2xk9p -- nslookup db.production.svc.cluster.local
;; connection timed out; no servers could be reached

$ kubectl logs orders-7d9f8c6b5d-2xk9p -n production
ERROR: dial tcp: lookup db.production.svc.cluster.local: no such host
ERROR: dial tcp: lookup redis.production.svc.cluster.local: no such host
```

**🔍 Diagnosis**
1. Confirm the new policy is egress-default-deny and has no DNS carve-out:
   ```bash
   kubectl describe networkpolicy default-deny-egress -n production
   # Spec:
   #   PodSelector:     <none> (Allowing all pods in this namespace)
   #   Allowing egress traffic:
   #     <none> (Selected pods are isolated for egress connectivity)
   ```
2. Recognize the pattern immediately: CoreDNS lives in `kube-system`, a different namespace — default-deny-egress blocks the pod's outbound UDP:53 query to it, so *every* hostname lookup times out, not just external ones. This looks like a total outage but it's purely DNS (see `../Components/NetworkPolicy/NetworkPolicy.md`, "Classic DNS-Breakage Gotcha").
3. Confirm CoreDNS's actual labels before writing the fix — don't assume:
   ```bash
   kubectl get pods -n kube-system --show-labels | grep coredns
   # coredns-6d4b75cb6d-abc12   1/1   Running   k8s-app=kube-dns,...
   ```

**✅ Fix**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-egress
  namespace: production
spec:
  podSelector: {}                # ← applies to every pod in the namespace, same scope as the deny policy
  policyTypes:
    - Egress
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system   # ← DNS lives in a different namespace
          podSelector:
            matchLabels:
              k8s-app: kube-dns   # ← confirmed via --show-labels above, don't guess this
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53                # ← TCP 53 needed too: large DNS responses fall back to TCP
```

**🛡️ Prevention**
- Never ship a default-deny-egress policy without a paired allow-DNS-egress policy in the same apply/PR — template them together so one can't land without the other
- Test any new default-deny policy in a non-prod namespace first with a `netshoot` pod (`kubectl run tmp-shell --rm -it --image=nicolaka/netshoot -n production -- /bin/bash` then `dig`) before rolling to production
- Add a synthetic DNS-resolution check as a pre-flight gate in the NetworkPolicy CI/CD pipeline

> ⚠️ **Never:** Apply a namespace-wide default-deny-egress policy directly to production "for the audit" without first applying it to staging — DNS breakage is instant and total, and by the time alerts fire you've already caused an incident across every pod in the namespace.

---

# 🔴 Slide 3 · Scenario: "Secure" NetworkPolicy Has Zero Effect

**🏗️ Setup**
> *A team writes a textbook-correct default-deny-all NetworkPolicy, `kubectl apply` succeeds with no errors, and it shows up cleanly in `kubectl get networkpolicy`. Weeks later, a penetration test report comes back saying pods in that namespace can still reach each other freely — the "isolation" never existed.*

**❓ The Question**
The NetworkPolicy YAML is correct and applies without error, but a pentest proves pods can talk to each other completely unrestricted. How is that possible, and how do you actually fix it?

```
$ kubectl get networkpolicy -n production
NAME               POD-SELECTOR   AGE
default-deny-all   <none>         21d

$ kubectl exec -n production frontend-abc123 -- curl -sv http://payments.production.svc.cluster.local:8443/internal/debug
* Connected to payments.production.svc.cluster.local (10.0.2.14) port 8443
< HTTP/1.1 200 OK              # ← should be blocked; policy claims default-deny
```

**🔍 Diagnosis**
1. `kubectl apply` only validates against the API schema — it never checks whether anything in the cluster is actually capable of enforcing the object. This is the #1 production gotcha with NetworkPolicy (see `../Components/NetworkPolicy/NetworkPolicy.md`).
2. Check which CNI is actually running before assuming the YAML itself is wrong:
   ```bash
   kubectl get pods -n kube-system -o wide | grep -Ei 'flannel|calico|cilium|weave|aws-node'
   # kube-flannel-ds-8h6xz   1/1   Running   0   45d
   # kube-flannel-ds-l2vqk   1/1   Running   0   45d
   ```
3. Flannel in basic/vxlan mode is a pure overlay network with **no policy engine at all** — it programs routes but never reads NetworkPolicy objects. The API object sits in etcd, valid and inert, forever.
4. Cross-check against the CNI enforcement table: Flannel ❌, kubenet ❌, unconfigured AWS VPC CNI ❌, Calico/Cilium/Weave ✅.

**✅ Fix**
```bash
# There is no YAML fix — the policy was always correct. The CNI has to change.

# Option 1: migrate the cluster's CNI to a policy-enforcing one (Calico is the
# common industry-standard choice, disruptive but complete)
helm repo add projectcalico https://docs.tigera.io/calico/charts
helm install calico projectcalico/tigera-operator -n tigera-operator --create-namespace

# Option 2 (EKS specific, lower blast radius): keep the AWS VPC CNI for the
# dataplane, enable the network policy agent for enforcement only
kubectl set env daemonset aws-node -n kube-system ENABLE_NETWORK_POLICY=true

# After migration — re-run the same pentest command; it should now be refused
kubectl exec -n production frontend-abc123 -- curl -sv --max-time 3 \
  http://payments.production.svc.cluster.local:8443/internal/debug
# curl: (28) Connection timed out    # ← policy now actually enforced
```

**🛡️ Prevention**
- Before writing a single NetworkPolicy, verify enforcement is even possible: `kubectl get pods -n kube-system` and cross-reference against the CNI enforcement table — do this on every new cluster, don't assume parity with a previous one
- After every policy change, empirically verify with a throwaway pod (`kubectl run tmp-shell --rm -it --image=nicolaka/netshoot`) attempting the exact connection the policy should block — never trust the YAML's mere existence as proof
- Bake CNI capability checks into cluster-provisioning automation so a non-enforcing CNI can never silently ship to a namespace that assumes isolation

> ⚠️ **Never:** Report a NetworkPolicy as "applied" or "isolation complete" in a security review just because `kubectl get networkpolicy` shows it — that only proves the object exists in etcd, not that any component is reading or enforcing it.

---

# 🔴 Slide 4 · Scenario: Service Has No Endpoints — Selector Mismatch

**🏗️ Setup**
> *A new Service is deployed in front of an existing, healthy Deployment. Pods pass their readiness checks and show `1/1 Running`, but nothing behind the Service ever receives a single request.*

**❓ The Question**
Pods are healthy and ready, but the Service routes nowhere. `kubectl get endpoints my-svc` shows `<none>`. What's wrong and how do you confirm it?

```
$ kubectl get endpoints my-svc -n production
NAME     ENDPOINTS   AGE
my-svc   <none>      8m

$ kubectl get pods -n production -l app=my-app
No resources found in production namespace.
```

**🔍 Diagnosis**
1. `<none>` endpoints with otherwise-healthy pods almost always means the Service's `selector` doesn't match any pod's actual labels — not a readiness problem this time (contrast with Slide 1, where pods existed under the label but failed readiness; here the label query itself returns zero pods).
2. Pull the Service's selector and the pods' real labels side by side:
   ```bash
   kubectl get svc my-svc -n production -o jsonpath='{.spec.selector}'
   # {"app":"my-app"}

   kubectl get pods -n production --show-labels
   # NAME                     READY   STATUS    LABELS
   # myapp-7f9c8d6b-2xk9p     1/1     Running   app=myapp,version=v2
   ```
3. Spot the mismatch: Service selects `app: my-app` (hyphenated), pods are labeled `app: myapp` (no hyphen) — a one-character typo, most likely introduced when the Service manifest was copy-pasted from a different app's template.

**✅ Fix**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-svc
  namespace: production
spec:
  selector:
    app: myapp        # ← corrected to exactly match the pod template's label, not "my-app"
  ports:
    - port: 80
      targetPort: 8080
```

```bash
# Verify the fix — endpoints should populate within seconds
kubectl get endpoints my-svc -n production
# NAME     ENDPOINTS                         AGE
# my-svc   10.0.1.12:8080,10.0.1.13:8080     9m
```

**🛡️ Prevention**
- Generate Service selectors from the same label values used in the Deployment's `template.metadata.labels` — via a shared Helm value or Kustomize base — so they can never drift independently
- Add `kubectl get endpoints` to post-deploy smoke tests in CI; fail the pipeline if any Service's endpoint list is empty
- See `../Components/Service/Service.md` — the Endpoints object is the ground truth for "is this Service actually wired to anything," always check it before touching Ingress or DNS

> ⚠️ **Never:** "Fix" this by loosening the Service selector to `{}` or a broad label just to get *something* matched — you'll silently route traffic to unrelated pods that happen to share a common label.

---

# 🔴 Slide 5 · Scenario: Annotations Silently Stop Working After Ingress Controller Migration

**🏗️ Setup**
> *The platform team migrates the cluster's public-facing Ingress from ingress-nginx to the AWS ALB Ingress Controller for better AWS integration (WAF, ACM certs). Every manifest applies cleanly with zero errors. A week later, product reports that URL rewrites are broken and the canary release for checkout-v2 is sending 100% of traffic to the old version instead of the intended 10%.*

**❓ The Question**
Nothing errored during the migration, but rewrite and canary behavior both silently stopped working. Why, and what's the actual fix?

```yaml
# This applied with no errors or warnings on the new ALB IngressClass:
metadata:
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-weight: "10"
```

**🔍 Diagnosis**
1. Ingress annotations are entirely controller-specific — they're how each controller exposes features the core `networking.k8s.io/v1` spec has no field for. A controller that doesn't recognize an annotation just ignores it: no error, no warning, no event (see `../Components/Ingress/Ingress.md`, "Annotations Are NOT Portable").
2. Confirm which controller is actually driving the Ingress now:
   ```bash
   kubectl get ingress checkout-ingress -n production -o jsonpath='{.spec.ingressClassName}'
   # alb
   ```
3. Every `nginx.ingress.kubernetes.io/*` annotation is meaningless to `ingress.k8s.aws/alb` — it's dead YAML now. Rewrites and nginx-style canary weighting have no ALB equivalent at all in some cases, and a different vocabulary in others.
4. Check the ALB controller's own annotation vocabulary for what actually replaces each one — the answer differs per feature, not a 1:1 swap:

| Old (nginx) | New (ALB) | Notes |
|---|---|---|
| `rewrite-target` | *(none)* | ALB has no native rewrite concept — move rewrite logic into the app or an intermediate proxy |
| `canary` / `canary-weight` | *(none natively)* | ALB doesn't support weighted canary at the Ingress layer — needs a service mesh, or weighted target groups via `alb.ingress.kubernetes.io/actions.<name>` forward-action JSON |
| `ssl-redirect` | `alb.ingress.kubernetes.io/ssl-redirect: '443'` | different annotation key entirely |
| `proxy-body-size` | *(configured on the ALB target group / listener, not per-Ingress)* | |

**✅ Fix**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: checkout-ingress
  namespace: production
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    # Weighted canary re-implemented via ALB's forward action with target-group weights —
    # not a drop-in annotation swap, this is a structurally different mechanism
    alb.ingress.kubernetes.io/actions.checkout-weighted: >
      {"type":"forward","forwardConfig":{"targetGroups":
        [{"serviceName":"checkout-v1-svc","servicePort":80,"weight":90},
         {"serviceName":"checkout-v2-svc","servicePort":80,"weight":10}]}}
spec:
  ingressClassName: alb
  rules:
    - host: checkout.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: checkout-weighted   # ← "use" action, name matches the annotation key
                port:
                  name: use-annotation
```

**🛡️ Prevention**
- Treat every controller migration as a full re-implementation project, not a `kubectl apply` swap — inventory every annotation in use first (`kubectl get ingress -A -o yaml | grep -E 'nginx.ingress|alb.ingress'`) and map each one to its destination-controller equivalent before cutting over
- Re-test rewrites, redirects, auth, and canary behavior explicitly post-migration — none of these fail loudly, they just quietly behave differently
- Consider Gateway API for new work specifically because it standardizes route types across controllers and removes this exact class of migration risk (see `../Components/Ingress/Ingress.md`, "Gateway API")

> ⚠️ **Never:** Assume a clean `kubectl apply` after a controller migration means behavior is preserved — annotations are silently ignored, not validated, so "no errors" tells you nothing about functional parity.

---

# 🔴 Slide 6 · Scenario: Real Client IP Lost Behind NodePort/LoadBalancer

**🏗️ Setup**
> *A compliance requirement mandates IP-allowlisting at the application layer for a partner API. After rollout, every request — from every partner, from every source IP — shows up in application logs as coming from one of a handful of internal node IPs.*

**❓ The Question**
The application needs the real client IP for allowlisting, but every request appears to originate from a cluster node, not the actual client. Why, and how do you fix it?

```
$ kubectl logs api-gateway-7d9f8c6b5d-2xk9p -n production --tail=5
[10.0.4.11] GET /v1/partner/orders     # ← this is a node's internal IP, not the partner's real IP
[10.0.4.12] GET /v1/partner/orders
[10.0.4.11] GET /v1/partner/orders
```

**🔍 Diagnosis**
1. Check the Service's traffic policy — this is almost always the cause when the real source IP disappears at a NodePort/LoadBalancer boundary:
   ```bash
   kubectl get svc api-gateway -n production -o jsonpath='{.spec.externalTrafficPolicy}'
   # Cluster
   ```
2. Understand the mechanism: with `externalTrafficPolicy: Cluster` (the default), any node can accept traffic on the NodePort and forward it internally to a pod on *any* node, even a different one — that internal hop rewrites the source IP via SNAT so the return path works, which destroys the original client IP by the time it reaches the pod (see `../Components/Service/Service.md`, "externalTrafficPolicy: Cluster vs Local").
3. Confirm this isn't a proxy-protocol/X-Forwarded-For issue at the LB layer instead — check whether the cloud LB is even configured to preserve/pass the client IP header, since some LoadBalancer types need that explicitly too. In this case the LB is passing it correctly; the SNAT is happening at the kube-proxy hop, confirmed by the IP being a node IP, not the LB's own IP.

**✅ Fix**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: api-gateway
  namespace: production
spec:
  type: LoadBalancer
  externalTrafficPolicy: Local   # ← only nodes with a matching pod accept traffic; no SNAT hop, real client IP preserved
  selector:
    app: api-gateway
  ports:
    - port: 443
      targetPort: 8443
```

```bash
# Verify — logs should now show real external client IPs
kubectl logs api-gateway-7d9f8c6b5d-2xk9p -n production --tail=5
# [203.0.113.44] GET /v1/partner/orders   # ← real partner IP, allowlisting now works
```

**🛡️ Prevention**
- Document the `Local` vs `Cluster` trade-off explicitly wherever this Service is defined: `Local` means only nodes that actually have a pod scheduled get traffic — if a pod runs on 2 of 10 nodes, those 2 nodes take 100% of the load, and cloud LB health checks must reflect per-node pod presence or you'll route to a node with no local pod
- Pair `externalTrafficPolicy: Local` with a `PodDisruptionBudget` and adequate replica spread (anti-affinity across nodes) so the uneven-distribution trade-off doesn't concentrate load dangerously during a rolling update
- For Ingress-fronted HTTP traffic instead of raw Service exposure, prefer real client IP via `X-Forwarded-For`/proxy protocol at the controller — this scenario is specific to NodePort/LoadBalancer-type Services bypassing Ingress

> ⚠️ **Never:** "Fix" the missing client IP by trusting an `X-Forwarded-For` header without also locking down who can set it — if the Service is reachable directly (not only through a trusted LB), a client can simply forge that header and defeat the allowlist entirely; `externalTrafficPolicy: Local` fixes it at the network layer instead of trusting a spoofable header.

---

# 🔴 Slide 7 · Scenario: Two NetworkPolicies Combine Into an Unintended Allow

**🏗️ Setup**
> *Security applies a strict default-deny-all policy to the `payments` namespace. Separately, the platform team applies a cluster-wide "allow monitoring to scrape metrics" policy using a loose namespace label selector. A later audit finds the `payments` namespace is reachable from a namespace nobody intended to grant access to.*

**❓ The Question**
Both policies looked correct in isolation. Combined, they allow traffic a security review explicitly assumed was blocked. How does this happen, and how do you audit for it?

```yaml
# Policy A — payments namespace, looks airtight
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: payments
spec:
  podSelector: {}
  policyTypes: [Ingress, Egress]
  ingress: []
  egress: []
---
# Policy B — platform team's "allow monitoring" policy, applied to payments too
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-monitoring-scrape
  namespace: payments
spec:
  podSelector: {}
  policyTypes: [Ingress]
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              scrape: "true"      # ← intended to match only the "monitoring" namespace
```

**🔍 Diagnosis**
1. NetworkPolicies are purely additive — there is no explicit deny and no precedence between policies. If pod `payments` is selected by both policies above, the effective ruleset is the *union*: default-deny-all narrows nothing once anything else grants access; `allow-monitoring-scrape` widens it back open for anything matching its selector (see `../Components/NetworkPolicy/NetworkPolicy.md`, "Multiple Policies: Purely Additive").
2. The actual bug: the `scrape: "true"` namespace label was applied more broadly than intended — check every namespace carrying that label, not just the one you meant:
   ```bash
   kubectl get namespaces --show-labels | grep 'scrape=true'
   # monitoring        scrape=true,...
   # staging-debug      scrape=true,...   # ← unintended: a developer copied a namespace label template
   ```
3. `staging-debug` now satisfies Policy B's `namespaceSelector` and gets ingress into `payments`, completely bypassing the intent of the default-deny-all policy — and neither policy's YAML is "wrong" in isolation, which is exactly why this passes casual review.
4. Systematically audit every policy touching a given pod, not just the one you expect to be relevant:
   ```bash
   kubectl get networkpolicy -n payments -o yaml
   # review every policy whose podSelector could match "payments" pods —
   # a policy applied for a completely unrelated purpose (monitoring) can still
   # grant access into this namespace if podSelector: {} selects everything
   ```

**✅ Fix**
```yaml
# Narrow the namespaceSelector to something that can't collide — match on name,
# not on a broad boolean-style label anyone might reuse
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-monitoring-scrape
  namespace: payments
spec:
  podSelector:
    matchLabels:
      app: payments-api      # ← also narrow which pods this even applies to, not podSelector: {}
  policyTypes: [Ingress]
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: monitoring   # ← immutable, unique, can't be accidentally duplicated
      ports:
        - protocol: TCP
          port: 9100                                     # ← also scope to the metrics port only, not all ports
```

**🛡️ Prevention**
- Prefer `kubernetes.io/metadata.name` (the automatic, immutable, unique namespace-name label) over custom boolean-ish labels like `scrape: "true"` for any `namespaceSelector` used in a security-relevant policy — custom labels get reused by accident, the name label can't be
- Treat NetworkPolicy review as a full-namespace exercise: for any pod, list and read *every* policy that could select it (`kubectl get networkpolicy -A -o yaml` and grep for matching selectors), not just the policy you're currently editing — the additive model means the effective rule set is never fully visible from one file
- Add a periodic automated diff/report of "which namespaces can reach `payments`" derived from actual applied policies, not from design docs, so drift like this surfaces before an external audit does

> ⚠️ **Never:** Sign off a security review by reading only the policy that was intentionally written to lock the namespace down — NetworkPolicy has no deny primitive, so a completely unrelated policy elsewhere in the same namespace (or matching via a loose namespace label) can silently widen access back open.

---

# 🎤 Slide 8 · Follow-up Q&A

---

### Q: A Service isn't routing traffic to any pod. What's your systematic checklist?
- Start at the Service, not the Ingress: `kubectl get endpoints <svc>` — empty or `<none>` is the single most important signal
- If endpoints are empty: check `kubectl get pods --show-labels` against the Service's `spec.selector` for a mismatch (typo, wrong app label) — see Slide 4
- If matching pods exist but still no endpoints: check `kubectl get pods -o wide` for `READY 0/1` — the pod is `Running` but failing its readinessProbe, so it's never added — see Slide 1
- If endpoints are populated but traffic still doesn't arrive: check `targetPort` vs the container's actual listening port, then check NetworkPolicy (`kubectl get networkpolicy -n <ns>`) for anything that could be blocking ingress to those pods — but only after confirming the CNI enforces policy at all
- Only after all of the above check the Ingress/controller layer — Ingress config is rarely the actual bug when the symptom is "no traffic reaches pods" (see `../Components/Service/Service.md`, `../Components/Ingress/Ingress.md`)

> 💬 **Say:** "I always work inside-out: Endpoints first, then pod readiness, then NetworkPolicy, and only then the Ingress config — in that order, because the Ingress is almost never actually broken when the real problem is that the Service has nothing behind it."

---

### Q: How do you verify a NetworkPolicy is actually being enforced before trusting it as a security boundary?
- `kubectl apply` on a NetworkPolicy only validates schema — it proves nothing about enforcement, since any CNI will happily store an object it never reads
- First check which CNI is running: `kubectl get pods -n kube-system -o wide | grep -Ei 'flannel|calico|cilium|weave|aws-node'` — Flannel and kubenet don't enforce policy at all; AWS VPC CNI only does with the network policy agent explicitly enabled
- Then verify empirically, not just structurally: spin up a throwaway pod (`kubectl run tmp-shell --rm -it --image=nicolaka/netshoot -n <ns> -- /bin/bash`) and attempt the exact connection the policy is supposed to block — a timeout confirms enforcement, a successful connection means the policy is dead weight regardless of what the YAML says
- For multi-policy namespaces, also audit for unintended additive allows: list every policy that could select the target pod (`kubectl get networkpolicy -n <ns> -o yaml`), because NetworkPolicy has no deny primitive and an unrelated policy elsewhere can silently widen access back open — see Slide 7

> 💬 **Say:** "NetworkPolicy YAML existing in etcd tells you nothing — I check the CNI's enforcement capability first, then prove it empirically with a test pod attempting the blocked connection, because that's the only way to know it's not just a false sense of security."

---
