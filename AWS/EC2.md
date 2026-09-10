# EC2 — Elastic Compute Cloud

> EC2 is a core AWS service that provides resizable virtual compute capacity. Think of it as renting a virtual server (VM) where you can run any application — just like a traditional server, but in the cloud with on-demand scaling.

---

## What Is EC2

- Scalable: Increase or decrease instances as needed (Auto Scaling)
- Flexible: Supports multiple OS (Linux, Windows, etc.)
- Integrated with VPC, IAM, S3, ELB, CloudWatch, SSM
- Pay-as-you-go: billed by second (minimum 60 seconds for most types)

---

## AMI — Amazon Machine Image

An AMI is a template for launching EC2 instances. It includes:
- An OS (e.g., Ubuntu, Amazon Linux, Windows)
- Application server, tools, or custom software
- Configuration settings

```bash
# Launch instance from AMI via CLI:
aws ec2 run-instances \
  --image-id ami-0abc123def456 \
  --instance-type t3.medium \
  --key-name my-keypair \
  --subnet-id subnet-0abc123 \
  --security-group-ids sg-0abc123
```

---

## Custom AMI — Golden Images

You can create your own AMI from a running EC2 instance. Use cases:
- Reusing a pre-configured environment
- Rapid scaling with identical setup (auto scaling groups)
- Creating golden images for security or compliance

```bash
# Create AMI from running instance:
aws ec2 create-image \
  --instance-id i-0abc123 \
  --name "my-golden-image-v1" \
  --description "Pre-configured app server" \
  --no-reboot   # or omit to reboot first (recommended for consistency)
```

**What the AMI Includes:**
- Operating System (Linux/Windows)
- All installed applications and packages
- Configuration files
- Custom scripts and environment setup
- Any changes to the file system

**What the AMI Does NOT Include:**
- Elastic IP address
- Instance metadata (IAM role, instance type, tags)
- Attached instance store (ephemeral) volumes
- Security groups and network settings

---

## EBS — Elastic Block Store

```bash
# Volumes attached to an EC2 instance:
# Root Volume  → Created from AMI, stores OS and boot files
# Additional   → Extra EBS volumes for data storage
# Ephemeral    → Instance store — physically attached, lost on stop/terminate

# Check volumes:
lsblk                    # list block devices
df -h                    # disk usage by filesystem

# Volume types (by use case):
# gp3 (General Purpose SSD) — balanced price/performance (default)
# io2/io1                   — high IOPS SSD (databases)
# st1                        — HDD, throughput-intensive (big data, streaming)
# sc1                        — cold HDD (infrequent access, cheapest)
```

### Resize EBS Volume (Hot Resize)

```bash
# Step 1: Resize in AWS console/CLI (block level — instant)
aws ec2 modify-volume --volume-id vol-0abc123 --size 50

# Step 2: Grow partition (OS still sees old size)
sudo growpart /dev/xvda 1

# Step 3: Extend filesystem to use new partition
sudo resize2fs /dev/xvda1         # ext4
sudo xfs_growfs -d /              # XFS (Amazon Linux 2)

# File System Comparison:
# ext4  → Ubuntu/Debian default, stable, journaling
# XFS   → Amazon Linux/RHEL/CentOS, great for large files
# NTFS  → Windows, supports permissions and compression
```

**Why two steps?** AWS extends the block device (disk level) instantly, but the filesystem inside the OS still tracks the old size — you must explicitly tell it to use the new space.

---

## Connect to EC2 — 4 Methods

```bash
# Method 1: SSH (classic)
ssh -i ~/.ssh/my-key.pem ec2-user@<public-ip>
ssh -i ~/.ssh/my-key.pem ubuntu@<public-ip>   # Ubuntu

# Requires: public IP, port 22 open in SG, key pair
```

**Method 2: EC2 Instance Connect (Browser SSH)**
- AWS pushes a temporary public key to `~/.ssh/authorized_keys` (valid 60s)
- Connects via browser console — no key management
- Requires: public IP or VPC endpoint, port 22 in SG, Amazon Linux/Ubuntu

**Method 3: Session Manager (SSM)**
```json
// EC2 IAM Role must have: AmazonSSMManagedInstanceCore
// User IAM policy:
{
  "Effect": "Allow",
  "Action": ["ssm:StartSession", "ssm:SendCommand"],
  "Resource": "*"
}
```
- No SSH keys, no public IP, no open ports required
- Works on private instances (via VPC endpoint or internet access for SSM API)
- Best for production environments with strict security requirements

**Method 4: EC2 Serial Console**
- Low-level console access — useful when SSH/SSM fails entirely
- Use case: kernel panics, GRUB errors, broken fstab, boot issues
- Requires: Nitro-based instance type, serial console enabled at account level

### Connection Methods Comparison

| Method | Port | Public IP | SSH Key | Private Instance | Use When |
|--------|------|-----------|---------|-----------------|----------|
| SSH | 22 | Yes | Yes | No | Standard development access |
| EC2 Instance Connect | 22 | Yes | No | Limited | Quick browser access |
| Session Manager | None | No | No | Yes | Production, secure access |
| Serial Console | None | N/A | No | Yes | Instance not booting/unreachable |

---

## Auto Scaling Group

An Auto Scaling Group (ASG) automatically adjusts the number of EC2 instances based on demand:

```bash
# Core concepts:
# Min capacity  → minimum instances always running
# Max capacity  → maximum instances allowed to scale to
# Desired capacity → current target number of instances

# Create ASG:
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name my-app-asg \
  --launch-template LaunchTemplateName=my-lt,Version='$Latest' \
  --min-size 2 \
  --max-size 10 \
  --desired-capacity 3 \
  --vpc-zone-identifier "subnet-abc,subnet-def"

# Scale based on CPU:
aws autoscaling put-scaling-policy \
  --auto-scaling-group-name my-app-asg \
  --policy-name cpu-scale-out \
  --policy-type TargetTrackingScaling \
  --target-tracking-configuration \
    "PredefinedMetricSpecification={PredefinedMetricType=ASGAverageCPUUtilization},TargetValue=70.0"
```

---

## Interview Q&A

**Q: What is the difference between an AMI and an EBS snapshot?**
An AMI (Amazon Machine Image) is a template used to launch EC2 instances — it includes the OS configuration, installed software, and references to EBS snapshots. Creating an AMI automatically creates underlying EBS snapshots of all attached volumes. An EBS snapshot is a point-in-time backup of a single EBS volume stored in S3. The AMI is the launch template; the snapshot is the data backup. You can copy AMIs across regions (which copies the underlying snapshots), and you can create an AMI from a snapshot.

**Q: What is the difference between stopping and terminating an EC2 instance?**
Stopping an instance is like shutting down a computer — the data on EBS volumes persists, the EBS root volume is kept, and you can restart it later (you'll get a different public IP unless using an Elastic IP). Terminating an instance is permanent — by default, the root EBS volume is deleted (DeleteOnTermination=true), the instance is gone, and all instance store data is lost. Data volumes (non-root EBS) can be configured to persist after termination. Stopped instances don't incur compute charges but still incur EBS storage charges.

**Q: When would you use Session Manager vs SSH to connect to an EC2 instance?**
Use Session Manager for production environments, private instances, or when you want to avoid managing SSH keys and opening port 22. SSM provides audit logs (all session activity sent to CloudTrail), doesn't require public IPs, and works through IAM — no credential files to rotate or lose. Use SSH when you need port forwarding (`-L`, `-R` flags for tunneling), SCP file transfers, or when you need to troubleshoot SSM agent issues. Many teams use SSM as the primary access method and reserve SSH for edge cases.
