# 🎤 Storage & StatefulSet Incidents
**7 Slides · PVC/PV Binding, AZ Affinity, StatefulSet Data Retention, Multi-Attach, RWX, Resize, Reclaim Policy + Q&A**

---

# 🔴 Slide 1 · Scenario: Pod Stuck in `ContainerCreating` — Volume Node Affinity Conflict

**🏗️ Setup**
> *A pod that was running fine gets rescheduled after a node drain. It comes back stuck in `ContainerCreating` and never recovers. The PVC it depends on shows `Bound`, so at first glance storage looks healthy.*

**❓ The Question**
`kubectl describe pod` shows a scheduling warning about volume node affinity. Walk me through your diagnosis — what actually happened, and what's the real fix (not just a workaround)?

```
│ Events:
│   Type     Reason            Age   From               Message
│   ----     ------            ----  ----               -------
│   Warning  FailedScheduling  45s   default-scheduler  0/6 nodes are available:
│            2 node(s) had volume node affinity conflict, 4 node(s) didn't match
│            pod topology spread constraints.
```

**🔍 Diagnosis**
1. `kubectl get pvc app-data -o yaml` and `kubectl get pv <bound-pv> -o yaml` — check `nodeAffinity.required` on the PV; it will pin to a specific `topology.ebs.csi.aws.com/zone` label (e.g. `us-east-1a`).
2. `kubectl get nodes -L topology.kubernetes.io/zone` — confirm which AZ the schedulable/available nodes are actually in. Usually the surviving nodes are in `us-east-1b` or `1c`.
3. Check the StorageClass used at provisioning time: `kubectl get sc gp3 -o yaml` — look at `volumeBindingMode`. If it's `Immediate`, the EBS volume was created the moment the PVC was submitted, before any pod was scheduled — so it landed in whatever AZ was "current" at creation time, with zero awareness of where the pod would end up.
4. Confirm the mismatch: PV lives in `us-east-1a`, but the only nodes with capacity right now are in `us-east-1b` — EBS volumes cannot cross AZs, so the scheduler correctly refuses to place the pod anywhere.

**✅ Fix**
```yaml
# The permanent fix: change the StorageClass binding mode
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
volumeBindingMode: WaitForFirstConsumer  # ← delays provisioning until pod IS scheduled
reclaimPolicy: Delete
allowVolumeExpansion: true
```

```bash
# Immediate remediation for the stuck pod (existing PV is already zone-locked, can't be moved)
kubectl get pod app-0 -o wide                      # confirm which node/AZ it's pending on
kubectl get pv <pv-name> -o jsonpath='{.spec.nodeAffinity}'  # confirm the locked-in AZ

# If capacity exists back in the original AZ, cordon/uncordon or scale the ASG there
# so the scheduler has a valid node to place the pod on again
aws autoscaling set-desired-capacity --auto-scaling-group-name eks-nodes-us-east-1a --desired-capacity 2

# Longer-term: apply the WaitForFirstConsumer StorageClass to all NEW PVCs going forward
kubectl apply -f storageclass-gp3.yaml
```

**🛡️ Prevention**
- Always set `volumeBindingMode: WaitForFirstConsumer` on EBS-backed StorageClasses in multi-AZ clusters — see `../Components/Storage/Storage.md`
- Spread node group capacity evenly across AZs so a single-AZ node loss doesn't strand zone-locked volumes
- For workloads that must tolerate AZ loss without manual intervention, consider EFS (`ReadWriteMany`, regional) instead of EBS — see Slide 4

> ⚠️ **Never:** Delete and recreate the PVC to "force" a new volume in the right AZ without first confirming reclaim policy — if `reclaimPolicy: Delete` is set, deleting the PVC destroys the underlying EBS volume and the data with it (see Slide 6)

---

# 🔴 Slide 2 · Scenario: StatefulSet Recreated With Unexpectedly Stale Data

**🏗️ Setup**
> *An engineer renamed a StatefulSet as part of a refactor — deleted the old one, applied a new manifest with a temporary different name for testing, then reverted back to the original name a day later. The pods came back healthy, but the app is serving data from a week ago. Nobody wiped anything on purpose.*

**❓ The Question**
The team is confused — they deleted the StatefulSet, so why would old data still be there? Walk me through what actually happens to storage when a StatefulSet is deleted.

**🔍 Diagnosis**
1. `kubectl get pvc -l app=postgres` — even with the StatefulSet gone, the PVCs (`postgres-data-postgres-0`, `postgres-data-postgres-1`, etc.) are still present, still `Bound`.
2. This is intentional: **deleting a StatefulSet never deletes its PVCs** — it's a deliberate safety mechanism against accidental data loss, documented in `../Components/StatefulSet/statefulset.md`.
3. When the StatefulSet was reverted back to the original name, its `volumeClaimTemplates` generated the exact same deterministic PVC names (`<template>-<statefulset>-<ordinal>`) — so pod `postgres-0` re-bound to the SAME pre-existing PVC it had before, silently resuming the old data.
4. Confirm by checking PV creation timestamp vs. StatefulSet creation timestamp: `kubectl get pv <pv> -o jsonpath='{.metadata.creationTimestamp}'` — the PV predates the "new" StatefulSet, proving it's a re-bind, not a fresh volume.

**✅ Fix**
```bash
# Confirm which PVCs are stale re-binds vs genuinely new
kubectl get pvc -l app=postgres -o custom-columns=\
NAME:.metadata.name,VOLUME:.spec.volumeName,CREATED:.metadata.creationTimestamp

# If the intent really was a full data reset, PVCs must be deleted EXPLICITLY —
# StatefulSet deletion alone will never do this for you
kubectl delete statefulset postgres --cascade=orphan   # ← pods go, PVCs remain (default behavior)
kubectl delete pvc -l app=postgres                     # ← explicit, deliberate wipe

# Then reapply — pods will provision brand-new PVCs/PVs from volumeClaimTemplates
kubectl apply -f statefulset.yaml
```

**🛡️ Prevention**
- Treat `kubectl delete pvc` as a deliberate, reviewed action — never assume StatefulSet lifecycle manages it for you
- Before any StatefulSet rename/recreate exercise, snapshot the current PVC-to-PV mapping (`kubectl get pvc -o wide`) so you know exactly what will be re-attached
- Use distinct StatefulSet names for genuinely new environments (e.g., `postgres-v2`) instead of reusing a name that was recently deleted, to avoid the deterministic-naming collision entirely
- Document this behavior explicitly in runbooks — it is one of the most common "gotcha" surprises for teams new to StatefulSets

> ⚠️ **Never:** Assume "I deleted the StatefulSet" means "the data is gone" — in the vast majority of real incidents it's the opposite problem (stale data silently resurfacing), not data loss

---

# 🔴 Slide 3 · Scenario: "Multi-Attach error for volume" After Node Crash

**🏗️ Setup**
> *A worker node hard-crashes (kernel panic, hardware fault — no graceful shutdown). Kubernetes correctly detects the node is `NotReady` and reschedules the pod elsewhere, but the replacement pod refuses to start.*

**❓ The Question**
You see this error on the rescheduled pod. What's actually going on, and how do you resolve it safely?

```
│ Warning  FailedAttachVolume  2m  attachdetach-controller
│ Multi-Attach error for volume "pvc-abc123ef-4567-89ab-cdef-0123456789ab"
│ Volume is already exclusively attached to one node and can't be attached to another
```

**🔍 Diagnosis**
1. Confirm the volume's current attachment state directly against AWS, not just Kubernetes: `aws ec2 describe-volumes --volume-ids vol-0abc123 --query 'Volumes[*].Attachments'` — it will still show `attached` to the dead instance ID.
2. This is the expected consequence of EBS being strictly `ReadWriteOnce` (RWO) — an EBS volume can only be attached to one EC2 instance at a time, and AWS has no way to know the old node is truly gone (it never sent a graceful detach).
3. Check `kubectl get volumeattachment` — the stale `VolumeAttachment` object for the dead node may still be present, blocking the CSI driver from attaching to the new node.
4. Kubernetes' attach-detach controller has a built-in force-detach timeout (default 6 minutes, `--attach-detach-reconcile-sync-period` / node monitor grace period tunables) — after that window it will force-detach automatically and let the new node attach.

**✅ Fix**
```bash
# Step 1: verify the volume is genuinely stuck on the dead node
aws ec2 describe-volumes --volume-ids vol-0abc123 \
  --query 'Volumes[*].{State:State,Attachments:Attachments}'

# Step 2: normal path — just wait. K8s force-detaches after ~6 min once the node
# is confirmed NotReady/gone. Re-check pod status periodically:
kubectl get pod app-0 -w

# Step 3: ONLY if the wait has clearly failed (node object was force-deleted from
# etcd without proper drain, or AWS never released the lock) — manual force detach
aws ec2 detach-volume --volume-id vol-0abc123 --force

# Step 4: clean up any orphaned VolumeAttachment object referencing the dead node
kubectl get volumeattachment | grep vol-0abc123
kubectl delete volumeattachment <stuck-attachment-name>
```

**🛡️ Prevention**
- Use `ReadWriteOncePod` instead of `ReadWriteOnce` where supported (K8s 1.22+) for extra safety against split-brain double-mount attempts
- Ensure node draining/termination is graceful wherever possible (spot instance interruption handlers, `terminationGracePeriodSeconds` tuned appropriately) so volumes detach cleanly before the node disappears
- Tune `pod-eviction-timeout` and node monitor grace period deliberately — don't leave defaults unexamined for latency-sensitive stateful workloads
- For workloads that truly cannot tolerate this multi-minute gap, this is a strong signal to reconsider EBS vs. EFS/distributed storage (Slide 4)

> ⚠️ **Never:** Reach for `aws ec2 detach-volume --force` as your first move — forcing detach while the old node is still alive (e.g., a network partition, not a real crash) can corrupt the filesystem if both nodes end up writing to it; always confirm the node is genuinely dead first

---

# 🔴 Slide 4 · Scenario: Multiple Pods Need Concurrent Write Access to the Same Volume

**🏗️ Setup**
> *A new batch-processing workload needs several pods, spread across several nodes, all writing to a shared dataset simultaneously. It was provisioned on the team's default EBS-backed StorageClass, copy-pasted from an existing database deployment — and pods are now failing to schedule or mount.*

**❓ The Question**
Why is this failing, and what's the right storage choice here?

```
│ Warning  FailedMount  3m  kubelet
│ Unable to attach or mount volumes: unmounted volumes=[shared-data], unattached
│ volumes=[shared-data]: timed out waiting for the condition
│
│ Warning  FailedAttachVolume  3m  attachdetach-controller
│ Multi-Attach error for volume "pvc-shared01" Volume is already exclusively
│ attached to one node and can't be attached to another
```

**🔍 Diagnosis**
1. `kubectl get pvc shared-data -o jsonpath='{.spec.accessModes}'` → `["ReadWriteOnce"]`, backed by `provisioner: ebs.csi.aws.com`.
2. EBS is block storage — per `../Components/Storage/Storage.md`, it fundamentally only supports `ReadWriteOnce`: the underlying EBS volume can be attached to exactly one EC2 instance at a time, regardless of how many pods try to reference the PVC.
3. As soon as a second pod on a different node tries to mount the same PVC, it hits the same `Multi-Attach error` seen in Slide 3 — but this time it's not a transient node-crash artifact, it's a permanent architectural mismatch between the access pattern required and the storage type chosen.
4. Confirm the actual requirement with the app team: true concurrent multi-node read+write, not just "multiple replicas that happen to each want their own copy" (which would actually be fine on EBS via separate PVCs, e.g. via `volumeClaimTemplates` in a StatefulSet).

**✅ Fix**
```yaml
# Migrate to an EFS-backed StorageClass — NFS-based, supports ReadWriteMany
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: efs-shared
provisioner: efs.csi.aws.com     # ← EFS CSI driver, not ebs.csi.aws.com
parameters:
  provisioningMode: efs-ap
  fileSystemId: fs-0abc123def456
  directoryPerms: "700"
reclaimPolicy: Retain
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: shared-data
spec:
  accessModes:
    - ReadWriteMany                # ← now legal, multiple nodes can attach concurrently
  storageClassName: efs-shared
  resources:
    requests:
      storage: 100Gi
```

**🛡️ Prevention**
- Decide access pattern BEFORE picking a StorageClass: per-pod dedicated volume → EBS; genuinely shared concurrent access → EFS
- Don't copy-paste StorageClass choice from an unrelated workload — audit `accessModes` requirements explicitly during design review
- Understand the trade-off going in: EFS is NFS-based and has materially different performance characteristics than EBS — higher latency per operation, throughput that scales with file system size/mode rather than a dedicated IOPS allocation. It is the right tool for shared config, uploads, and ML datasets, but a poor substitute for a high-IOPS single-writer database volume
- See `../Flows/volumeCreationFlow.md` for the full access-mode-by-storage-type comparison table

> ⚠️ **Never:** "Fix" a Multi-Attach error under this scenario by switching everything to `hostPath` or a single pod handling all writes — that just trades one architectural problem (wrong storage class) for another (no scheduling flexibility, single point of failure)

---

# 🔴 Slide 5 · Scenario: PVC Resized in Manifest, But Capacity Doesn't Change

**🏗️ Setup**
> *Disk usage on a stateful app is climbing toward 100%. An engineer edits the PVC manifest, bumping `storage: 20Gi` to `storage: 50Gi`, and applies it. `kubectl get pvc` still shows `20Gi`, and the app is still throwing "no space left on device."*

**❓ The Question**
The manifest clearly says 50Gi now — why hasn't anything changed, and how do you fix it without an outage?

**🔍 Diagnosis**
1. `kubectl get pvc app-data` — check the `CAPACITY` column and `kubectl describe pvc app-data` for any `Conditions` like `FileSystemResizePending` or resize-related events.
2. **Cause A — expansion not enabled at all:** `kubectl get sc gp3 -o jsonpath='{.allowVolumeExpansion}'` — if this is missing or `false`, the PVC edit is silently rejected/ignored at the API level; the StorageClass must explicitly opt in.
3. **Cause B — expansion enabled, but filesystem not grown:** if `allowVolumeExpansion: true` IS set, check `kubectl describe pvc app-data` for condition `FileSystemResizePending: True` — this means the underlying EBS volume itself was resized in AWS, but the filesystem inside the container (ext4/xfs) hasn't been grown to use the new space yet. On older CSI driver versions this requires a pod restart to trigger `NodeExpandVolume`; newer drivers do it online.
4. Cross-check directly against AWS: `aws ec2 describe-volumes --volume-ids vol-0abc123 --query 'Volumes[*].Size'` — if this already shows `50`, the block device grew fine and the remaining gap is purely the filesystem layer (Cause B); if it still shows `20`, the StorageClass never allowed expansion in the first place (Cause A).

**✅ Fix**
```yaml
# Cause A fix: enable expansion on the StorageClass first — this is a one-time,
# cluster-level setting; existing PVCs cannot expand without it
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3
provisioner: ebs.csi.aws.com
allowVolumeExpansion: true    # ← must be set BEFORE editing any PVC size
```

```bash
# Re-apply the PVC size increase now that expansion is allowed
kubectl patch pvc app-data -p '{"spec":{"resources":{"requests":{"storage":"50Gi"}}}}'

# Cause B: confirm resize condition, then restart the pod to trigger filesystem expansion
kubectl describe pvc app-data | grep -A2 Conditions
# Conditions:
#   Type                      Status
#   FileSystemResizePending   True        # ← block device grew, fs did not

kubectl delete pod app-0     # ← StatefulSet recreates it; kubelet runs NodeExpandVolume on start
kubectl get pvc app-data -w  # ← watch CAPACITY column flip to 50Gi
```

**🛡️ Prevention**
- Always set `allowVolumeExpansion: true` on every StorageClass used for stateful workloads from day one — see `../Components/Storage/Storage.md`
- Alert on disk usage well before 100% (e.g., 75-80% threshold) so a resize is never done under emergency pressure
- Know your CSI driver version's online-expansion support — recent `ebs.csi.aws.com` versions expand the filesystem without a restart, but don't assume this for older clusters
- Bake a documented resize runbook into the on-call playbook so nobody is diagnosing Cause A vs. B for the first time during an incident

> ⚠️ **Never:** Assume editing the PVC YAML is sufficient and move on — always verify with `kubectl describe pvc` that both the volume AND filesystem actually grew; a "successful" `kubectl apply` on a PVC size field is not proof the disk pressure is resolved

---

# 🔴 Slide 6 · Scenario: Production PVC Accidentally Deleted — Data Unrecoverable

**🏗️ Setup**
> *An engineer, cleaning up what they believed was an unused dev PVC, runs `kubectl delete pvc` — but they were in the wrong namespace context. It was a production database PVC. Within seconds, the underlying volume is gone. There are no snapshots, no Velero backups.*

**❓ The Question**
Walk me through why this data is gone permanently, and what should have been in place to prevent this — since at this point there's nothing left to recover.

```
$ kubectl delete pvc postgres-data-postgres-0
persistentvolumeclaim "postgres-data-postgres-0" deleted

$ kubectl get pv pvc-9f8e7d6c
Error from server (NotFound): persistentvolumes "pvc-9f8e7d6c" not found
```

**🔍 Diagnosis**
1. `kubectl get sc gp3 -o jsonpath='{.reclaimPolicy}'` → `Delete` — this is the default `reclaimPolicy` for dynamically provisioned StorageClasses, per `../Components/Storage/Storage.md`.
2. With `reclaimPolicy: Delete`, deleting the PVC doesn't just release the PV — it cascades: PVC deleted → bound PV deleted → underlying EBS volume deleted, all within the same reconcile loop, with no manual confirmation step.
3. Confirm total loss: `aws ec2 describe-volumes --volume-ids vol-0abc123` returns nothing — the EBS volume itself, not just the Kubernetes objects pointing to it, is gone.
4. Check for any safety net that could still save the data: `aws ec2 describe-snapshots --filters "Name=volume-id,Values=vol-0abc123"` and `velero backup get` — if both come back empty, there is no recovery path; this incident is now purely a "what do we do going forward" conversation, not a "how do we restore" one.

**✅ Fix**
```yaml
# There is no fix for the lost data. The "fix" here is the prevention that should
# have existed BEFORE this happened — reclaimPolicy must be Retain for prod PVs.

apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3-prod
provisioner: ebs.csi.aws.com
reclaimPolicy: Retain          # ← PV and EBS volume survive PVC deletion
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
```

```bash
# Going forward: any PVC deletion in prod becomes a two-step, recoverable action
# Step 1: PVC delete only releases the PV (Retain policy) — volume is NOT destroyed
kubectl delete pvc postgres-data-postgres-0
kubectl get pv pvc-9f8e7d6c    # ← still exists, STATUS: Released

# Step 2: explicit, deliberate, separate action to actually remove the volume —
# gives a human a second chance to notice the mistake before data is destroyed
aws ec2 delete-volume --volume-id vol-0abc123
```

**🛡️ Prevention**
- Set `reclaimPolicy: Retain` on every StorageClass backing production stateful workloads — non-negotiable for databases, message queues, anything with `volumeClaimTemplates`
- Enable automated EBS snapshots on a schedule (AWS Backup / DLM lifecycle policies) independent of Kubernetes entirely — a snapshot layer that doesn't care what happens inside the cluster
- Run Velero with scheduled backups covering both Kubernetes objects and volume snapshots, so a full namespace/PVC accidental deletion is restorable within minutes
- Use `kubectl config` contexts/namespaces defensively — require `--context` and `-n` to be explicit in any destructive-command alias, and consider an admission webhook (OPA/Kyverno) that blocks `delete` on PVCs labeled `environment=production` without an override annotation

> ⚠️ **Never:** Treat "we'll just be more careful" as the prevention plan — the actual fix is removing the ability for a single `kubectl delete` to cascade into irreversible data loss in the first place; `reclaimPolicy: Retain` plus real backups are the only things that matter here, not vigilance

---

# 🎤 Slide 7 · Follow-up Q&A

---

### Q: What's your pre-flight checklist before deleting anything storage-related in production?
- Confirm current context and namespace explicitly: `kubectl config current-context` and `-n <namespace>` on every command, never rely on a default
- Check the reclaim policy of the PV in play (`kubectl get pv <name> -o jsonpath='{.spec.persistentVolumeReclaimPolicy}'`) — know whether this is reversible before you act
- Verify a recent backup/snapshot exists and is restorable, not just "scheduled to exist" — check `velero backup get` or `aws ec2 describe-snapshots` timestamps
- Confirm with `kubectl get pvc <name> -o jsonpath='{.metadata.labels}'` that this is actually the resource you think it is — production PVCs from StatefulSets follow predictable naming, but predictable names are also easy to typo between environments
- If the StorageClass is `Delete` policy and there's no recent backup, stop and get a second approver before proceeding

> 💬 **Say:** "Before any storage deletion in prod, I check three things — reclaim policy, backup recency, and that I'm in the right context — because a PVC delete under `Delete` reclaim policy with no backup is a one-way door, and I want to know that BEFORE I hit enter, not after."

---

### Q: How do you decide between EBS and EFS for a new stateful workload?
- Start with the access pattern: does exactly one pod/node need the volume at a time, or do multiple pods across multiple nodes need concurrent read+write?
- Single-writer, high-IOPS, latency-sensitive (databases, message queue logs) → EBS with `ReadWriteOnce`, per-pod via `volumeClaimTemplates` in a StatefulSet
- Multi-writer, shared dataset, cross-AZ tolerance needed (shared uploads, ML training data, shared config/cache) → EFS with `ReadWriteMany`
- Factor in the trade-off explicitly: EFS is NFS-based with higher per-operation latency than a dedicated EBS volume — don't reach for it just because RWX is convenient if the workload is actually IOPS-sensitive
- Also weigh blast radius: EBS is zone-locked (mitigated with `WaitForFirstConsumer`), EFS is regional and survives AZ loss without any topology awareness needed

> 💬 **Say:** "It comes down to one question — does more than one node need to write to this at the same time? If yes, that's EFS, full stop, because EBS physically cannot do it. If no, EBS wins on performance every time, and I'd rather eat the AZ-locking trade-off with `WaitForFirstConsumer` than take an NFS latency hit I don't need."

---

### Q: A StatefulSet pod is stuck and you need to force-recreate it — what could go wrong, and how do you do it safely?
- `kubectl delete pod <name>` is generally safe — the StatefulSet controller recreates it with the same ordinal and re-binds the same PVC, per `../Components/StatefulSet/statefulset.md`
- Danger zone is scaling operations combined with `Parallel` pod management policy — without `OrderedReady`, multiple pods can terminate/start simultaneously, which can violate quorum assumptions in distributed systems (e.g., losing 2 of 3 etcd/Cassandra nodes at once)
- Before force-deleting a stuck pod, check `kubectl get statefulset <name> -o jsonpath='{.spec.podManagementPolicy}'` and confirm the app can tolerate the ordinal being briefly unavailable
- If the pod is stuck due to a stale node reference (node was force-removed from the cluster), you may also need `kubectl delete pod <name> --grace-period=0 --force` — but only after confirming via `kubectl get node` that the old node is truly gone, otherwise you risk two instances of the same ordinal writing to shared assumptions simultaneously

> 💬 **Say:** "For a StatefulSet, deleting the pod is usually fine — the controller guarantees it comes back with the same identity and PVC. What I actually check first is the pod management policy and whether the app has quorum requirements that a brief ordinal gap could violate."

---
