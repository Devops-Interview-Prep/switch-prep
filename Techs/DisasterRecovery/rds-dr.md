# RDS DR (Amazon Relational Database Service Disaster Recovery)

- AWS RDS offers several powerful features for DR:

- **Multi-AZ Deployments:**
  - Description: 
    - Synchronous replication of your database to a standby instance in a different Availability Zone (AZ) within the same region.

  - Purpose: Primarily for High Availability (HA) within a region, not cross-region DR.

  - Failover: Automatic failover in case of an AZ outage or primary instance failure.

  - RPO/RTO: Near-zero RPO, very low RTO (seconds to minutes).

- **Cross-Region Read Replicas:**

  - Description: 
    - Asynchronous replication of your database to one or more read replica instances in a different AWS region.

  - Purpose: DR and read scaling.

  - Failover: Manual promotion of a read replica to a standalone DB instance in the DR region. 
  - This becomes your new primary.

  - RPO/RTO: Low RPO (data loss depends on replication lag), moderate RTO (manual promotion and DNS updates).

- **Aurora Global Database:**

  - Description: 
    - A single Aurora database that spans multiple AWS regions. 
    - It uses dedicated replication infrastructure for extremely fast and low-latency replication.

  - Purpose: High availability and disaster recovery for Aurora.

  - Failover: Very fast (often less than a minute) RTO with minimal data loss for planned or unplanned failovers to a secondary region.

  - RPO/RTO: Near-zero RPO, very low RTO (typically less than a minute).

  - Pros: Best-in-class for RTO/RPO for Aurora, simplified management.

  - Cons: Only for Aurora, higher cost.

- **Snapshots and Backups:**

- Description: 
  - RDS automatically takes daily snapshots. 
  - You can also manually create snapshots. 
  - These can be copied to other regions.

- Purpose: Basic DR and point-in-time recovery.

- Failover: Restore a snapshot in the DR region, then apply transaction logs (if point-in-time recovery is needed).

- RPO/RTO: High RPO (last snapshot or point-in-time recovery limit), High RTO (time to restore and apply logs).