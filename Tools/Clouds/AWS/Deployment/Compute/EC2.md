# EC2

- EC2 (Elastic Compute Cloud) is a core AWS service that provides resizable compute capacity in the cloud

- It's like renting a virtual server (VM) where you can run applications just like on a traditional server

- Key Features:
  - Scalable: Increase or decrease instances as needed
  - Flexible: Supports multiple OS (Linux, Windows, etc.).
  - Integrated with other AWS services.
  - Pay-as-you-go pricing.


# AMI (Amazon Machine Image)
- An AMI is a template for launching EC2 instances. It includes:
  - An OS (e.g., Ubuntu, Amazon Linux, Windows)
  - Application server, tools, or custom software
  - Configuration settings
- You launch an instance from an AMI

# Custom AMI
- You can create your own AMI from an existing EC2 instance. This is useful for:
  - Reusing a pre-configured environment.
  - Rapid scaling with the same setup.
  - Creating golden images for security or compliance.

# How to create a custom AMI

- Launch and configure an EC2 instance.
- Install applications, packages, settings.
- From the AWS Console → EC2 → Actions → Create Image.
- AWS creates an AMI and associated snapshots.
- A snapshot of the root volume is automatically created.
- You can include additional volumes manually during image creation.
- Whether to reboot the instance (recommended for consistency)
  - When selected, Amazon EC2 reboots the instance so that data is at rest when snapshots of the attached volumes are taken. This ensures data consistency.

- Creates an Amazon Machine Image (AMI).
- Automatically creates EBS snapshot(s) of the attached volume(s).
- Captures the exact state of the instance at the time of image creation.

- *What the AMI Includes*
  - Operating System (Linux/Windows)
  - All installed applications and packages
  - Configuration files
  - User data scripts (if stored on disk)
  - Custom scripts and environment setup
  - Any changes to the file system
  
- *What the AMI Does NOT Include*
  - Elastic IP address
  - Instance metadata (IAM role, instance type, tags)
  - Attached instance store (ephemeral) volumes
  - Security groups and network settings
  - Monitoring or CloudWatch configurations 

# Disk in EC2: EBS (Elastic Block Store)
- Snapshots are stored in AWS-managed S3 (you are billed for them).
- Snapshots are incremental (optimized for storage cost).
- Each EC2 instance has one or more volumes attached:
- *Root Volume*
  - Created from AMI
  - Stores OS and boot files
- *Additional Volumes*
  - You can attach more EBS volumes for data storage.
- *Ephemeral Volumes(Instance Store Volumes)*
  - Ephemeral volumes (also called instance store volumes) are temporary disks that:
    - Are physically attached to the EC2 host machine.
    - Exist only during the lifetime of the EC2 instance.
    - Data is lost when:
      - Instance is stopped or terminated
      - Host hardware fails or is replaced
    -  No snapshot support
- *Volume Types:*
  - gp3 (General Purpose SSD) – balanced price/performance.
  - io2 / io1 – high IOPS SSD.
  - st1, sc1 – HDD-based for throughput-intensive workloads.
- *Key Operations:*
  - Create, Attach, Detach, Resize.
  - Snapshots: Create point-in-time backups.
  - Volumes are persistent (can outlive the instance).

# Modify the EBS Volume Size of an EC2 Instance
-  When you modify the EBS volume size, AWS changes the size at the disk (block) level instantly (hot resize)
-  The file system inside the instance (like ext4, XFS, NTFS) does not automatically grow to use the new size — it still sees the old size.
-  Identify your device (usually /dev/xvda1 or /dev/nvme0n1p1): `lsblk`
-  Resize using growpart and resize2fs (for ext4):

      ```
      # Install growpart (Amazon Linux/Ubuntu)
      sudo yum install -y cloud-utils-growpart   # Amazon Linux
      sudo apt install -y cloud-guest-utils      # Ubuntu/Debian

      # Grow partition
      sudo growpart /dev/xvda 1

      # Resize filesystem
      sudo resize2fs /dev/xvda1

      #If you're using XFS (common in Amazon Linux 2), use this instead:
      sudo xfs_growfs -d /
      ```

- **Block Level (Disk Level)**
    - This is the raw storage provided by the volume.

    - Think of it as extending the physical hard drive itself — just more space available.

    - AWS does this part when you modify the volume size in the EC2 Console or via CLI.

    - The OS can now "see" that the disk is physically bigger.

    - BUT the OS doesn’t yet know how to use the extra space — because the file system hasn’t been expanded yet.

- **File System Level**
  - The file system is the structure that the operating system uses to organize and manage data on the disk.
  - This includes folders, files, permissions, etc.
  - Even if the disk is physically bigger, the file system only uses the old size — until you tell it to grow.
    ```
    File System	            Used By	        Key Features
    ext4	                 Linux	    Default in Ubuntu/Debian. Stable, fast, supports journaling.
    XFS	                     Linux	    Used in Amazon Linux, RHEL, and CentOS. Great for large files and high-performance workloads.
    NTFS	                Windows	    Default file system for Windows. Supports permissions, compression, etc.
    ```


# Connect To the EC2 Instance 

**1. Using SSH**

**2. EC2 Instance Connect (Browser-based SSH)**

- A browser-based SSH client provided by AWS in the EC2 console.
- Allows you to connect to Amazon Linux or Ubuntu instances without opening your terminal.
- *When to Use:*
  - Quick debugging when SSH keys are configured properly.
  - Temporary access for users without direct SSH.
- *Requirements:*
  - Instance must have a public IP or be in a public subnet.
  - EC2 Instance in private subnet with route to NAT or VPC endpoints.
  - Security group must allow inbound SSH (port 22).
  - Instance must have EC2 Instance Connect installed (already present in Amazon Linux & Ubuntu).
- *Configuration:*
    ```
    #IAM policy for user:

    {
      "Effect": "Allow",
      "Action": "ec2-instance-connect:SendSSHPublicKey",
      "Resource": "*"
    }

    ```
- *How It Works:*
  - AWS Generates a temporary SSH key pair for your session.
  - Pushes the public key to the instance’s ~/.ssh/authorized_keys file (valid for 60 seconds).
  - Establishes the connection from the browser-based terminal.
  - After the session ends or the 60 seconds expire, the public key is removed or ignored.

**3. Session Manager (SSM)**

- A fully managed AWS tool that lets you connect to EC2 instances securely without SSH keys, public IPs, or open ports.

- Connects through the SSM Agent, using AWS API calls.

- *When to Use:*
  - Secure remote access to private EC2 instances.
  - When you've lost your SSH key.
  - For automation, patching, and script execution.

- *Requirements:*
  - SSM Agent installed and running (pre-installed in Amazon Linux, Ubuntu 20.04+, Windows 2019+).
  - IAM permissions for the user:

    ```
    {
      "Effect": "Allow",
      "Action": [
        "ssm:StartSession",
        "ssm:DescribeInstanceInformation",
        "ssm:SendCommand"
      ],
      "Resource": "*"
    }
    ```
  -  IAM Role for EC2 Instance
     - The EC2 instance needs an IAM role with permission to talk to SSM
     - This is usually the managed policy: `AmazonSSMManagedInstanceCore`
  - VPC endpoint for SSM or internet access.


**4. EC2 Serial Console**

- Low-level, text-based console access to your instance.
- Similar to plugging a monitor directly into a physical server.
- Useful for boot issues, broken fstab, firewall misconfigurations.

- *When to Use:*
  - When EC2 is unreachable via SSH, SSM, or even not booting properly.
  - Troubleshooting kernel panics, GRUB errors, etc.

- *Requirements:*
  - Instance must use Nitro-based instance type (most modern instances).
  - Serial console access must be enabled in the account.
  - IAM policy must allow:
    ```
    {
      "Effect": "Allow",
      "Action": "ec2-instance-connect:ConnectSerialConsole",
      "Resource": "*"
    }
    ```
  - OS must have a serial console enabled (Linux: getty on ttyS0).

- Enable EC2 serial console from Account Settings.
- Add IAM permissions.
- Connect via EC2 → Instance → Connect → Serial Console tab.


# Autoscaling Group


  