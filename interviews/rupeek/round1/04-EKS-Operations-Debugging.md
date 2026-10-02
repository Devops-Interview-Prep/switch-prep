# Rupeek Round 1 — EKS operations and deep debugging

> Node group strategy and Karpenter guardrails, the cluster upgrade runbook, add-on lifecycle, admission control (Kyverno / PSA / VAP), network policies, and a layer-by-layer debugging map from the API server down to the kernel.

---

The JD lists node group strategy, cluster upgrades, addons lifecycle, admission controllers, network policies, Pod Security Admission, and then "comfortable debugging at layers others can't: kernel/OS, container runtime, CNI, etcd, control plane". Expect one scenario-based question per item, and expect them to push until you say "I would look at X" where X is a file, a metric, or a command.

## Node group strategy

**Options and when each fits:**
- **Managed node groups (MNG)**: AWS handles the ASG, launch template, rolling updates with `maxUnavailable`, graceful drain on scale-in. Good for a **stable baseline pool** (system add-ons, stateful services, anything that must not churn). Supports spot MNGs with capacity-optimised allocation.
- **Karpenter**: a cluster-native provisioner that reads pending pods and launches the cheapest instance that fits, from a wide instance list, with consolidation that actively replaces under-utilised nodes. The default for **application workloads**. Concepts: `NodePool` (constraints, limits, disruption policy, taints, weights), `EC2NodeClass` (AMI family, subnets, security groups, block devices, user data, IMDS settings), `NodeClaim` (one node). Karpenter itself must run on nodes it does not manage (an MNG or Fargate) to avoid a chicken-and-egg problem.
- **Self-managed ASGs**: only when you need something neither offers (very custom AMIs with specific bootstrap, Windows edge cases); more operational load.
- **Fargate**: isolated profiles for specific namespaces; no DaemonSets, limited sizes, slow start. Niche.
- **EKS Auto Mode**: AWS-managed Karpenter plus add-ons; trade control for less toil. For a regulated shop that must run hardened AMIs or specific CNI settings, know what you give up.

**A sane layout:** one small on-demand MNG per cluster labelled and tainted for `system`/`platform` (CoreDNS, Karpenter, ArgoCD, observability, ingress controllers); Karpenter NodePools per workload class: `general` (on-demand plus spot, broad instance families, consolidation on), `stable` (on-demand, `WhenEmpty` consolidation only, `expireAfter: Never`, for things that cannot tolerate churn), `gpu` or `batch` (spot, scale to zero), with taints so workloads land where intended.

**Spot:** diversify across 15+ instance types, handle the 2-minute interruption notice (Karpenter and the Node Termination Handler drain), never for singletons or anything without a PDB, fine for stateless replicas and batch. Mixed on-demand/spot via NodePool weights or `capacity-type` requirements. Graviton (arm64) for 20 to 40 percent better price-performance where images are multi-arch.

**Consolidation tuning is a tech-lead topic.** `consolidationPolicy: WhenEmptyOrUnderutilized` with a short `consolidateAfter` and a large disruption budget saves money and destroys workloads that lack PDBs. Guardrails: PDBs on everything with more than one replica, `karpenter.sh/do-not-disrupt` on singletons and jobs, disruption budgets (`nodes: "10%"` with schedules that allow aggressive consolidation only off-hours), `expireAfter` set so nodes still get refreshed for patching, `terminationGracePeriod` on the NodePool so a stuck drain cannot block forever.

> **Your story:** Your Karpenter churn incident is tailor-made here: dev cluster, pods "restarting" with restart count zero, Prometheus showed 54 distinct pods for a 3-replica deployment in a week, Loki showed around 800 Karpenter disruption decisions a week on a 30-node pool, average node lifetime around 6 hours, no PDBs anywhere in the namespace. Root cause: `WhenEmptyOrUnderutilized`, `consolidateAfter: 30m`, 25 percent budget, bursty KEDA and cron workloads constantly changing the bin-packing. Fix: a dedicated `stable` NodePool (WhenEmpty, budget zero, never expire), affinity and tolerations in the values, PDBs, and a recommendation to raise `consolidateAfter` and shrink the budget on the shared pool. Lesson you state: consolidation is a cost lever with a reliability price; the platform must ship the PDB and the stable pool as defaults, not expect every team to know.

## Cluster upgrades

Kubernetes releases three times a year; EKS supports a version for about 14 months standard then charges extended support. A tech lead owns a cadence (one minor every four months, never more than one behind) and a runbook. The runbook:

1. **Read**: Kubernetes changelog, EKS release notes, deprecated/removed APIs (`kubectl` with Pluto or kube-no-trouble, EKS **upgrade insights** in the console/API which flag deprecated API usage from audit logs), add-on compatibility matrix, Helm charts in use (ingress controller, cert-manager, ESO, Karpenter all have minimum versions).
2. **Fix workloads first**: update manifests off removed APIs, fix anything relying on behaviour changes (e.g. PSP removal in 1.25, in-tree volume plugin removals, `cgroup v2` in AL2023 AMIs affecting JVM memory settings and old Java versions).
3. **Non-prod first**, soak at least a week, run the regression suites.
4. **Control plane**: `terraform apply` of the version bump; takes 20 to 40 minutes; API server keeps serving but may briefly drop connections; one minor at a time (1.30 to 1.31 to 1.32).
5. **Add-ons**: upgrade in order VPC CNI, kube-proxy, CoreDNS, then EBS/EFS CSI, Pod Identity agent, then third-party controllers. Check each add-on's version matrix against the new control plane. Use `preserve` or `most_recent` carefully; pin versions in Terraform.
6. **Nodes**: MNG rolling update (new launch template with the new AMI, `maxUnavailable` or percentage, respects PDBs); Karpenter picks up the new AMI via the `EC2NodeClass` `amiSelectorTerms` (pin to an AMI alias version, not `latest`, so the node refresh is a deliberate change) and **drift** replaces nodes within budgets. Watch for pods that cannot be drained (PDB with `minAvailable` equal to replicas, singletons without PDB causing forced eviction) and for `FailedDraining`.
7. **Verify**: control plane health, add-on pods, a smoke test of ingress, DNS, storage, IRSA, and your golden signals dashboards. Keep the previous AMI ID and the previous add-on versions written down; rollback of nodes and add-ons is possible, rollback of the control plane version is not.
8. **Record**: change ticket, timings, issues, as audit evidence and as input to the next runbook iteration.

**Version skew rules:** kubelet may be up to three minors behind the API server (two for older releases), never ahead; `kubectl` within one minor; add-ons per their matrix. This is why the control plane goes first and why skipping minors is not allowed.

**Blue/green cluster** (build a new cluster, shift traffic by DNS or by moving ArgoCD targets) is the alternative when the in-place path is scary (several minors behind, PSP still in use, CNI mode change). More expensive but a clean rollback. State your view: in-place for routine upgrades on a current cluster, blue/green to escape debt.

## Add-ons lifecycle

Core add-ons and what breaks when they are stale:

| **Add-on** | **What to know** |
|---|---|
| VPC CNI (`aws-node`) | Pod IPs, prefix delegation, custom networking, network policy enforcement (since v1.14 with the network policy agent), `ENABLE_POD_ENI` for security groups per pod. Version must match the control plane; config via advanced configuration in the EKS add-on, not by editing the DaemonSet (the add-on will overwrite). IRSA/Pod Identity role for the CNI. |
| kube-proxy | iptables (default) vs IPVS mode; large clusters with many Services suffer from iptables rule counts; `conntrack` sizing comes from here. |
| CoreDNS | Replica count and `autoscaler` (cluster-proportional autoscaler or the EKS add-on's autoscaling), `ndots:5` causing 5x lookups for external names (fix with FQDN trailing dots or `ndots` in pod `dnsConfig`), NodeLocal DNSCache to cut conntrack pressure, and the classic "DNS latency spikes on node churn" because CoreDNS pods landed on churny nodes (pin them to the system pool with a PDB). |
| EBS CSI driver | Required since 1.23 for EBS volumes; storage classes with `gp3`, encryption by default via KMS, volume resize, snapshots; topology constraints (EBS is AZ-bound, so a StatefulSet pod cannot move AZs). |
| EFS CSI / Mountpoint S3 CSI | Shared RWX volumes; EFS throughput modes and cost; S3 CSI for read-heavy data lakes. |
| Pod Identity agent | Needed for EKS Pod Identity associations; runs as a DaemonSet with host networking. |
| AWS Load Balancer Controller | ALB from Ingress, NLB from Service; `ip` target type; shared ALB via `group.name`; WAF association; needs IRSA/Pod Identity with a specific policy; subnet tags. |
| Metrics Server, cluster-autoscaler or Karpenter, External Secrets Operator, cert-manager, ingress-nginx, ArgoCD, Prometheus stack, Kyverno | Platform add-ons installed by the platform stack (Terraform `helm_release` or ArgoCD app-of-apps). Each has a version matrix; each needs its own upgrade cadence tracked in a single table owned by the platform team. |

**Standard to set:** add-on versions pinned in Terraform (`addon_version`), an upgrade matrix document per cluster version, Renovate watching Helm charts, a monthly "add-on patch Tuesday" in non-prod and a fortnight later in prod, and `most_recent = true` banned in prod roots.

## Admission control

**What it is:** after authentication and authorisation, the API server runs **mutating** then **validating** admission webhooks (and built-in plugins) before persisting an object. This is where platform policy is enforced regardless of how the YAML arrived (kubectl, Helm, ArgoCD).

**Options:**
- **Pod Security Admission (PSA)**: built in since 1.25 (PSP removed). Three profiles (privileged, baseline, restricted) applied per namespace via labels in three modes (`enforce`, `audit`, `warn`). Covers only pod security fields; not general policy.
- **Kyverno**: policies written as Kubernetes YAML; validate, mutate, generate (e.g. create a default NetworkPolicy and PDB in every new namespace), verify image signatures (cosign), clean up. Easy for a team to adopt; policy library is large.
- **OPA Gatekeeper**: Rego policies via ConstraintTemplates; more expressive, steeper learning curve, strong audit mode and external data.
- **ValidatingAdmissionPolicy (VAP)**: in-tree, CEL expressions, GA in 1.30; no webhook, so no availability risk or latency; mutating variant (MAP) arriving in later versions. Good for simple invariants; cannot call out or generate.

**Policies a fintech platform enforces (be ready to list ten):** images only from approved registries (your ECR, with digest or signed tag); no `latest` tag; cosign signature verified; run as non-root, no privilege escalation, drop all capabilities, read-only root filesystem where feasible, seccomp `RuntimeDefault`; no `hostNetwork`/`hostPID`/`hostPath` outside system namespaces; resource requests and limits required; liveness and readiness probes required; mandatory labels (`team`, `service`, `cost-center`) for cost allocation; PDB required for deployments with more than one replica; no `NodePort` or public `LoadBalancer` Services outside the ingress namespace; Ingress must have TLS and the internal-scheme annotation unless explicitly allowed; secrets not in env literals; no wildcard RBAC; namespaces get a default-deny NetworkPolicy generated on creation.

**Operating webhooks safely:** `failurePolicy: Fail` is correct for security policies but means a dead webhook blocks all deploys, so the policy engine runs with multiple replicas on the system pool, a PDB, resource limits, `namespaceSelector` excluding `kube-system` and itself, tight `timeoutSeconds`, and alerting on webhook latency and error rate. Roll out every new policy in `Audit` mode first, review the report, then `Enforce`. Prefer VAP for simple rules precisely because it cannot go down.

> **Have an opinion:** Kyverno plus PSA `restricted` as the baseline, VAP for the handful of invariants that must never depend on a webhook, Gatekeeper only if the team already writes Rego. The sequencing matters more than the tool: audit mode, a dashboard of violations per team, a deadline, then enforce.

## Pod Security Admission rollout

How to move an existing cluster to PSA without breaking production:
1. Label every namespace `pod-security.kubernetes.io/warn=restricted` and `audit=restricted`; nothing is blocked, but every violating create produces a warning to the user and an audit log entry.
2. Collect violations from audit logs (CloudWatch Logs Insights on the `pod-security.kubernetes.io` annotation) per namespace and per team for two weeks.
3. Fix the workloads: `securityContext.runAsNonRoot`, `allowPrivilegeEscalation: false`, `capabilities.drop: [ALL]`, `seccompProfile.type: RuntimeDefault`; this mostly means image changes (non-root user, correct file ownership) and chart defaults. Platform-owned chart defaults make this a one-line change per service.
4. Set `enforce=baseline` cluster-wide first, then `enforce=restricted` namespace by namespace. Exempt system namespaces explicitly and document each exemption with an owner and expiry.
5. Use Kyverno to **mutate** in the defaults for teams that lag, and to block removal of the labels.

## Network policies

**Default:** without a NetworkPolicy, every pod can talk to every pod. A regulated platform wants **default deny** per namespace with explicit allow rules, and an auditor will ask to see it.

**Enforcement options on EKS:** the VPC CNI's native network policy support (eBPF-based agent, Kubernetes `NetworkPolicy` API only), Calico (richer `GlobalNetworkPolicy`, host endpoints, DNS-based egress rules), Cilium (eBPF, L7 policies, Hubble observability, can replace kube-proxy; heavier to adopt). Only one enforcer at a time.

**Rollout pattern:** generate (Kyverno) a default-deny ingress and egress policy in every namespace with allow rules for DNS (kube-dns on 53/UDP and TCP), the observability scrapers, and the ingress controller. Then per-service allow rules in the chart (`networkPolicy.ingressFrom` values). Egress to RDS and external APIs is by CIDR or, with Calico/Cilium, by FQDN. Audit mode is not in the standard API; test in non-prod with traffic replay and watch for broken health checks, Prometheus scrapes and webhook callbacks, the three things everyone forgets.

**Security groups for pods** (`ENABLE_POD_ENI`) attach an ENI-level security group to specific pods, which is the way to let only the payments service reach the ledger RDS at the VPC level. Cost: ENI limits per instance and branch-ENI quirks; use for the handful of high-value flows.

## Debugging at layers others can't

They will give you a symptom and ask what you look at. Here is the map, from the top of the stack down. For each, say the **signal**, the **command or metric**, and the **fix**.

### Control plane and etcd

- **API server slow or `429 Too Many Requests`**: API Priority and Fairness is throttling a noisy client. Metric `apiserver_flowcontrol_rejected_requests_total`, audit log by `user.username` and `userAgent` to find the controller doing a list-every-second (common culprits: a misconfigured operator, a monitoring agent listing all pods, a CI job polling). Fix the client; use informers/watches; raise priority levels only for system components. On EKS you cannot resize the control plane, but AWS scales it; still, the fix is always the client.
- **etcd size**: EKS limit 8 GB database size; the cluster goes read-only when hit. Causes: huge numbers of Events, Jobs never cleaned (`ttlSecondsAfterFinished`), large ConfigMaps/Secrets, CRDs storing blobs, Helm release history (`--history-max`). Metrics in CloudWatch via control-plane metrics (`apiserver_storage_size_bytes`, `etcd_db_total_size_in_bytes` on recent versions). Fix: delete bulk objects in batches, set TTLs, cap Helm history, alarm at 60 percent.
- **etcd latency**: `etcd_request_duration_seconds` and `apiserver_request_duration_seconds` rising together, slow `kubectl` and controller lag. On EKS this is AWS's problem to fix but your problem to detect and open a support case with evidence.
- **Webhook timeouts**: everything hangs on create; `kubectl get validatingwebhookconfigurations`, check the webhook pods, look for `failurePolicy: Fail` with no healthy backends. Temporary fix: set `failurePolicy: Ignore` or delete the configuration (a documented break-glass step).
- **Leader election flapping** in controllers (`kube-controller-manager` is AWS-managed, but your operators are not): usually API latency or CPU throttling of the controller pod.

### Node, kernel and OS

- **Node `NotReady`**: `kubectl describe node` conditions (`MemoryPressure`, `DiskPressure`, `PIDPressure`, `NetworkUnavailable`), then on the node (SSM Session Manager, not SSH): `journalctl -u kubelet`, `journalctl -u containerd`, `dmesg -T` for OOM killer and hung tasks, `df -h /var/lib/containerd` and inode usage, `systemctl status`. Causes: disk full from image layers or logs (set `imageGCHighThresholdPercent`, log rotation, bigger root volume), kernel OOM killing kubelet (reserve resources: `kube-reserved`/`system-reserved`), ENI attachment failures, IMDS throttling, a bad AMI.
- **OOM: container vs node vs cgroup**: exit code 137 with `OOMKilled` in `describe pod` is the **container** exceeding its limit (cgroup OOM). `dmesg` showing `Out of memory: Killed process` with no limit involved is **node** memory pressure; the kubelet evicts by QoS class (BestEffort first, then Burstable above request, Guaranteed last). Pods with requests far below actual use are the usual cause of node-level pressure. For JVMs: heap from `MaxRAMPercentage` plus metaspace, threads, direct buffers must fit the limit; cgroup v2 on AL2023 changed how older JDKs see memory.
- **CPU throttling**: `container_cpu_cfs_throttled_periods_total` high with low average usage means the limit is too low for bursts (the CFS quota is per 100 ms period). Options: raise limits, remove CPU limits for latency-sensitive services while keeping requests, or use static CPU manager policy for pinning.
- **Eviction vs crash**: restart count zero but pods replaced frequently means eviction or node churn (consolidation, spot interruption, drift), not an application crash. Check `kubectl get events`, Karpenter logs, Node Termination Handler logs.
- **PID exhaustion, file descriptors, inotify watches**: `PIDPressure`, `too many open files`, `fs.inotify.max_user_watches` on nodes running many agents; set kernel sysctls via the node class user data or a tuning DaemonSet.
- **Clock skew**: TLS and token failures across the cluster; `chronyd` status on nodes.
- **Kernel-level network**: `conntrack` table full (`nf_conntrack: table full, dropping packet` in `dmesg`, metric `node_nf_conntrack_entries`); raise `net.netfilter.nf_conntrack_max`, use NodeLocal DNSCache to cut UDP conntrack entries, prefer keep-alive. Source port exhaustion through NAT (`ephemeral port range`, NAT gateway `ErrorPortAllocation` metric) from many short connections to one destination; fix with connection pooling, more NAT IPs, or VPC endpoints.

### Container runtime

- containerd since EKS 1.24 (Docker shim gone). Tools: `crictl ps`, `crictl inspect`, `crictl logs`, `ctr -n k8s.io images ls`, `journalctl -u containerd`.
- **Image pull failures**: `ImagePullBackOff` with 401/403 means ECR auth (node role lacks `ecr:GetAuthorizationToken`, or cross-account repo policy), `not found` means tag or repository path (a real HiLabs case: wrong ECR repo in Helm values), timeouts mean no route to ECR (missing VPC endpoints or NAT issue), `too many requests` on Docker Hub means use ECR pull-through cache.
- **Disk pressure from images**: `crictl rmi --prune`, kubelet GC thresholds, bigger root volume in the `EC2NodeClass` `blockDeviceMappings`.
- **Container stuck terminating**: `terminationGracePeriodSeconds` plus a process ignoring SIGTERM (PID 1 problem; use `tini` or `exec` in entrypoints), or a volume unmount hanging (EBS detach, EFS NFS stale handle). Force delete only after confirming the node will not resurrect it.
- **`CreateContainerConfigError`**: missing ConfigMap/Secret key. **`CrashLoopBackOff`** with exit 1: read `logs --previous`. Exit 139: segfault, often a native library on the wrong architecture (arm64 image on amd64 node or vice versa).

### CNI and cluster networking

- **Pods stuck `ContainerCreating` with `failed to assign an IP address`**: subnet exhaustion or ENI/IP limits per instance type. Check `aws-node` logs, `kubectl describe node` allocatable pods, subnet free IP counts, CNI env (`WARM_*`, prefix delegation), and whether the subnet is too fragmented for `/28` prefixes.
- **Intermittent connection failures between pods**: security group rules between node groups (each MNG or node class may have its own SG), a network policy you forgot about, `conntrack`, or a pod on a node whose ENI failed to attach.
- **DNS**: `ndots:5`, CoreDNS throttled or evicted, `conntrack` races on UDP (the classic 5 s timeout), upstream Route 53 resolver limits (1024 packets per second per ENI; NodeLocal DNSCache fixes most of it). Debug with a netshoot pod: `dig`, `nslookup`, `tcpdump -i any port 53`.
- **Service not reachable**: `kubectl get endpoints` empty means readiness or label selector; `iptables-save | grep <svc>` on a node to see kube-proxy rules; `kube-proxy` logs; a `NodePort` blocked by SG.
- **ALB 502/504**: target group health (pod readiness vs ALB health check path mismatch), `ip` targets deregistering slowly during rollouts (add a `preStop` sleep and `terminationGracePeriodSeconds` greater than the deregistration delay), idle timeout lower than the app's keep-alive (set app keep-alive above ALB idle timeout), security group between ALB and pods.
- **Cross-AZ traffic surprises**: topology-aware routing (`service.kubernetes.io/topology-mode: Auto`) and pod topology spread so replicas exist in every AZ.

### A worked scenario to rehearse out loud

"Checkout latency doubled at 11:05, no deploys." Narrate: dashboards (golden signals per service, pick the one whose latency rose first), then node churn (Karpenter disruptions, spot interruptions at 11:00), then CoreDNS (latency and errors), then conntrack and NAT metrics (new connection rate, port allocation errors), then RDS (connections, CPU, locks, a failover event at 11:04 would show in RDS events), then API server throttling if controllers lag. Say what you would roll back or scale as a mitigation before root cause, and what you would write in the post-mortem.

## Interview questions and model answers

### Q1: Managed node groups or Karpenter?

Both: a small on-demand managed group for the platform itself (Karpenter cannot schedule the node it runs on; CoreDNS and the policy engine must not churn), and Karpenter NodePools for everything else because of instance diversity, spot handling, bin-packing and consolidation. Guardrails come with it: PDBs, do-not-disrupt on singletons, disruption budgets by schedule, a stable pool for churn-sensitive services, and pinned AMI aliases so node refreshes are deliberate.

---

### Q2: Walk me through upgrading a prod cluster from 1.31 to 1.32.

Read changelog and EKS notes, run upgrade insights and Pluto for removed APIs, check the add-on and controller matrix, fix manifests, upgrade non-prod and soak a week with regression runs. Change ticket and comms. Control plane via Terraform, 30 minutes. Add-ons in order: CNI, kube-proxy, CoreDNS, CSI, Pod Identity agent, then Helm-installed controllers. Nodes: new AMI alias in the EC2NodeClass and MNG launch template, Karpenter drift rolls within budgets, MNG rolling update respects PDBs; watch for FailedDraining. Smoke tests, dashboards, write-up. Rollback plan covers nodes and add-ons; the control plane cannot be downgraded, which is why non-prod soak is non-negotiable.

---

### Q3: How do you run admission webhooks without creating an outage risk?

Policy engine on the system pool with multiple replicas and a PDB, excluded from its own policies and from kube-system via namespaceSelector, short timeouts, SLO alerts on webhook latency and errors. `failurePolicy: Fail` for security policies and a documented break-glass to flip it. Use in-tree ValidatingAdmissionPolicy for the small set of invariants that must never depend on a webhook. Every policy goes through audit mode and a violations dashboard before enforce.

---

### Q4: Pods in a namespace cannot resolve DNS after you enabled network policies. Why?

The default-deny egress policy blocked UDP and TCP 53 to kube-dns. The default-deny template must always allow egress to the kube-dns pods (by namespace and pod selector, both protocols), plus the ingress controller and the Prometheus scraper on ingress. I generate that baseline with Kyverno so nobody writes it by hand.

---

### Q5: etcd is at 7 GB on an 8 GB limit. What do you do?

First stop the growth: find the object type (`kubectl get --raw /metrics` for `apiserver_storage_objects` by resource, or count per type), typically Events, finished Jobs, or a CRD storing payloads. Delete in batches to avoid an apiserver spike, set `ttlSecondsAfterFinished`, cap Helm history, fix the operator writing blobs. Then alarm at 60 percent, and consider the event TTL and audit log volume. Document it; the next step without this is a read-only cluster.

---

### Q6: A node goes NotReady every few hours and recovers. How do you root-cause it?

Correlate with node conditions and kubelet logs via SSM: look for PLEG not healthy, container runtime unresponsive, disk pressure from image GC, memory pressure OOM-killing kubelet because requests are under-set and nothing is reserved. Check `dmesg` for OOM and hung-task messages, `containerd` logs, EBS burst balance on the root volume (gp2 to gp3), and CloudWatch instance status checks. Fix the root cause (reservations, volume size/type, requests) and set `node-problem-detector` to surface it next time.

---

### Q7: Pods are stuck ContainerCreating with no IP available. Options?

Immediate: scale down something or add nodes in a subnet with space. Short term: enable prefix delegation and tune WARM targets so the CNI stops hoarding, check instance types with low ENI limits. Structural: secondary CIDR with custom networking, or larger subnets in a new node class, or IPv6. Also check for leaked ENIs from crashed nodes.

---

### Q8: How does kube-proxy in iptables mode fall over, and what is the alternative?

Rule count grows with Services times endpoints, and every sync rewrites the table, so large clusters see slow Service updates and CPU spikes. IPVS mode scales better; Cilium eBPF replaces kube-proxy entirely. For most EKS clusters under a few thousand Services iptables is fine; the real issue is conntrack, which is why NodeLocal DNSCache is on my default list.

---

### Q9: What is PLEG and why does it make a node NotReady?

Pod Lifecycle Event Generator, kubelet's loop that relists containers from the runtime. If a relist takes over three minutes the kubelet reports NotReady. Causes: too many containers on a node, a slow or hung containerd, disk I/O saturation. Fix the runtime or disk, cap pods per node, and alert on `kubelet_pleg_relist_duration_seconds`.

---

### Q10: How do you debug a 502 from an ALB in front of EKS during deploys?

The ALB keeps sending to a pod that is terminating. Fix the handoff: readiness fails on SIGTERM, a `preStop` sleep of 10 to 20 seconds, `terminationGracePeriodSeconds` greater than deregistration delay plus request timeout, app keep-alive longer than the ALB idle timeout, and the pod readiness gate the LB controller supports so rollouts wait for target registration.

---

### Q11: What would you alert on for cluster health?

Node NotReady, pending pods older than N minutes, Karpenter provisioning failures, CoreDNS error rate and latency, API server 5xx and throttling, etcd size, webhook latency, PDB-blocked drains, certificate expiry, image pull errors, OOM kills by namespace, CPU throttling ratio, PVC near full, and the control-plane upgrade insight findings. Each with a runbook link.

---
