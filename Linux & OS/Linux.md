# Linux — DevOps Interview Prep

---

# 🗂️ Linux Fundamentals

---

# What Is Linux — Architecture Overview

- Linux = kernel + GNU tools + shell + user apps
- Monolithic kernel: most OS services run in kernel space (vs microkernel where services run in user space)
- User space vs kernel space — system calls cross the boundary via the System Call Interface
- Every interaction with hardware goes: User App → glibc (system library) → System Call Interface → Kernel → Hardware
- The kernel manages: process scheduling, memory management, VFS (Virtual File System), network stack, device drivers
- **Distributions by package manager:**
  - Ubuntu / Debian → apt / .deb packages
  - RHEL / CentOS / Fedora → yum / dnf / .rpm packages
  - Alpine → apk / musl libc (minimal, used heavily for containers)
  - Arch → pacman

```
[ User App: nginx, python, bash ]
        ↓
[ glibc / libc — wraps syscalls ]
        ↓
[ System Call Interface — read(), write(), fork(), execve() ]
        ↓
[ Linux Kernel: scheduler, mm, VFS, net, drivers ]
        ↓
[ Hardware: CPU, RAM, Disk, NIC ]
```

> 💬 Say: "The kernel is one file — /boot/vmlinuz. Everything else is user space."

> 💡 Takeaway: Alpine uses musl libc instead of glibc — this causes subtle compatibility issues with some binaries compiled against glibc. If a container crashes with "not found" on a binary that clearly exists, musl vs glibc is the first suspect.

---

# Boot Process — BIOS to Login Prompt

Full boot sequence:

1. **BIOS/UEFI** — Power-On Self Test (POST). Detects and initializes hardware. Finds bootable device via boot order.
2. **MBR/GPT** — First 512 bytes of the disk (MBR) or GPT header contains the stage-1 bootloader which hands off to GRUB.
3. **GRUB (Grand Unified Bootloader)** — Loads the kernel image (`vmlinuz`) and `initramfs` into RAM. Displays the boot menu. Passes kernel parameters (e.g., `quiet splash root=/dev/sda1`).
4. **Kernel decompresses itself** — Initializes CPU, memory, detects hardware, sets up basic drivers using built-in modules.
5. **initramfs (initial RAM filesystem)** — A temporary root filesystem packed into RAM. Contains just enough drivers and tools to mount the real root filesystem (e.g., LVM drivers, LUKS decrypt, NFS).
6. **Real root mounted** — initramfs runs `/init`, locates the real root device, mounts it, then `pivot_root` or `switch_root` hands control to it.
7. **PID 1 launches** — `/sbin/init` or `/lib/systemd/systemd` becomes PID 1. Runs for the entire life of the system.
8. **systemd targets** — systemd processes unit dependencies in order:
   - `sysinit.target` → mount filesystems, set up swap, load modules
   - `basic.target` → sockets, timers, paths
   - `multi-user.target` → all network services, SSH, app servers
   - `graphical.target` → display manager (if desktop)
9. **Getty / SSH** — Login prompt appears on TTY or SSH daemon accepts connections.

```bash
# Diagnose boot
journalctl -b                     # all logs from current boot
journalctl -b -1                  # logs from previous boot (useful after crash)
systemd-analyze                   # total boot time
systemd-analyze blame             # which units took longest to start
systemd-analyze critical-chain    # the dependency chain that gated startup
```

> ⚠️ Watch out: `/boot/grub/grub.cfg` is auto-generated — never edit it directly. On Ubuntu: `update-grub`. On RHEL: `grub2-mkconfig -o /boot/grub2/grub.cfg`. Edit `/etc/default/grub` and `/etc/grub.d/` instead.

> 💡 Takeaway: If a server won't boot, boot into GRUB rescue mode (press `e` at GRUB menu), edit the kernel line to add `init=/bin/bash`, boot, fix the issue, then `exec /sbin/init`.

---

# Linux File System Hierarchy (FHS) — Every Directory Explained

| Directory | Purpose | What's inside |
|---|---|---|
| `/` | Root of the entire filesystem | Everything starts here |
| `/bin` | Essential user binaries | ls, cp, mv, bash, cat (symlink to /usr/bin on modern distros) |
| `/sbin` | Essential system binaries | fsck, mount, ifconfig, init |
| `/usr` | Secondary hierarchy — bulk of installed software | /usr/bin, /usr/lib, /usr/share |
| `/usr/bin` | Non-essential user commands | python3, nginx, git, vim |
| `/usr/lib` | Shared libraries for /usr/bin | .so files |
| `/usr/local` | Locally compiled/installed software | Doesn't get overwritten by distro upgrades |
| `/etc` | System-wide configuration files | All config — sshd_config, fstab, hosts, passwd |
| `/home` | User home directories | /home/alice, /home/bob |
| `/root` | Root user's home directory | Separate from /home |
| `/var` | Variable data — grows over time | Logs, spools, caches, databases |
| `/var/log` | Log files | syslog, auth.log, nginx/, apt/ |
| `/var/run` | Old location for runtime data | Symlink to /run on modern systems |
| `/run` | Runtime data — tmpfs, cleared on reboot | PID files, sockets, lock files |
| `/tmp` | Temporary files | World-writable, cleared on reboot (often tmpfs) |
| `/proc` | Virtual FS — kernel/process info (in RAM) | /proc/cpuinfo, /proc/meminfo, /proc/<pid>/ |
| `/sys` | Virtual FS — hardware, driver, kernel objects | Device parameters, power management |
| `/dev` | Device files | sda, tty, null, zero, urandom, loop |
| `/boot` | Boot files | vmlinuz (kernel), initramfs, grub/ |
| `/lib` | Shared libraries for /bin and /sbin | libc.so, kernel modules |
| `/lib/modules` | Kernel modules | Loadable drivers (.ko files) |
| `/mnt` | Temporary mount point (manual use) | Admins mount disks here temporarily |
| `/media` | Auto-mounted removable media | USB drives, DVDs |
| `/opt` | Optional third-party software | /opt/google/, /opt/splunk/ |
| `/srv` | Service data | Web server document roots |

**Key directories in depth:**

`/proc` — virtual filesystem generated by the kernel in RAM:
```bash
cat /proc/cpuinfo              # CPU model, cores, flags
cat /proc/meminfo              # memory breakdown
cat /proc/loadavg              # load average (same as uptime)
cat /proc/uptime               # seconds since boot
ls /proc/1234/                 # everything about PID 1234
cat /proc/1234/cmdline         # command that launched it
ls /proc/1234/fd/              # open file descriptors
cat /proc/1234/status          # state, memory, thread count

# Kernel tuning via /proc/sys (sysctl):
cat /proc/sys/net/ipv4/ip_forward       # is IP forwarding on? (0=no, 1=yes)
echo 1 > /proc/sys/net/ipv4/ip_forward  # enable (temporary, gone on reboot)
sysctl -w net.ipv4.ip_forward=1         # same, but also shows current value
sysctl -p                               # reload /etc/sysctl.conf (make permanent)
```

`/dev` — device files:
```bash
/dev/sda, /dev/sdb             # SCSI/SATA block devices
/dev/nvme0n1                   # NVMe block device
/dev/null                      # black hole — discard everything written
/dev/zero                      # returns infinite zero bytes
/dev/urandom                   # cryptographically secure random bytes
/dev/tty                       # current terminal
/dev/loop0                     # loop device (mount a file as a block device)
```

> 💡 Takeaway: `/run` is tmpfs — it lives in RAM and is cleared on every reboot. PID files and Unix sockets live here. If a service fails to start because its socket file wasn't cleaned up after a crash, check `/run`.

---

# File Types in Linux — Everything Is a File

Linux has 7 file types — the first character of `ls -la` output reveals the type:

| Symbol | Type | Example |
|---|---|---|
| `-` | Regular file | /etc/hosts, /bin/bash, image.png |
| `d` | Directory | /home/alice/, /etc/ |
| `l` | Symbolic link | /usr/bin/python → python3 |
| `c` | Character device | /dev/tty, /dev/null, /dev/urandom |
| `b` | Block device | /dev/sda, /dev/nvme0n1 |
| `s` | Unix domain socket | /var/run/docker.sock, /tmp/mysql.sock |
| `p` | Named pipe (FIFO) | Created with mkfifo |

```bash
ls -la /dev/null /dev/sda /var/run/docker.sock /etc/hosts
# crw-rw-rw-  1 root root    1,  3 Jan  1 /dev/null        ← character device
# brw-rw----  1 root disk  8,   0 Jan  1 /dev/sda          ← block device
# srw-rw----  1 root docker    0 Jan  1 /var/run/docker.sock ← socket
# -rw-r--r--  1 root root   185 Jan  1 /etc/hosts          ← regular file
```

**Hard links vs Symbolic links:**

```bash
# Hard link — same inode, second name for the same data
ln /etc/hosts /tmp/hosts-copy        # same inode number
ls -i /etc/hosts /tmp/hosts-copy     # both show same inode
# - Deleting original does NOT break hard link
# - Hard links CANNOT cross filesystem boundaries
# - Hard links CANNOT point to directories (except . and ..)

# Symbolic link — a file whose content is a path string
ln -s /etc/nginx/nginx.conf /tmp/nginx-conf   # new inode, stores path
ls -la /tmp/nginx-conf   # → /tmp/nginx-conf -> /etc/nginx/nginx.conf
# - Deleting or moving the original BREAKS the symlink (dangling)
# - Can cross filesystems
# - Can point to directories
```

```bash
# stat — full inode information
stat /etc/hosts
# File: /etc/hosts
# Size: 185       Blocks: 8     IO Block: 4096  regular file
# Device: fd01h   Inode: 524295  Links: 1
# Access: (0644/-rw-r--r--)  Uid: (0/root)   Gid: (0/root)
# Access: 2024-01-15 09:00:00
# Modify: 2024-01-10 12:00:00
# Change: 2024-01-10 12:00:00

ls -i /etc/hosts      # just inode number: 524295 /etc/hosts
```

> 💡 Takeaway: Docker mounts config files as symlinks inside containers. If the container can't read the config, check whether the symlink target is also mounted. Volumes bind-mount the inode — they follow hard links but may not resolve symlinks into other directories.

---

# 🗂️ File Permissions

---

# Unix File Permissions — chmod and Octal

Every file has permissions for three classes: **owner (u)**, **group (g)**, **others (o)**

```bash
ls -la script.sh
-rwxr-xr--  1 ubuntu devs 4096 Jan 1 12:00 script.sh
│└┬┘└┬┘└┬┘
│ │  │  └── others: r-- = read only (4)
│ │  └───── group:  r-x = read + execute (5)
│ └──────── owner:  rwx = read + write + execute (7)
└────────── file type: - = regular file
```

**Octal permission values:**

| Octal | Binary | Permissions |
|---|---|---|
| 0 | 000 | --- (none) |
| 1 | 001 | --x (execute only) |
| 2 | 010 | -w- (write only) |
| 3 | 011 | -wx (write + execute) |
| 4 | 100 | r-- (read only) |
| 5 | 101 | r-x (read + execute) |
| 6 | 110 | rw- (read + write) |
| 7 | 111 | rwx (read + write + execute) |

```bash
# Numeric (octal) mode
chmod 755 script.sh      # owner: rwx, group: r-x, others: r-x
chmod 644 config.yaml    # owner: rw-, group: r--, others: r--
chmod 600 ~/.ssh/id_rsa  # owner: rw-, group: ---, others: --- (private key)
chmod 400 secret.pem     # owner: r--, nobody else (read-only secret)
chmod -R 644 /var/www    # recursive — apply to all files in tree

# Symbolic mode
chmod u+x script.sh        # add execute for owner
chmod g-w file.txt         # remove write from group
chmod o=r file.txt         # set others to read-only (exact)
chmod u+x,g-w,o=r file    # multiple changes in one command
chmod a+r file.txt         # all (a) = u + g + o

# What execute means for directories:
# r = can list directory contents (ls)
# w = can create/delete files in directory
# x = can enter directory (cd) and access files inside
# A directory without x cannot be traversed — files inside are inaccessible
```

> ✅ Rule: 755 for directories, 644 for files — the web server standard. SSH private keys: 600. Read-only secrets: 400. World-writable files: security audit flag.

> ⚠️ Watch out: `chmod -R 777 /var/www` is a security disaster. It makes every file executable and writable by everyone. Attackers who can write any file can execute PHP/scripts.

---

# Special Permissions — SUID, SGID, Sticky Bit

**SUID — Set User ID (4000)**

When set on an executable, it runs with the **file owner's** UID, not the caller's.

```bash
ls -la /usr/bin/passwd
-rwsr-xr-x 1 root root 68208 Jan 1 /usr/bin/passwd
     ↑ 's' in owner execute position = SUID set

# Why passwd needs SUID:
# Regular user runs passwd → process runs as ROOT (because passwd is owned by root + SUID)
# Only root can write /etc/shadow — SUID bridges this gap safely

# Set SUID
chmod u+s /usr/bin/myprog
chmod 4755 /usr/bin/myprog      # 4 = SUID prefix

# Find all SUID files (audit regularly!)
find / -perm /4000 -type f 2>/dev/null
find / -perm -4000 -type f 2>/dev/null   # both forms work
```

> ⚠️ Watch out: SUID root programs are a primary attack surface. A buffer overflow or command injection in an SUID root binary gives instant root access. Any unexpected SUID file is a serious security finding.

**SGID — Set Group ID (2000)**

On an **executable**: runs with the file's **group** permissions.
On a **directory**: new files created inside inherit the **directory's group** (not the creator's primary group).

```bash
ls -la /usr/bin/write
-rwxr-sr-x 1 root tty 14328 Jan 1 /usr/bin/write
              ↑ 's' in group execute position = SGID set

# SGID on shared directory — team collaboration:
mkdir /shared/team
chown root:devs /shared/team
chmod 2775 /shared/team        # SGID so new files are owned by 'devs' group
# Now: alice (member of devs) creates file.txt → file.txt group = devs, not alice

chmod g+s /shared/team         # same as chmod 2xxx

# Find SGID files
find / -perm /2000 -type f 2>/dev/null
```

**Sticky Bit (1000)**

On a **directory**: only the **file owner** (or root) can delete files, even if others have write permission on the directory.

```bash
ls -la / | grep tmp
drwxrwxrwt  14 root root 4096 Jan 1 /tmp
              ↑ 't' = sticky bit set (everyone can write, only owner can delete own files)

# Set sticky bit
chmod +t /shared/uploads
chmod 1777 /tmp          # the classic /tmp permissions

# Sticky bit + octal: 1=sticky, 2=SGID, 4=SUID, combined:
chmod 3775 /dir          # SGID (2) + sticky (1) = 3
```

**Capital T / S** = the underlying execute bit is NOT set (sticky or SUID/SGID set but no execute). This is usually a mistake — `chmod +t` or `chmod u+s` without also setting execute.

---

# umask — Default Permission Control

`umask` defines which permission bits are **removed** from newly created files and directories.

- Default max for directories: **777**
- Default max for files: **666** (never 777 — files should not have default execute)
- `default permission = max - umask`

| umask | New dir | New file | Use case |
|---|---|---|---|
| 022 | 755 | 644 | Standard — world readable |
| 027 | 750 | 640 | Stricter — others get nothing |
| 077 | 700 | 600 | Paranoid — owner only |
| 002 | 775 | 664 | Collaborative — group can write |

```bash
umask              # view current umask → 0022
umask 027          # set stricter umask (this shell session only)
umask -S           # symbolic display: u=rwx,g=rx,o=

# Make permanent:
echo "umask 027" >> ~/.bashrc           # per-user
echo "umask 027" >> /etc/profile        # system-wide login shells
echo "umask 027" >> /etc/bash.bashrc    # system-wide interactive shells

# Test: create a file and see the result
umask 027
touch testfile && ls -la testfile    # → -rw-r----- (640)
mkdir testdir && ls -ld testdir      # → drwxr-x--- (750)
```

> 💡 Takeaway: In automated deployments, check the umask of the user running the deployment. If a service creates a config file with 640 but the app runs as a different user, it can't read its own config.

---

# ACLs — Fine-Grained Permissions

Standard Unix permissions have one owner, one group, and others — ACLs break this limitation by allowing **per-user and per-group** permissions on any file.

```bash
# Check if filesystem supports ACLs (look for 'acl' in mount options)
mount | grep " / "
# or ensure the filesystem is mounted with acl option:
# UUID=xxx  /  ext4  defaults,acl  0 1

# View ACL on a file/directory
getfacl /shared/project/
# # file: shared/project/
# # owner: root
# # group: devs
# user::rwx              ← owner permissions
# user:alice:rw-         ← alice specifically gets rw
# group::r-x             ← group 'devs' gets rx
# group:ops:rwx          ← group 'ops' gets rwx
# mask::rwx              ← effective permission ceiling
# other::---             ← everyone else: nothing

# Grant user "alice" read+write on a file
setfacl -m u:alice:rw /shared/project/config.yaml

# Grant group "devs" read recursively on a directory
setfacl -R -m g:devs:r /shared/project/

# Set default ACL (inherited by ALL new files created in directory)
setfacl -d -m u:alice:rw /shared/project/
setfacl -d -m g:devs:rx /shared/project/

# Remove a specific ACL entry
setfacl -x u:alice /shared/project/config.yaml

# Remove ALL ACLs (revert to standard permissions)
setfacl -b /shared/project/config.yaml

# Copy ACLs from one file to another
getfacl source_file | setfacl --set-file=- dest_file
```

```bash
# ls shows '+' when ACL is present
ls -la /shared/project/config.yaml
-rw-rw-r--+ 1 root devs 1024 Jan 1 config.yaml
              ↑ '+' = ACL is set beyond standard permissions
```

> ✅ Rule: Use ACLs when you need to give one specific person or team access to a file without changing the group ownership or breaking existing permission structure. Common in CI/CD: grant `deploy` user rw on configs without making it a member of every group.

---

# 🗂️ Users and Groups

---

# User Management — /etc/passwd, /etc/shadow, /etc/group

**/etc/passwd** — 7 colon-separated fields:
```
username:x:UID:GID:comment:home_dir:shell

ubuntu:x:1000:1000:Ubuntu User:/home/ubuntu:/bin/bash
www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin
nobody:x:65534:65534::/nonexistent:/usr/sbin/nologin
```
- `x` in password field = password is in /etc/shadow
- UID 0 = root, 1–999 = system/service accounts, 1000+ = regular human users
- `nologin` or `false` shell = account exists (for service ownership) but cannot log in

**/etc/shadow** — 9 colon-separated fields (readable by root only):
```
username:hashed_pw:last_change:min_age:max_age:warn:inactive:expire:reserved

ubuntu:$6$salt$hashedpassword...:19000:0:99999:7:::
```
- `$6$` = SHA-512, `$5$` = SHA-256, `$1$` = MD5 (insecure), `!` or `*` = locked/disabled
- `last_change` = days since epoch (Jan 1 1970) when password last changed
- `!!` = password never set (new account, or key-only SSH account)

**/etc/group** — 4 colon-separated fields:
```
groupname:x:GID:member1,member2,member3

sudo:x:27:ubuntu,alice
docker:x:998:ubuntu,bob
developers:x:1001:alice,bob,carol
```

**Key user management commands:**
```bash
# Create user with home directory, bash shell, add to sudo group
useradd -m -s /bin/bash -G sudo,docker alice

# Modify existing user
usermod -aG docker alice          # append to group (CRITICAL: always use -a with -G)
usermod -s /bin/bash alice        # change shell
usermod -L alice                  # lock account (prepends ! to shadow password)
usermod -U alice                  # unlock account
usermod -e 2024-12-31 alice       # set account expiry date

# Password management
passwd alice                      # set/change password interactively
passwd -l alice                   # lock password
passwd -e alice                   # expire password (force change on next login)
chage -l alice                    # show password aging info
chage -M 90 alice                 # max 90 days between password changes
chage -E 2024-12-31 alice         # account expires on date

# Delete user
userdel alice                     # remove user (keep home dir)
userdel -r alice                  # remove user + home dir + mail spool

# Query
id alice                          # uid=1001(alice) gid=1001(alice) groups=1001(alice),27(sudo),998(docker)
groups alice                      # alice : alice sudo docker
getent passwd alice               # lookup from all sources (files + LDAP + etc.)
finger alice                      # detailed user info (if finger installed)
who                               # who is currently logged in
w                                 # who is logged in and what they're doing
last                              # login history from /var/log/wtmp
lastb                             # failed login attempts from /var/log/btmp
```

> ⚠️ Watch out: `usermod -G docker alice` (without `-a`) **replaces** all supplementary groups with just `docker`. Alice loses sudo, loses other groups. Always use `-aG` to append.

---

# sudo and sudoers — Controlled Privilege Escalation

```bash
# /etc/sudoers — ONLY edit with visudo (validates syntax before saving)
visudo                            # opens in $EDITOR with syntax validation
visudo -f /etc/sudoers.d/alice    # edit a specific drop-in file
visudo -c                         # check syntax without editing

# Sudoers syntax: WHO WHERE=(AS_WHO:AS_GROUP) WHAT
alice ALL=(ALL:ALL) ALL           # alice can run anything as anyone anywhere
%sudo ALL=(ALL) ALL               # group sudo can run anything
%wheel ALL=(ALL) NOPASSWD: ALL    # wheel group, no password (RHEL style)

# Restrict to specific commands
deployer ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart myapp
deployer ALL=(ALL) NOPASSWD: /usr/bin/systemctl start myapp, /usr/bin/systemctl stop myapp
backup ALL=(ALL) NOPASSWD: /usr/bin/rsync

# /etc/sudoers.d/ — drop-in files (preferred over editing /etc/sudoers)
# These are auto-included via: #includedir /etc/sudoers.d
echo "deployer ALL=(ALL) NOPASSWD: /usr/bin/systemctl" | \
  sudo tee /etc/sudoers.d/deployer
sudo chmod 440 /etc/sudoers.d/deployer    # MUST be 440 — sudo ignores other modes

# Usage
sudo command                      # run as root
sudo -u postgres psql             # run as specific user (postgres)
sudo -g devs touch /shared/file   # run with specific group
sudo -l                           # list what THIS user can sudo
sudo -l -U alice                  # list what alice can sudo (as root)
sudo -i                           # interactive root login shell (loads root profile)
sudo -s                           # non-login root shell (inherits current env)
sudo -k                           # invalidate cached sudo credentials immediately
sudo -v                           # refresh sudo credential cache
```

> ⚠️ Watch out: A syntax error in /etc/sudoers can lock everyone out of sudo permanently. `visudo` prevents saving broken config. If you're already locked out: boot to single-user mode or use another method to get root access.

> ✅ Rule: In CI/CD pipelines, create a dedicated service user with NOPASSWD sudo for only the specific commands it needs. Never give a deploy user `ALL=(ALL) NOPASSWD: ALL` — that's equivalent to root.

---

# 🗂️ Process Management

---

# Process Lifecycle and States — Full Detail

**Process states:**

| State | Code | Meaning |
|---|---|---|
| Running | R | Actively on CPU or in the run queue waiting for CPU |
| Sleeping (interruptible) | S | Waiting for I/O, timer, or signal — **can be woken by signal** |
| Sleeping (uninterruptible) | D | Deep kernel I/O wait — **SIGKILL does not work** |
| Stopped | T | Paused by SIGSTOP or a debugger (gdb/strace) |
| Zombie | Z | Exited but parent hasn't called wait() — takes no resources except PID slot |
| Dead | X | Should never appear in ps output |

**Process creation flow:**
```
fork()  → duplicates parent process (copy-on-write: memory pages shared until written)
exec()  → replaces current process image with a new program
clone() → creates threads (shared address space, file descriptors, signal handlers)
wait()  → parent waits for child to exit and reaps its exit status
```

**Inspecting processes via /proc:**
```bash
# /proc/<pid>/ — virtual directory for every running process
cat /proc/1234/cmdline        # full command line (null-byte separated)
cat /proc/1234/status         # state, UID, memory stats, thread count, parent PID
ls -la /proc/1234/fd/         # all open file descriptors (symlinks to files)
cat /proc/1234/maps           # memory map: virtual address ranges, permissions
cat /proc/1234/environ        # environment variables at process start
cat /proc/1234/io             # I/O stats: bytes read/written
cat /proc/1234/net/tcp        # TCP sockets this process has open
readlink /proc/1234/exe       # path to the executable binary
```

```bash
ps aux              # all processes, user-oriented format
# USER  PID %CPU %MEM    VSZ   RSS TTY   STAT START  TIME COMMAND
# root    1  0.0  0.1 169128 10752 ?    Ss   Jan01   0:05 /lib/systemd/systemd

ps -ef              # all processes, full format with PPID
ps -eo pid,ppid,user,stat,pcpu,pmem,cmd   # custom columns
ps --sort=-pcpu | head -10   # top CPU consumers
ps -T -p 1234       # show all threads of PID 1234
pstree -p           # tree view of process parent-child relationships
pgrep -la nginx     # find PIDs by name with command line
```

> 💡 Takeaway: D-state processes are the hardest to handle. You cannot kill them. They appear with `D` in `ps aux`. Usually caused by hung NFS mounts or a failing disk. Only a reboot reliably resolves a stuck D-state kernel wait.

---

# Signals — Complete Reference

| Signal | Number | Catchable | Default Action | Common Use |
|---|---|---|---|---|
| SIGHUP | 1 | Yes | Terminate | Reload config (nginx, sshd send HUP to reload) |
| SIGINT | 2 | Yes | Terminate | Ctrl+C in terminal |
| SIGQUIT | 3 | Yes | Core dump | Ctrl+\ — terminates with core dump |
| SIGKILL | 9 | **No** | Terminate (forced) | Last resort force kill |
| SIGTERM | 15 | Yes | Terminate (graceful) | Default kill signal — allows cleanup |
| SIGSTOP | 17/19 | **No** | Stop process | Cannot be caught — forced pause |
| SIGCONT | 18 | Yes | Continue | Resume stopped process |
| SIGCHLD | 20/17 | Yes | Ignore | Child process changed state |
| SIGUSR1 | 10 | Yes | Terminate | User-defined (app-specific: e.g., nginx reopen logs) |
| SIGUSR2 | 12 | Yes | Terminate | User-defined |
| SIGPIPE | 13 | Yes | Terminate | Write to broken pipe |
| SIGALRM | 14 | Yes | Terminate | Timer expired |
| SIGWINCH | 28 | Yes | Ignore | Terminal window resized |

```bash
# Sending signals
kill -15 1234           # SIGTERM — graceful shutdown (default when you run 'kill')
kill -9 1234            # SIGKILL — force kill (no cleanup)
kill -1 1234            # SIGHUP — reload config
kill -0 1234            # check if process exists (no signal sent, just checks)
kill 1234               # default: SIGTERM

# Kill by name
killall nginx           # SIGTERM to all 'nginx' processes
killall -9 nginx        # SIGKILL to all 'nginx' processes
pkill -f "python app"   # match by full command line
pkill -u alice          # kill all processes owned by alice

# Signal to process group (negative PID)
kill -15 -1234          # SIGTERM to entire process group of 1234

# Trap signals in bash scripts
trap "echo 'Cleaning up...'; rm -f /tmp/lockfile; exit 0" SIGTERM SIGINT
trap "" SIGHUP          # ignore SIGHUP (common in daemon scripts)
```

> ✅ Rule: Always try SIGTERM first. Wait 5–10 seconds for the process to clean up (flush writes, drain connections, remove lock files). Then SIGKILL only if it hasn't exited. Abrupt SIGKILL on a database = potential corruption.

---

# ps, top, htop — Process Monitoring

**ps — process snapshot:**
```bash
ps aux                    # all processes, user-friendly format
ps -ef                    # all processes, standard format with PPID
ps -eo pid,ppid,user,stat,pcpu,pmem,comm --sort=-pcpu   # custom, sorted by CPU
ps -T -p $(pgrep java)    # all threads of java process

# Process columns explained:
# USER     — process owner
# PID      — process ID
# %CPU     — CPU usage percentage
# %MEM     — physical memory percentage
# VSZ      — virtual memory (KB) — all mapped memory including not-in-RAM
# RSS      — resident set size (KB) — actual RAM used
# TTY      — controlling terminal (? = daemon/no terminal)
# STAT     — state (S=sleep, R=run, D=disk wait, Z=zombie, T=stopped)
#            s = session leader, + = foreground process group, l = multi-threaded
# START    — when started
# TIME     — cumulative CPU time consumed
# COMMAND  — command name/line
```

**top — live process monitor:**
```bash
top                       # interactive process monitor
top -d 1                  # refresh every 1 second
top -u alice              # show only alice's processes
top -p 1234,5678          # watch specific PIDs only
top -b -n 3 > top.log     # batch mode: 3 iterations, save to file

# top header lines:
# top - 14:30:01 up 5 days, 3:12  — uptime
# Tasks: 200 total, 1 running, 199 sleeping, 0 stopped, 0 zombie
# %Cpu(s): 2.1 us, 0.5 sy, 0.0 ni, 97.0 id, 0.2 wa, 0.0 hi, 0.1 si, 0.0 st
#          us=user  sy=system  ni=nice  id=idle  wa=iowait  si=softirq  st=stolen(VM)
# MiB Mem: 16384 total, 2048 free, 8192 used, 6144 buff/cache
# MiB Swap:  4096 total,  4096 free,    0 used.  7168 avail Mem
```

**top memory columns:**
| Column | Meaning |
|---|---|
| VIRT | Virtual memory — all reserved address space (may never touch RAM) |
| RES | Resident memory — pages actually in RAM right now |
| SHR | Shared memory — shared libraries, tmpfs (counted in multiple processes) |

**top interactive keys:**
- `1` — toggle per-CPU display vs aggregate
- `M` — sort by memory (RES)
- `P` — sort by CPU
- `k` — kill (enter PID then signal)
- `r` — renice (change priority)
- `u` — filter by username
- `f` — column manager (add/remove fields)
- `W` — write config to ~/.toprc
- `q` — quit

---

# Cron and Scheduling — Complete Reference

**Crontab syntax:**
```
# ┌───────── minute        (0-59)
# │ ┌───────── hour          (0-23)
# │ │ ┌───────── day of month  (1-31)
# │ │ │ ┌───────── month         (1-12 or Jan-Dec)
# │ │ │ │ ┌───────── day of week   (0-7, Sunday=0 or 7)
# │ │ │ │ │
# * * * * *  /path/to/command arg1 arg2

# Step values: */n = every n units
# Lists: 1,5,10 = at minute 1, 5, and 10
# Ranges: 1-5 = minutes 1 through 5

0 * * * *       /usr/bin/cleanup.sh           # top of every hour
*/15 * * * *    /usr/bin/health-check.sh      # every 15 minutes
0 2 * * *       /usr/bin/backup.sh            # daily at 2:00 AM
0 2 * * 0       /usr/bin/weekly-report.sh     # every Sunday at 2 AM
0 2 1 * *       /usr/bin/monthly-cleanup.sh   # 1st of every month at 2 AM
0 9-17 * * 1-5  /usr/bin/business-check.sh    # 9am-5pm Mon-Fri
@reboot         /usr/bin/start-my-service.sh  # on every system boot
@daily          /usr/bin/daily-task.sh        # alias for 0 0 * * *
@hourly         /usr/bin/hourly-task.sh       # alias for 0 * * * *
@weekly         /usr/bin/weekly-task.sh       # alias for 0 0 * * 0
@monthly        /usr/bin/monthly-task.sh      # alias for 0 0 1 * *
```

```bash
crontab -e              # edit current user's crontab
crontab -l              # list current user's crontab
crontab -r              # remove entire crontab (NO confirmation — careful!)
crontab -u alice -l     # view alice's crontab (as root)
crontab -u alice -e     # edit alice's crontab (as root)

# System-wide cron locations:
# /etc/cron.hourly/    — drop scripts here, run every hour
# /etc/cron.daily/     — run daily (usually 6:25 AM)
# /etc/cron.weekly/    — run weekly
# /etc/cron.monthly/   — run monthly
# /etc/cron.d/         — crontab-format files with an extra user field:
#   * * * * *  www-data  /usr/lib/apache2/suexec
# /var/spool/cron/crontabs/  — per-user crontabs (managed by crontab command)
```

**Cron gotchas:**
```bash
# Cron's PATH is minimal: /usr/bin:/bin
# ALWAYS use full paths in cron commands

# Bad:  0 2 * * * python3 /opt/backup.py
# Good: 0 2 * * * /usr/bin/python3 /opt/backup.py

# Set PATH at top of crontab:
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
SHELL=/bin/bash
MAILTO=admin@company.com   # email output to this address (empty string = silence)

# Redirect output to log (cron emails output by default)
0 2 * * * /usr/bin/backup.sh >> /var/log/backup.log 2>&1
```

> ⚠️ Watch out: cron runs with a minimal environment. HOME, USER, and SHELL are set, but DISPLAY, SSH_AUTH_SOCK, and other session variables are not. Scripts that work interactively may fail in cron for this reason. Test with `env -i HOME=/root /usr/bin/yourscript.sh`.

**systemd timers — modern replacement for cron:**
```bash
# /etc/systemd/system/backup.service
[Unit]
Description=Nightly Backup

[Service]
Type=oneshot
ExecStart=/usr/bin/backup.sh
User=backup

# /etc/systemd/system/backup.timer
[Unit]
Description=Nightly Backup Timer

[Timer]
OnCalendar=daily           # every day at midnight
# OnCalendar=*-*-* 02:00:00   # specific time
# OnCalendar=Mon..Fri 09:00   # weekdays at 9am
Persistent=true            # if system was off at trigger time, run when it comes back

[Install]
WantedBy=timers.target

# Enable and start
systemctl daemon-reload
systemctl enable --now backup.timer

# Monitor timers
systemctl list-timers --all      # all timers, last trigger, next trigger
journalctl -u backup.service     # logs from the timer-triggered service
```

---

# 🗂️ Memory Management

---

# Virtual Memory, Paging, and Swap

**Virtual memory concepts:**
- Every process sees its own **contiguous** address space (0 to 2^64 on 64-bit)
- The **MMU** (Memory Management Unit in hardware) translates virtual → physical via **page tables**
- Default page size: **4 KB** (hugepages: 2 MB or 1 GB for databases)
- A page can be: in RAM, on swap disk, or never-loaded (demand paging — loaded on first access)
- **Copy-on-Write (CoW)**: after fork(), parent and child share the same physical pages until one writes — then a copy is made. Makes fork() fast for exec() pattern.

```bash
# /proc/meminfo — authoritative memory breakdown
cat /proc/meminfo

MemTotal:       16384000 kB   # total physical RAM
MemFree:         1024000 kB   # completely unused RAM
MemAvailable:    8192000 kB   # RAM available without swapping (includes reclaimable cache)
Buffers:          512000 kB   # kernel buffer cache (raw block I/O)
Cached:          5120000 kB   # page cache (file data) — reclaimable by kernel
SwapCached:        20480 kB   # data on swap that's also in RAM (quick swap-in)
Active:          6144000 kB   # recently used pages (less likely to be reclaimed)
Inactive:        3072000 kB   # older pages (candidates for reclaim)
SwapTotal:       4096000 kB   # total swap space
SwapFree:        3993600 kB   # unused swap
SwapUsed:         102400 kB   # swap in use (ALERT if non-zero on production)
Dirty:             51200 kB   # data modified in RAM but not yet written to disk
Writeback:             0 kB   # data actively being flushed to disk
Shmem:            204800 kB   # shared memory (tmpfs, Docker overlayfs layers)
SReclaimable:     819200 kB   # kernel slab caches that CAN be reclaimed
SUnreclaim:       204800 kB   # kernel slab caches that CANNOT be reclaimed
```

> 💡 Takeaway: `MemAvailable` is the metric to alert on — not `MemFree`. Linux fills free RAM with disk cache (makes reads faster). MemAvailable accounts for reclaimable cache and reports what's truly available for new processes without swapping.

```bash
# Human-readable overview
free -h
#               total        used        free      shared  buff/cache   available
# Mem:           15Gi        7.8Gi       1.0Gi       200Mi       6.2Gi       7.8Gi
# Swap:           4Gi          0Bi       4Gi

# Swap management
swapon --show               # show swap devices (file or partition) and usage
swapon -a                   # enable all swap listed in /etc/fstab
swapoff -a                  # disable all swap (required before Kubernetes node setup)
swapoff /swapfile           # disable specific swap file

# Create a swap file on-the-fly:
fallocate -l 4G /swapfile   # allocate 4GB (faster than dd)
chmod 600 /swapfile          # secure it
mkswap /swapfile             # format as swap
swapon /swapfile             # enable it
echo '/swapfile none swap sw 0 0' >> /etc/fstab   # persist

# Swappiness (how aggressively kernel uses swap)
cat /proc/sys/vm/swappiness    # default: 60 (0=avoid swap, 100=swap aggressively)
sysctl -w vm.swappiness=10     # set lower for production servers
echo 'vm.swappiness=10' >> /etc/sysctl.conf       # persist
```

> ⚠️ Watch out: Kubernetes requires swap to be **disabled** (`swapoff -a`) on all nodes. With swap enabled, the kubelet refuses to start by default. Swap breaks CPU/memory QoS guarantees that Kubernetes scheduling depends on.

---

# OOM Killer — What It Is and How to Control It

When the kernel runs out of memory and cannot reclaim more from cache/swap:

1. **OOM Killer activates** — invoked by the kernel memory allocator
2. **Scores every process** (0–1000): based on memory usage, runtime, process type
3. **Kills the highest-scoring process** (and its children)
4. Logs to kernel ring buffer: `dmesg` or `journalctl -k`

**OOM score calculation factors:**
- RSS / total RAM × 1000 = base score
- Each additional thread: +~30 points
- Long-running processes: lower score bonus
- Root processes: -30 points bonus
- `oom_score_adj` modifier: -1000 (immune) to +1000 (kill first)

```bash
# Monitor OOM score of any process
cat /proc/$(pidof nginx)/oom_score         # current calculated score (0-1000)
cat /proc/$(pidof nginx)/oom_score_adj     # current adjustment (-1000 to +1000)

# Protect a critical process (make immune to OOM killer)
echo -1000 > /proc/$(pidof sshd)/oom_score_adj     # -1000 = immune

# Make a disposable process more likely to die first
echo 1000 > /proc/$(pidof background-job)/oom_score_adj

# In a service unit (persistent across restarts):
# /etc/systemd/system/sshd.service
[Service]
OOMScoreAdjust=-1000

# Find OOM kill events
dmesg | grep -E "oom|killed|Out of memory"
journalctl -k | grep -iE "oom|killed"
journalctl -k --since "1 hour ago" | grep -i "oom\|killed process"
# Look for: "Out of memory: Kill process 1234 (myapp) score 800 or sacrifice child"
```

> ✅ Rule: In Kubernetes, configure `resources.requests` and `resources.limits` on every pod. Kubernetes uses these to set OOM score adjustments:
> - **Guaranteed QoS** (requests == limits): `oom_score_adj = -998` (nearly immune — killed last)
> - **Burstable QoS** (requests < limits): score based on memory ratio — killed before Guaranteed
> - **BestEffort QoS** (no requests/limits): `oom_score_adj = 1000` — killed FIRST
>
> Pods without resource limits are BestEffort — they die first in any OOM event.

---

# 🗂️ Disk and Storage

---

# Block Devices, Partitions, and Filesystems

```bash
# Discover block devices
lsblk                    # tree view: disk → partitions → mount points
lsblk -f                 # + filesystem type, UUID, mount point
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,UUID
fdisk -l                 # full partition table details (requires root)
parted -l                # parted's view (handles GPT better)
blkid                    # device UUIDs and filesystem types
blkid /dev/sdb1          # specific device

# Device naming conventions:
# /dev/sda       — 1st SCSI/SATA/USB disk
# /dev/sda1      — 1st partition of sda
# /dev/sda2      — 2nd partition of sda
# /dev/sdb       — 2nd SCSI/SATA disk
# /dev/nvme0n1   — 1st NVMe disk, namespace 1
# /dev/nvme0n1p1 — 1st partition of nvme0n1
# /dev/xvda      — Xen virtual disk (older AWS EC2)
# /dev/vda       — virtio virtual disk (KVM, newer AWS EC2)
# /dev/loop0     — loop device (disk image mounted as block device)
```

**Create, format, and mount a new disk:**
```bash
# Step 1: partition the disk
# Using fdisk (MBR/DOS partition tables):
fdisk /dev/sdb
# → n (new partition) → p (primary) → 1 (first) → Enter (default start) → +20G → w (write)

# Using parted (GPT — better for disks > 2TB or use with LVM):
parted /dev/sdb mklabel gpt
parted /dev/sdb mkpart primary ext4 0% 100%

# Step 2: format with a filesystem
mkfs.ext4 /dev/sdb1                       # ext4 — general purpose, journaled
mkfs.ext4 -L "appdata" /dev/sdb1          # with a label
mkfs.xfs /dev/sdb1                        # xfs — RHEL default, great for large files
mkfs.xfs -L "logs" /dev/sdb1
mkfs.ext4 -m 0 /dev/sdb1                  # 0% reserved space (not a root fs)

# Step 3: mount
mkdir -p /mnt/data
mount /dev/sdb1 /mnt/data                 # auto-detect filesystem
mount -t ext4 /dev/sdb1 /mnt/data         # explicit filesystem type
mount -o ro /dev/sdb1 /mnt/data           # read-only mount
umount /mnt/data                          # unmount
```

**/etc/fstab — persistent mounts (survive reboots):**
```bash
# Format: <device> <mountpoint> <fstype> <options> <dump> <pass>
UUID=abc-1234-def  /mnt/data   ext4    defaults,nofail   0   2
UUID=xyz-5678-ghi  /var/log    xfs     defaults,nofail   0   2
/dev/vg0/lv_app    /app        ext4    defaults           0   2
tmpfs              /tmp        tmpfs   defaults,size=2G   0   0

# Options explained:
# defaults    = rw, suid, dev, exec, auto, nouser, async
# nofail      = don't fail boot if this device is missing (external/cloud disks!)
# noatime     = don't update access time on reads (big performance win for busy dirs)
# nodiratime  = don't update directory access times
# pass 0      = no fsck
# pass 1      = fsck first (root filesystem only)
# pass 2      = fsck after root (other filesystems)

# Get UUID for a device
blkid /dev/sdb1
# → /dev/sdb1: UUID="abc-1234-def" TYPE="ext4"

# Test fstab entries without rebooting
mount -a              # mount all entries in fstab (errors surface immediately)
```

---

# LVM — Logical Volume Manager

LVM adds a flexible abstraction layer between physical disks and filesystems.

**Three layers:**
- **PV (Physical Volume)**: raw disk or partition marked for LVM use
- **VG (Volume Group)**: storage pool combining one or more PVs
- **LV (Logical Volume)**: virtual partition carved from a VG — what you format and mount

```bash
# Create LVM from scratch on two disks:
pvcreate /dev/sdb /dev/sdc                  # initialize disks as PVs
vgcreate vg_data /dev/sdb /dev/sdc          # create VG spanning both disks
lvcreate -L 50G -n lv_app vg_data           # create 50GB LV
lvcreate -L 20G -n lv_logs vg_data          # create 20GB LV
lvcreate -l 100%FREE -n lv_rest vg_data     # use all remaining space

mkfs.ext4 /dev/vg_data/lv_app              # format
mount /dev/vg_data/lv_app /app             # mount
# Device path: /dev/VGname/LVname  OR  /dev/mapper/VGname-LVname

# Inspect LVM state
pvs                      # physical volumes (concise)
pvdisplay /dev/sdb       # PV detail: size, PE (physical extent) count, VG it belongs to
vgs                      # volume groups
vgdisplay vg_data        # VG detail: total/free size, number of PVs/LVs
lvs                      # logical volumes
lvdisplay /dev/vg_data/lv_app   # LV detail: size, path, segments

# EXTEND an LV online — the killer feature of LVM:
lvextend -L +20G /dev/vg_data/lv_app        # grow LV by 20GB
resize2fs /dev/vg_data/lv_app               # grow ext4 fs to fill new LV size (live!)
# For xfs (can ONLY grow, not shrink):
xfs_growfs /app                             # grow xfs from the mount point

# SHRINK an LV (ext4 only — xfs cannot shrink):
umount /app
e2fsck -f /dev/vg_data/lv_app              # MUST check first
resize2fs /dev/vg_data/lv_app 30G          # shrink filesystem to 30G first
lvreduce -L 30G /dev/vg_data/lv_app        # then shrink LV (must be smaller than fs)
mount /dev/vg_data/lv_app /app

# Add a new disk to expand the VG:
pvcreate /dev/sdd
vgextend vg_data /dev/sdd                   # storage pool is now bigger
# Now you can grow existing LVs or create new ones

# Remove a disk from VG (move data off it first):
pvmove /dev/sdb                             # migrate all PEs from sdb to other PVs
vgreduce vg_data /dev/sdb                   # remove sdb from VG
pvremove /dev/sdb                           # clear PV metadata

# LVM snapshots (useful for backups)
lvcreate -L 5G -s -n lv_app_snap /dev/vg_data/lv_app   # create snapshot
mount -o ro /dev/vg_data/lv_app_snap /mnt/snap           # mount read-only for backup
lvremove /dev/vg_data/lv_app_snap                         # remove when done
```

> ✅ Rule: Always use LVM in production. When "disk full" alert fires at 3am: `lvextend -L +50G /dev/vg0/root && resize2fs /dev/vg0/root` — 30 seconds, zero downtime. Without LVM you're repartitioning live or rebooting into rescue mode.

---

# df, du — Disk Space Troubleshooting

```bash
# df — disk space by mounted filesystem
df -h                         # all filesystems, human readable
df -h /                       # specific mount point
df -h /var/log                # which filesystem /var/log is on and how full
df -i                         # inode usage (can be 100% even when space is available)
df -h --type=ext4             # only ext4 filesystems
df -h --exclude-type=tmpfs    # skip tmpfs entries
df -hT                        # include filesystem type column

# du — directory space usage
du -sh /var/log               # single summary for /var/log
du -sh /var/log/*             # summary for each item in /var/log
du -h --max-depth=1 /var      # one level deep from /var
du -ah /var/log | sort -rh | head -20    # top 20 largest files/dirs by size

# Find large files
find /var -size +100M -type f -exec ls -lh {} \;
find / -size +1G -type f 2>/dev/null
find /var/log -name "*.log" -size +500M

# Find recently modified large files
find / -type f -newer /tmp/ref_file -size +50M 2>/dev/null
```

**Disk full investigation procedure:**
```bash
# Step 1: Which filesystem is full?
df -h
# → /dev/sda1    50G   50G   0 100% /var

# Step 2: Find the space consumer
du -sh /var/*             # start at the top
du -sh /var/log/*         # drill down — logs are most common culprit
du -sh /var/lib/docker/   # Docker can consume huge amounts

# Step 3: Check for deleted files held open by processes
lsof | grep "(deleted)"   # files deleted from disk but still open by a process
# Space isn't freed until the process closes or is restarted
# Fix: identify the process, restart it (or send it SIGUSR1 to reopen logs)
lsof | grep deleted | awk '{print $2}' | sort -u   # just the PIDs

# Step 4: Check inode exhaustion (separate from disk space)
df -i
# → /dev/sda1    3.2M  3.2M    0  100% /var  ← inode 100% but space may be fine
# Find the directory with millions of tiny files:
find /var -xdev -printf '%h\n' | sort | uniq -c | sort -rn | head -10
# Common causes: PHP sessions, Postfix mail queue, thumbnail cache, npm cache

# Step 5: Check for large core dumps
find / -name "core" -o -name "core.*" -type f 2>/dev/null | xargs ls -lh
find / -name "*.hprof" 2>/dev/null    # Java heap dumps

# Rotate logs manually if logrotate didn't
logrotate -f /etc/logrotate.conf
```

---

# 🗂️ Networking

---

# Network Interfaces — ip Command (Replaces ifconfig)

```bash
# Show interfaces
ip addr show                    # all interfaces with IP addresses
ip addr show eth0               # specific interface
ip link show                    # link layer only (MAC, speed, UP/DOWN state)
ip -s link show eth0            # with RX/TX statistics
ip -br addr show                # brief/compact format: eth0 UP 192.168.1.5/24

# Bring interface up/down
ip link set eth0 up
ip link set eth0 down

# Configure IP (temporary — lost on reboot)
ip addr add 192.168.1.10/24 dev eth0
ip addr del 192.168.1.10/24 dev eth0
ip addr flush dev eth0          # remove all addresses from interface

# Routing table
ip route show                              # full routing table
ip route show table all                    # all tables
ip route add default via 192.168.1.1      # add default gateway
ip route add 10.0.0.0/8 via 10.1.1.1 dev eth0  # static route
ip route del 10.0.0.0/8                   # remove route
ip route get 8.8.8.8                      # which route/interface for this destination?

# ARP / Neighbor table
ip neigh show                   # ARP table (IP → MAC mappings)
ip neigh flush all              # flush ARP cache (force re-ARP)
ip neigh add 192.168.1.1 lladdr aa:bb:cc:dd:ee:ff dev eth0  # static ARP entry
```

**Reading `ip addr show eth0` output:**
```
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP
    link/ether 0a:1b:2c:3d:4e:5f brd ff:ff:ff:ff:ff:ff   ← MAC address
    inet 172.31.10.5/24 brd 172.31.10.255 scope global dynamic eth0
    │   │                │                │      │       │
    │   └─ IP/prefix     └─ broadcast     │      │       └─ interface name
    │                                     │      └─ dynamic = DHCP assigned
    │                                     └─ global = routable (vs link-local)
    inet6 fe80::81b:2cff:fe3d:4e5f/64 scope link   ← IPv6 link-local
```

**Persistent network configuration:**
```bash
# Ubuntu (Netplan — /etc/netplan/*.yaml)
cat /etc/netplan/00-installer-config.yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: true
    eth1:
      addresses: [10.0.0.5/24]
      routes:
        - to: 0.0.0.0/0
          via: 10.0.0.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]

netplan apply              # apply without reboot

# RHEL/CentOS (NetworkManager / /etc/sysconfig/network-scripts/)
nmcli device show eth0
nmcli connection modify eth0 ipv4.addresses 10.0.0.5/24
nmcli connection up eth0
```

---

# ss — Socket Statistics (Replaces netstat)

```bash
# Core flags:
# -t = TCP, -u = UDP, -l = listening only, -n = numeric (no DNS), -p = process
# -a = all sockets (listening + established), -e = extended info

ss -tlnp             # TCP listening sockets with process names
ss -tunap            # TCP+UDP, all, numeric, with process — the all-in-one view
ss -s                # socket statistics summary

# Filter examples
ss -tnp state established                    # only established connections
ss -tnp state listening                      # only listening
ss -tnp dport = :443                         # connections to remote port 443
ss -tnp sport = :80                          # connections from local port 80
ss -tnp dst 10.0.0.5                         # connections to specific remote IP
ss -tnp src 172.31.10.5                      # from specific local IP

# Find what's using a port
ss -tlnp | grep :8080
fuser 8080/tcp        # returns PID (install psmisc)
lsof -i :8080         # more detailed — shows user, PID, command

# Count connections by state
ss -tan | awk '{print $1}' | sort | uniq -c | sort -rn
# TIME_WAIT: normal for busy web servers — connections recently closed
# CLOSE_WAIT: server-side bug — server isn't closing connections (memory leak)
# SYN_RECV: possible SYN flood attack

# Show socket buffer sizes (memory tuning)
ss -tm

# Unix domain sockets (IPC between local processes)
ss -xlp              # Unix domain sockets with process

# Output of ss -tlnp explained:
# State   Recv-Q  Send-Q  Local Address:Port  Peer Address:Port  Process
# LISTEN       0     128        0.0.0.0:22          0.0.0.0:*    users:(("sshd",pid=1234))
```

> 💡 Takeaway: `netstat` is deprecated and not installed by default on modern distros. `ss` reads directly from the kernel (no proc filesystem overhead) and is significantly faster on systems with thousands of connections.

---

# iptables / nftables — Firewall Basics

**iptables structure:**

| Table | Chains | Purpose |
|---|---|---|
| filter | INPUT, OUTPUT, FORWARD | Accept/drop/reject packets |
| nat | PREROUTING, POSTROUTING, OUTPUT | Network address translation |
| mangle | All 5 chains | Packet modification (TTL, mark) |
| raw | PREROUTING, OUTPUT | Bypass connection tracking |

```bash
# View current rules
iptables -L -n -v --line-numbers         # filter table, verbose, with line numbers
iptables -t nat -L -n -v                 # NAT table
iptables -t nat -L PREROUTING -n -v     # specific chain

# Basic filter rules
iptables -A INPUT -i lo -j ACCEPT                              # allow loopback
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT  # allow return traffic
iptables -A INPUT -p tcp --dport 22 -j ACCEPT                 # allow SSH
iptables -A INPUT -p tcp --dport 80 -j ACCEPT                 # allow HTTP
iptables -A INPUT -p tcp --dport 443 -j ACCEPT                # allow HTTPS
iptables -A INPUT -j DROP                                      # drop everything else

# Set default policy (drop all incoming unless explicitly allowed)
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT       # typically allow all outgoing

# Delete a rule (by line number)
iptables -L INPUT --line-numbers
iptables -D INPUT 3             # delete rule 3 from INPUT chain

# Insert rule at specific position
iptables -I INPUT 1 -p tcp --dport 22 -j ACCEPT   # insert at top

# Rate limiting (anti-brute-force for SSH)
iptables -A INPUT -p tcp --dport 22 -m state --state NEW \
  -m recent --set --name SSH
iptables -A INPUT -p tcp --dport 22 -m state --state NEW \
  -m recent --update --seconds 60 --hitcount 4 --name SSH -j DROP

# Port forwarding via NAT
iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080
iptables -t nat -A PREROUTING -p tcp --dport 443 -j DNAT --to-destination 10.0.0.5:443

# IP masquerade (outbound NAT — internet sharing)
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Save/restore rules
iptables-save > /etc/iptables/rules.v4
iptables-restore < /etc/iptables/rules.v4
# Ubuntu: apt install iptables-persistent  → saves/restores automatically

# UFW — Ubuntu simplified frontend
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80,443/tcp
ufw allow from 10.0.0.0/8 to any port 5432   # postgres from internal only
ufw enable
ufw status verbose
ufw status numbered    # with rule numbers for deletion
ufw delete 3           # delete rule 3

# firewalld — RHEL/CentOS frontend
firewall-cmd --list-all                           # current zone and rules
firewall-cmd --add-port=8080/tcp --permanent     # open port permanently
firewall-cmd --add-service=https --permanent     # by service name
firewall-cmd --add-rich-rule='rule family=ipv4 source address=10.0.0.0/8 port port=5432 protocol=tcp accept' --permanent
firewall-cmd --reload                             # apply permanent rules
```

> ✅ Rule: In AWS/GCP/Azure, Security Groups (cloud firewalls) handle external traffic. Use iptables/ufw for host-level controls like restricting service-to-service communication on the same host. Don't fight both layers without documentation.

---

# DNS Resolution — How It Works on Linux

**Resolution order** — controlled by `/etc/nsswitch.conf`:
```
hosts: files dns mdns4_minimal [NOTFOUND=return]
# 1. files = /etc/hosts
# 2. dns = /etc/resolv.conf nameservers
# 3. mdns = multicast DNS (.local domains)
```

```bash
# /etc/hosts — takes precedence over DNS
127.0.0.1       localhost
::1             localhost
10.0.0.5        db.internal db postgres
10.0.0.10       app.internal api

# /etc/resolv.conf — DNS resolver configuration
nameserver 8.8.8.8
nameserver 8.8.4.4
search company.internal aws.internal    # search domains appended to short names
options ndots:5    # if hostname has fewer than 5 dots, try search domains first
options timeout:2  # 2 second timeout per server
options attempts:3 # try 3 times before failing
```

```bash
# DNS lookup tools
dig google.com                      # full DNS response with all sections
dig +short google.com               # just the IP addresses
dig google.com MX                   # mail exchange records
dig google.com NS                   # name server records
dig google.com TXT                  # TXT records (SPF, DKIM, etc.)
dig google.com @8.8.8.8             # query specific nameserver
dig google.com @8.8.8.8 +tcp        # force TCP (test large responses)
dig -x 8.8.8.8                      # reverse lookup (PTR record)
dig +trace google.com               # trace from root nameservers down (great for debugging)
dig +short google.com AAAA          # IPv6 address

nslookup google.com                 # simple lookup (interactive or one-shot)
nslookup -type=MX gmail.com 8.8.8.8 # query specific server, specific type

host google.com                     # concise: shows A, MX records
host -t NS google.com               # NS records only
host 8.8.8.8                        # reverse lookup

# systemd-resolved (modern Ubuntu)
resolvectl status                   # show nameservers per interface
resolvectl query google.com         # make a query through systemd-resolved
resolvectl flush-caches             # flush DNS cache

# Legacy cache flush
systemctl restart nscd              # name service cache daemon
service dnsmasq restart             # dnsmasq cache

# Debug resolution for a specific hostname
strace -e trace=network getent hosts google.com   # see exactly what syscalls are made
```

> ⚠️ Watch out: On Ubuntu with systemd-resolved, `/etc/resolv.conf` may be a symlink to `/run/systemd/resolve/stub-resolv.conf` pointing to `127.0.0.53` (the local stub resolver). If you see `127.0.0.53` in resolv.conf, DNS queries go to systemd-resolved first. Configure DNS via `resolvectl` or systemd network config — not by editing resolv.conf directly.

---

# 🗂️ Logs and Monitoring

---

# journalctl — Full Reference

systemd-journald collects logs from: all systemd services, the kernel (dmesg), the initramfs, and anything writing to /dev/log or the journal socket.

```bash
# Basic viewing
journalctl                          # all logs, oldest first (paged)
journalctl -r                       # reverse — newest first
journalctl -f                       # follow (like tail -f syslog)
journalctl -n 100                   # last 100 lines
journalctl -e                       # jump to end of log

# Filter by systemd unit (service)
journalctl -u nginx                 # all nginx service logs
journalctl -u nginx -f              # follow nginx logs
journalctl -u nginx -u sshd        # logs from multiple units
journalctl -u "app-*"              # wildcard unit name matching

# Filter by time
journalctl --since "2024-01-15 09:00:00"
journalctl --since "1 hour ago"
journalctl --since "yesterday"
journalctl --since today
journalctl --since "2024-01-15 09:00" --until "2024-01-15 12:00"
journalctl -u nginx --since today

# Filter by priority level
journalctl -p err                   # errors and higher (err, crit, alert, emerg)
journalctl -p warning               # warnings and higher
journalctl -p debug                 # all levels including debug
journalctl -p warning..err          # range: warning and error only
# Levels: 0=emerg 1=alert 2=crit 3=err 4=warning 5=notice 6=info 7=debug

# Kernel messages
journalctl -k                       # kernel messages only (replaces dmesg)
journalctl -k --since "boot"        # kernel messages since boot
journalctl -k | grep -i "error\|warn\|fail"

# Boot logs
journalctl -b                       # current boot
journalctl -b -1                    # previous boot (great for post-crash debug)
journalctl -b -2                    # two boots ago
journalctl --list-boots             # list all recorded boots with timestamps

# Output formats
journalctl -u nginx -o json         # JSON (one object per line)
journalctl -u nginx -o json-pretty  # pretty-printed JSON
journalctl -u nginx -o short-iso    # short format with ISO 8601 timestamps
journalctl -u nginx -o cat          # just the message, no metadata
journalctl -u nginx --no-pager      # no paging (pipe to grep/awk)

# Combining filters
journalctl -u nginx -p err --since "1 hour ago" --no-pager | grep "upstream"

# Disk space management
journalctl --disk-usage                       # total journal size on disk
journalctl --vacuum-size=500M                 # trim to 500MB (removes oldest)
journalctl --vacuum-time=30d                  # remove entries older than 30 days
journalctl --vacuum-files=5                   # keep only 5 journal files

# Configuration: /etc/systemd/journald.conf
# SystemMaxUse=500M     → max disk space for persistent logs
# RuntimeMaxUse=200M    → max for /run/log/journal (volatile)
```

**Traditional /var/log files** (still used by apps that don't use journald):
```
/var/log/syslog          — general system log (Debian/Ubuntu)
/var/log/messages        — general system log (RHEL/CentOS)
/var/log/auth.log        — authentication, sudo, SSH (Debian/Ubuntu)
/var/log/secure          — authentication log (RHEL/CentOS)
/var/log/kern.log        — kernel messages only
/var/log/dmesg           — kernel ring buffer from last boot
/var/log/cron            — cron job execution log
/var/log/apt/            — apt install/remove/upgrade history
/var/log/nginx/          — access.log, error.log
/var/log/mysql/          — MySQL error log
/var/log/postgresql/     — PostgreSQL logs
```

```bash
# logrotate — rotating traditional log files
cat /etc/logrotate.d/nginx
# /var/log/nginx/*.log {
#     daily
#     missingok
#     rotate 14
#     compress
#     delaycompress
#     notifempty
#     create 0640 www-data adm
#     sharedscripts
#     postrotate
#         nginx -s reopen   # tell nginx to reopen log files after rotation
#     endscript
# }

logrotate -f /etc/logrotate.conf    # force rotation now (testing)
logrotate -d /etc/logrotate.d/nginx # dry run — show what would happen
```

---

# Performance Monitoring — vmstat, iostat, sar

**vmstat — virtual memory, CPU, I/O summary:**
```bash
vmstat 2 10          # print every 2 seconds, 10 times
vmstat -S M 2        # in MB instead of KB

# Output columns:
# procs:    r=runnable (on CPU or waiting)  b=blocked (in D state, waiting for I/O)
# memory:   swpd=swap used  free=free RAM  buff=buffer cache  cache=page cache
# swap:     si=swap-in KB/s  so=swap-out KB/s  (NON-ZERO = MEMORY PRESSURE)
# io:       bi=blocks-in/s (disk reads)  bo=blocks-out/s (disk writes)
# system:   in=interrupts/s  cs=context-switches/s (high cs = many short tasks)
# cpu:      us=user  sy=system  id=idle  wa=iowait  st=stolen (by hypervisor)

# Diagnosing:
# r > num_cpus = CPU saturation (queue of runnable processes)
# b > 0        = processes stuck waiting on I/O or kernel locks
# so > 0       = actively swapping out — real memory pressure
# wa > 10-20%  = I/O bottleneck
# st > 1%      = hypervisor is throttling this VM (noisy neighbor)
```

**iostat — block device I/O statistics:**
```bash
iostat -x 2 5        # extended stats, every 2 seconds, 5 times
iostat -x -d sda 2   # specific device
iostat -hx 2         # human-readable extended

# Key columns in extended output (-x):
# r/s        — reads per second
# w/s        — writes per second
# rkB/s      — KB read per second
# wkB/s      — KB written per second
# await      — average time for I/O request to complete (ms): service + queue
# r_await    — average read wait time (ms)
# w_await    — average write wait time (ms)
# aqu-sz     — average queue length (requests waiting) — >1 = disk is saturated
# %util      — % time device was busy (100% = saturated, can be misleading on SSDs)

# Interpreting:
# HDD normal await: < 10ms
# SSD normal await: < 1ms
# %util 100% on SSD doesn't mean saturated — SSDs can parallelize internally
# High await + high aqu-sz = device is truly overloaded
```

**sar — system activity reporter (historical):**
```bash
# sar requires sysstat package: apt install sysstat / dnf install sysstat
# Collects data every 10 minutes via cron, stores in /var/log/sa/

sar 1 5              # CPU utilization, 5 samples every 1s (live)
sar -r 1 5           # memory utilization
sar -b 1 5           # I/O and transfer rates
sar -n DEV 1 5       # network interface statistics
sar -q 1 5           # queue length (load average)
sar -d 1 5           # block device I/O rates

# Historical data — reviewing what happened earlier
sar -u             # today's CPU stats from saved data
sar -u -f /var/log/sa/sa20    # CPU stats from the 20th of the month
sar -r -s 09:00:00 -e 12:00:00  # memory between 9am and noon today
sar -b -f /var/log/sa/sa19    # I/O stats from yesterday (the 19th)
```

**Performance troubleshooting decision tree:**
```
Is the system slow?
│
├── Check: uptime  →  load average > num_CPUs?
│   └── YES: CPU or I/O saturated  →  top (check %wa vs %us/%sy)
│       ├── High %wa (iowait):     → iostat -x  → which disk? what process?
│       │                            iotop -o   → which process?
│       └── High %us/%sy (CPU):   → top (P key) → which process?
│
├── Check: free -h  →  swap in use?
│   └── YES: vmstat 1  →  si/so non-zero = actively swapping
│       → Check MemAvailable, find memory leak (top M key)
│       → Check OOM logs: dmesg | grep -i oom
│
├── Check: ss -s  →  unusual socket counts?
│   ├── Many CLOSE_WAIT:  server not closing connections → app bug
│   ├── Many TIME_WAIT:   normal for busy server, but tune tcp_tw_reuse if needed
│   └── Many SYN_RECV:    possible SYN flood → check for attack
│
└── Check: journalctl -p err --since "1 hour ago"  →  errors?
```

---

# 🗂️ SSH and Security

---

# SSH Agent, Forwarding, and ProxyJump

```bash
# Start the SSH agent and load its env vars into your shell
eval $(ssh-agent -s)
# → Agent pid 12345

# Add your private key (prompts for passphrase once)
ssh-add ~/.ssh/id_ed25519          # add specific key
ssh-add -l                          # list loaded keys and their fingerprints
ssh-add -L                          # show public keys of loaded identities
ssh-add -D                          # remove all loaded keys from agent
ssh-add -t 3600 ~/.ssh/id_ed25519  # add key, expire from agent in 1 hour

# Connect — agent provides the key automatically
ssh user@server

# ProxyJump — tunnel SSH through a bastion host
# One-liner:
ssh -J ec2-user@bastion.company.com ubuntu@10.0.1.50

# Multiple hops:
ssh -J ec2-user@bastion,admin@jumphost ubuntu@10.0.1.50

# ~/.ssh/config — cleaner than command-line flags
Host bastion
    HostName bastion.company.com
    User ec2-user
    IdentityFile ~/.ssh/prod-key.pem

Host private-db
    HostName 10.0.2.25
    User ubuntu
    ProxyJump bastion
    IdentityFile ~/.ssh/prod-key.pem

Host *.internal
    User ubuntu
    ProxyJump bastion
    IdentityFile ~/.ssh/prod-key.pem

# Now: ssh private-db   — automatically proxies through bastion

# SCP through ProxyJump
scp -J ec2-user@bastion ubuntu@10.0.1.50:/var/log/app.log ./

# Port forwarding through SSH tunnel
ssh -L 5432:db.internal:5432 ec2-user@bastion   # forward local 5432 to db through bastion
ssh -L 8080:localhost:80 ubuntu@10.0.1.50        # forward local 8080 to remote's port 80
ssh -R 2222:localhost:22 user@public-server      # reverse tunnel (expose local SSH publicly)
ssh -D 1080 ec2-user@bastion                     # SOCKS proxy through bastion
```

**Agent Forwarding vs ProxyJump:**
| | ProxyJump | Agent Forwarding (-A) |
|---|---|---|
| How it works | Direct encrypted tunnel from client through bastion to target | Your agent socket is forwarded to bastion |
| Key exposure | Private key never leaves your machine | Key accessible on bastion via agent socket |
| Security | Preferred — zero key exposure on bastion | Risk: root on bastion can steal your agent |
| When to use | Default choice for bastion/jump hosts | Only when target needs to SSH further and ProxyJump can't chain |

> ✅ Rule: Use `ProxyJump` for bastion hosts. Never use `ForwardAgent yes` for production jumphosts. If an attacker or insider compromises the bastion, agent forwarding exposes all your loaded private keys.

---

# SSH Hardening — sshd_config Best Practices

```bash
# /etc/ssh/sshd_config — the authoritative SSH daemon config

# AUTHENTICATION
PermitRootLogin no                    # never allow direct root login
PasswordAuthentication no             # key-based auth only
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys .ssh/authorized_keys2

# If you need password auth (avoid), at least:
# MaxAuthTries 3                      # lock after 3 failures
# PermitEmptyPasswords no             # no empty passwords ever

# USER/GROUP RESTRICTIONS (whitelist approach)
AllowUsers deployer alice bob         # ONLY these users can SSH (everyone else denied)
AllowGroups ssh-users                 # alternatively: must be in this group
# DenyUsers baduser                   # blacklist specific users
# Note: AllowUsers takes precedence over AllowGroups if both set

# SESSION SECURITY
LoginGraceTime 30                     # disconnect if not authenticated in 30 seconds
MaxSessions 10                        # max simultaneous sessions per connection
MaxStartups 10:30:60                  # rate-limit connections: start throttle/drop behavior

# KEEPALIVE (detect dead connections)
ClientAliveInterval 300               # send keepalive every 5 minutes
ClientAliveCountMax 2                 # disconnect after 2 missed keepalives (10 min total)

# DISABLE RISKY FEATURES
X11Forwarding no                      # no GUI forwarding (attack surface)
AllowTcpForwarding no                 # disable port forwarding (unless needed)
AllowAgentForwarding no               # disable agent forwarding (unless needed)
PermitTunnel no                       # disable tun/tap VPN mode
GatewayPorts no                       # prevent reverse tunnel exposure

# CRYPTOGRAPHY (restrict to modern algorithms)
Protocol 2                            # SSHv1 is broken — v2 only
Ciphers aes256-gcm@openssh.com,chacha20-poly1305@openssh.com,aes128-gcm@openssh.com
MACs hmac-sha2-512,hmac-sha2-256
KexAlgorithms curve25519-sha256,diffie-hellman-group16-sha512

# SFTP
Subsystem sftp internal-sftp          # use built-in SFTP instead of sftp-server

# Chroot specific users to SFTP only (file upload accounts):
Match User sftpuser
    ForceCommand internal-sftp
    ChrootDirectory /srv/sftp/%u
    AllowTcpForwarding no
    X11Forwarding no
```

```bash
# Workflow for safe config changes:
sshd -t                    # validate sshd_config BEFORE applying (catches syntax errors)
sshd -T | grep -i "allow\|permit\|password"   # show effective config
systemctl reload sshd      # reload config without dropping existing sessions
# (systemctl restart drops all sessions — only for major changes)

# Authorized keys management
cat ~/.ssh/authorized_keys
# ssh-ed25519 AAAA... alice@laptop
# ssh-rsa AAAA... deploy-key
# Options prefix: no-port-forwarding,no-x11-forwarding,command="backup.sh" ssh-rsa ...
# ↑ Restrict what this specific key can do
```

> ⚠️ Watch out: When applying SSH hardening, always keep your current session open. In a second terminal, test that you can still connect with the new config before closing the first session. One syntax error can lock you out if you close the session first.

---

# 🗂️ Package Management

---

# apt — Debian/Ubuntu Package Management

```bash
# INDEX MANAGEMENT — always update before installing
apt update                         # refresh package index from repositories
apt upgrade                        # upgrade all installed packages (safe — no removals)
apt full-upgrade                   # upgrade + handle dependency removals/installs
apt dist-upgrade                   # same as full-upgrade (older alias)
apt autoremove                     # remove packages no longer needed (auto-deps)
apt autoclean                      # remove old downloaded package files from cache
apt clean                          # remove all cached .deb files (frees space)

# PACKAGE OPERATIONS
apt install nginx                          # install latest version
apt install nginx=1.18.0-0ubuntu1          # install specific version
apt install ./local-package.deb            # install from local .deb file
apt install -y nginx                       # non-interactive (yes to all prompts)
apt install --no-install-recommends nginx  # skip recommended optional packages
apt remove nginx                           # remove binary (keep config files)
apt purge nginx                            # remove binary + all config files
apt reinstall nginx                        # reinstall without removing

# INFORMATION AND SEARCH
apt search nginx                   # search package names and descriptions
apt show nginx                     # detailed package info (version, deps, size)
apt list --installed               # all installed packages
apt list --installed | grep nginx  # is nginx installed?
apt list --upgradable              # packages with available upgrades
apt-cache policy nginx             # show installed version vs available versions + repo priority
apt-cache depends nginx            # show package dependencies
apt-cache rdepends nginx           # show what depends on nginx

# HOLD — pin a package at current version (prevent upgrades)
apt-mark hold nginx                # hold nginx at current version
apt-mark unhold nginx              # release hold
apt-mark showhold                  # list held packages

# REPOSITORY MANAGEMENT
cat /etc/apt/sources.list          # main repo list
ls /etc/apt/sources.list.d/        # additional repos (PPAs, third-party)
# Add PPA:
add-apt-repository ppa:deadsnakes/python3.12
# Add third-party repo:
curl -fsSL https://example.com/gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/example.gpg
echo "deb https://example.com/repo stable main" > /etc/apt/sources.list.d/example.list
apt update
```

```bash
# dpkg — low-level package management
dpkg -l nginx                      # installed? version? (ii=installed, rc=removed but config)
dpkg -l | grep "^ii" | wc -l      # count installed packages
dpkg -L nginx                      # list all files installed by nginx package
dpkg -S /usr/sbin/nginx            # which package owns this file?
dpkg -i package.deb                # install .deb directly (no dependency resolution)
dpkg -r nginx                      # remove nginx (keep config)
dpkg -P nginx                      # purge nginx (remove config too)
dpkg --configure -a                # reconfigure any half-installed packages
dpkg --get-selections              # list all packages with their status

# Fix broken packages
apt --fix-broken install           # resolve dependency issues
dpkg --configure -a                # complete interrupted package installs
apt install -f                     # same as --fix-broken
```

---

# yum/dnf — RHEL/CentOS/Fedora Package Management

```bash
# dnf is the modern replacement for yum (faster, better deps, Python 3)
# yum syntax is identical for most commands — this covers dnf

# UPDATE
dnf check-update                   # list available updates without installing
dnf update                         # update all packages
dnf update nginx                   # update specific package
dnf update --security              # install security updates only

# INSTALL AND REMOVE
dnf install nginx                  # install
dnf install nginx-1.20.1           # specific version
dnf install /path/to/package.rpm   # from local file
dnf install -y nginx               # non-interactive
dnf remove nginx                   # remove package
dnf autoremove                     # remove unused dependencies

# SEARCH AND INFORMATION
dnf search nginx                   # search package name and summary
dnf search all "web server"        # search in all fields including description
dnf info nginx                     # detailed package information
dnf list installed                 # all installed packages
dnf list available                 # all available (not installed)
dnf list all                       # installed + available
dnf provides /usr/sbin/nginx       # which package owns this file?
dnf provides "*/nginx"             # which packages include 'nginx' in path?
dnf repolist                       # show enabled repositories
dnf repolist all                   # enabled + disabled repos

# HISTORY — yum/dnf transaction history
dnf history                        # list all transactions with IDs
dnf history info 5                 # details of transaction #5
dnf history undo 5                 # undo transaction #5 (rollback!)
dnf history rollback 5             # rollback to state before transaction 5

# GROUP MANAGEMENT
dnf group list                     # list available package groups
dnf group install "Development Tools"   # install a group
dnf group info "Development Tools"      # what's in this group?

# MODULE STREAMS (RHEL 8+/CentOS Stream)
dnf module list                    # show all modules and streams
dnf module enable nodejs:18        # enable nodejs 18 stream
dnf module install nodejs:18/default

# REPOSITORY MANAGEMENT
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf config-manager --enable epel   # enable a disabled repo
dnf config-manager --disable epel  # disable without removing
dnf install epel-release           # EPEL for RHEL/CentOS (Extra Packages)

# HOLD packages from updates
dnf versionlock add nginx          # pin nginx version (needs versionlock plugin)
dnf versionlock list
dnf versionlock delete nginx
```

```bash
# rpm — low-level package management
rpm -qa                            # list all installed packages
rpm -qa | grep nginx               # is nginx installed?
rpm -ql nginx                      # list files in installed nginx package
rpm -qi nginx                      # package info (version, description, vendor)
rpm -qf /usr/sbin/nginx            # which package owns this file?
rpm -qR nginx                      # show dependencies required by nginx
rpm -ivh package.rpm               # install: verbose + hash progress bar
rpm -Uvh package.rpm               # upgrade (or install if not present)
rpm -evh nginx                     # erase/uninstall nginx (verbose)
rpm -V nginx                       # verify: check installed files against package DB
rpm --import /path/to/gpg-key      # import GPG key for package verification
```

---

# 🗂️ Interview Q&A

---

# Q&A — Process and Memory

**Q: What is a zombie process and how do you get rid of it?**

A zombie process has finished execution but still has an entry in the process table because its parent hasn't called `wait()` to read its exit status. A zombie consumes only a PID slot — no CPU or memory. You **cannot** kill a zombie with SIGKILL because it's already dead.

Solutions:
1. Send `SIGCHLD` to the parent — this signals it to call `wait()` and reap the zombie
2. Kill the parent — orphaned zombie is immediately adopted by PID 1 (systemd) which reaps it
3. If parent is stuck and unkillable: reboot

Finding zombies: `ps aux | grep Z` or `ps aux | awk '$8=="Z"'`

> ✅ Rule: A few zombies are normal (brief reaping delay). Hundreds of zombies = parent has a bug where it never calls wait(). This eventually exhausts the PID namespace — no new processes can be created.

---

**Q: What is the difference between SIGKILL and SIGTERM?**

`SIGTERM` (15) is a polite request to terminate — the process **can catch it**, run cleanup handlers (flush write buffers, close database connections, release locks, remove temp files), and exit gracefully. Well-written services handle SIGTERM by finishing in-progress requests before shutting down.

`SIGKILL` (9) is a kernel-level forced termination — it **cannot be caught, blocked, or ignored**. The kernel immediately removes the process. No cleanup occurs: open files may be left in inconsistent states, temp files remain, database transactions may be incomplete.

> ✅ Rule: Always try SIGTERM first. Wait at least 5–30 seconds (depending on the service). Only send SIGKILL if the process refuses to exit. `kill PID` sends SIGTERM by default.

---

**Q: A process is stuck in D state and can't be killed. What do you do?**

`D` (uninterruptible sleep) means the process is blocked in the kernel waiting for I/O — typically NFS timeout, hung storage driver, or slow disk. `SIGKILL` **cannot interrupt a D-state process** — the process is in kernel space and signal delivery happens only in user space.

Diagnosis:
```bash
cat /proc/<pid>/wchan        # what kernel function the process is waiting in
dmesg | tail -50             # look for device errors, NFS timeouts, disk errors
strace -p <pid>              # sometimes works — shows which syscall is blocked
```

Options:
1. Fix the underlying cause (bring NFS server back, fix disk, unmount hung filesystem)
2. If it's an NFS mount: `umount -f -l /mnt/nfs` (forced + lazy unmount)
3. If truly unrecoverable: **reboot** — it's the only reliable fix for a stuck kernel wait

---

**Q: What does MemAvailable mean vs MemFree in /proc/meminfo?**

`MemFree` is RAM that is completely unused and in no use at all.

`MemAvailable` is the kernel's **estimate** of how much memory can be made available to new processes without swapping — it includes MemFree plus reclaimable page cache (disk read cache) and reclaimable kernel slab caches.

Linux deliberately fills free RAM with disk cache because free RAM is wasted RAM. `MemAvailable` accounts for this by including cache that the kernel can evict on demand. It's the number to alert on.

> 💡 Takeaway: If `MemFree` is 100MB but `MemAvailable` is 8GB, the system has plenty of RAM — it's just being used as a disk cache buffer which will be released when needed.

---

# Q&A — Disk and Filesystem

**Q: Disk space says 100% but `du -sh /` shows much less. Why?**

**Deleted files held open by processes.** When a process opens a file and you `rm` it, the directory entry is removed (file is "deleted" from the namespace) but the **inode** and its disk blocks remain allocated until every open file descriptor is closed. `df` reports disk blocks in use including these "deleted but open" files. `du` walks directory entries — it doesn't see files with no directory entry.

```bash
lsof | grep "(deleted)"    # find deleted files still held open
lsof | grep deleted | awk '{print $2, $8, $NF}'   # PID, size, filename
```

Fix: Restart the process that has the file open (common cause: log file held by app after logrotate). Or send SIGUSR1 if the app supports reopen-on-signal.

---

**Q: What is the difference between a hard link and a symbolic link?**

**Hard link**: a directory entry pointing to the same inode as another file. Both names are equals — neither is "the original." The file's data is freed only when **all** hard links are deleted. Hard links cannot cross filesystem boundaries and cannot point to directories.

**Symbolic link**: a separate file (new inode) whose content is the pathname to the target. It's a reference to a **name**, not an inode. Deleting the original file leaves a broken (dangling) symlink. Symlinks can cross filesystems and point to directories.

```bash
ln /etc/hosts /tmp/hosts-hard       # hard link — same inode
ln -s /etc/hosts /tmp/hosts-soft    # symlink — new inode, stores path
stat /etc/hosts /tmp/hosts-hard     # same inode number
stat /tmp/hosts-soft                # different inode, "File: -> /etc/hosts"
```

---

**Q: df shows inode usage at 100% but disk space is fine. What now?**

Inode exhaustion means the filesystem cannot create new files even though disk space is available. Each inode represents one file — inodes are allocated at filesystem creation time.

Cause: millions of tiny files — PHP session files, Postfix mail queue, thumbnail caches, small temp files in an app.

```bash
# Find where the inodes are
df -i                          # which filesystem is at 100% inodes?
find / -xdev -printf '%h\n' | sort | uniq -c | sort -rn | head -20
# ↑ shows directories with the most files
find /tmp -type f | wc -l      # count files in /tmp
```

Fix: delete the small files (PHP: `find /var/lib/php/sessions -type f -delete`).
Long-term fix: tune inode density at format time: `mkfs.ext4 -i 4096 /dev/sdb1` (1 inode per 4096 bytes instead of default 16384).

---

**Q: How does LVM help in production? Give a real scenario.**

3am: monitoring alerts that the root filesystem is at 98% full. Application logs are filling it.

**Without LVM**: You must take the server offline, boot into rescue mode, repartition (dangerous, time-consuming), or attach a new disk and move data manually. Downtime: hours.

**With LVM**:
```bash
# Add a new disk to the VG if needed:
pvcreate /dev/sdd
vgextend vg0 /dev/sdd

# Extend the logical volume and resize filesystem:
lvextend -L +50G /dev/vg0/root
resize2fs /dev/vg0/root         # ext4: live, no unmount needed
```

Total time: 45 seconds. Zero downtime. The application never sees a hiccup.

> ✅ Rule: Always use LVM for root and data volumes in production. Cloud VMs: attach an additional EBS/disk, add as PV to existing VG, extend LV online.

---

# Q&A — Networking

**Q: How do you check which process is listening on port 8080?**

```bash
ss -tlnp | grep :8080
# LISTEN  0  128  0.0.0.0:8080  0.0.0.0:*  users:(("java",pid=1234,fd=7))

lsof -i :8080
# COMMAND  PID   USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
# java    1234 ubuntu   7u  IPv4  12345      0t0  TCP *:8080 (LISTEN)

fuser 8080/tcp
# 8080/tcp: 1234

# Get the full command for PID 1234:
cat /proc/1234/cmdline | tr '\0' ' '
# or:
ps -p 1234 -o cmd
```

---

**Q: What is the difference between `curl` and `wget`?**

Both fetch content over HTTP/HTTPS/FTP but serve different purposes.

`curl` is designed for **data transfer in scripts and APIs**: supports 25+ protocols, can send POST bodies, set request headers, follow redirects, handle cookies, do OAuth, show timing breakdowns. Output goes to stdout by default. Used in DevOps for API calls, health checks, and debugging.

`wget` is designed for **downloading files**: better at recursive downloads (mirroring websites), resuming interrupted downloads (`-c`), downloading in the background. Output saved to files by default.

```bash
curl -H "Authorization: Bearer token" -X POST -d '{"key":"val"}' https://api.example.com/endpoint
curl -o /tmp/file https://example.com/file.tar.gz
curl -w "%{http_code} %{time_total}\n" -s -o /dev/null https://healthcheck.example.com

wget -c https://example.com/large-file.iso     # resume partial download
wget -r -np https://example.com/docs/          # recursive download
```

---

**Q: traceroute shows `* * *` for some hops. What does that mean?**

The router at that hop is **not sending back ICMP "Time Exceeded"** messages — usually because its outbound ICMP is blocked by a firewall policy or rate-limited. The packets are still being forwarded (the hop is traversed), you just can't see it.

`* * *` does NOT mean packets are being dropped there. If the final destination responds, all intermediate hops are working fine. `* * *` only on some middle hops is cosmetic — the network is likely fine.

> 💡 Takeaway: Use `traceroute -T -p 80` (TCP mode on port 80) instead of default UDP when ICMP is filtered — TCP traceroute often gets through corporate firewalls better.

---

**Q: ping succeeds but curl to the same host fails. What's wrong?**

ping uses **ICMP** — often allowed through firewalls separately from TCP. `curl` uses TCP and a specific port. The host is reachable at network layer (L3) but:

1. The service on that port is not running
2. The host's firewall (iptables/ufw/Security Group) blocks that port
3. The service is listening on `127.0.0.1` only (not `0.0.0.0`)
4. The application crashed

```bash
# On the target server:
ss -tlnp | grep :80          # is something listening on port 80?
systemctl status nginx       # is the service running?
# If listening on 127.0.0.1:80 only → service is local-only
# If 0.0.0.0:80 → check firewall

# On the client:
curl -v http://server:80     # verbose — shows connection attempt and failure reason
telnet server 80             # test raw TCP connection
nc -zv server 80             # netcat: test connectivity to port
```

---

# Q&A — Users, Permissions, and SSH

**Q: How does sudo work internally?**

`sudo` is a **SUID root binary** — it always runs as root. When you execute `sudo command`:

1. sudo reads `/etc/sudoers` (and `/etc/sudoers.d/`) to check if this user is allowed to run this command as the requested user
2. Authenticates the caller via PAM (usually prompts for their own password, not root's)
3. Sets up the new process environment (optionally reset or preserved based on config)
4. forks and execs the requested command as the target user (root by default)
5. Logs the event to `/var/log/auth.log` or journald: who ran what as whom

This is why `sudo -l` shows what you can run, and why `sudo -u postgres psql` lets you run as the postgres user.

---

**Q: What is SUID and why is it a security risk?**

SUID (Set User ID) causes an **executable to run with the file owner's privileges** instead of the calling user's. `passwd` is SUID root — so any user can execute it and it gets root powers to write `/etc/shadow`.

Security risk: if an SUID root program has a vulnerability (buffer overflow, format string bug, command injection), an attacker can use that vulnerability to execute arbitrary code as root — instant privilege escalation.

```bash
# Audit all SUID files
find / -perm /4000 -type f 2>/dev/null | sort
# Expected: /usr/bin/passwd, /usr/bin/sudo, /usr/bin/newgrp, /bin/su
# Unexpected: /tmp/suid_shell, /home/alice/backdoor ← CRITICAL finding
```

> ✅ Rule: Run this audit regularly and compare against a known-good baseline. Any new SUID file that wasn't there before is a potential rootkit or misconfiguration.

---

**Q: How does SSH public key authentication work step by step?**

1. Client sends its public key to the server as an authentication offer
2. Server checks if this public key is in `~/.ssh/authorized_keys` for the target user
3. Server generates a **random challenge** (a nonce), encrypts it with the client's public key
4. Server sends the encrypted challenge to the client
5. Client decrypts the challenge using its **private key** (which never leaves the client)
6. Client combines the decrypted challenge with the session ID, hashes it, and sends back a signature
7. Server verifies the signature using the public key — authentication succeeds

The private key is never transmitted. Even if every packet of the handshake is captured by an attacker, they cannot authenticate without the private key.

---

**Q: A user can't SSH even though their key is in authorized_keys. What do you check?**

Checklist (in order):
```bash
# 1. File permissions — sshd is VERY strict about this
stat /home/alice               # home dir must NOT be group/world writable
stat /home/alice/.ssh          # must be 700 (drwx------)
stat /home/alice/.ssh/authorized_keys   # must be 600 (-rw-------)

ls -ld /home/alice             # drwxr-xr-x is fine, drwxrwxr-x is rejected
ls -la /home/alice/.ssh/

# 2. Check sshd config allows pubkey auth
sshd -T | grep -i "pubkeyauth\|allowusers\|denyusers"

# 3. Check the sshd logs — they say exactly what failed
journalctl -u sshd -n 50
tail -50 /var/log/auth.log
# Look for: "Authentication refused: bad ownership or modes for directory /home/alice"
#           "Permission denied (publickey)"

# 4. Test from client side with verbose output
ssh -vvv alice@server 2>&1 | grep -E "offer|sent|accept|refuse|fail"

# 5. Check authorized_keys format — one key per line, no line breaks
cat /home/alice/.ssh/authorized_keys
# Should be: ssh-ed25519 AAAA... user@host
# Common error: pasted key wrapped across multiple lines

# 6. SELinux (RHEL) context
ls -Z /home/alice/.ssh/authorized_keys
restorecon -R -v /home/alice/.ssh/   # fix SELinux context
```

---

# Q&A — systemd and Boot

**Q: What is systemd and what problem did it solve?**

**SysVinit** (the predecessor) started services **sequentially** via shell scripts in `/etc/init.d/`. Problems: slow boot (no parallelism), no dependency tracking (scripts ran in fixed order), no crash recovery, complex shell scripts to maintain, and separate tools for logging (syslog), scheduling (cron), and device management (udev).

**systemd** solved this by:
- **Parallel startup**: services start simultaneously as soon as dependencies are met
- **Declarative units**: simple `[Service]`, `[Timer]`, `[Socket]` files instead of shell scripts
- **Dependency management**: `After=`, `Requires=`, `Wants=` in unit files
- **Auto-restart**: `Restart=always` in a service unit
- **Integrated logging**: journald captures all stdout/stderr automatically
- **Socket activation**: start services on-demand when a connection arrives
- **cgroups integration**: resource limits per service, and process tracking (no escaping the cgroup)
- **Unified tooling**: `systemctl` replaces service, chkconfig, update-rc.d

---

**Q: A service keeps crashing and restarting. How do you diagnose?**

```bash
# Step 1: Current state
systemctl status myservice
# Shows: Active state, last exit code, last few log lines

# Step 2: Full recent logs
journalctl -u myservice -n 100 --no-pager
journalctl -u myservice --since "10 min ago"

# Step 3: Stop the crash loop so you can investigate
systemctl stop myservice

# Step 4: Look for crash pattern
journalctl -u myservice -p err --since today

# Step 5: Check restart policy and rate limits
systemctl show myservice | grep -E "Restart|StartLimit"
# StartLimitBurst=5 StartLimitIntervalSec=10 → allows 5 restarts in 10 seconds
# After hitting limit: systemd stops restarting → service stays "failed"
# Fix crash loop limit exhaustion:
systemctl reset-failed myservice    # reset failure counter
systemctl start myservice

# Step 6: Run the service manually to see the error directly
sudo -u serviceuser /usr/bin/myservice --config /etc/myservice.conf
# Now you see the actual error without systemd wrapping it
```

---

**Q: What happens when you run `systemctl daemon-reload`?**

systemd caches unit file content in memory for performance. `daemon-reload` tells systemd to **re-read all unit files** from disk:
- `/etc/systemd/system/`
- `/lib/systemd/system/`
- `/run/systemd/system/`

It does **NOT** restart any running services. Running services continue with the old configuration until explicitly restarted. It does re-evaluate dependencies and may start/stop units that are affected by dependency changes.

Required after: creating a new unit file, modifying an existing unit file, changing a `[Unit]`, `[Install]`, or `[Service]` section.

Workflow:
```bash
# Edit unit file
vim /etc/systemd/system/myapp.service

# Tell systemd to re-read the change
systemctl daemon-reload

# Apply the new config to the running service
systemctl restart myapp

# Enable so it starts on boot
systemctl enable myapp
```

---

# Q&A — Performance and Troubleshooting

**Q: Server is slow. Walk me through your investigation.**

```bash
# 1. Gauge severity: load average vs CPU count
uptime
# load: 12.5, 11.2, 9.8 on an 8-core server → CPU is saturated (>1.0 per core)
nproc            # how many cores?

# 2. What kind of pressure? CPU or I/O?
top              # look at %wa (iowait) and %us/%sy
# High %wa (>10%): I/O bottleneck
# High %us: application CPU usage
# High %sy: kernel CPU (many syscalls, maybe NFS or network I/O)

# 3. If I/O bottleneck:
iostat -x 2      # which device? check %util and await
iotop -o         # which process is doing the I/O?

# 4. Memory pressure?
free -h          # is swap being used?
vmstat 1 5       # si/so columns: swap in/out per second
# Non-zero si/so = actively swapping = serious problem

# 5. Which process is the culprit?
top              # press P (sort by CPU) or M (sort by memory)
ps aux --sort=-pcpu | head -10   # top CPU consumers
ps aux --sort=-rss | head -10    # top memory consumers

# 6. What is that process actually doing?
strace -p <pid> -c    # summary of syscalls (10 seconds, then Ctrl+C)
lsof -p <pid>         # what files/sockets does it have open?

# 7. Network?
ss -s             # socket summary: many CLOSE_WAIT or TIME_WAIT?
ip -s link show eth0   # packet drops? errors?
sar -n DEV 1 5    # network throughput per interface

# 8. Recent changes?
journalctl -p err --since "2 hours ago"    # any errors around when slowness started?
last -20          # did anyone log in recently?
rpm -qa --last | head -10    # recently installed packages (RHEL)
dpkg -l | grep "^ii" | awk '{print $3}' # Debian: recent installs need apt history
```

---

**Q: How do you find which process is using the most disk I/O?**

```bash
# Best tool: iotop
iotop -o               # show only processes with active I/O (refreshes)
iotop -oa              # cumulative mode (total I/O since start)
iotop -b -n 3 -d 1     # batch mode, 3 iterations, 1 second interval (for logging)

# Without iotop (parse /proc):
pidstat -d 2           # per-process disk I/O stats every 2 seconds (sysstat package)

# For a specific PID:
cat /proc/1234/io
# rchar: 1234567     — bytes read (including cache)
# wchar: 234567      — bytes written (including cache)
# read_bytes: 12345  — bytes actually read from disk
# write_bytes: 2345  — bytes actually written to disk

# Which process has a specific file open?
lsof /var/log/huge.log           # which process has this file open?
fuser -v /var/lib/mysql/data/    # verbose: who's using this directory?
```

---

**Q: What is iowait and when is it a problem?**

**iowait** (`%wa` in top/iostat) is the percentage of time the CPU is **idle but waiting for disk I/O to complete**. During iowait, the CPU cannot do useful work because it's blocked waiting for a storage response.

When it's a problem:
- Sustained iowait > 10–20% indicates disk is a bottleneck
- Application latency increases because processes are spending time blocked on I/O
- HDD: await > 10ms is notable; > 50ms is severe
- SSD/NVMe: await > 1ms is notable; > 10ms is severe

Causes: bulk writes/reads, many small random I/Os (databases), logging storms, VM contention (noisy neighbor on shared storage).

```bash
# Investigate:
iostat -x 2            # which device? check await and %util
iotop -o               # which process is doing the writes?
dmesg | grep -i "error\|warn\|io error"   # hardware errors?
smartctl -a /dev/sda   # check disk health (SMART data)

# Mitigation:
# 1. Move log files to a separate volume
# 2. Tune I/O scheduler: cat /sys/block/sda/queue/scheduler
#    echo mq-deadline > /sys/block/sda/queue/scheduler   # good for databases
# 3. Increase readahead for streaming workloads:
#    blockdev --setra 4096 /dev/sda
```

---
