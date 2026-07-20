# 🎤 Security, RBAC & Admission Control Incidents
**7 Slides · Admission Webhooks, RBAC, Pod Security Admission, ServiceAccount Tokens, OPA Gatekeeper**

---

# 🔴 Slide 1 · Scenario: The Webhook That Bricked The Cluster

**🏗️ Setup**
> *Pages start firing from every team at once. Nobody can deploy, scale, or even patch a ConfigMap. It's 20 minutes before your own biggest customer's release window.*

**❓ The Question**
Every `kubectl apply` in the cluster — Pods, Deployments, basically anything — is suddenly failing. Walk me through your incident response, right now, in order.

```
Error from server (InternalError): error when creating "app.yaml": Internal error occurred:
failed calling webhook "policy.example.com": failed to call webhook: Post
"https://gatekeeper-webhook.gatekeeper-system.svc:443/v1/admit": context deadline exceeded
```

**🔍 Diagnosis**
1. Read the error — it names the webhook (`policy.example.com`) and the exact failure mode (`context deadline exceeded`, not a policy denial). This is an *unreachable webhook*, not a legitimate rejection.
2. Check the webhook's `failurePolicy` — a cluster-wide outage on every matching resource only happens if it's set to `Fail`: `kubectl get validatingwebhookconfigurations policy.example.com -o yaml`.
3. Check whether the backing Service actually has healthy endpoints: `kubectl get endpoints gatekeeper-webhook -n gatekeeper-system` and `kubectl get pods -n gatekeeper-system -o wide`.
4. Check the webhook pod's own state and recent history: `kubectl describe pod -n gatekeeper-system -l control-plane=controller-manager` and `kubectl logs -n gatekeeper-system -l control-plane=controller-manager --previous`.

**✅ Fix**
```bash
# Step 1: confirm the actual root cause before touching enforcement
kubectl get pods -n gatekeeper-system -o wide
# gatekeeper-controller-manager-7f9d... 0/1 OOMKilled  CrashLoopBackOff  6  4m
kubectl describe pod -n gatekeeper-system gatekeeper-controller-manager-7f9d... | grep -A3 "Last State"
# Last State: Terminated, Reason: OOMKilled           # ← root cause: memory limit too low under load

# Step 2: fastest cluster-wide unblock — flip failurePolicy open (does NOT fix the webhook, buys time)
kubectl patch validatingwebhookconfiguration policy.example.com \
  --type='json' -p='[{"op":"replace","path":"/webhooks/0/failurePolicy","value":"Ignore"}]'
# ← CAVEAT: every constraint this webhook enforces is now UNENFORCED cluster-wide until reverted

# Step 3 (only if patch doesn't land fast enough, or the webhook object itself is broken): delete it outright
# kubectl delete validatingwebhookconfiguration policy.example.com

# Step 4: fix the real problem — bump memory limits, then re-tighten
kubectl set resources deployment gatekeeper-controller-manager -n gatekeeper-system \
  --limits=memory=512Mi --requests=memory=256Mi   # ← was 128Mi, OOMKilled under normal audit load
kubectl rollout status deployment gatekeeper-controller-manager -n gatekeeper-system

# Step 5: once healthy, restore enforcement
kubectl patch validatingwebhookconfiguration policy.example.com \
  --type='json' -p='[{"op":"replace","path":"/webhooks/0/failurePolicy","value":"Fail"}]'
```

**🛡️ Prevention**
- Run the webhook Deployment with 2+ replicas and a `PodDisruptionBudget` — it is now load-bearing infrastructure, not just another app.
- Set `namespaceSelector` to exclude `kube-system` and the webhook's own namespace, so its own recovery pod can never be blocked by itself.
- Keep `timeoutSeconds` short (2–10s) so a hung webhook fails fast instead of hanging every API call in the cluster.
- Roll out any *new* webhook with `failurePolicy: Ignore` first, prove stability, then flip to `Fail` — never ship straight to `Fail`.

> ⚠️ **Never:** Reach for `failurePolicy: Ignore` or `kubectl delete` as your first move before confirming it's actually an outage and not a legitimate policy denial — read the error message first. And never leave it patched to `Ignore` after the incident; that silently disables enforcement with no alert until someone notices in an audit.

See: [AdmissionWebhooks.md](../Components/AdmissionWebhooks/AdmissionWebhooks.md), [OPAGatekeeper.md](../Components/OPAGatekeeper/OPAGatekeeper.md)

---

# 🔴 Slide 2 · Scenario: The "Read-Only" Role That Leaked Every Secret

**🏗️ Setup**
> *A security audit flags that the on-call engineer's debugging access — supposedly view-only — was actually used to read the plaintext value of the payments database password three weeks before an incident.*

**❓ The Question**
The `oncall-viewer` Role only grants what looks like read access. How did it leak every Secret in the namespace, and how do you fix it?

```yaml
# The role that "just grants read access" — audit finding
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: oncall-viewer
  namespace: payments
rules:
  - apiGroups: [""]
    resources: ["pods", "deployments", "secrets"]
    verbs: ["list", "watch"]   # ← the actual problem, not obviously so
```

**🔍 Diagnosis**
1. Check the exact verbs granted on `secrets`: `kubectl describe role oncall-viewer -n payments` — `list`/`watch`, not `get`.
2. Understand why that matters: `get` requires already knowing a specific Secret's name and returns only that one object; `list`/`watch` return the **full `data` field of every Secret** matching the query — effectively read access to all credentials in the namespace, discoverable without prior knowledge of names.
3. Confirm the actual blast radius by impersonating the bound identity: `kubectl auth can-i list secrets --as=system:serviceaccount:payments:oncall-viewer -n payments`.
4. Audit for the same pattern cluster-wide — this is rarely a one-off.

**✅ Fix**
```yaml
# SAFER — get only, scoped to explicit named secrets, no wildcard discovery
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: oncall-viewer
  namespace: payments
rules:
  - apiGroups: [""]
    resources: ["pods", "deployments"]
    verbs: ["get", "list", "watch"]        # ← fine for pods/deployments — no equivalent data-exfil risk
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get"]                          # ← get, never list/watch
    resourceNames: ["app-db-conn"]          # ← explicit allowlist — the one secret debugging actually needs
```

```bash
# Verify the fix removed the blast radius
kubectl auth can-i list secrets --as=system:serviceaccount:payments:oncall-viewer -n payments
# no

kubectl auth can-i get secrets --as=system:serviceaccount:payments:oncall-viewer -n payments
# yes   (bounded to resourceNames above — auth can-i doesn't show resourceNames scoping directly,
#        so also confirm by attempting a get on an out-of-list secret and expecting Forbidden)

# Cluster-wide audit for the same pattern
kubectl get roles,clusterroles -A -o json | \
  jq -r '.items[] | select(.rules[]? | .resources[]? == "secrets" and (.verbs[]? == "list" or .verbs[]? == "watch")) | .metadata.namespace + "/" + .metadata.name'
```

**🛡️ Prevention**
- Never grant `list`/`watch` on `secrets` in a role marketed as "read-only" or "viewer" — treat it as equivalent to full data access.
- If a team says "just read access for debugging," default to `get` + `resourceNames`, not a blanket verb list.
- Run the audit query above on a schedule (quarterly at minimum) — this pattern reappears constantly because it "looks safe" to whoever wrote it.

> ⚠️ **Never:** Assume a role is safe because it doesn't include `create`/`update`/`delete` — RBAC's danger isn't only in the write verbs; `list`/`watch` on `secrets` is a read-only exfiltration primitive.

See: [RBAC.md](../Components/RBAC/RBAC.md), [ConfigMapSecret.md](../Components/ConfigMapSecret/ConfigMapSecret.md)

---

# 🔴 Slide 3 · Scenario: Pod Security Admission Breaks a Working Deployment

**🏗️ Setup**
> *The platform team rolls out `restricted` Pod Security Admission on the `checkout` namespace overnight as part of a compliance push. By morning, the checkout service's Deployment can't roll a single new pod.*

**❓ The Question**
A previously-fine Deployment now fails to create pods with this error. Diagnose it and give the corrected spec — and tell me what should have happened differently during rollout.

```
Error creating: pods "checkout-7d9f8b-x2k4p" is forbidden: violates PodSecurity "restricted:latest":
allowPrivilegeEscalation != false (container "checkout" must set securityContext.allowPrivilegeEscalation=false),
unrestricted capabilities (container "checkout" must set securityContext.capabilities.drop=["ALL"]),
runAsNonRoot != true (pod or container "checkout" must set securityContext.runAsNonRoot=true)
```

**🔍 Diagnosis**
1. Read the message — PSA names every violated field explicitly; this is not RBAC and not a webhook timeout, it's the `restricted` level rejecting an unhardened pod spec.
2. Confirm the namespace's actual PSA labels: `kubectl get ns checkout --show-labels` — likely `enforce=restricted` with no prior `warn`/`audit` burn-in.
3. Diff the Deployment's current `securityContext` against what `restricted` requires: no `allowPrivilegeEscalation: false`, no `capabilities.drop: ["ALL"]`, no `runAsNonRoot: true` / `runAsUser`.
4. Confirm this wasn't a one-off — check how many other Deployments in the namespace are equally unhardened before assuming this is the only casualty.

**✅ Fix**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: checkout
  namespace: checkout
spec:
  template:
    spec:
      securityContext:
        runAsNonRoot: true      # ← validation gate: rejects if effective UID resolves to 0
        runAsUser: 10001        # ← explicit non-root UID, pairs with runAsNonRoot
        seccompProfile:
          type: RuntimeDefault  # ← required by restricted
      containers:
        - name: checkout
          image: registry.example.com/checkout:1.4.2
          securityContext:
            allowPrivilegeEscalation: false   # ← required by restricted
            capabilities:
              drop: ["ALL"]                    # ← required by restricted
              add: ["NET_BIND_SERVICE"]         # ← only if binding to a port <1024 as non-root
            readOnlyRootFilesystem: true
          volumeMounts:
            - name: tmp
              mountPath: /tmp                   # ← writable scratch since root fs is now read-only
      volumes:
        - name: tmp
          emptyDir: {}
```

```bash
# Validate before applying for real
kubectl apply --dry-run=server -f checkout-deployment.yaml -n checkout
```

**🛡️ Prevention**
- Use the safe rollout pattern: `pod-security.kubernetes.io/warn=restricted` and `audit=restricted` first, watch warnings/audit logs across a full deploy cycle, fix flagged workloads, only then flip `enforce=restricted`.
- Never jump a live, populated namespace straight to `enforce` — that's exactly how this incident happened.
- Bake the hardened `securityContext` block into the org's base Deployment template/Helm chart so new services are `restricted`-compliant by default, not retrofitted under incident pressure.

> ⚠️ **Never:** "Fix" this by loosening the namespace back to `baseline` or `privileged` to unblock the release — that reverts the actual security posture the rollout was trying to establish; harden the workload instead.

See: [SecurityContext.md](../Components/SecurityContext/SecurityContext.md)

---

# 🔴 Slide 4 · Scenario: The Leaked Legacy ServiceAccount Token

**🏗️ Setup**
> *A security scan of an old CI build log — accidentally left public for months — turns up what looks like a Kubernetes ServiceAccount JWT in plaintext.*

**❓ The Question**
A ServiceAccount token has been sitting in a leaked CI log. How bad is this, and what do you do about it?

**🔍 Diagnosis**
1. Determine the token's type first — decode the JWT and check `kubernetes.io/serviceaccount/secret.name` claims, or check whether it's a legacy Secret-based token vs a short-lived projected token: `kubectl get secrets -n ci --field-selector type=kubernetes.io/service-account-token`.
2. If it's legacy: these are **non-expiring by default** — valid until someone manually deletes the backing Secret. A token leaked "months ago" in an old build log has potentially been usable this entire time.
3. Check what the ServiceAccount can actually do — the real blast radius: `kubectl get rolebindings,clusterrolebindings -A -o json | jq '.items[] | select(.subjects[]?.name=="ci-deployer")'`.
4. Check API server audit logs for any activity from that identity in the window since the leak, to determine if it was actually exploited.

**✅ Fix**
```bash
# Step 1: kill the leaked credential immediately — deleting the Secret invalidates the token
kubectl get secrets -n ci --field-selector type=kubernetes.io/service-account-token
kubectl delete secret ci-deployer-token-x7k2p -n ci
# ← any caller presenting this token now gets 401 Unauthorized immediately

# Step 2: rotate — a new legacy Secret auto-regenerates only on pre-1.24 clusters;
# on modern clusters, nothing regenerates automatically, which is the point (see below)
kubectl get sa ci-deployer -n ci -o yaml   # confirm no lingering secret references

# Step 3: migrate off legacy tokens entirely — use TokenRequest-based projected tokens
```
```yaml
# Modern pattern: short-lived, audience-bound token via projected volume — never a Secret object
apiVersion: v1
kind: Pod
metadata:
  name: ci-runner
  namespace: ci
spec:
  serviceAccountName: ci-deployer
  containers:
    - name: runner
      image: ci-runner:2.1
      volumeMounts:
        - name: token
          mountPath: /var/run/secrets/tokens
  volumes:
    - name: token
      projected:
        sources:
          - serviceAccountToken:
              path: api-token
              expirationSeconds: 3600   # ← auto-rotated by kubelet before expiry, unusable after
              audience: ci-internal      # ← scoped — useless if leaked outside this specific consumer
```

**🛡️ Prevention**
- On clusters 1.24+, long-lived Secret-based tokens are **not auto-created** for new ServiceAccounts by default — this class of leak mostly can't happen for anything created post-upgrade. Confirm the cluster version and whether any legacy SAs predate the upgrade.
- Audit for any surviving legacy tokens: `kubectl get secrets -A --field-selector type=kubernetes.io/service-account-token`, and migrate consumers off them deliberately rather than leaving them as an unused-but-live credential.
- Set `automountServiceAccountToken: false` on ServiceAccounts/Pods that never call the Kubernetes API at all — no token, no leak surface.
- Never let raw tokens flow into CI logs in the first place — scrub secrets from build output as a pipeline-level control, independent of token lifetime.

> ⚠️ **Never:** Treat "rotate the token" as done once you've deleted the Secret — also check what that identity's RBAC bindings actually grant and whether audit logs show it was used maliciously in the exposure window; a rotated credential doesn't undo actions already taken with it.

See: [RBAC.md](../Components/RBAC/RBAC.md)

---

# 🔴 Slide 5 · Scenario: The RoleBinding to `cluster-admin`

**🏗️ Setup**
> *During an incident review, someone points out that a RoleBinding in the `analytics` namespace references the built-in `cluster-admin` ClusterRole. The engineer who wrote it insists "it's fine, it's just scoped to that one namespace."*

**❓ The Question**
Is the engineer right? What does this RoleBinding actually grant, and what's the real risk here?

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: analytics-admin
  namespace: analytics
subjects:
  - kind: ServiceAccount
    name: analytics-pipeline
    namespace: analytics
roleRef:
  kind: ClusterRole
  name: cluster-admin   # ← references a ClusterRole from a namespaced RoleBinding
  apiGroup: rbac.authorization.k8s.io
```

**🔍 Diagnosis**
1. Confirm the mechanics first: a RoleBinding's effective scope is **always** limited to the namespace the RoleBinding object itself lives in, even when `roleRef` points at a ClusterRole. This binding does **not** grant cluster-wide `cluster-admin` — the engineer's core claim is correct, and this is the most common RBAC trick question for a reason.
2. But identify what actually still makes this dangerous: `cluster-admin`'s rule set includes `*` verbs on `*` resources in `*` apiGroups — some of which are cluster-scoped resources (nodes, PersistentVolumes, ClusterRoles/ClusterRoleBindings themselves, namespaces). A namespaced RoleBinding can't grant access to objects that don't belong to any namespace in the first place — but any *namespaced* resource inside `analytics` is now fully exposed, including creating new RoleBindings in that namespace referencing anything, deleting the namespace's own ResourceQuota, etc.
3. Check `kubectl describe clusterrole cluster-admin` to see the actual rule breadth being granted, even scoped down.
4. Compare against what `analytics-pipeline` actually needs — almost certainly not full CRUD on every namespaced resource type that exists.

**✅ Fix**
```yaml
# Least-privilege alternative 1: built-in `admin` ClusterRole instead of `cluster-admin`
# — full read/write on namespaced resources including managing Roles/RoleBindings in-namespace,
#   but excludes cluster-scoped resources and the namespace object/quota itself
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: analytics-admin
  namespace: analytics
subjects:
  - kind: ServiceAccount
    name: analytics-pipeline
    namespace: analytics
roleRef:
  kind: ClusterRole
  name: admin          # ← still reused across namespaces, still no cluster-scoped access
  apiGroup: rbac.authorization.k8s.io
---
# Least-privilege alternative 2: purpose-built custom Role — best option if the pipeline's
# actual needs are narrower than "admin" (e.g. only jobs + configmaps)
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: analytics-pipeline-role
  namespace: analytics
rules:
  - apiGroups: ["batch"]
    resources: ["jobs"]
    verbs: ["create", "get", "list", "watch", "delete"]
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get", "list"]
```

```bash
# Audit for this exact pattern cluster-wide
kubectl get rolebindings -A -o json | \
  jq -r '.items[] | select(.roleRef.name=="cluster-admin") | .metadata.namespace + "/" + .metadata.name'
```

**🛡️ Prevention**
- Never bind `cluster-admin` from a RoleBinding "because it's just namespaced anyway" — the scoping claim is technically true, but `cluster-admin`'s rule breadth is designed for cluster operators, not workload service accounts, and it's the wrong role even at reduced scope.
- Default to `admin` (namespaced-appropriate, still broad) or a purpose-built custom Role for anything short of genuine cluster operations.
- Periodically audit every RoleBinding referencing `cluster-admin` — this pattern spreads via copy-paste from whichever pipeline first got unblocked this way.

> ⚠️ **Never:** Let "it's just scoped to one namespace" end the conversation — that's correcting one misconception (cluster-wide reach) while ignoring the real one (unnecessarily broad rule set for what the workload needs, and any cluster-scoped side effects `cluster-admin`'s rules happen to include).

See: [RBAC.md](../Components/RBAC/RBAC.md)

---

# 🔴 Slide 6 · Scenario: Gatekeeper Straight to `deny`

**🏗️ Setup**
> *A platform team gets impatient with `dryrun`, flips their `require-cost-center-label` constraint straight to `enforcementAction: deny` on a Friday afternoon, and by Monday half the org can't update any existing Deployment.*

**❓ The Question**
New pods are being rejected across dozens of services, but the currently-running old pods are untouched and still serving traffic. Diagnose it, and tell me what the rollout should have looked like.

**🔍 Diagnosis**
1. Confirm this is Gatekeeper, not RBAC or PSA — the rejection message will carry the constraint's own violation text, not an RBAC 403 or a PSA `restricted:latest` message.
2. Check the constraint's accumulated violations from *before* it was flipped: `kubectl describe k8srequiredlabels require-cost-center-label` — expect a large pre-existing `.status.violations` list populated by the audit controller, which was evaluating this constraint the whole time it sat in `dryrun`.
3. Understand why old pods are unaffected: admission enforcement only evaluates objects at create/update time — pods already running before the flip were never re-evaluated and aren't touched; only the *next* rollout of each affected Deployment hits `deny` and fails to create new pods.
4. Confirm nobody reviewed `.status.violations` between `dryrun` and `deny` — that review step is exactly what got skipped.

**✅ Fix**
```bash
# Step 1: immediate mitigation — revert to non-blocking while violations are triaged
kubectl patch k8srequiredlabels require-cost-center-label \
  --type='merge' -p '{"spec":{"enforcementAction":"warn"}}'
# ← restores the ability to roll deployments; violations still visible via warnings, not silently invisible

# Step 2: see exactly what's non-compliant and how many resources are affected
kubectl get k8srequiredlabels require-cost-center-label -o jsonpath='{.status.totalViolations}'
kubectl describe k8srequiredlabels require-cost-center-label | grep -A2 "Violations:"

# Step 3: remediate flagged Deployments (add the missing cost-center label) —
# or grant an explicit, reviewed exception via tighter `match` scope for anything intentionally excluded
```
```yaml
# Correct rollout sequence for the Constraint itself
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: require-cost-center-label
spec:
  enforcementAction: dryrun   # ← 1. start here, let audit sweep existing objects for days, not minutes
  match:
    kinds:
      - apiGroups: ["apps"]
        kinds: ["Deployment"]
  parameters:
    labels: ["cost-center"]
# 2. review .status.violations exhaustively
# 3. remediate or explicitly except every flagged resource
# 4. THEN flip enforcementAction to deny — never before violations are at (or near) zero
```

**🛡️ Prevention**
- Treat `dryrun` as a mandatory step with an actual review gate, not a formality to skip when someone's impatient — the whole point of `dryrun` + the audit controller is discovering the backlog *before* it becomes an outage.
- Require a documented `.status.violations` review (ideally near-zero, or all remaining ones explicitly excepted) as a checklist item before any PR that flips `enforcementAction` to `deny` gets approved.
- Consider `warn` as an intermediate step between `dryrun` and `deny` for constraints affecting many teams — visible pressure to fix without a hard outage.

> ⚠️ **Never:** Flip a constraint straight from `dryrun` to `deny` without reading `.status.violations` first — the audit controller has already told you exactly what will break; skipping that review is the entire root cause here, not a coincidence.

See: [OPAGatekeeper.md](../Components/OPAGatekeeper/OPAGatekeeper.md), [AdmissionWebhooks.md](../Components/AdmissionWebhooks/AdmissionWebhooks.md)

---

# 🎤 Slide 7 · Follow-up Q&A

---

### Q: What's your incident-response playbook when a webhook or policy engine is blocking the whole cluster?
- Read the actual error first — it names the webhook and the failure mode (timeout/unreachable vs a legitimate denial); never assume it's broken before confirming that
- Check the backing Service's endpoints and the webhook pod's own health (`kubectl get endpoints`, `kubectl get pods -o wide`, `kubectl logs --previous`) to find the real root cause (OOMKilled, crashloop, bad cert, missing `caBundle`)
- If genuinely an outage and it's blocking legitimate work: patch `failurePolicy` to `Ignore` (or delete the webhook config as a last resort) to unblock the cluster — but say out loud that this removes enforcement, and treat it as a temporary, tracked state, not a fix
- Fix the underlying webhook server issue (resources, health, cert), then re-tighten `failurePolicy` back to `Fail` before closing the incident
- Postmortem action items almost always include: HA replicas + PodDisruptionBudget for the webhook, `namespaceSelector` excluding `kube-system`/its own namespace, and a short `timeoutSeconds`

> 💬 **Say:** "First I confirm from the error whether this is a real policy denial or an unreachable webhook — those need completely different fixes. If it's an outage, I check the webhook's own pod health and Service endpoints for root cause, patch failurePolicy to Ignore only long enough to unblock the cluster and fix the real problem, then re-tighten it before I call the incident closed."

---

### Q: How do you audit a cluster's RBAC for over-permissioning?
- Find every binding to `cluster-admin` cluster-wide: `kubectl get clusterrolebindings,rolebindings -A -o json | jq '.items[] | select(.roleRef.name=="cluster-admin")'` — every hit is worth a conversation about whether it's actually needed
- Find every Role/ClusterRole granting `list`/`watch` on `secrets` — the single most common "looks read-only, isn't" mistake: `kubectl get roles,clusterroles -A -o json | jq '.items[] | select(.rules[]? | .resources[]? == "secrets" and (.verbs[]? == "list" or .verbs[]? == "watch"))'`
- Check for wildcard verbs/resources (`verbs: ["*"]`, `resources: ["*"]`) left over from "just get it working" roles that nobody revisited
- Use `kubectl auth can-i --list --as=<identity>` (or a tool like `rbac-lookup`/`rakkess`) to reconstruct effective permissions per identity, since there's no single built-in command that dumps "all effective permissions" directly
- Cross-check ServiceAccounts for lingering legacy Secret-based tokens (`kubectl get secrets -A --field-selector type=kubernetes.io/service-account-token`) as a separate axis from RBAC bindings — a stale long-lived token is a liability independent of what it's actually authorized to do
- Remember RBAC and IRSA/IAM are orthogonal — a "least privilege" RBAC audit tells you nothing about a Pod's AWS blast radius; audit both planes separately

> 💬 **Say:** "I run three standing queries: every binding to cluster-admin, every role granting list or watch on secrets, and every legacy service-account token still lying around. Those three catch the vast majority of real-world RBAC over-permissioning, and I'd run them on a schedule, not just during an incident."

---
