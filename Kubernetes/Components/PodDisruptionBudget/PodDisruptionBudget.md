# PodDisruptionBudget (PDB)

> A PDB throttles **voluntary** disruptions (drains, autoscaler scale-downs, manual evictions) by capping how many pods of a workload can be evicted at once via the Eviction API — it does nothing for hardware failures, kernel panics, or `kubectl delete`. Getting this distinction wrong is the #1 reason PDBs "don't work" or silently stall cluster upgrades in production.

## Voluntary vs Involuntary Disruptions — the entire point of PDB

A PDB only ever intervenes in **voluntary** disruptions — actions initiated by a person or controller that *could* have been delayed or avoided. It provides **zero protection** against **involuntary** disruptions, which are failures outside anyone's control.

| Disruption type | Examples | Does a PDB help? |
|---|---|---|
| Voluntary | `kubectl drain` (node maintenance/upgrade), Cluster Autoscaler scaling down a node, manual `kubectl delete pod` **routed through eviction** (e.g. `kubectl delete pod --wait` via some tooling, or explicit eviction API calls), descheduler evictions | ✅ Yes — throttled/blocked if it would violate the budget |
| Involuntary | Node hardware failure, kernel panic, OOM kill, network partition, VM host failure, `kubectl delete pod` (raw delete, bypasses eviction) | ❌ No — cannot be blocked, PDB is never consulted |

This is the single most misunderstood aspect of PDBs in interviews and in production incidents: **"I have a PDB, why did my pods still go down?"** — the answer is almost always that the disruption was involuntary, or it was a raw delete that skipped the Eviction API entirely (see below).

## The Eviction API Mechanism

Well-behaved voluntary-disruption initiators (`kubectl drain`, Cluster Autoscaler, managed node group upgrades, the descheduler) do **not** call `DELETE` on the pod directly. They call the **`pods/eviction` subresource** — a dedicated API that lets the API server enforce policy before the pod is removed.

Flow:
1. Initiator (e.g. `kubectl drain`) POSTs an `Eviction` object to `/api/v1/namespaces/<ns>/pods/<pod>/eviction`.
2. The API server looks up any PDB whose `selector` matches the pod's labels.
3. It checks the PDB's **current computed status** — specifically `status.disruptionsAllowed` — which is continuously maintained by the **disruption controller** (a controller-manager loop that watches matching pods and recalculates `currentHealthy`, `desiredHealthy`, and `disruptionsAllowed`).
4. If `disruptionsAllowed > 0`, the eviction is admitted, the pod is deleted, and `disruptionsAllowed` is decremented (until the controller recomputes on the next reconcile).
5. If `disruptionsAllowed == 0`, the API server **rejects the request with HTTP 429 Too Many Requests**. The initiator is expected to back off and retry later (`kubectl drain` will keep retrying until it succeeds or you give up and `--force`).

```mermaid
sequenceDiagram
    participant D as kubectl drain / Cluster Autoscaler
    participant API as API Server
    participant DC as Disruption Controller
    participant PDB as PodDisruptionBudget (status)
    participant Pod as Target Pod

    DC->>PDB: continuously recompute disruptionsAllowed
    D->>API: POST /pods/{name}/eviction
    API->>PDB: read status.disruptionsAllowed
    alt disruptionsAllowed > 0
        API->>Pod: delete pod (graceful termination)
        API->>PDB: decrement disruptionsAllowed
        API-->>D: 200 OK
    else disruptionsAllowed == 0
        API-->>D: 429 Too Many Requests
        Note over D: drain/CA retries later;<br/>node stays cordoned & undrained
    end
```

Contrast this with a **raw `kubectl delete pod <name>`**: it calls the pod's `DELETE` endpoint directly, never touches the eviction subresource, and is **not evaluated against any PDB at all**. This is the classic confusion: someone (or some script, or a chaos tool) deletes a pod directly, the "protected" pod goes down anyway, and the PDB gets blamed for "not working" when it was never in the code path.

```bash
# This IS routed through the Eviction API and IS subject to PDB checks:
kubectl drain node-1 --ignore-daemonsets --delete-emptydir-data

# This is NOT — bypasses PDB entirely:
kubectl delete pod my-app-abc123
```

## minAvailable vs maxUnavailable

Mutually exclusive — a single PDB spec sets exactly one of them, never both.

| Field | Meaning | Accepts |
|---|---|---|
| `minAvailable` | Minimum number/percentage of pods that must remain healthy after any voluntary disruption | Absolute int or percentage string (e.g. `"50%"`) |
| `maxUnavailable` | Maximum number/percentage of pods that may be unhealthy/evicted at once | Absolute int or percentage string (e.g. `"25%"`) |

Percentage rounding:
- `minAvailable: "50%"` on 3 replicas → rounds **up** to 2 (ceil), so at most 1 pod can be evicted at a time.
- `maxUnavailable: "50%"` on 3 replicas → rounds **down** to 1 (floor), so at most 1 pod can be evicted at a time.
- Kubernetes always resolves the percentage against the **current `.spec.replicas` of the owning controller** (Deployment/StatefulSet/ReplicaSet), not the number of pods currently `Ready`. If replicas change, `disruptionsAllowed` is recomputed automatically.

Use `maxUnavailable` when you think in terms of "how much capacity can I sacrifice" (common for large stateless fleets). Use `minAvailable` when you think in terms of "how much capacity must always be up" (common for quorum-based systems like etcd, ZooKeeper, or anything with a hard minimum for read/write availability).

## The Classic Single-Replica Gotcha

The most common production incident tied to PDBs:

```yaml
# Deployment: replicas: 1
# PDB: minAvailable: 1
```

With `replicas: 1` and `minAvailable: 1`, the disruption controller computes `currentHealthy=1`, `desiredHealthy=1`, so `disruptionsAllowed=0` **permanently** — evicting the one and only pod would drop available count to 0, which always violates the budget. The pod can **never** be voluntarily evicted.

Symptom: `kubectl drain` hangs forever (or keeps 429ing and retrying) on any node that hosts this pod. A node upgrade, a Cluster Autoscaler scale-down, a managed node group rolling upgrade — all stall indefinitely on this one node, with no error surfaced anywhere except repeated `Cannot evict pod as it would violate the pod's disruption budget` events.

```bash
# Diagnose: find pods blocking a drain
kubectl get pdb -A
kubectl describe pdb <name> -n <namespace>
# Look at: ALLOWED DISRUPTIONS column == 0 is the red flag

kubectl get events -n <namespace> --field-selector reason=FailedEviction
```

Fix — pick one, depending on whether the workload can tolerate brief unavailability:
- **Scale to `replicas: 2+`** if the workload should genuinely be highly available — this is the correct fix for anything user-facing.
- **Loosen the PDB** to `maxUnavailable: 1` (which for a single replica still evaluates to "1 pod may be down" — i.e., effectively no protection, but at least doesn't block forever) if the workload is a true singleton that tolerates downtime during maintenance.
- **Remove the PDB entirely** for genuinely single-instance, restart-tolerant workloads (dev tools, batch singletons) where blocking node maintenance is worse than a few seconds of downtime.

## Selector Precision — a Silent Failure Mode

A PDB's `selector` is just a label selector, exactly like a Service or Deployment selector. If it doesn't precisely match the target pods — a typo, a stale label after a refactor, or a selector that matches **zero** pods — the PDB provides **no protection whatsoever**, and there is **no error, warning, or event**. It just silently does nothing; evictions proceed as if the PDB didn't exist.

This is worse than not having a PDB at all, because it creates false confidence ("we have a PDB for that, we're covered") that isn't backed by reality.

Always verify a PDB is actually bound to the pods you expect:

```bash
kubectl get pdb -n production
# NAME          MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
# api-server    2               N/A               1                    10d

# If ALLOWED DISRUPTIONS looks wrong (e.g. equals total replica count),
# the selector likely matches 0 pods — cross-check:
kubectl get pods -n production -l app=api-server --show-labels
kubectl describe pdb api-server -n production   # shows "Status: Allowed disruptions: N"
```

If the selector matches zero pods, `describe` typically shows `Total: 0`, `Allowed disruptions: 0` or an unexpectedly permissive number — either way, cross-reference the pod count manually; don't trust the PDB object's existence as proof it's effective.

## Interaction with StatefulSet Rollouts and Scaling

StatefulSets already enforce their own ordered rollout/scaling (reverse-ordinal termination, one-at-a-time by default). A PDB on a StatefulSet adds an **additional, independent constraint** evaluated only for voluntary evictions (drains, CA) — it does **not** change how the StatefulSet controller itself performs rolling updates or scale-down, because the StatefulSet controller deletes/replaces its own pods directly (not via the eviction API) as part of its native rollout logic.

Where the PDB matters for a StatefulSet is specifically **external** voluntary disruptions: a node drain during a Kubernetes/node upgrade will hit the eviction API for `postgres-1`, and if `minAvailable` for the `postgres` PDB would be violated (e.g. quorum-based system, `minAvailable: 2` on a 3-node etcd/ZK/Kafka cluster), the drain is rejected until enough replicas are healthy elsewhere. This is exactly the protection you want for quorum systems — you never want a drain to accidentally evict 2 of 3 Kafka brokers concurrently and lose the partition leader and its only in-sync replica.

## Interaction with Cluster Autoscaler

Cluster Autoscaler (CA) evaluates PDBs **before** picking a node to scale down. During scale-down evaluation, CA simulates draining a candidate node; if evicting any pod on that node would violate its PDB, CA **skips that node** as a scale-down candidate — it does not force the issue or wait.

This is one of the most common "why won't this obviously underutilized node scale down" questions in real clusters. The node looks empty/idle, but it hosts one pod backed by a tight PDB (often the single-replica gotcha above), so CA silently passes over it forever.

```bash
# Check CA's own reasoning (if CA status configmap/logs are exposed)
kubectl get configmap cluster-autoscaler-status -n kube-system -o yaml

# Look for "NoScaleDown" reasons per node, e.g.:
#   NotUnneeded: pod tied to PDB would be evicted, violating budget
```

## Interaction with EKS / Self-Managed Node Group Rolling Upgrades

A managed node group upgrade (EKS Managed Node Groups, `eksctl upgrade nodegroup`, or a self-managed ASG rolling replacement via a launch template bump) performs, per node: cordon → drain (via Eviction API) → wait for drain success → terminate instance → replace. This is exactly the same eviction path as `kubectl drain`.

Consequence: a single misconfigured PDB anywhere in the cluster — most often the single-replica `minAvailable: 1` gotcha — can stall the **entire node group rollout**, not just one node, because EKS's rolling upgrade typically processes nodes sequentially and won't proceed to force-terminate a node stuck mid-drain (depending on configured drain timeout). This has caused real multi-hour-stalled upgrade incidents where an unrelated dev-team workload's PDB blocked an unrelated platform-team's node upgrade, and nobody noticed until someone checked why the upgrade had been "in progress" for 3 hours.

```bash
# Diagnose a stuck EKS managed node group upgrade
kubectl get nodes                                   # look for nodes stuck SchedulingDisabled (cordoned)
kubectl describe node <stuck-node>                  # check taints/conditions
kubectl get pods --all-namespaces --field-selector spec.nodeName=<stuck-node>
kubectl get pdb --all-namespaces                    # scan for ALLOWED DISRUPTIONS == 0
kubectl get events --all-namespaces --field-selector reason=FailedEviction
```

Operational takeaway: audit `minAvailable`/`maxUnavailable` on every PDB against actual `replicas` **before** kicking off a cluster/node upgrade, especially for anything with `replicas: 1` or an aggressive `minAvailable`.

## Common Interview Questions

**Q: Does a PodDisruptionBudget protect against node failure?**
No — a PDB only governs voluntary disruptions initiated through the Eviction API (`kubectl drain`, Cluster Autoscaler, managed node group upgrades). A node hardware failure, kernel panic, or OOM kill is an involuntary disruption; the kubelet or the node simply disappears, there's no eviction request for the PDB to intercept, and the pod is gone regardless of what the PDB says. The only real defense against involuntary disruption is running enough replicas spread across failure domains (zones/nodes) via anti-affinity or topology spread constraints — a PDB doesn't create availability, it only paces how fast you can voluntarily remove availability that already exists.

**Q: Why did my pod get evicted even though I have a PDB for it?**
Two likely causes, both common: either the disruption was involuntary (node failure, OOM) and never went through the Eviction API, or someone/something bypassed the Eviction API with a raw `kubectl delete pod` or the controller (e.g. a Deployment rolling update replacing pods) deleted it directly rather than evicting it — Deployment rollouts do not consult PDBs on the pods they replace themselves, only external evictors do. The fix isn't to "fix the PDB," it's to identify what actually deleted the pod: check `kubectl get events` for `Killing` vs `Evicted` reasons, and audit any automation/scripts with delete permissions on pods.

**Q: What's the danger of `replicas: 1` combined with `minAvailable: 1`?**
The math never allows a voluntary eviction: with 1 desired and 1 required available, evicting the only pod would drop availability to 0, so `disruptionsAllowed` is permanently 0. This isn't a transient state — it holds forever until you change replicas or the PDB. In practice this manifests as a node stuck in `cordon`/`drain` indefinitely during any maintenance operation that touches that node, which can stall an entire node group rolling upgrade. Fix by scaling to 2+ replicas (if the workload should be HA) or relaxing to `maxUnavailable: 1` / removing the PDB (if brief downtime for a true singleton is acceptable).

**Q: How do you verify a PDB is actually working, not just present?**
`kubectl get pdb` and check the `ALLOWED DISRUPTIONS` column against your expected replica count and disruption tolerance — if it shows `0` when you expect headroom, or an unexpectedly high number equal to total replicas, the selector probably isn't matching the pods you think it is. Cross-check with `kubectl get pods -l <same-selector> --show-labels` to confirm pod count and labels line up. A PDB with a broken selector (typo, stale label after a refactor) matches zero pods, produces no error or warning anywhere, and silently provides zero protection — this is worse than no PDB because teams assume they're covered when they aren't.

**Q: minAvailable vs maxUnavailable — how do you choose, and how does percentage rounding work?**
They're mutually exclusive; pick whichever framing matches how you reason about the workload. `minAvailable` rounds percentages **up** (ceiling) — conservative, favors availability, good for quorum systems (etcd, ZooKeeper, Kafka) where you must never drop below a hard floor. `maxUnavailable` rounds percentages **down** (floor) — favors throughput of the disruption/drain process, good for large stateless fleets where you want to move through node drains quickly and can tolerate proportional capacity dips. Both are always evaluated against the controller's current `.spec.replicas`, not the live ready-pod count, and are recomputed automatically as replicas change.

**Q: Why won't Cluster Autoscaler scale down a node that looks completely idle?**
CA simulates draining every scale-down candidate node before acting, and if evicting any pod scheduled there would violate that pod's PDB, CA skips the node entirely — silently, with the reason only visible in CA's own logs/status configmap (`NotUnneeded` / PDB-related reason), not as a cluster event you'd notice by default. This is frequently caused by exactly the single-replica PDB gotcha: one lone pod with `minAvailable: 1` pins down a node indefinitely regardless of how underutilized it is. Always check `kubectl get pdb -A` for zero `ALLOWED DISRUPTIONS` entries when diagnosing "why won't this node scale down."
