# EKS DR (Amazon Elastic Kubernetes Service Disaster Recovery)

- DR for EKS involves several layers:
  - Cluster Configuration:
    - IaC: 
      - Define your EKS cluster, node groups, and Kubernetes resources (deployments, services, configmaps, secrets) using IaC (e.g., Terraform, Helm charts). 
      - This allows you to quickly provision a new cluster in another region.

  - Backup etcd: 
    - While AWS manages the EKS control plane etcd, backing up your Kubernetes resource definitions (YAML files) is crucial. 
    - Tools like Velero can back up and restore Kubernetes objects and persistent volumes.

  - Application Data:
    - Persistent Volumes (PVs): 
      - If your applications use Persistent Volumes, you need a strategy to replicate or restore that data.

    - CSI Drivers: 
      - Use CSI (Container Storage Interface) drivers that support cross-region snapshots and replication (e.g., for EBS, EFS).

  - Database DR: 
    - For stateful applications, external databases (RDS, DynamoDB) should have their own DR strategy (see RDS DR below).

  - Stateless Applications: 
    - Much easier to recover; simply redeploy them from your IaC.

  - Networking:
    - Ensure your recovery EKS cluster can connect to necessary services (databases, external APIs).
    - Update DNS records to point to the new load balancer/Ingress controller in the recovery region.

  - Strategies:

    - Pilot Light: 
      - Stand up a minimal EKS cluster in the DR region with core services, and scale up/deploy additional applications during an incident.

    - Warm Standby: 
      - Maintain a scaled-down but functional EKS cluster with all applications deployed.

    - Active-Active: 
      - Run two EKS clusters in different regions, potentially using a global load balancer (e.g., AWS Global Accelerator) and multi-cluster Ingress solutions. 
      - This is complex for stateful applications.

