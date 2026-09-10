# Linux File System Hierarchy

> Linux uses a single unified directory tree rooted at `/`. Everything — files, devices, processes, network sockets — is represented as a file or directory within this tree. Understanding the FHS (Filesystem Hierarchy Standard) is essential for debugging, configuration, and security work.

---

## Directory Structure Overview

```
/                           ← root of the entire filesystem tree
├── bin/                    ← essential user binaries (ls, cp, mv, cat, bash)
├── sbin/                   ← essential system binaries (reboot, fsck, ip, iptables)
├── etc/                    ← system-wide configuration files
├── home/                   ← user home directories (/home/alice, /home/bob)
├── root/                   ← root user's home directory (NOT inside /home)
├── var/                    ← variable data (logs, mail, databases, caches)
├── tmp/                    ← temporary files, cleared on reboot
├── usr/                    ← secondary hierarchy for user programs
│   ├── bin/                ← non-essential user binaries (python, vim, gcc, git)
│   ├── sbin/               ← non-essential system binaries
│   ├── lib/                ← libraries for /usr/bin and /usr/sbin
│   └── local/              ← locally compiled software (not from package manager)
├── lib/                    ← essential shared libraries (.so files) for /bin and /sbin
├── boot/                   ← kernel, initramfs, GRUB bootloader
├── dev/                    ← device files (not real files — interface to kernel)
├── proc/                   ← virtual FS: kernel + process information
├── sys/                    ← virtual FS: kernel + hardware device information
├── run/                    ← runtime data (PIDs, sockets) — cleared on reboot
├── mnt/                    ← temporary mount points (manual mounts)
├── media/                  ← auto-mounted removable media (USB, CD/DVD)
├── opt/                    ← optional third-party software (/opt/google, /opt/jdk)
├── srv/                    ← service data (/srv/www for web server files)
└── snap/                   ← Snap package installation directory (Ubuntu)
```

---

## Key Directories In-Depth

```bash
## /etc — System Configuration

# The "brain" of the system — almost all config files live here
/etc/passwd              # User accounts (username, UID, GID, home, shell)
/etc/shadow              # Hashed passwords (readable only by root)
/etc/group               # Group definitions
/etc/hostname            # System hostname
/etc/hosts               # Static DNS resolution (IP → hostname mapping)
/etc/resolv.conf         # DNS server configuration
/etc/fstab               # Filesystem mount table (auto-mounted on boot)
/etc/ssh/sshd_config     # SSH daemon configuration
/etc/sudoers             # sudo permissions (edit with visudo only!)
/etc/cron.d/             # System cron jobs
/etc/systemd/system/     # systemd unit files (services)
/etc/nginx/              # nginx configuration
/etc/environment         # System-wide environment variables

## /var — Variable Data (grows over time)

/var/log/                # System and application logs
/var/log/syslog          # General system log (Ubuntu/Debian)
/var/log/messages        # General system log (RHEL/CentOS)
/var/log/auth.log        # Authentication events
/var/log/nginx/          # nginx access and error logs
/var/lib/                # Persistent application state
/var/lib/docker/         # Docker images, containers, volumes
/var/lib/postgresql/     # PostgreSQL database files
/var/run/                # Runtime PID files and sockets (symlink to /run)
/var/tmp/                # Temporary files that survive reboots (unlike /tmp)
/var/spool/cron/         # User crontab files

## /proc and /sys — Virtual Filesystems (kernel interfaces)

# /proc — process and kernel information (no actual disk storage)
/proc/cpuinfo            # CPU details (cores, speed, flags)
/proc/meminfo            # Detailed memory breakdown (used by free, top)
/proc/loadavg            # Load averages (used by uptime)
/proc/version            # Kernel version
/proc/net/dev            # Network interface statistics
/proc/<PID>/             # Per-process directory (cmdline, status, fd, maps, etc.)
/proc/<PID>/status       # Process status (VmRSS, threads, state)
/proc/<PID>/fd/          # File descriptors (open files, sockets)
/proc/<PID>/environ      # Process environment variables

# /sys — hardware device and driver information
/sys/class/net/          # Network interface details (/sys/class/net/eth0/speed)
/sys/class/block/        # Block device information (disks)
/sys/devices/            # Device tree mirroring physical hardware topology
/sys/kernel/mm/          # Memory management parameters (hugepages, etc.)

## /dev — Device Files (kernel I/O interface)

/dev/sda                 # First SATA/SCSI disk
/dev/sda1                # First partition of /dev/sda
/dev/nvme0n1             # First NVMe disk (modern SSDs)
/dev/null                # Black hole — discard all writes, reads return EOF
/dev/zero                # Returns infinite stream of null bytes
/dev/random              # Cryptographically secure random (blocks when low entropy)
/dev/urandom             # Non-blocking random (safer for general use)
/dev/tty                 # Current terminal
/dev/stdin, /dev/stdout  # Standard input/output as files
```

---

## File Types in Linux

```bash
# Linux has 7 file types — ls shows the type as the first character
ls -la /dev/

# Output examples:
-rw-r--r-- 1 root  root   file.txt     # - regular file
drwxr-xr-x 2 root  root   /etc         # d directory
lrwxrwxrwx 1 root  root   link → real  # l symbolic link
crw-rw-rw- 1 root  tty    /dev/null    # c character device
brw-rw---- 1 root  disk   /dev/sda     # b block device
srwxrwxrwx 1 root  root   /run/docker  # s socket
prw-r--r-- 1 root  root   pipe         # p named pipe (FIFO)

# Check file type:
file /dev/sda          # block special (8/0)
file /etc/passwd       # ASCII text
file /bin/ls           # ELF 64-bit LSB executable
stat /etc/passwd       # detailed metadata including type
```

---

## Mounting — Attaching Storage

```bash
# Mount a device to a directory
mount /dev/sdb1 /mnt/data           # mount first partition of sdb to /mnt/data
mount -t ext4 /dev/sdb1 /mnt/data   # specify filesystem type
mount -o ro /dev/sdb1 /mnt/data     # mount read-only

# Show currently mounted filesystems
mount                               # all mounts
df -h                               # disk usage + mount points
findmnt                             # tree view of mounts
cat /proc/mounts                    # kernel's view of mounts

# Unmount
umount /mnt/data                    # unmount cleanly
umount -l /mnt/data                 # lazy unmount (detach even if busy — for NFS hangs)

# Persistent mounts: /etc/fstab
# Format: DEVICE MOUNTPOINT FSTYPE OPTIONS DUMP PASS
UUID=abc123 /data ext4 defaults 0 2
/dev/sdb1   /mnt/data ext4 defaults,nofail 0 0

# Apply fstab changes without rebooting:
mount -a                            # mount all entries in /etc/fstab
```

---

## Practical Commands

```bash
# Find what's in a directory and how much space it uses
du -sh /var/log/*              # size of each log file/dir
du -sh /var/lib/docker/        # Docker disk usage
df -h                          # filesystem usage overview
df -i                          # inode usage (if "no space" but disk looks empty)

# Find which process has a file open (useful for "device busy" errors)
lsof /var/log/app.log          # who has this file open?
lsof +D /var/log               # all processes with files in /var/log

# Find files by location pattern
find /etc -name "*.conf" -type f     # all config files
find /var/log -name "*.log" -mtime +7 -delete  # delete old logs

# Check filesystem health
fsck /dev/sdb1                  # check (unmount first!)
e2fsck -f /dev/sdb1             # force check of ext4 filesystem
```

---

## Interview Q&A

**Q: What is the difference between `/bin` and `/usr/bin`?**
`/bin` contains essential binaries that must be available even when only the root filesystem is mounted (e.g., during boot or single-user mode for recovery) — things like `ls`, `cp`, `bash`. `/usr/bin` contains non-essential user programs that are available after the full system mounts — things like `python`, `vim`, `gcc`. In modern Linux (Ubuntu 20+, Fedora), `/bin` is often a symlink to `/usr/bin`, merging the two for simplicity. The historical separation was needed when `/usr` might be on a separate filesystem that wasn't always mounted early in boot.

**Q: What are `/proc` and `/sys` and why don't they use disk space?**
Both are virtual filesystems (`proc` is `procfs`, `sys` is `sysfs`) — they exist only in RAM and are dynamically generated by the kernel on every read. `/proc` exposes process information and kernel parameters: `cat /proc/cpuinfo` reads live CPU data from the kernel, not from disk. `/sys` exposes hardware device and driver information in a structured tree. Writing to files in `/sys` can control hardware (e.g., enable/disable kernel features, change power states). Neither uses disk space — they're kernel data presented as files.

**Q: What is `/dev/null` and how is it used?**
`/dev/null` is the "null device" — a character device file that discards all data written to it and returns EOF on reads. It's used to discard output you don't want: `command 2>/dev/null` discards stderr; `command >/dev/null 2>&1` discards both stdout and stderr. Common pattern in cron jobs: `0 * * * * /script.sh >/dev/null 2>&1` to suppress all output. `cat /dev/null > file` truncates a file to zero bytes while keeping it open (safe for log rotation).

**Q: Why does `df` show disk is full but `du` shows only 50% used?**
`du` counts file data (blocks used by files). `df` shows filesystem usage which includes: all file data PLUS filesystem metadata (superblock, inode table, journal) PLUS files that have been deleted but are still held open by a process. The last case is the most common cause: `rm logfile` removes the directory entry but the disk blocks aren't freed until the process that has it open closes it. Find it with `lsof | grep deleted`. Fix: restart the process holding the deleted file open.
