![alt text](image.png)

DevOps / SRE / Platform Engineer
│
├── Linux & OS Internals
│   ├── Process Management
│   │   ├── fork / exec / threads
│   │   ├── Zombie & orphan processes
│   │   └── CPU scheduling (CFS, nice)
│   ├── Memory Management
│   │   ├── Virtual memory & paging
│   │   ├── NUMA
│   │   └── OOM killer
│   ├── Filesystems
│   │   ├── ext4 vs xfs
│   │   └── inode exhaustion
│   └── Performance Debugging
│       ├── top, htop, vmstat, iostat
│       ├── strace / ltrace
│       └── perf / eBPF basics
│
├── Networking
│   ├── Core Networking
|   |   |-- Models
│   │   ├── Protocols
│   │   ├── DNS (recursive, authoritative)
│   │   └── HTTP/1.1 vs HTTP/2 vs HTTP/3
│   ├── Load Balancing
│   │   ├── L4 vs L7
│   │   └── Algorithms (RR, least conn, hash)
│   ├── Cloud Networking
│   │   ├── VPC, Subnets
│   │   ├── Security Groups vs NACLs
│   │   └── NAT, IGW, TGW
│   └── Kubernetes Networking
│       ├── CNI (VPC CNI, Calico, Cilium)
│       ├── Service types
│       └── kube-proxy (iptables / IPVS)
│
├── Kubernetes
│   ├── Core Architecture
│   │   ├── API Server
│   │   ├── etcd (quorum, snapshots)
│   │   ├── Scheduler
│   │   └── Controller Manager
│   ├── Workloads
│   │   ├── Deployments
│   │   ├── StatefulSets
│   │   ├── DaemonSets
│   │   └── Jobs / CronJobs
│   ├── Scheduling & Autoscaling
│   │   ├── Requests & Limits
│   │   ├── QoS Classes
│   │   ├── HPA / VPA
│   │   └── Cluster Autoscaler / Karpenter
│   ├── Storage
│   │   ├── PV / PVC lifecycle
│   │   ├── CSI drivers
│   │   └── EBS / EFS / local volumes
│   ├── Security
│   │   ├── RBAC
│   │   ├── Service Accounts
│   │   ├── Pod Security Standards
│   │   └── Network Policies
│   └── Debugging
│       ├── CrashLoopBackOff
│       ├── Pending pods
│       └── Node NotReady
│
├── Observability
│   ├── Metrics
│   │   ├── Golden Signals
│   │   ├── RED / USE
│   │   ├── Prometheus internals (WAL, TSDB)
│   │   └── Cardinality management
│   ├── Logging
│   │   ├── Structured logging
│   │   ├── Fluent Bit / Promtail
│   │   └── Loki architecture
│   ├── Tracing
│   │   ├── OpenTelemetry
│   │   ├── Context propagation
│   │   └── Sampling strategies
│   └── Alerting
│       ├── Recording rules
│       ├── Burn rate alerts
│       └── Noise reduction
│
├── SRE & Reliability
│   ├── SRE Fundamentals
│   │   ├── SLIs / SLOs / SLAs
│   │   ├── Error budgets
│   │   └── Toil reduction
│   ├── Incident Management
│   │   ├── On-call practices
│   │   ├── Incident severity
│   │   └── Blameless postmortems
│   └── Failure Engineering
│       ├── Chaos engineering
│       ├── Game days
│       └── Cascading failure analysis
│
├── Cloud & AWS
│   ├── Identity & Security
│   │   ├── IAM deep dive
│   │   └── IRSA
│   ├── Compute
│   │   ├── EC2 lifecycle
│   │   ├── Auto Scaling Groups
│   │   └── Spot vs On-Demand
│   ├── Containers
│   │   ├── EKS internals
│   │   ├── ALB / NLB
│   │   └── Load Balancer Controller
│   ├── Storage & Data
│   │   ├── S3, EBS, EFS
│   │   ├── RDS vs DynamoDB
│   │   └── Backups & DR
│   └── Cost & Reliability
│       ├── Cost optimization
│       ├── Multi-AZ vs Multi-region
│       └── RTO / RPO
│
├── CI/CD & Infrastructure as Code
│   ├── CI Pipelines
│   │   ├── GitHub Actions / GitLab CI
│   │   ├── Secure builds
│   │   └── Artifact management
│   ├── CD Strategies
│   │   ├── Blue-Green
│   │   ├── Canary
│   │   └── Rolling updates
│   ├── GitOps
│   │   ├── ArgoCD / Flux
│   │   └── Drift detection
│   └── Terraform
│       ├── State management
│       ├── Modules
│       └── Policy as Code
│
├── Security & DevSecOps
│   ├── Cloud Security
│   │   ├── Least privilege IAM
│   │   └── Network segmentation
│   ├── Kubernetes Security
│   │   ├── Pod hardening
│   │   └── Admission controllers
│   └── Supply Chain Security
│       ├── Image scanning
│       ├── SBOM
│       └── Image signing
│
├── Programming & Automation
│   ├── Go
│   │   ├── Controllers & operators
│   │   └── Exporters & CLIs
│   ├── Python
│   │   └── Automation & tooling
│   └── Bash
│       └── Advanced scripting
│
├── System Design (SRE Focus)
│   ├── Scalability
│   │   ├── Horizontal vs Vertical
│   │   └── Backpressure
│   ├── High Availability
│   │   ├── Redundancy
│   │   └── Failover
│   └── Disaster Recovery
│       ├── Backup strategies
│       └── Multi-region design
│
└── Platform Engineering
    ├── Platform Concepts
    │   ├── Internal developer platforms
    │   ├── Golden paths
    │   └── Self-service infra
    ├── Tooling
    │   ├── Backstage
    │   ├── Crossplane
    │   └── Internal APIs
    └── Governance
        ├── Guardrails
        └── Developer experience (DX)







