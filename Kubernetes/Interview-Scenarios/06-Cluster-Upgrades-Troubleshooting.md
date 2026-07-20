# 🎤 Cluster Upgrades & General Troubleshooting
**7 Slides · Node Group Upgrades, NotReady Eviction Timing, API Deprecations, On-Call Triage + Debugging Toolkit + Q&A**

---

# 🔴 Slide 1 · Scenario: Managed Node Group Upgrade Stalls Indefinitely

**🏗️ Setup**
> *You kicked off an EKS managed node group rolling upgrade last night to bump the AMI version. This morning it's still "in progress" — one node has been `SchedulingDisabled` and draining for over an hour, and the rollout refuses to move to the next node.*

**❓ The Question**
The node group upgrade has been stuck for over an hour on a single node. Walk me through exactly how you'd diagnose and unblock it.

```
$ kubectl get nodes
NAME                             STATUS                     ROLES    AGE   VERSION
ip-10-0-1-11.ec2.internal        Ready                      <none>   45d   v1.27.9
ip-10-0-1-42.ec2.internal        Ready,SchedulingDisabled    <none>   45d   v1.27.9
ip-10-0-1-77.ec2.internal        Ready                      <none>   3m    v1.28.5

$ kubectl get events -n prod --field-selector reason=FailedEviction
LAST SEEN   TYPE      REASON           OBJECT                MESSAGE
2m          Warning   FailedEviction   pod/billing-worker-0  Cannot evict pod as it would
                                                              violate the pod's disruption budget.
```

**🔍 Diagnosis**
1. `kubectl get nodes` — confirm which node is stuck `SchedulingDisabled` (cordoned but not yet drained).
2. `kubectl get pods --all-namespaces --field-selector spec.nodeName=<stuck-node>` — see what's still running there.
3. `kubectl get pdb -A` — scan every namespace for `ALLOWED DISRUPTIONS == 0`. This is almost always the culprit; see [PodDisruptionBudget.md](../Components/PodDisruptionBudget/PodDisruptionBudget.md) for the mechanics of why a PDB can permanently block eviction.
4. `kubectl describe pdb billing-worker -n prod` — confirm `Allowed disruptions: 0` and cross-check `minAvailable`/`maxUnavailable` against the Deployment's actual `replicas`.
5. Separately, verify the drain itself wasn't run naively: `ps aux | grep drain` / check the EKS-managed node group's own drain logs — if `--ignore-daemonsets` wasn't set (or the managed node group's internal drain equivalent doesn't skip DaemonSets), DaemonSet pods (`calico-node`, `aws-node`, log agents) will also block the drain, exactly as covered in [DaemonSet.md](../Components/DaemonSet/DaemonSet.md#interaction-with-kubectl-drain). Check for a *second*, distinct error alongside the PDB one: `error: cannot delete Pods declared in DaemonSet: kube-system/aws-node`.
6. Confirm the compound cause: `billing-worker` Deployment is `replicas: 1` with a PDB `minAvailable: 1` — the disruption controller computes `disruptionsAllowed = 0` forever, because evicting the only pod would drop availability below the budget.

**✅ Fix**
```bash
# Step 1: confirm the exact blocking pod and its owning Deployment/PDB
kubectl get pdb -A -o wide                                  # ← scan for ALLOWED DISRUPTIONS == 0
kubectl get deployment billing-worker -n prod -o jsonpath='{.spec.replicas}'
# → 1   (the smoking gun: replicas:1 + minAvailable:1 = never evictable)

# Fix Option A: accept the availability risk, scale up first (preferred for anything user-facing)
kubectl scale deployment billing-worker -n prod --replicas=2   # ← now evicting 1 of 2 still satisfies minAvailable:1
kubectl get pdb billing-worker -n prod                         # ← ALLOWED DISRUPTIONS should now show 1

# Fix Option B: temporarily loosen the PDB if the workload can tolerate brief downtime
kubectl patch pdb billing-worker -n prod \
  -p '{"spec":{"minAvailable":0}}'                              # ← ⚠️ removes protection entirely, revert after upgrade
# (minAvailable/maxUnavailable are immutable-ish in some API versions — may require delete+recreate)

# Step 2: if the drain itself never used --ignore-daemonsets, re-run it explicitly
kubectl drain ip-10-0-1-42.ec2.internal \
  --ignore-daemonsets \            # ← skip DaemonSet-owned pods (they run through the upgrade by design)
  --delete-emptydir-data \
  --force                          # ← last resort only, after confirming no PDB-protected singleton remains

# Step 3: confirm the node finally drains and the rollout proceeds
kubectl get nodes -w
```

**🛡️ Prevention**
- Before starting any node group upgrade, run `kubectl get pdb -A` and audit every PDB against its controller's actual `replicas` — flag anything with `replicas: 1` + `minAvailable: 1` ahead of time, not during the incident.
- Set a sane drain timeout on the node group upgrade config so it fails fast and pages someone instead of silently hanging for hours.
- Bake `--ignore-daemonsets --delete-emptydir-data` into any custom drain automation/runbook by default — don't rely on remembering it live.

> ⚠️ **Never:** Reach for `kubectl drain --force --grace-period=0` as the first move on a stuck node — it bypasses PDBs by force-deleting pods rather than evicting them, which is exactly the availability guarantee the PDB existed to enforce. Fix the root cause (replica count or PDB threshold) first; force-delete only after you've made a deliberate, informed call that the downtime is acceptable.

---

# 🔴 Slide 2 · Scenario: Node Goes NotReady, Pods Don't Move for 5 Minutes

**🏗️ Setup**
> *A transient network blip makes a node miss its heartbeats. The node flips to `NotReady`, but the pods scheduled on it — including a customer-facing API — keep sitting there for a full 5 minutes before anything reschedules, during which the service is degraded.*

**❓ The Question**
Why does it take ~5 minutes for pods to move off a `NotReady` node, and how would you tune that for an SLA-critical workload — what's the trade-off?

```
$ kubectl get nodes
NAME                        STATUS     ROLES    AGE   VERSION
ip-10-0-2-19.ec2.internal   NotReady   <none>   12d   v1.28.5

$ kubectl describe node ip-10-0-2-19.ec2.internal | grep -A3 Taints
Taints:  node.kubernetes.io/unreachable:NoExecute
```

**🔍 Diagnosis**
1. Node controller stops seeing kubelet heartbeats (via the Lease object); after `node-monitor-grace-period` (default ~40s), it flips the node condition to `NotReady`/`Unknown` and applies the `node.kubernetes.io/not-ready` or `unreachable` taint with effect `NoExecute`.
2. `NoExecute` is the only taint effect that acts on **already-running** pods — but eviction isn't immediate. Every pod's **effective `tolerationSeconds`** for that taint governs the actual delay.
3. If the pod spec doesn't explicitly set a toleration for `not-ready`/`unreachable`, the `DefaultTolerationSeconds` admission controller injects one automatically at `tolerationSeconds: 300` (5 minutes) at pod creation time.
4. Total time-to-reschedule ≈ 40s detection + 300s default grace ≈ 5m40s — this matches the observed symptom exactly. Full mechanics in [Scheduling.md](../Components/Scheduling/Scheduling.md#why-eviction-isnt-instant--default-grace-period).
5. This delay is **intentional**, not a bug: without it, any 10-second network blip that self-resolves would trigger a mass eviction-and-reschedule storm across every affected node — potentially worse for stability than just waiting it out.

**✅ Fix**
```yaml
# Option A: override tolerationSeconds on the SLA-critical workload only (targeted, safer)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: checkout-api
spec:
  template:
    spec:
      tolerations:
        - key: "node.kubernetes.io/not-ready"
          operator: "Exists"
          effect: "NoExecute"
          tolerationSeconds: 30     # ← reschedule after 30s instead of the 300s default
        - key: "node.kubernetes.io/unreachable"
          operator: "Exists"
          effect: "NoExecute"
          tolerationSeconds: 30     # ← same override for the "heartbeat unknown" case
```

```bash
# Option B: cluster-wide default (affects EVERY pod without an explicit toleration — use with caution)
# Set on kube-apiserver's DefaultTolerationSeconds admission plugin config:
#   --default-not-ready-toleration-seconds=30
#   --default-unreachable-toleration-seconds=30
# (self-managed control plane only — not tunable on EKS/GKE managed control planes)

# Verify current behavior on a live node going down:
kubectl get nodes -w
kubectl get pods -o wide --field-selector spec.nodeName=ip-10-0-2-19.ec2.internal
kubectl describe node ip-10-0-2-19.ec2.internal | grep -A5 Taints
```

**🛡️ Prevention**
- Only shorten `tolerationSeconds` on workloads that are (a) genuinely SLA-critical and (b) run enough replicas across enough nodes/zones that a false-positive reschedule doesn't just move the problem — pair with topology spread constraints ([Scheduling.md](../Components/Scheduling/Scheduling.md#topology-spread-constraints)).
- Don't tune the cluster-wide default down globally — a network blip that self-resolves in 60s now triggers full reschedules for every stateless workload in the cluster, which is real churn (new pod scheduling, image pulls, connection draining) for no lasting benefit.
- For workloads that can't tolerate 5 minutes of degradation, the better fix is often redundancy (multiple replicas across zones/nodes) rather than shrinking the eviction timer — a single-replica workload with `tolerationSeconds: 10` still has a gap between node failure and rescheduling; it's just a shorter gap.

> ⚠️ **Never:** Set `tolerationSeconds` to something very low (e.g., `0`–`5`) cluster-wide "to be safe" — you'll convert every transient network hiccup into a full pod eviction/reschedule storm, and if the blip resolves itself in 15 seconds, you've paid the full cost of a reschedule (new scheduling, image pulls if the node is different, connection draining, potential thundering herd on dependent services) for zero actual benefit.

---

# 🔴 Slide 3 · Scenario: Deployment Fails After Control-Plane Upgrade Due to Removed API

**🏗️ Setup**
> *The cluster's control plane was upgraded from 1.21 to 1.22 over the weekend. Monday morning, a routine `kubectl apply` on a manifest that's deployed unchanged for a year suddenly fails.*

**❓ The Question**
This deploy was working fine last week — what changed, and how do you fix it right now plus prevent it next upgrade?

```
$ kubectl apply -f app.yaml
error: resource mapping not found for name: "app" namespace: "prod" from "app.yaml": no matches for kind "Ingress" in version "extensions/v1beta1"
ensure CRDs are installed first
```

**🔍 Diagnosis**
1. This is not a manifest bug — the manifest is unchanged. The API version it references, `extensions/v1beta1` for `Ingress`, was **removed** (not just deprecated) in Kubernetes 1.22.
2. `kubectl api-resources` and `kubectl explain ingress` on the new control plane confirm which API versions are currently served — `extensions/v1beta1` and `networking.k8s.io/v1beta1` Ingress are both gone; only `networking.k8s.io/v1` remains.
3. This is a well-known, recurring upgrade hazard class, not a one-off — API removals happen on a predictable schedule (a `v1beta1` typically gets ~1 year / several minor versions of deprecation warning before removal). `extensions/v1beta1` Ingress removed in 1.22 is the textbook example every senior engineer should recognize by error text alone.
4. Check whether this should have been caught **before** the upgrade: was a deprecated-API scan run against the target version ahead of time?

**✅ Fix**
```bash
# Immediate fix: convert the manifest to the current stable API version
kubectl-convert -f app.yaml --output-version networking.k8s.io/v1 -o app-v1.yaml
# ← kubectl-convert is a kubectl plugin (krew install convert) purpose-built for this

# Manually, the equivalent diff usually looks like:
```
```yaml
# BEFORE (removed in 1.22)
apiVersion: extensions/v1beta1        # ← gone as of 1.22
kind: Ingress
metadata:
  name: app
spec:
  rules:
    - host: app.example.com
      http:
        paths:
          - path: /
            backend:
              serviceName: app        # ← old field name
              servicePort: 80

# AFTER (current stable)
apiVersion: networking.k8s.io/v1      # ← current stable API
kind: Ingress
metadata:
  name: app
spec:
  ingressClassName: nginx             # ← now required explicitly, was implicit/annotation-based before
  rules:
    - host: app.example.com
      http:
        paths:
          - path: /
            pathType: Prefix          # ← now required field, no default
            backend:
              service:                # ← nested object replaces flat serviceName/servicePort
                name: app
                port:
                  number: 80
```
```bash
# Apply the corrected manifest
kubectl apply -f app-v1.yaml

# Going forward: scan the whole repo of manifests against the NEXT target version before upgrading
pluto detect-files -d ./manifests --target-versions k8s=v1.25.0   # ← github.com/FairwindsOps/pluto
# or
kubent   # ← github.com/doitintl/kube-no-trouble, scans a LIVE cluster for deprecated/removed API usage
```

**🛡️ Prevention**
- Before every control-plane upgrade, read the official [Kubernetes API deprecation guide](https://kubernetes.io/docs/reference/using-api/deprecation-guide/) for the exact target version — it lists every removed API and its replacement.
- Run `pluto` or `kubent` against the cluster (live objects) and the manifest repo (CI-gated) as a standard pre-upgrade step, not an afterthought — catch this in CI, not in production Monday morning.
- Track which team owns which manifests referencing soon-to-be-removed APIs well before the deprecation window closes; don't wait for the upgrade to force the conversation.

> ⚠️ **Never:** Pin the control plane to an older version indefinitely just to avoid dealing with API migrations — you're deferring the same work while accumulating a growing gap to catch up on, and falling further behind means losing security patches and eventually landing on a version that's fully out of support.

---

# 🔴 Slide 4 · Scenario: On-Call — 5 Minutes Before the Next Escalation Page

**🏗️ Setup**
> *PagerDuty fires: "production degraded, elevated error rate." You open `kubectl` and see several pods crash-looping across two services. You have about 5 minutes before this auto-escalates to your manager if you haven't posted a status update with a working theory.*

**❓ The Question**
Walk me through your exact triage sequence — in order — for the first 5 minutes of this incident. What do you check first, second, third, and why that order?

**🔍 Diagnosis / Triage Sequence**
1. **What changed recently?** — `kubectl rollout history deployment/<svc> -n prod` and check the deploy pipeline/Slack for anything shipped in the last 30–60 minutes. The overwhelming majority of production incidents correlate with a recent change; check this before anything else because it's the fastest path to a working theory ("we just deployed X, roll it back").
2. **Cluster-wide signal, sorted by time** — `kubectl get events --all-namespaces --sort-by=.lastTimestamp | tail -50` — a fast scan for `BackOff`, `FailedScheduling`, `OOMKilled`, `Unhealthy`, `FailedMount` across the whole cluster, not just the one service someone reported. This catches "it's not just service A, it's every pod on node X" in seconds.
3. **The crash-looping pod itself** — `kubectl get pods -n prod | grep -v Running` to see the blast radius, then `kubectl describe pod <pod>` for the Events section (last restart reason: OOMKilled? Liveness probe failure? ImagePullBackOff?), then `kubectl logs <pod> --previous` — the **previous** container's logs are almost always more useful than the current crash-looping container's logs, since the current one may not have logged anything yet before dying again.
4. **Resource pressure** — `kubectl top nodes` / `kubectl top pods -n prod` (requires metrics-server) to rule out node-level memory/CPU pressure or a noisy-neighbor pod causing OOM kills across the node, not just the reported service.
5. **Node health** — `kubectl get nodes` for any `NotReady` nodes correlating with the affected pods' `spec.nodeName` — rules out "this is actually a node problem, not an app problem."
6. **Dependent services** — is the crash-looping service actually the root cause, or is it crash-looping *because* a downstream dependency (DB, cache, another internal service) is down and a bad readiness/liveness probe is killing it on every failed health check? Check the dependency's health before assuming the pod itself is the bug.

**✅ Fix (the "what do you actually DO" half)**
```bash
# 1. Change correlation — fastest path to a theory
kubectl rollout history deployment/checkout-api -n prod
kubectl rollout undo deployment/checkout-api -n prod          # ← if a recent deploy is the obvious suspect, roll back FIRST, investigate root cause after

# 2. Cluster-wide event sweep
kubectl get events --all-namespaces --sort-by=.lastTimestamp | tail -50

# 3. Specific pod diagnosis
kubectl get pods -n prod -o wide | grep -v Running
kubectl describe pod checkout-api-7d9f8-xk2p1 -n prod          # ← read Events section: OOMKilled? Liveness fail?
kubectl logs checkout-api-7d9f8-xk2p1 -n prod --previous        # ← the crash's actual output, not the empty new attempt

# 4. Resource pressure check
kubectl top nodes
kubectl top pods -n prod --sort-by=memory

# 5. Node health
kubectl get nodes
kubectl describe node <node-hosting-the-pod> | grep -A5 Conditions

# 6. Dependency health (DB/cache/queue)
kubectl exec -it debug-pod -n prod -- nc -zv postgres.prod.svc.cluster.local 5432
```

**🛡️ Prevention**
- Have this exact sequence written down as a runbook, not reconstructed from memory under pressure — muscle memory beats improvisation at 3am.
- Alert on `kubectl rollout` events feeding into the same channel as PagerDuty so "what just changed" is answered before anyone opens a terminal.
- Ensure every deployment has `kubectl logs --previous`-worthy logging — i.e., the app actually logs the fatal error before it dies, not just silently exits.

> ⚠️ **Never:** Start deep-diving into application-level debugging (attaching a debugger, reading application code, guessing at business logic bugs) before you've done the cheap, fast, cluster-level checks above — the interview signal here is prioritization under time pressure: recent changes and cluster-wide signals are 30-second checks that resolve the majority of incidents, while application-level debugging is expensive and should only happen after the cheap checks come up empty.

---

# 🔴 Slide 5 · Debugging Toolkit

**❓ The Question**
What debugging tools do you reach for when a Kubernetes cluster/node/pod behaves unexpectedly?

**✅ Fix**
```bash
# --- API-server-level view: cluster events ---
kubectl get events --all-namespaces --sort-by=.lastTimestamp    # ← chronological, cluster-wide signal
kubectl get events -n prod -o json | jq '.items[] | select(.reason=="FailedScheduling")'
# ← jq filtering when grep isn't precise enough (structured fields: reason, involvedObject, count)

# --- Pod-level: current vs previous container ---
kubectl logs <pod> -n prod                    # current container's stdout/stderr
kubectl logs <pod> -n prod --previous         # ← the crashed container's logs — critical for CrashLoopBackOff
kubectl logs <pod> -n prod -c <container>     # multi-container pod: must specify which container
kubectl describe pod <pod> -n prod            # ← Events section: OOMKilled, Unhealthy, FailedMount, etc.

# --- Resource pressure (requires metrics-server) ---
kubectl top nodes
kubectl top pods -n prod --sort-by=memory
kubectl describe node <node> | grep -A10 "Allocated resources"   # ← requests vs allocatable, DaemonSet multiplier gotcha

# --- Ephemeral debug containers (no debug tools in the app image) ---
kubectl debug -it <pod> -n prod --image=busybox:1.36 --target=<container>
# ← attaches an ephemeral container INTO a running pod's namespaces, shares process namespace with --target

# Debugging a pod that won't even start (Pending / ImagePullBackOff) via a node-level session:
kubectl debug node/<node-name> -it --image=busybox:1.36
# ← launches a privileged pod with the NODE's filesystem mounted at /host — for node-level investigation

# --- Below the API server: node/container-runtime level ---
# When kubectl's view isn't enough (pod already gone, API server slow, runtime-level issue):
crictl ps -a                          # ← all containers incl. exited ones, direct from containerd/CRI-O
crictl logs <container-id>            # ← runtime-level logs, bypasses kubelet log rotation/API entirely
crictl inspect <container-id>         # ← full container state: exit code, OOM flag, mounts

# --- Node-level: kubelet itself ---
# SSH/SSM onto the node when the kubelet or container runtime itself is suspect:
journalctl -u kubelet -f               # ← live kubelet logs — node registration, probe failures, volume mount errors
journalctl -u kubelet --since "10 min ago" | grep -i error

# --- Cross-reference: what does the scheduler/autoscaler think? ---
kubectl -n kube-system logs deployment/cluster-autoscaler | grep <pod-name>
kubectl get pod <pod> -o jsonpath='{.status.conditions}' | jq .
```

> ⚠️ **Never:** Reach straight for `crictl`/node SSH access before checking `kubectl describe` and `kubectl get events` — 90% of the time the API server already has the answer (Events section, resource pressure, PDB/scheduling messages), and dropping to the node level first wastes time and requires elevated node access that not everyone on-call has. Escalate down the stack only when the API-server view genuinely doesn't explain the symptom (e.g., kubelet itself is unresponsive, or a container exited in a way the API server never recorded).

---

# 🎤 Slide 6 · Follow-up Q&A

---

### Q: Walk me through your first 5 minutes of any Kubernetes production incident.
- Check what changed recently — `kubectl rollout history`, recent deploys, recent config/PDB/HPA changes — before touching anything else.
- Sweep cluster-wide events sorted by time, not just the one service that was reported, to catch a shared root cause (node failure, resource pressure) affecting multiple services at once.
- Pull `--previous` logs on any crash-looping pod immediately — the current container likely hasn't logged the failure yet.
- Rule out node-level and dependency-level causes before assuming the reported service's own code is at fault.
- Post a working theory or "still investigating, here's what we've ruled out" update before the escalation timer runs out — communication under time pressure is itself part of the job.

> 💬 **Say:** "I always start with 'what changed' and a cluster-wide event sweep before drilling into the specific pod that was reported — most incidents correlate with a recent deploy or a shared node/dependency problem, and checking those first is a 30-second investment that often resolves the incident before I've even opened detailed logs."

---

### Q: How do you prepare for a Kubernetes control-plane version upgrade so nothing breaks?
- Read the official Kubernetes deprecation guide and the specific release notes for every minor version between current and target — API removals are documented well in advance, there's no excuse for being surprised by them.
- Run a deprecated-API scanner (`pluto`, `kubent`) against both the live cluster and the manifest repository in CI, gated so PRs introducing a soon-to-be-removed API version fail the build.
- Upgrade one minor version at a time even if the target is further away — skipping versions means missing the deprecation warnings that would have been surfaced along the way, and most managed offerings (EKS) only support sequential minor-version upgrades anyway.
- Test the upgrade against a staging cluster with production-like manifests first, and audit every PDB (see [PodDisruptionBudget.md](../Components/PodDisruptionBudget/PodDisruptionBudget.md)) against current replica counts before touching node groups, since a single bad PDB can stall the entire rollout as covered in Slide 1.
- Check third-party controllers/CRDs (ingress controllers, cert-manager, service mesh) for compatibility with the target control-plane version — a CRD's API version can lag behind what the new control plane expects.

> 💬 **Say:** "Upgrades fail for two predictable reasons — a removed API nobody scanned for, or a PDB/replica misconfiguration that stalls the node rollout — so my prep is a deprecated-API scan across the whole manifest repo plus a PDB audit against real replica counts, done in staging, before I touch anything in production."

---

### Q: A node is stuck `NotReady` and a PDB is blocking a drain at the same time — which do you fix first, and does the order matter?
- They're actually independent problems that happen to surface together during upgrades: `NotReady`/eviction timing governs *involuntary* disruption (the node just died or lost network), while a PDB blocking a drain governs *voluntary* disruption (someone is deliberately trying to evict a healthy pod for maintenance) — see the voluntary-vs-involuntary distinction in [PodDisruptionBudget.md](../Components/PodDisruptionBudget/PodDisruptionBudget.md).
- If the node is genuinely `NotReady` (dead/unreachable), the PDB is irrelevant to that node — the `NoExecute` taint and toleration-seconds timer, not the eviction API, will move those pods regardless of any PDB, because a dead node's pods are gone whether or not the budget allows it.
- The PDB only matters for the *other*, healthy nodes you're trying to drain as part of the same upgrade — fix that one first since it's the one actually blocking forward progress on a rollout; the `NotReady` node will resolve itself on its own eviction timer or by being terminated/replaced by the node group.

> 💬 **Say:** "PDBs and the NotReady toleration timer solve different problems — PDBs only ever gate voluntary evictions on healthy nodes, they have zero say over what happens on a node that's actually died. So if I see both during an upgrade, I focus on the PDB first since that's the one actually blocking the rollout; the dead node resolves on its own via the taint-eviction timer."

---
