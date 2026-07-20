# 🎤 Scheduling & Capacity Incidents
**9 Slides · Pending Pods, Quotas, PDBs, HPA/VPA/Cluster Autoscaler, DaemonSets, Topology Spread + Q&A**

---

# 🔴 Slide 1 · Scenario: Pod Stuck Pending With a Compound Cause

**🏗️ Setup**
> *A new Deployment rolls out and one replica sits `Pending` indefinitely. The on-call engineer assumes it's a single simple cause and starts guessing instead of reading the full Events line — burning 20 minutes on the wrong fix.*

**❓ The Question**
`kubectl describe pod` shows this Events line. Walk me through your diagnosis — what's actually blocking scheduling here?

```
Events:
  Type     Reason            Age   From               Message
  ----     ------            ----  ----               -------
  Warning  FailedScheduling  90s   default-scheduler   0/5 nodes are available:
  2 Insufficient cpu, 2 node(s) didn't match Pod's node affinity/selector,
  1 node(s) had taint {dedicated: gpu}, that the pod didn't tolerate.
```

**🔍 Diagnosis**
1. Don't assume it's one root cause — the message is additive: **all 5 nodes** failed the filter phase, but for **three different reasons**, 2+2+1. Fix only one bucket and the pod is still `Pending`.
2. Go node-by-node, not bucket-by-bucket: `kubectl get nodes -o wide` then for each node cross-reference `kubectl describe node <n>` for `Allocatable`/`Allocated resources`, `kubectl get nodes --show-labels`, and `kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints`.
3. Isolate which 2 nodes are CPU-starved (check `Allocated resources` percentage vs. what this pod requests), which 2 fail node affinity (label mismatch — often a typo'd value or a rolled-back label), and which 1 carries the `dedicated: gpu` taint this pod doesn't tolerate.
4. Ask "is any single one of these three fixable, or is this cluster structurally short of capacity for this pod's actual requirements?" — see `../Components/Scheduling/Scheduling.md` for the filtering-vs-scoring mental model this event line comes from.

**✅ Fix**
```bash
# Step 1: enumerate exactly which node failed for which reason
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints
kubectl get nodes --show-labels
kubectl describe node node-1 | grep -A5 "Allocated resources"   # ← repeat per node

# Step 2: confirm the pod's actual requirements against reality
kubectl get pod worker-7f9c -o jsonpath='{.spec.containers[0].resources}'
kubectl get pod worker-7f9c -o jsonpath='{.spec.affinity}'
kubectl get pod worker-7f9c -o jsonpath='{.spec.tolerations}'
```

```yaml
# Fix A (2 CPU-starved nodes): either lower the request or free capacity —
# don't just add the toleration and declare victory, CPU is still short there
resources:
  requests:
    cpu: 250m        # ← was 1000m; right-size against profiled usage instead of scaling nodes

# Fix B (2 nodes failing affinity): the pod's required rule expects a label
# that was renamed/removed from those nodes — align one side or the other
nodeAffinity:
  requiredDuringSchedulingIgnoredDuringExecution:
    nodeSelectorTerms:
      - matchExpressions:
          - key: workload-tier     # ← confirm this key/value still exists on target nodes
            operator: In
            values: ["standard"]

# Fix C (1 GPU-tainted node): only add this toleration if the pod GENUINELY needs GPU —
# otherwise leave it untolerated, that node is correctly excluded
tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "gpu"
    effect: "NoSchedule"   # ← only if this workload actually uses the GPU
```

**🛡️ Prevention**
- Always read the full `FailedScheduling` message and count nodes per reason before touching anything — `2 + 2 + 1 = 5` is the tell that this is compound, not singular
- Keep a per-node-group inventory of labels/taints so affinity mismatches are caught in code review, not production
- Alert on sustained `Pending` pods (>5 min) with the full event message attached, not just a generic "pod not ready" alert

> ⚠️ **Never:** Add a blanket toleration for every taint you see in the error just to make scheduling "succeed" — you may land the pod on GPU hardware it doesn't need (wasting expensive capacity) while the real CPU/affinity problem goes unfixed for the next rollout.

---

# 🔴 Slide 2 · Scenario: ResourceQuota Rejects Pod Creation

**🏗️ Setup**
> *A team's Deployment manifest hasn't changed in months. Today, `kubectl apply` suddenly fails on every new pod. Nothing in their YAML changed — but the platform team quietly added a ResourceQuota to the namespace yesterday.*

**❓ The Question**
You see this exact admission error. What's happening and how do you fix it?

```
Error from server (Forbidden): error when creating "app.yaml":
pods "worker-7f9c" is forbidden: failed quota: compute-quota:
must specify limits.cpu,limits.memory
```

**🔍 Diagnosis**
1. This is a `403 Forbidden` from the **ResourceQuota admission plugin**, not a scheduler problem — the pod never even reaches the scheduler.
2. The namespace now has a `ResourceQuota` covering `limits.cpu`/`limits.memory`. The rule: once a quota covers those keys, **every container in every pod must explicitly set them**, or the pod is rejected outright — omission is never treated as "unlimited."
3. Confirm with `kubectl describe resourcequota -n <ns>` and `kubectl get resourcequota -n <ns>` — there can be several, differently scoped.
4. Root cause of "why now": someone added the `ResourceQuota` without a companion `LimitRange` to backfill defaults for existing manifests that never set resources. Full mechanism in `../Components/ResourceQuotas/ResourceQuotas.md`.

**✅ Fix**
```bash
# Confirm the quota and what it requires
kubectl describe resourcequota compute-quota -n team-checkout
kubectl get resourcequota -n team-checkout
```

```yaml
# Durable fix: add a LimitRange so admission-time defaulting fills in
# missing fields BEFORE ResourceQuota evaluates the pod (LimitRange runs first)
apiVersion: v1
kind: LimitRange
metadata:
  name: team-checkout-limits
  namespace: team-checkout
spec:
  limits:
    - type: Container
      default:                # ← injected as limits for containers that omit them
        cpu: "500m"
        memory: 512Mi
      defaultRequest:          # ← injected as requests for containers that omit them
        cpu: "100m"
        memory: 128Mi
```

```yaml
# Complementary fix: update the manifest to set resources explicitly
# rather than relying on defaulting long-term
resources:
  requests:
    cpu: 100m        # ← explicit, matches expected steady-state usage
    memory: 128Mi
  limits:
    cpu: 500m        # ← explicit ceiling
    memory: 512Mi
```

**🛡️ Prevention**
- Always deploy `ResourceQuota` and `LimitRange` as a pair — never ship one without the other into a namespace with pre-existing manifests
- Platform teams: run a dry-run/admission-webhook check across existing Deployments before rolling out a new namespace-wide quota
- Require resource requests/limits in CI (e.g., via OPA/Kyverno policy) so manifests never depend on quota-triggered defaulting to "happen to work"

> ⚠️ **Never:** Tell the team to "just remove the quota" to unblock them — that reopens the exact noisy-neighbor problem the platform team was trying to close. The correct fix is the LimitRange, not deleting the guardrail.

---

# 🔴 Slide 3 · Scenario: PodDisruptionBudget Blocks a Node Drain

**🏗️ Setup**
> *A scheduled Kubernetes version upgrade kicks off. `kubectl drain node-3` has been running for two hours and hasn't finished. The on-call engineer assumes the node is stuck or the drain command is broken.*

**❓ The Question**
The drain won't complete. `kubectl get pdb` shows `ALLOWED DISRUPTIONS: 0`. How do you diagnose and fix this?

```bash
$ kubectl get pdb -n payments
NAME          MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
payments-api  1               N/A               0                     92d

$ kubectl get deployment payments-api -n payments -o jsonpath='{.spec.replicas}'
1
```

**🔍 Diagnosis**
1. `kubectl drain` calls the **Eviction API**, and the API server checks `status.disruptionsAllowed` on any PDB matching the pod's labels before allowing the eviction — see `../Components/PodDisruptionBudget/PodDisruptionBudget.md` for the full request/response mechanism.
2. With `replicas: 1` and `minAvailable: 1`, the disruption controller computes `currentHealthy=1`, `desiredHealthy=1` → `disruptionsAllowed=0`, **permanently**. Evicting the only pod would always drop availability below the budget.
3. This isn't transient — the drain will retry forever (or 429 forever) until the underlying math changes. Confirm with `kubectl get events -n payments --field-selector reason=FailedEviction`.
4. The node isn't broken and the drain command isn't broken — the PDB is doing exactly what it was configured to do.

**✅ Fix**
```bash
# Diagnose: confirm this is the classic single-replica gotcha
kubectl describe pdb payments-api -n payments
kubectl get events -n payments --field-selector reason=FailedEviction
```

```yaml
# Fix Option 1 (preferred for anything user-facing): scale to 2+ replicas
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payments-api
spec:
  replicas: 2        # ← now disruptionsAllowed can be >0 with minAvailable: 1
```

```yaml
# Fix Option 2 (only if this is a true singleton that tolerates brief downtime):
# loosen to maxUnavailable, or remove the PDB entirely
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: payments-api
  namespace: payments
spec:
  maxUnavailable: 1   # ← for 1 replica this effectively allows the eviction to proceed
  selector:
    matchLabels:
      app: payments-api
```

**🛡️ Prevention**
- Audit every PDB's `minAvailable`/`maxUnavailable` against the owning controller's actual `replicas` **before** starting a cluster/node-group upgrade — don't discover the mismatch mid-upgrade
- Treat `replicas: 1` + `minAvailable: 1` as a lint-time failure in CI/admission policy, not something a human catches by accident
- For anything genuinely single-instance and restart-tolerant (dev tools, batch singletons), don't attach a PDB at all — it adds friction without protecting real availability

> ⚠️ **Never:** Reach for `kubectl drain --force --disable-eviction` (or `--force --ignore-daemonsets` misapplied to bypass the eviction path entirely) as your default unblock — that skips the Eviction API and the PDB check altogether, and on a workload where the PDB was actually protecting something real (e.g., a quorum-based system), you can drop below quorum with zero warning.

---

# 🔴 Slide 4 · Scenario: HPA Stuck With `<unknown>` Targets

**🏗️ Setup**
> *A production Deployment has an HPA configured for CPU-based autoscaling. Traffic has been climbing for 20 minutes with zero scale-up. `kubectl get hpa` shows the target column has never once shown a real number.*

**❓ The Question**
```bash
$ kubectl get hpa
NAME             REFERENCE               TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
api-server-hpa   Deployment/api-server   <unknown>/70%   3         20        3          41d
```
Why is this stuck, and what's your fix?

**🔍 Diagnosis**
1. HPA doesn't collect metrics itself — it queries `metrics.k8s.io`, served by **metrics-server**. `<unknown>` forever means that API path is broken, not that the workload is idle.
2. Verify the APIService itself is registered and healthy:
```bash
kubectl get apiservices | grep metrics
# v1beta1.metrics.k8s.io   kube-system/metrics-server   False (FailedDiscoveryCheck)
```
3. Confirm end-to-end with `kubectl top nodes` / `kubectl top pods` — if those fail too, it's confirmed as a metrics-pipeline outage, not something HPA-specific.
4. `kubectl describe hpa api-server-hpa` — look for `FailedGetResourceMetric` events, which point at the same root cause. Full detail in `../Components/Autoscaling/Autoscaling.md`.

**✅ Fix**
```bash
# Step 1: confirm the APIService state and reason
kubectl get apiservices | grep metrics
kubectl describe apiservice v1beta1.metrics.k8s.io

# Step 2: check metrics-server pod health directly
kubectl get pods -n kube-system -l k8s-app=metrics-server
kubectl logs -n kube-system deployment/metrics-server

# Step 3: common self-managed-cluster cause — kubelet TLS cert validation failing
kubectl -n kube-system get deployment metrics-server -o yaml | grep -A3 args
```

```yaml
# Stopgap (self-signed kubelet certs on self-managed clusters):
# NOT a long-term fix — schedule the real cert-trust fix separately
spec:
  template:
    spec:
      containers:
        - name: metrics-server
          args:
            - --kubelet-insecure-tls   # ← bypasses kubelet cert validation, stopgap only
```

```bash
# Step 4: verify recovery
kubectl top pods -n production
kubectl get hpa api-server-hpa   # TARGETS should show a real percentage within ~1 min
```

**🛡️ Prevention**
- Alert directly on `metrics.k8s.io` APIService availability — don't rely on noticing `<unknown>` in `kubectl get hpa` by eye
- Treat metrics-server as tier-1 infrastructure with its own on-call runbook, not an afterthought add-on
- Fix kubelet certificate trust properly rather than leaving `--kubelet-insecure-tls` as a permanent setting

> ⚠️ **Never:** Assume `<unknown>` means "no load, nothing to scale" and move on — that reading is backwards; it means the autoscaler is blind, and a real traffic spike during that blindness turns into an uncontrolled latency incident with zero automatic response.

---

# 🔴 Slide 5 · Scenario: HPA and VPA Fighting Over the Same Metric

**🏗️ Setup**
> *A team enables VPA "to stop manually tuning CPU requests" on a Deployment that already has an HPA scaling on CPU utilization. Within a day, replica count and CPU requests are both oscillating every few minutes and the workload never settles at a steady state.*

**❓ The Question**
Replica count and CPU requests are oscillating in lockstep every few minutes. What's the root cause, and how do you fix it?

**🔍 Diagnosis**
1. HPA's CPU utilization metric is `usage / request`. VPA raises the pod's CPU **request** when observed usage runs high.
2. The moment VPA increases the request, the same usage now computes to a *lower* utilization percentage — HPA reads this as "load dropped" and scales pods **down**.
3. Fewer, differently-sized pods absorb the same total load → per-pod usage spikes again → VPA reacts by resizing again → HPA reacts to the new percentage again. No stable equilibrium — it's a closed feedback loop, not a tuning problem you can fix by adjusting thresholds.
4. This is a known, named anti-pattern — see `../Components/Autoscaling/Autoscaling.md` ("HPA + VPA on the Same Metric: The Conflict") for the full mechanism.

**✅ Fix**
```bash
# Confirm both are targeting the same Deployment on the same dimension
kubectl get hpa,vpa -n production
kubectl get hpa api-server-hpa -o jsonpath='{.spec.metrics}'
kubectl get vpa api-server-vpa -o jsonpath='{.spec.resourcePolicy}'
```

```yaml
# Fix: give HPA and VPA disjoint responsibilities — no shared denominator
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-server-hpa
spec:
  metrics:
    - type: Pods
      pods:
        metric:
          name: http_requests_per_second   # ← custom metric, NOT CPU — VPA never touches this
        target:
          type: AverageValue
          averageValue: "500"
```

```yaml
# VPA independently right-sizes CPU/memory requests — no longer HPA's denominator
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: api-server-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api-server
  updatePolicy:
    updateMode: "Auto"
  resourcePolicy:
    containerPolicies:
      - containerName: "*"
        controlledResources: ["cpu", "memory"]   # ← HPA no longer scales on either of these
```

**🛡️ Prevention**
- Sanity-check on every rollout: `kubectl get hpa,vpa -n <ns>` and confirm nothing targets the same resource+metric
- Default posture: VPA in `Off` mode (recommendations only) until you've deliberately chosen its resource dimension and confirmed HPA doesn't overlap it
- Document the "who owns which dimension" split in the service's runbook — CPU/memory sizing vs. replica count are different questions and should have different owners

> ⚠️ **Never:** Try to fix the oscillation by tuning HPA's `stabilizationWindowSeconds` or tolerance band alone — that dampens the symptom's frequency but doesn't remove the feedback loop; the two controllers are still fighting, just more slowly.

---

# 🔴 Slide 6 · Scenario: Cluster Autoscaler Won't Scale Down an Idle Node

**🏗️ Setup**
> *Finance flags a node group that's been running well above its steady-state size for over an hour. `kubectl top nodes` shows one node sitting at 20% utilization the entire time — Cluster Autoscaler should have removed it long ago, but it hasn't, and there's no alert or error anywhere.*

**❓ The Question**
Why would Cluster Autoscaler refuse to scale down a node that's clearly underutilized, and how do you find the actual reason?

**🔍 Diagnosis**
1. CA marks a node a scale-down candidate below ~50% utilization sustained for `scale-down-unneeded-time` (default 10 min) — but it will **skip** a candidate node if any pod on it is protected. Checklist, in order of likelihood:
   - A pod with annotation `cluster-autoscaler.kubernetes.io/safe-to-evict: "false"`
   - A **bare pod** not owned by any controller — CA can't guarantee it gets rescheduled, so it refuses by default
   - A pod whose eviction would violate a **PodDisruptionBudget** (the single-replica PDB gotcha from Slide 3 is a frequent culprit here too)
2. This is "rarely a CA bug, almost always a deliberate safety guard doing its job" — the fix is finding *which* guard, not fighting CA.
3. Go straight to CA's own stated reasoning rather than guessing:
```bash
kubectl -n kube-system logs deployment/cluster-autoscaler | grep -i "scale_down\|NotUnneeded"
kubectl get configmap cluster-autoscaler-status -n kube-system -o yaml
```
4. Cross-reference with `kubectl describe node <node>` to see exactly what's still running there. Full checklist in `../Components/Autoscaling/Autoscaling.md` and the CA-interaction section of `../Components/PodDisruptionBudget/PodDisruptionBudget.md`.

**✅ Fix**
```bash
# Step 1: see everything actually scheduled on the "idle" node
kubectl get pods --all-namespaces --field-selector spec.nodeName=<node-name> -o wide

# Step 2: check each pod for the safe-to-evict annotation
kubectl get pod <pod> -n <ns> -o jsonpath='{.metadata.annotations}'

# Step 3: check for bare pods (no owner reference)
kubectl get pod <pod> -n <ns> -o jsonpath='{.metadata.ownerReferences}'
# empty output = bare pod, CA will not evict it by default

# Step 4: check PDBs matching pods on this node
kubectl get pdb --all-namespaces
kubectl describe pdb <name> -n <ns>   # look for ALLOWED DISRUPTIONS == 0

# Step 5: read CA's own stated reason, don't guess
kubectl -n kube-system logs deployment/cluster-autoscaler | grep <node-name>
```

```yaml
# If the annotation is truly no longer needed (workload is safely interruptible now):
metadata:
  annotations:
    cluster-autoscaler.kubernetes.io/safe-to-evict: "true"   # ← only after confirming it's safe
```

**🛡️ Prevention**
- Treat `safe-to-evict: "false"` as a deliberate, documented decision with an owner — not a default anyone sets defensively
- Never run long-lived workloads as bare pods; wrap everything in a Deployment/Job/StatefulSet so CA (and everything else) can safely manage them
- Include CA's scale-down blockers in the same PDB audit you run before cluster upgrades (Slide 3) — the same misconfigured PDB blocks both

> ⚠️ **Never:** Manually cordon and force-terminate the node to "help" CA along without checking why it was blocked first — if a bare pod or a PDB-protected pod was on there for a reason (in-flight batch job, quorum member), you can lose work or drop below quorum with no automatic recovery.

---

# 🔴 Slide 7 · Scenario: A DaemonSet Quietly Eating Fleet-Wide Capacity

**🏗️ Setup**
> *Application teams complain pods are scheduling less densely than capacity planning predicted — nodes are "full" well before the expected number of app pods land. Nobody changed any application manifest recently.*

**❓ The Question**
`kubectl describe node` shows a surprisingly large "Allocated resources" percentage before any application workload even runs. Where do you look, and why does this happen?

```bash
$ kubectl describe node node-12 | grep -A 10 "Allocated resources"
Allocated resources:
  Resource           Requests     Limits
  --------           --------     ------
  cpu                1850m (46%)  4200m (105%)
  memory             3100Mi (39%) 6800Mi (86%)
```

**🔍 Diagnosis**
1. A large chunk of "Allocated" before app pods run is almost always accumulated **DaemonSet** requests — every DaemonSet's per-container request is reserved **once per node**, on every node in the fleet, not once total.
2. A "harmless-looking" `256Mi` request on a single logging agent, times 500 nodes, is 128Gi of allocatable memory gone before a single application pod schedules — see `../Components/DaemonSet/DaemonSet.md` ("Resource Requests: The Fleet-Wide Multiplier Gotcha").
3. Enumerate every DaemonSet's resource requests, not just the obvious one — logging agent, CNI, CSI node plugin, security/compliance agent, node-exporter can each individually look small and collectively be enormous.
4. Confirm the multiplier: sum each DaemonSet's per-container request × node count, compare against total cluster allocatable capacity.

**✅ Fix**
```bash
# Step 1: list every DaemonSet across the cluster with its resource requests
kubectl get daemonset -A -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,CPU_REQ:.spec.template.spec.containers[0].resources.requests.cpu,MEM_REQ:.spec.template.spec.containers[0].resources.requests.memory

# Step 2: confirm the actual breakdown on a representative node
kubectl describe node node-12 | grep -A 15 "Non-terminated Pods"
kubectl describe node node-12 | grep -A 10 "Allocated resources"

# Step 3: compare requested vs. actually profiled usage per DaemonSet pod
kubectl top pods -n kube-system -l app=fluent-bit
```

```yaml
# Fix: right-size based on profiled usage, not guesswork —
# remember this number gets multiplied by every node in the fleet
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluent-bit
  namespace: kube-system
spec:
  template:
    spec:
      containers:
        - name: fluent-bit
          resources:
            requests:
              cpu: 20m         # ← trimmed from 50m after profiling actual usage
              memory: 48Mi     # ← trimmed from 64Mi
            limits:
              cpu: 100m
              memory: 96Mi
```

**🛡️ Prevention**
- Include DaemonSet resource requests explicitly in cluster capacity planning math — they're fixed overhead per node, not "one pod's worth" of slack
- Re-profile DaemonSet resource usage on a schedule (quarterly) as agent versions and node counts change
- Require any new DaemonSet (new logging/security/monitoring agent) to go through the same resource-request review as an application workload — it's not exempt just because it's infrastructure

> ⚠️ **Never:** Bump a DaemonSet's request "just to be safe" without profiling — a rounding-up decision on one agent, multiplied across a 500-node fleet, is a capacity-planning line item, not a minor tweak.

---

# 🔴 Slide 8 · Scenario: Topology Spread Constraint Leaves Pods Permanently Pending

**🏗️ Setup**
> *Cluster Autoscaler scales down nodes in an underused AZ overnight to save cost. The next morning, a rolling deployment in a different service can't schedule any new pods — and this service didn't change anything.*

**❓ The Question**
New pods with `whenUnsatisfiable: DoNotSchedule` and `maxSkew: 1` can't schedule after the AZ imbalance. What's the exact failure, and what are the trade-offs in fixing it?

```
Events:
  Warning  FailedScheduling  4m   default-scheduler   0/9 nodes are available:
  3 node(s) didn't match pod topology spread constraints
  (missing required label), 6 node(s) didn't match pod topology
  spread constraints.
```

**🔍 Diagnosis**
1. `DoNotSchedule` is a **hard** constraint — the scheduler will not violate `maxSkew` even if it means leaving the pod `Pending` forever. This is by design; see `../Components/Scheduling/Scheduling.md` ("Topology Spread Constraints").
2. With `maxSkew: 1` across 3 AZs, satisfying the constraint after CA removed all nodes from one AZ would require placing a pod in a zone that currently has **zero capacity** — an impossible ask until a node exists there again.
3. This is structurally the same failure mode as `minDomains` protects against, just triggered from the opposite direction: instead of scaling into an empty zone too early, the cluster scaled *out* of a zone that a running workload still structurally depends on.
4. Check whether CA/Karpenter maintains a minimum node count per AZ — if not, this will recur every time utilization dips in one zone.

**✅ Fix**
```bash
# Confirm the exact constraint and current per-AZ node distribution
kubectl get pod <pod> -o jsonpath='{.spec.topologySpreadConstraints}'
kubectl get nodes -L topology.kubernetes.io/zone
kubectl get pods -o wide -l app=<app> | awk '{print $7}' | sort | uniq -c   # pods per node, cross-ref to zone
```

```yaml
# Option A: soften to ScheduleAnyway as a fallback — accept temporary imbalance
# rather than blocking scheduling entirely
topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: topology.kubernetes.io/zone
    whenUnsatisfiable: ScheduleAnyway   # ← was DoNotSchedule; degrades to best-effort instead of Pending
    labelSelector:
      matchLabels:
        app: checkout-api
```

```yaml
# Option B (better long-term): keep DoNotSchedule but ensure the autoscaler
# never fully empties an AZ that workloads depend on — Cluster Autoscaler
# balance-similar-node-groups, or Karpenter minimum-per-zone constraint
# (Karpenter NodePool example)
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: default
spec:
  template:
    spec:
      requirements:
        - key: topology.kubernetes.io/zone
          operator: In
          values: ["us-east-1a", "us-east-1b", "us-east-1c"]   # ← keep all 3 zones eligible
  disruption:
    consolidateAfter: 300s   # ← don't over-eagerly consolidate away an entire zone's capacity
```

**🛡️ Prevention**
- Pair `DoNotSchedule` topology spread with explicit per-AZ minimum node guarantees in the autoscaler config — don't let cost optimization silently break availability-driven scheduling
- Use `minDomains` alongside `DoNotSchedule` so the scheduler's skew math accounts for zones that should exist even when temporarily empty
- Alert on `FailedScheduling` events mentioning "topology spread constraints" specifically — they're a distinct signature from plain resource-pressure Pending pods and point straight at autoscaler/topology interaction

> ⚠️ **Never:** Reflexively switch every topology spread constraint to `ScheduleAnyway` cluster-wide to "make the Pending pods go away" — for workloads where the spread was there to survive an AZ outage (not just for even bin-packing), silently degrading to best-effort removes the actual availability guarantee without anyone noticing until the next real AZ failure.

---

# 🎤 Slide 9 · Follow-up Q&A

---

### Q: How do you triage a Pending pod in under 2 minutes?
- `kubectl describe pod <pod>` first, always — the Events section states the exact reason(s); never start guessing before reading it
- Count the reasons in the message (`N Insufficient cpu`, `N didn't match affinity`, `N had taint`) — if they sum to the total node count, it's compound, not singular (Slide 1 pattern)
- Cross-check node reality fast: `kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints` and `kubectl get nodes --show-labels` against what the pod actually requests/requires
- If the message mentions "topology spread constraints" or "node affinity," check whether the required domain/label can ever exist in this cluster — if not, no amount of Cluster Autoscaler/Karpenter scaling will fix it, and you need a spec change, not more capacity

> 💬 **Say:** "I read the Events line character by character before touching anything — a compound Pending pod that gets `describe`'d in 10 seconds saves 20 minutes of chasing the wrong single cause."

---

### Q: How do resource requests interact across HPA, ResourceQuota, and the scheduler simultaneously?
- The **scheduler** uses `requests` (not `limits`) to decide if a pod fits on a node — `Allocatable` minus already-`Allocated` requests is the number that actually gates placement
- **ResourceQuota** sums `requests`/`limits` across every pod in the namespace against `.hard` — once it covers those keys, missing fields become a hard admission rejection, not "unmetered"
- **HPA**'s `averageUtilization` metric is `usage / request` — if requests are wrong (too high, too low, or missing and defaulted by a LimitRange to something arbitrary), the percentage HPA scales on is measuring against the wrong baseline, and scaling decisions become meaningless even though the HPA object itself looks healthy
- All three read the *same* `resources.requests` field for three different purposes — a single misconfigured or quota-defaulted request value can simultaneously break scheduling density, quota accounting, and autoscaling accuracy

> 💬 **Say:** "Requests aren't just a scheduling hint — they're the shared denominator for the scheduler, ResourceQuota, and HPA all at once. Getting them wrong doesn't fail loudly in one place, it quietly degrades three systems that all assumed the number was trustworthy."

---

### Q: A cluster has Pending pods, an idle-looking node, and a stalled drain all at the same time — how do you figure out if they're related?
- Start with PDBs — `kubectl get pdb -A` and scan for `ALLOWED DISRUPTIONS: 0` — a single-replica PDB gotcha can simultaneously explain a stalled drain (Slide 3) *and* an idle node Cluster Autoscaler won't remove (Slide 6), because it's the same root cause blocking two different voluntary-disruption paths
- Then check whether the Pending pods are a topology-spread symptom of that same node's removal being blocked/unblocked inconsistently (Slide 8) — an AZ that looks "about to empty" can produce Pending pods before the drain even finishes
- Resist fixing each symptom independently — trace all three back to `kubectl describe pdb` and `kubectl -n kube-system logs deployment/cluster-autoscaler` first; in practice these three symptoms sharing one incident window usually share one root cause

> 💬 **Say:** "When Pending pods, a stuck drain, and an autoscaler that won't scale down all show up together, I don't treat them as three tickets — I check PDBs first, because that one object type is wired into both the drain path and the Cluster Autoscaler scale-down path simultaneously."

---
