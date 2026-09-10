# Kubernetes Node — Architecture, GPU & Non-GPU Deep Dive

> A Node is the worker machine in Kubernetes — physical server, VM, or cloud instance. Every Pod runs on a Node. This doc covers what lives on a Node, how the control plane manages nodes, and — in full depth — how GPU nodes differ from CPU-only nodes, how to schedule GPU workloads correctly, and all the operational patterns around both.

---

## What Runs on Every Node

Each Node runs three critical components regardless of whether it has GPUs:

```
┌─────────────────────────────────────────────────────────┐
│                         Node                            │
│                                                         │
│  ┌──────────┐  ┌─────────────┐  ┌────────────────────┐ │
│  │ kubelet  │  │ kube-proxy  │  │ Container Runtime  │ │
│  │ (agent)  │  │ (iptables/  │  │ (containerd/CRI-O) │ │
│  │          │  │  IPVS)      │  │                    │ │
│  └──────────┘  └─────────────┘  └────────────────────┘ │
│                                                         │
│  ┌──────────────────────────────────────────────────┐   │
│  │               Pod  Pod  Pod  Pod                 │   │
│  │         (containers running workloads)           │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

**kubelet** — the node agent. Registers the node with the API server, watches for Pods assigned to this node, starts/stops containers via the CRI, runs liveness/readiness probes, reports node and Pod status, manages volumes. Talks to the API server over HTTPS; the control plane never pushes — kubelet pulls.

**kube-proxy** — implements Kubernetes Service routing on the node. In `iptables` mode: installs iptables DNAT rules for every ClusterIP Service. In `IPVS` mode: programs the kernel's IPVS table (faster for large clusters, O(1) vs O(n)). In `nftables` mode (1.29+): same idea with nftables. Some CNIs (Cilium eBPF mode) skip kube-proxy entirely and handle Service routing in BPF maps.

**Container runtime** — the software that actually starts containers. Must implement the Container Runtime Interface (CRI). Options: containerd (default everywhere), CRI-O (RHEL ecosystem), Docker via cri-dockerd (deprecated). For GPU nodes, the runtime must be configured to expose GPU devices to containers.

---

## Node Registration and Lifecycle

```bash
# A node self-registers by kubelet calling:
# POST /api/v1/nodes
# with its hostname, labels, capacity (CPU, memory, ephemeral-storage, GPUs)

# View all nodes
kubectl get nodes
kubectl get nodes -o wide          # also shows internal/external IP, OS, kernel, runtime

# Node details
kubectl describe node <node-name>
# Shows: Labels, Taints, Conditions, Capacity, Allocatable, Pods

# Node conditions (what the control plane watches)
kubectl get node <node> -o jsonpath='{.status.conditions[*].type}'
# Ready, MemoryPressure, DiskPressure, PIDPressure, NetworkUnavailable
```

**Node Conditions:**

| Condition | Healthy | Problem |
|---|---|---|
| `Ready` | `True` | `False` (kubelet not healthy) / `Unknown` (no heartbeat) |
| `MemoryPressure` | `False` | `True` → kubelet starts evicting Pods |
| `DiskPressure` | `False` | `True` → kubelet evicts Pods, stops pulling images |
| `PIDPressure` | `False` | `True` → too many PIDs on node |
| `NetworkUnavailable` | `False` | `True` → CNI not configured |

When `Ready=Unknown` for >40s (node-monitor-grace-period), the node controller adds `node.kubernetes.io/unreachable:NoExecute` taint → pods evict after `tolerationSeconds` (default 300s).

---

## Node Labels and Capacity

Labels are how schedulers and operators identify node types. Kubernetes auto-applies well-known labels at registration:

```bash
kubectl get node worker-01 --show-labels

# Well-known auto-applied labels:
kubernetes.io/hostname=worker-01
kubernetes.io/os=linux
kubernetes.io/arch=amd64                    # or arm64 for ARM instances
node.kubernetes.io/instance-type=m5.xlarge  # cloud instance type
topology.kubernetes.io/region=us-east-1     # cloud region
topology.kubernetes.io/zone=us-east-1a      # AZ
```

**Node capacity vs allocatable:**
```bash
kubectl describe node worker-01 | grep -A10 "Capacity:\|Allocatable:"
# Capacity:           ← what the node physically has
#   cpu:              4
#   memory:           16Gi
#   pods:             110
# Allocatable:        ← what Pods can request (capacity minus system reserved)
#   cpu:              3800m    ← 200m reserved for kubelet/OS
#   memory:           15Gi     ← 1Gi reserved
#   pods:             110
```

System reserved is configured in kubelet via `--system-reserved` and `--kube-reserved` flags or kubelet config. Always set these — without them, Pods can starve the kubelet itself.

---

## 🗂️ GPU Nodes

---

## GPU Node Architecture — What's Different

A GPU node has everything a regular node has, PLUS:

```
┌──────────────────────────────────────────────────────────────────┐
│                         GPU Node                                 │
│                                                                  │
│  kubelet   kube-proxy   containerd                               │
│                              │                                   │
│                     ┌────────▼──────────┐                        │
│                     │  NVIDIA Container │  ← nvidia-container-  │
│                     │  Runtime (NCR)    │    toolkit             │
│                     └────────┬──────────┘                        │
│                              │ injects GPU into container        │
│  ┌─────────────────────────────────────────────────────────┐     │
│  │  NVIDIA Device Plugin (DaemonSet Pod on every GPU node) │     │
│  │  - Discovers GPUs on the node via NVML                  │     │
│  │  - Registers nvidia.com/gpu as an extended resource     │     │
│  │  - Reports count to kubelet → kubelet reports to API    │     │
│  └─────────────────────────────────────────────────────────┘     │
│                                                                  │
│  ┌──────────────────────────────────────────────────────┐        │
│  │  Physical GPUs: A100 x 8  (or H100, T4, V100, etc.) │        │
│  └──────────────────────────────────────────────────────┘        │
└──────────────────────────────────────────────────────────────────┘
```

The key additions on a GPU node:
1. **NVIDIA drivers** — installed on the host OS (not in a container)
2. **NVIDIA Container Toolkit (nvidia-container-runtime)** — a container runtime hook that injects GPU device files and CUDA libraries into the container at start time
3. **NVIDIA Device Plugin** — a DaemonSet that discovers GPUs and registers `nvidia.com/gpu` as a schedulable resource with Kubernetes

---

## NVIDIA Device Plugin — How It Works

The Device Plugin is how Kubernetes learns about GPUs on a node.

```yaml
# Device Plugin runs as a DaemonSet on every GPU node
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: nvidia-device-plugin-daemonset
  namespace: kube-system
spec:
  selector:
    matchLabels:
      name: nvidia-device-plugin-ds
  template:
    metadata:
      labels:
        name: nvidia-device-plugin-ds
    spec:
      # Only run on nodes with NVIDIA GPUs
      tolerations:
        - key: nvidia.com/gpu
          operator: Exists
          effect: NoSchedule
      nodeSelector:
        accelerator: nvidia
      priorityClassName: system-node-critical
      containers:
        - name: nvidia-device-plugin-ctr
          image: nvcr.io/nvidia/k8s-device-plugin:v0.14.5
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              drop: ["ALL"]
          volumeMounts:
            - name: device-plugin
              mountPath: /var/lib/kubelet/device-plugins   # plugin socket
      volumes:
        - name: device-plugin
          hostPath:
            path: /var/lib/kubelet/device-plugins
```

**What the Device Plugin does step-by-step:**
1. On start: calls NVML (NVIDIA Management Library) to enumerate all GPUs on the node
2. Registers a gRPC server on `/var/lib/kubelet/device-plugins/nvidia.com_gpu.sock`
3. Kubelet discovers the socket and calls `ListAndWatch` → Plugin reports available GPU IDs
4. Kubelet updates node capacity: `nvidia.com/gpu: 8` (or however many GPUs the node has)
5. When a Pod requesting `nvidia.com/gpu: 1` is scheduled here, kubelet calls `Allocate` on the plugin
6. Plugin returns the device ID + environment variables (`NVIDIA_VISIBLE_DEVICES=GPU-abc123`)
7. nvidia-container-runtime reads these env vars and exposes that GPU to the container

```bash
# Verify Device Plugin is working
kubectl get node gpu-node-01 -o json | jq '.status.capacity'
# {
#   "cpu": "96",
#   "memory": "768Gi",
#   "nvidia.com/gpu": "8",    ← device plugin registered 8 GPUs
#   "pods": "110"
# }

kubectl describe node gpu-node-01 | grep -A5 "Allocatable"
# Allocatable:
#   cpu:             94
#   memory:          750Gi
#   nvidia.com/gpu:  8        ← schedulable GPUs
```

---

## Scheduling GPU Workloads

GPU resources must be declared in both `requests` AND `limits` — they're not scalable like CPU/memory:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: gpu-training-job
spec:
  restartPolicy: Never
  containers:
    - name: trainer
      image: nvcr.io/nvidia/pytorch:23.10-py3
      command: ["python", "train.py"]
      resources:
        requests:
          memory: "64Gi"
          cpu: "8"
          nvidia.com/gpu: "2"      # request 2 GPUs
        limits:
          memory: "64Gi"
          cpu: "8"
          nvidia.com/gpu: "2"      # MUST equal requests for GPU
      env:
        - name: NVIDIA_VISIBLE_DEVICES
          value: all               # let NVIDIA runtime pick which GPUs
        - name: CUDA_VISIBLE_DEVICES
          value: "0,1"             # or explicitly specify GPU indices
```

**Rules for GPU scheduling:**
- `requests` must equal `limits` for GPU resources (integer only — no fractional GPUs in vanilla Kubernetes)
- A Pod gets exclusive access to the GPU(s) allocated — no sharing by default
- GPUs are not oversubscribed — if a node has 8 GPUs and a Pod requests 4, only 4 remain for other Pods
- GPU resources are freed only when the Pod terminates (not when it's idle)

---

## Node Labels for GPU Targeting

Use `nodeSelector` or `nodeAffinity` to ensure GPU workloads land on GPU nodes:

```yaml
spec:
  # Simple: nodeSelector
  nodeSelector:
    accelerator: nvidia-tesla-a100     # exact label match

  # Or: nodeAffinity (more expressive)
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: nvidia.com/gpu.product
                operator: In
                values:
                  - A100-SXM4-80GB
                  - A100-PCIE-40GB
              - key: nvidia.com/gpu.memory
                operator: Gt
                values: ["40000"]     # > 40GB VRAM
```

**Standard GPU node labels (set by NVIDIA GPU Feature Discovery or manually):**

```bash
# Applied by NVIDIA GPU Feature Discovery (GFD) DaemonSet automatically
nvidia.com/gpu.product=A100-SXM4-80GB
nvidia.com/gpu.memory=81920              # VRAM in MB
nvidia.com/gpu.count=8                   # GPUs on this node
nvidia.com/gpu.family=ampere             # GPU architecture
nvidia.com/cuda.driver.major=535
nvidia.com/cuda.runtime.major=12

# Custom labels you add manually
accelerator=nvidia                       # generic: has NVIDIA GPU
gpu-type=a100                            # specific model label
workload-type=ml-training                # dedicated for training jobs
```

---

## GPU Node Taints — Reserving Nodes for GPU Workloads

A common pattern: taint GPU nodes so only GPU workloads land there, preventing CPU workloads from consuming expensive GPU instances:

```bash
# Taint the GPU node
kubectl taint nodes gpu-node-01 nvidia.com/gpu=present:NoSchedule

# Or use a more descriptive key
kubectl taint nodes gpu-node-01 dedicated=gpu:NoSchedule
```

```yaml
# GPU workload Pod — must tolerate the taint
spec:
  tolerations:
    - key: "nvidia.com/gpu"
      operator: "Exists"
      effect: "NoSchedule"
    # Or match specific value:
    - key: "dedicated"
      operator: "Equal"
      value: "gpu"
      effect: "NoSchedule"
  nodeSelector:
    accelerator: nvidia
  containers:
    - resources:
        limits:
          nvidia.com/gpu: "1"
```

The NVIDIA Device Plugin DaemonSet itself needs this toleration to run on GPU nodes — which is why the official DaemonSet manifest includes it by default.

---

## MIG — Multi-Instance GPU (A100/H100)

NVIDIA Multi-Instance GPU (MIG) lets you physically partition an A100 or H100 into smaller independent GPUs. Each partition gets dedicated VRAM, compute cores, and memory bandwidth — completely isolated at hardware level.

```
┌──────────────────────────────────────────────────────────┐
│  A100 80GB GPU — MIG 7g.80gb (full) or split into:       │
│                                                          │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐   │
│  │ 2g.20gb  │ │ 2g.20gb  │ │ 2g.20gb  │ │ 1g.10gb  │   │
│  │ MIG slice│ │ MIG slice│ │ MIG slice│ │ MIG slice│   │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘   │
│  (20GB VRAM, 2/7 SMs)                                    │
└──────────────────────────────────────────────────────────┘
```

In Kubernetes with MIG enabled, the Device Plugin exposes slice resources instead of whole GPUs:

```bash
kubectl get node gpu-mig-node -o json | jq '.status.capacity'
# {
#   "nvidia.com/mig-1g.10gb": "2",    ← two 10GB MIG slices
#   "nvidia.com/mig-2g.20gb": "3",    ← three 20GB MIG slices
#   "nvidia.com/mig-3g.40gb": "1",    ← one 40GB MIG slice
# }
```

Pod requesting a MIG slice:
```yaml
resources:
  limits:
    nvidia.com/mig-2g.20gb: "1"    # request one 2g.20gb MIG slice
```

---

## Time-Slicing — Sharing One GPU Across Multiple Pods

For non-MIG GPUs (or when MIG isn't needed), the NVIDIA Device Plugin supports time-slicing: multiple Pods share one physical GPU via GPU time-slicing. **No memory isolation** — all Pods see the full GPU memory.

```yaml
# ConfigMap for Device Plugin — enable time-slicing
apiVersion: v1
kind: ConfigMap
metadata:
  name: nvidia-device-plugin-config
  namespace: kube-system
data:
  config.yaml: |
    version: v1
    sharing:
      timeSlicing:
        resources:
          - name: nvidia.com/gpu
            replicas: 4   # expose each physical GPU as 4 virtual GPUs
```

With 8 physical GPUs and `replicas: 4`, the node exposes `nvidia.com/gpu: 32` to Kubernetes. Four Pods can share one GPU simultaneously (time-sliced by the driver).

> ⚠️ Watch out: Time-slicing has no memory isolation — if one Pod allocates all GPU memory, others OOM. Use MIG for true isolation.

---

## GPU Monitoring

```bash
# On the node — NVIDIA CLI
nvidia-smi                          # GPU status, utilization, memory, temperature
nvidia-smi dmon -s u                # live utilization monitoring
nvidia-smi pmon -s u                # per-process GPU monitoring
nvidia-smi topo -m                  # NVLink/PCIe topology between GPUs

# In Kubernetes — DCGM Exporter (Prometheus)
# DaemonSet that exposes GPU metrics to Prometheus
kubectl apply -f https://raw.githubusercontent.com/NVIDIA/dcgm-exporter/main/deployment/kubernetes/dcgm-exporter.yaml

# Key metrics from DCGM Exporter:
# DCGM_FI_DEV_GPU_UTIL       — GPU utilization %
# DCGM_FI_DEV_FB_USED        — frame buffer (VRAM) used MB
# DCGM_FI_DEV_POWER_USAGE    — power draw watts
# DCGM_FI_DEV_SM_CLOCK       — streaming multiprocessor clock MHz
# DCGM_FI_DEV_GPU_TEMP       — temperature °C
```

HPA on GPU utilization (via Prometheus Adapter):
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: gpu-inference-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: inference-server
  minReplicas: 1
  maxReplicas: 8
  metrics:
    - type: Pods
      pods:
        metric:
          name: dcgm_fi_dev_gpu_util   # from Prometheus Adapter
        target:
          type: AverageValue
          averageValue: "80"           # scale when avg GPU util > 80%
```

---

## 🗂️ Non-GPU Nodes

---

## CPU-Only Node Types and Labeling Strategy

In a real cluster you typically have multiple node pools/groups, each with a purpose:

```
┌─────────────────────────────────────────────────────────────────┐
│ Node Pools in a Production Cluster                               │
│                                                                  │
│  system-pool      ← control plane components, CoreDNS, CNI      │
│  (t3.large x3)      NoSchedule taint: CriticalAddonsOnly        │
│                                                                  │
│  general-pool     ← stateless API services, web apps            │
│  (m5.xlarge x10)    no special taints                           │
│                                                                  │
│  memory-pool      ← in-memory caches, analytics                 │
│  (r5.4xlarge x4)    label: workload-type=memory-optimized       │
│                                                                  │
│  compute-pool     ← CPU-heavy batch processing                  │
│  (c5.9xlarge x6)    label: workload-type=compute-optimized      │
│                                                                  │
│  gpu-pool         ← ML training, inference                      │
│  (p4d.24xlarge x2)  taint: nvidia.com/gpu:NoSchedule           │
│                      label: accelerator=nvidia                  │
└─────────────────────────────────────────────────────────────────┘
```

```bash
# Label nodes by workload type
kubectl label nodes worker-{1..10} node-pool=general
kubectl label nodes memory-{1..4}  node-pool=memory workload=cache
kubectl label nodes compute-{1..6} node-pool=compute workload=batch
kubectl label nodes gpu-{1..2}     node-pool=gpu accelerator=nvidia

# Taint system nodes
kubectl taint nodes system-{1..3} CriticalAddonsOnly=true:NoSchedule

# Taint GPU nodes (reserve for GPU workloads only)
kubectl taint nodes gpu-{1..2} nvidia.com/gpu=present:NoSchedule
```

---

## Node Maintenance — Draining and Cordoning

```bash
# Cordon — stop new Pods from scheduling here (existing Pods stay)
kubectl cordon worker-01
# Node is marked Unschedulable but running Pods continue

# Drain — evict all Pods and cordon the node (prepare for maintenance)
kubectl drain worker-01 \
  --ignore-daemonsets \         # don't evict DaemonSet pods (they're managed)
  --delete-emptydir-data \      # evict pods with emptyDir volumes
  --grace-period=60 \           # give pods 60s to terminate gracefully
  --timeout=300s                # give up after 5 minutes

# What drain does:
# 1. Cordons the node (Unschedulable)
# 2. Sends eviction requests for all non-DaemonSet Pods
# 3. Waits for Pods to terminate (respects PodDisruptionBudgets)
# 4. Returns when all Pods are gone (or timeout)

# After maintenance — uncordon to allow scheduling again
kubectl uncordon worker-01

# Force drain (DANGEROUS — ignores PDBs, skips graceful termination)
kubectl drain worker-01 --force --ignore-daemonsets --delete-emptydir-data
```

> ⚠️ Watch out: `--force` ignores `PodDisruptionBudgets`. If a Deployment has `minAvailable: 1` and only 1 replica is running, normal drain respects the PDB and waits. `--force` evicts anyway, causing downtime.

---

## Node Troubleshooting Commands

```bash
# Node not Ready — first checks
kubectl describe node <node>            # check Events and Conditions
kubectl get events --field-selector involvedObject.name=<node>

# SSH to node (for deeper investigation)
# Check kubelet
systemctl status kubelet
journalctl -u kubelet -n 100 --no-pager

# Check disk pressure
df -h
du -sh /var/lib/containerd    # container storage consuming disk?
du -sh /var/log               # logs consuming disk?

# Check memory pressure
free -h
cat /proc/meminfo | grep -E "MemAvailable|Cached|SwapUsed"

# Check running containers
crictl ps                     # containerd native CLI
crictl pods                   # running pods via CRI
crictl images                 # cached images

# Check resource consumption
kubectl describe node <node> | grep -A20 "Allocated resources"
# Shows: CPU and memory requested vs allocatable, per-Pod breakdown

# Top nodes
kubectl top nodes              # requires metrics-server
kubectl top nodes --sort-by=cpu
kubectl top nodes --sort-by=memory

# Get all pods on a specific node
kubectl get pods -A --field-selector spec.nodeName=<node>

# Node not joining the cluster
systemctl status kubelet       # is it running?
journalctl -u kubelet -n 50    # look for: "Failed to connect to API server"
curl -k https://<api-server>:6443/healthz   # can node reach API server?
cat /etc/kubernetes/kubelet.conf   # check API server address
```

---

## Node Resource Management — Eviction and Reservation

**Kubelet eviction thresholds** — kubelet evicts Pods when the node hits these limits:

```yaml
# /etc/kubernetes/kubelet-config.yaml (or kubelet flags)
evictionHard:
  memory.available: "100Mi"      # evict if <100Mi memory left
  nodefs.available: "10%"        # evict if disk <10% free
  nodefs.inodesFree: "5%"        # evict if <5% inodes free
  imagefs.available: "15%"       # evict if image filesystem <15% free

evictionSoft:
  memory.available: "200Mi"      # start evicting after evictionSoftGracePeriod
  nodefs.available: "15%"

evictionSoftGracePeriod:
  memory.available: "90s"        # wait 90s before soft eviction kicks in

# System reserved (remove from allocatable)
systemReserved:
  cpu: "200m"
  memory: "500Mi"
  ephemeral-storage: "2Gi"

# Kube reserved (for kubelet itself and other k8s components)
kubeReserved:
  cpu: "200m"
  memory: "500Mi"
```

---

## Interview Q&A — Node

**Q: What happens when a node stops sending heartbeats to the control plane?**

Kubelet sends two types of heartbeats: `NodeStatus` updates (full status, every ~10s) and `Lease` object updates (lightweight, every 10s by default). The node controller watches these. After `node-monitor-grace-period` (default 40s) with no heartbeat, the controller marks the node `Ready=Unknown`, then applies `node.kubernetes.io/unreachable:NoExecute`. Pods with the default toleration (`tolerationSeconds: 300`) run for 5 more minutes, then are evicted to healthy nodes. StatefulSet Pods are NOT auto-rescheduled in some versions — you may need to manually delete the Pod.

**Q: A GPU Pod is stuck in Pending with "0/N nodes are available: N Insufficient nvidia.com/gpu." What do you check?**

Step-by-step:
1. `kubectl describe node gpu-node | grep nvidia.com/gpu` — are GPUs showing in capacity and allocatable? If not: Device Plugin DaemonSet not running or not healthy.
2. `kubectl get pods -n kube-system | grep nvidia` — is the Device Plugin Pod in Running state? If CrashLoopBackOff: driver or NVML issue on the node.
3. Are all GPUs already allocated? `kubectl describe node | grep -A5 "Allocated resources"` — if `nvidia.com/gpu` shows `8/8` used, the node is full.
4. Does the GPU node have a NoSchedule taint and the Pod doesn't tolerate it? Check `kubectl describe node | grep Taint` and compare with the Pod's tolerations.
5. Does the Pod have `nodeSelector` or `affinity` that doesn't match any GPU node?

**Q: What is the NVIDIA Device Plugin and why is it necessary?**

Kubernetes knows about CPU and memory natively, but GPUs are "extended resources" — custom device types the kubelet doesn't understand by default. The Device Plugin Framework (part of Kubernetes) lets hardware vendors register custom resources. The NVIDIA Device Plugin runs on each GPU node as a DaemonSet, discovers GPUs via NVML, and registers `nvidia.com/gpu` with the local kubelet via a gRPC socket in `/var/lib/kubelet/device-plugins/`. Without it, `nvidia.com/gpu` doesn't appear in node capacity and GPU-requesting Pods stay Pending forever.

**Q: What is the difference between MIG and time-slicing for GPU sharing?**

MIG (Multi-Instance GPU) physically partitions the GPU at hardware level — each partition gets dedicated compute units, VRAM, and memory bandwidth. It's true isolation: one Pod can't OOM another's GPU memory. Only supported on A100 and H100. Time-slicing exposes a single GPU as multiple virtual GPUs in Kubernetes — Pods take turns using the GPU (driver-level scheduling). No memory isolation — all Pods share the full GPU memory space, so a greedy Pod can OOM others. Time-slicing works on any NVIDIA GPU; MIG requires specific hardware. Use MIG for true multi-tenancy; use time-slicing for light inference workloads where isolation matters less.

**Q: A node is in DiskPressure. What is kubelet doing and how do you fix it?**

When `DiskPressure=True`, kubelet: (1) stops pulling new container images, (2) starts evicting Pods starting with BestEffort (no requests/limits), then Burstable, then Guaranteed — ordered by how much disk their emptyDir/logs consume. To fix: `df -h` to see which filesystem is full. Common culprits: container logs (`/var/log/containers`), container image cache (`/var/lib/containerd`), emptyDir volumes in Pods. Quick fix: `crictl rmi --prune` to remove unused images, then address the root cause. Long-term: configure log rotation, set `evictionHard.nodefs.available` higher to trigger cleanup earlier.

**Q: How does kubectl drain handle PodDisruptionBudgets?**

`kubectl drain` sends eviction requests via the Eviction API, not direct Pod deletion. The Eviction API checks PodDisruptionBudgets before allowing the eviction. If evicting the Pod would violate the PDB (e.g., `minAvailable: 2` and only 2 Pods are running → evicting one would leave 1, violating the budget), the Eviction API returns 429 Too Many Requests and drain waits + retries. Drain proceeds only when the PDB allows it — which typically happens when the scheduler places a replacement Pod on another node. This is why proper PDB + multiple replicas is critical for zero-downtime node maintenance.

**Q: What is the difference between cordoning and draining a node?**

`kubectl cordon` marks the node `Unschedulable` — the scheduler stops placing new Pods there, but existing Pods keep running undisturbed. Use it when you want to gracefully drain traffic without disrupting running workloads immediately. `kubectl drain` does everything cordon does (marks Unschedulable) and then evicts all non-DaemonSet Pods — either gracefully via the Eviction API (respects PDBs and terminationGracePeriodSeconds) or forcefully with `--force`. Drain is for node maintenance where you need the node empty. Cordon is a temporary traffic deflector.
