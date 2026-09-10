# 🎯 Linux Interview Scenarios
**8 Real-World Incident Scenarios — Investigation, Resolution, Key Learnings**

---

# 🗂️ Linux Scenarios

---

# 🔴 Scenario 1 · Production Server Disk Full at 3AM

**Alert:** PagerDuty fires — "Disk usage at 100% on /dev/sda1 (/) on prod-web-01"

**Your response:**

```bash
# Step 1: Confirm which filesystem is full
df -h
# Filesystem      Size  Used Avail Use% Mounted on
# /dev/sda1        50G   50G    0  100% /

# Step 2: Find what's consuming space — drill down
du -sh /var/*     # usually the culprit
# 46G /var/log    ← found it

du -sh /var/log/*
# 45G /var/log/app
# 800M /var/log/nginx

du -sh /var/log/app/*
# 45G /var/log/app/application.log   ← one massive file

# Step 3: Check if it's held open by a process (deleted file issue)
lsof | grep application.log
# java  1234  appuser  3w  REG  8,1  48318382080  /var/log/app/application.log

# The file is being written by the java process (PID 1234)
# Sending SIGHUP to log-rotate-aware processes (like nginx) makes them reopen log files
# But for Java/custom apps, you need to check if they support log rotation
```

**Investigation reveals:** The log file is not being rotated because `logrotate` was misconfigured.

```bash
# Check logrotate config
cat /etc/logrotate.d/app
# Missing! No config for our app

# Emergency fix — truncate the active log (DO NOT rm while process has it open!)
# Option A: truncate (shrinks file to 0 bytes, process keeps writing)
truncate -s 0 /var/log/app/application.log
df -h   # space is freed immediately

# Option B: if process supports log signal
kill -USR1 1234   # many apps (nginx, etc.) rotate logs on SIGUSR1

# Option C: last resort — restart the app (brief outage)
systemctl restart myapp
```

**Permanent fix:**
```bash
# Create logrotate config
cat > /etc/logrotate.d/myapp <<'EOF'
/var/log/app/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0640 appuser appgroup
    postrotate
        kill -USR1 $(cat /var/run/myapp.pid) 2>/dev/null || true
    endscript
}
EOF

# Test it
logrotate -d /etc/logrotate.d/myapp   # dry run
logrotate -f /etc/logrotate.d/myapp   # force run
```

**Add disk monitoring alert:**
```bash
# Add to crontab:
# 0 * * * * df -h / | awk 'NR==2 {gsub(/%/,""); if ($5 > 80) print "WARN: disk at "$5"%" | "mail -s DISK_ALERT oncall@company.com"}'
```

> 💡 Key learning: Never `rm` a file held open by a process — the disk space isn't freed until the process closes it. Always `truncate -s 0` for active log files. Check `lsof | grep deleted` first.

---

# 🔴 Scenario 2 · Application Can't Start — Port Already In Use

**Error in app logs:**
```
Error starting application: bind: address already in use (port 8080)
```

**Investigation:**
```bash
# Step 1: What's using port 8080?
ss -tlnp | grep :8080
# LISTEN  0  128  0.0.0.0:8080  0.0.0.0:*  users:(("java",pid=5678,fd=123))

# Alternative
fuser 8080/tcp
# 8080/tcp: 5678

lsof -i :8080
# COMMAND  PID     USER  FD  TYPE DEVICE SIZE  NODE NAME
# java    5678  appuser  123 IPv4  12345  0t0   TCP *:8080 (LISTEN)

# Step 2: What is this process?
ps -p 5678 -o pid,ppid,user,cmd
# 5678  1  appuser  java -jar /opt/app/myapp.jar

# Step 3: Is it a legitimate running instance?
systemctl status myapp
# → Active: active (running)   ← it's still running from a previous deploy!

# Step 4: Understand the state
# It's the old version still listening — systemctl restart didn't stop it properly
```

**Resolution:**
```bash
# Graceful: let systemd handle it
systemctl stop myapp
ss -tlnp | grep :8080   # confirm port is free
systemctl start myapp

# Or if systemd is not managing it:
kill -15 5678   # SIGTERM — graceful shutdown
sleep 5
ss -tlnp | grep :8080   # check if released
kill -9 5678    # SIGKILL if still up (last resort)

# Wait for TIME_WAIT to clear (if connection was active)
# TIME_WAIT lasts ~60 seconds (2 × MSL)
# If you need the port immediately:
sysctl -w net.ipv4.tcp_tw_reuse=1   # allow reuse of TIME_WAIT sockets
```

**Understanding TIME_WAIT:**
```
TIME_WAIT = port closed, but OS holds it for ~60s to ensure late packets
             don't confuse a new connection on the same port
If you see "Address already in use" even after killing the process:
  ss -tn | grep :8080   # look for TIME_WAIT state
  # Wait 60 seconds, or set SO_REUSEADDR in your app (standard practice)
```

**Better systemd service to prevent this:**
```ini
[Service]
KillMode=mixed          # send SIGTERM to process group, then SIGKILL
TimeoutStopSec=30       # wait 30s for graceful shutdown before SIGKILL
Restart=on-failure
RestartSec=5
```

> 💡 Key learning: Always check for TIME_WAIT before concluding a port is "stuck". Use `ss -tn state time-wait | grep :8080` to confirm. For production services, configure systemd `TimeoutStopSec` so the app gets time to drain connections before being killed.

---

# 🔴 Scenario 3 · SSH Login Failing After Key Rotation

**Symptom:** `Permission denied (publickey)` after rotating SSH keys.

**Investigation (from client side):**
```bash
# Step 1: Enable verbose SSH to see exactly where it fails
ssh -vvv alice@prod-server-01
# ...
# debug1: Offering public key: /home/alice/.ssh/id_ed25519
# debug1: Authentications that can continue: publickey
# debug3: send packet: type 50
# debug1: Authentications that can continue: publickey
# debug2: we did not send a packet, disable method
# debug1: No more authentication methods to try.
# alice@prod-server-01: Permission denied (publickey).
#
# Translation: server rejected the key — it's not in authorized_keys

# Step 2: Can you still get in with the OLD key?
ssh -i ~/.ssh/id_ed25519_old alice@prod-server-01
# If yes: authorized_keys still has old key, new key not added correctly
```

**Investigation (on the server — if you have root/another way in):**
```bash
# Check authorized_keys exists and has correct content
cat /home/alice/.ssh/authorized_keys
# Should contain the NEW public key

# Check permissions — sshd REFUSES to use authorized_keys if permissions are wrong
ls -la /home/alice/.ssh/
# drwx------ 2 alice alice 4096  ← must be 700 (no group/other read)
# -rw------- 1 alice alice  567  ← authorized_keys must be 600

ls -la /home/alice/
# drwxr-xr-x 8 alice alice 4096  ← home dir must NOT be world-writable (drwxrwxrwx would break auth)

# Check sshd logs
journalctl -u sshd -n 50
# or on older systems:
tail -50 /var/log/auth.log
# Look for: "Authentication refused: bad ownership or modes for file /home/alice/.ssh/authorized_keys"
```

**Common causes and fixes:**
```bash
# Fix 1: Wrong permissions on .ssh directory
chmod 700 /home/alice/.ssh
chmod 600 /home/alice/.ssh/authorized_keys
chown -R alice:alice /home/alice/.ssh

# Fix 2: Wrong user owns the files (happened during deploy as root)
chown alice:alice /home/alice/.ssh/authorized_keys

# Fix 3: New public key not in authorized_keys
cat ~/.ssh/id_ed25519.pub   # on your laptop
# Append this to /home/alice/.ssh/authorized_keys on server

# Fix 4: Home directory is world-writable (sshd security requirement)
chmod 755 /home/alice    # not 777

# Fix 5: SELinux context wrong (RHEL/CentOS)
restorecon -Rv /home/alice/.ssh/

# Test after fix
ssh -v alice@prod-server   # confirm verbose shows key accepted
```

**Verify sshd config allows pubkey auth:**
```bash
grep -i pubkey /etc/ssh/sshd_config
# PubkeyAuthentication yes    ← must be yes (not no or commented out)
# AuthorizedKeysFile .ssh/authorized_keys  ← must point to correct file
```

> 💡 Key learning: sshd silently rejects authorized_keys if: directory is group/other writable, file is group/other writable, or ownership is wrong. Always check `journalctl -u sshd` for the exact rejection reason — it logs it clearly.

---

# 🔴 Scenario 4 · Server Load Spiking — CPU or I/O?

**Alert:** Load average 24.5 on a 4-core server. Response times elevated.

**Triage:**
```bash
# Step 1: Load average context
uptime
# load average: 24.51, 22.10, 18.92 (1min, 5min, 15min)
# On a 4-core server: >4 = overloaded. 24 = very overloaded
# Rising trend (24→22→18 going backwards) = getting worse over time

# Step 2: CPU or I/O?
top   # look at the header line
# %Cpu(s): 85.0 us, 5.0 sy, 0.0 ni, 5.0 id, 2.0 wa, ...
#                                             ↑ idle    ↑ iowait
# High %us (user) = CPU-bound
# High %wa (iowait) = I/O-bound
# Both low = something else (check 'b' in vmstat)

vmstat 2 5
# procs -----------memory---------- ---swap-- -----io---- -system-- ------cpu-----
#  r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st
# 22  3   1024  50000  20000 500000    0    0   8000  2000 5000 8000 80  5  2 15  0
# r=22 (22 processes waiting for CPU) = CPU bottleneck
# b=3 (3 processes in D state) = some I/O wait too
```

**Branch A — CPU bound:**
```bash
# Find the culprit
top   # press P to sort by CPU
# or
ps -eo pid,user,pcpu,pmem,cmd --sort=-pcpu | head -10

# What is it doing?
strace -p 5678 -c   # 30 seconds summary of system calls
# If: gettime, futex appear often = lock contention
# If: mmap, brk appear = memory allocation
# If: read, write = file I/O masquerading as CPU

# Is it a runaway job?
ps -eo pid,user,etimes,pcpu,cmd --sort=-pcpu | head -5
# etimes = elapsed time in seconds
# If PID has been running 10 minutes but etimes shows 10 seconds = recently spawned

# Resolution
nice -n 10 -p 5678      # reduce priority to 10 (less CPU time)
renice 10 -p 5678        # same effect
# If it's a cron job gone wild: kill it, fix the cron
# If it's legit traffic: horizontal scale or optimize the app
```

**Branch B — I/O bound:**
```bash
# Confirm with iostat
iostat -x 2
# Device  r/s  w/s  rkB/s  wkB/s  await  %util
# sda      5  500    50   5000    80ms  98%    ← 98% utilized, 80ms wait = saturated

# Find which process is doing the I/O
iotop -o    # -o = show only active I/O processes
# Alternatively:
pidstat -d 2   # per-process I/O every 2 seconds

# What files?
lsof -p 5678 | grep REG   # regular files opened by process

# Resolution
# 1. Identify if I/O is write or read (iostat shows)
# 2. Write-heavy: buffered writes, use async I/O, write to faster storage
# 3. Read-heavy: check if OS cache is being bypassed (O_DIRECT), add cache layer
# 4. Check if a sync/fsync loop is the issue: strace -e trace=fsync -p PID
```

> 💡 Key learning: Load average counts both CPU-waiting AND I/O-waiting processes. Always distinguish with `top` %wa (iowait). High load + low %wa = CPU problem. High load + high %wa = I/O problem. They require completely different solutions.

---

# 🔴 Scenario 5 · Process Keeps Dying — OOM Killer Investigation

**Symptom:** Application restarts every few hours with no clear error in app logs.

**Investigation:**
```bash
# Step 1: Check systemd restart count
systemctl status myapp
# Active: active (running) since 14:32:15; 23min ago
# Main PID: 9876
# ...
# (11 restarts in the last 5h)   ← being restarted repeatedly

# Step 2: Check OOM killer in kernel log
dmesg -T | grep -i "oom\|killed\|out of memory"
# [Mon Jan 15 12:05:23 2024] Out of memory: Kill process 8234 (java) score 752 or sacrifice child
# [Mon Jan 15 12:05:23 2024] Killed process 8234 (java) total-vm:4194304kB, anon-rss:3670016kB
# ↑ java process killed because it had 3.5GB RSS on a 4GB machine

journalctl -k | grep -i "oom\|killed"
# Same information from journal

# Step 3: Confirm it's OOM (not crash)
journalctl -u myapp | grep -E "killed|OOM|signal|status"
# Jan 15 12:05:23 systemd[1]: myapp.service: Main process exited, code=killed, status=9/KILL
# ↑ exit code 9 = SIGKILL from OOM killer (not app crash)

# Step 4: Memory trend before death
# Check if there's a memory leak
sar -r 1 60   # memory stats every second for a minute
# Watch for MemFree or MemAvailable steadily decreasing
```

**Resolution:**
```bash
# 1. Set memory limit in systemd (prevent OOM of OTHER processes)
systemctl edit myapp
# Add:
[Service]
MemoryMax=2G        # hard limit — process gets SIGKILL at 2GB
MemoryHigh=1.8G     # soft limit — process gets throttled at 1.8GB

# 2. Protect the process from OOM killer (use with caution)
# In /etc/systemd/system/myapp.service:
OOMScoreAdjust=-500    # -1000 = never kill, 0 = default, +1000 = kill first

# 3. Fix the memory leak (root cause)
# Add heap dump on OOM for Java:
# JAVA_OPTS="-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/tmp/heapdump.hprof"

# 4. Monitor memory
watch -n 5 'ps -p $(pgrep java) -o pid,rss,vsz,cmd'
# or
cat /proc/$(pgrep java)/status | grep -i mem

# 5. Add swap as emergency buffer (not a fix, but buys time)
fallocate -l 4G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab
```

> 💡 Key learning: Exit code 9 (SIGKILL) from systemd means OOM killer, not app crash. Always check `dmesg | grep -i oom` and `journalctl -k` first. Set `MemoryMax` in systemd unit files to control which process gets killed when memory runs out. A memory leak will always end in OOM — you must fix the root cause.

---

# 🔴 Scenario 6 · Cron Job Not Running for 3 Days

**Symptom:** Weekly database backup hasn't run. No backup files created since Tuesday.

**Investigation:**
```bash
# Step 1: Check if cron is running
systemctl status cron    # Debian/Ubuntu
systemctl status crond   # RHEL/CentOS

# Step 2: List the crontab
crontab -l
# 0 2 * * 0 /opt/scripts/backup.sh >> /var/log/backup.log 2>&1

# Step 3: Check cron log
grep CRON /var/log/syslog | tail -50         # Debian
journalctl -u cron --since "3 days ago"      # systemd
grep backup /var/log/cron | tail -50         # RHEL

# You might see:
# CRON[1234]: (root) CMD (/opt/scripts/backup.sh >> /var/log/backup.log 2>&1)
# ← cron DID run it, but the script itself failed

# Step 4: Check the script output
cat /var/log/backup.log
# /opt/scripts/backup.sh: line 5: pg_dump: command not found
# ↑ PATH issue! cron has minimal PATH, pg_dump not in it

# Step 5: Verify script is executable
ls -la /opt/scripts/backup.sh
# -rw-r--r-- 1 root root  ← NOT executable! Missing +x
chmod +x /opt/scripts/backup.sh
```

**Common cron failures and fixes:**

```bash
# Issue 1: PATH is too minimal in cron
# Cron PATH is usually: /usr/bin:/bin
# Fix: add PATH at top of crontab or use full paths in script
crontab -e
# Add at top:
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Or use full paths in script:
# /usr/bin/pg_dump instead of pg_dump
# /usr/local/bin/python3 instead of python3

# Issue 2: Script succeeds but output/errors aren't captured
# BAD: 0 2 * * 0 /opt/scripts/backup.sh
# GOOD: 0 2 * * 0 /opt/scripts/backup.sh >> /var/log/backup.log 2>&1

# Issue 3: Environment variables not set
# Cron doesn't load .bashrc or .bash_profile
# Fix: source them explicitly or set vars in the script
export HOME=/root
export AWS_PROFILE=backup

# Issue 4: Get email on failure (if mail configured)
crontab -e
MAILTO=oncall@company.com
0 2 * * 0 /opt/scripts/backup.sh

# Issue 5: Script runs as wrong user
crontab -u root -l    # check which user's crontab
# System cron in /etc/cron.d/ has a user column:
# 0 2 * * 0 root /opt/scripts/backup.sh

# Test the script manually as cron would run it
sudo -u root env -i PATH=/usr/bin:/bin HOME=/root /opt/scripts/backup.sh
```

**Debug cron with a test job:**
```bash
crontab -e
# Add a test job that runs every minute:
* * * * * echo "cron-test $(date)" >> /tmp/cron-test.log 2>&1
# Wait 2 minutes, then:
cat /tmp/cron-test.log
# If empty: cron itself is broken (check systemctl status cron)
# If has lines: cron works, problem is your specific job
```

> 💡 Key learning: 90% of cron failures are: (1) PATH too minimal — use absolute paths, (2) stderr discarded — always `2>&1`, (3) script not executable — check `chmod +x`. Test by running the command exactly as cron would: `sudo -u <user> env -i PATH=/usr/bin:/bin <command>`.

---

# 🔴 Scenario 7 · NFS Mount Causing D-State Hang

**Symptom:** Multiple processes stuck, server increasingly unresponsive. Load average 85 on an 8-core server.

**Investigation:**
```bash
# Step 1: Check process states
ps aux | awk '$8 == "D"'    # processes in D (uninterruptible sleep) state
# root     1234  0.0  0.1  D    find /mnt/nfs/data -name "*.log"
# ubuntu   5678  0.0  0.2  D    cp /mnt/nfs/backup/file.tar.gz /tmp/
# jenkins  9012  0.0  0.0  D    git pull origin main (working dir on NFS)
# ← multiple processes stuck waiting for NFS

# Step 2: Confirm it's NFS
strace -p 1234 2>&1 | head -5
# getdents64(7, ...)   ← trying to read directory entries
# ioctl(7, ...)        ← stuck on ioctl (NFS call waiting for server response)

# Or:
cat /proc/1234/wchan   # what kernel function is the process waiting on?
# nfs_wait_bit_killable  ← NFS wait! Confirmed.

# Step 3: Check NFS server connectivity
showmount -e nfs-server.internal    # can we reach the NFS server?
# clnt_create: RPC: Port mapper failure - Timed out ← NFS server unreachable

ping nfs-server.internal   # basic reachability
# Request timeout   ← NFS server is down
```

**Short-term fix:**
```bash
# Attempt lazy umount (detaches even if busy)
umount -l /mnt/nfs
# -l = lazy: immediately detach from filesystem namespace,
#            cleanup happens when all references are released

# Force umount (more aggressive)
umount -f /mnt/nfs

# Kill the D-state processes (SIGKILL won't work on D-state!)
# You cannot kill processes in D state — they're in kernel space
# Only fix the underlying I/O to release them
# If NFS server comes back: processes auto-recover
# If NFS server is permanently gone: reboot is the only option

# Check if processes cleared after umount
ps aux | awk '$8 == "D"'   # should be empty now
```

**Long-term fix — NFS mount options:**
```bash
# /etc/fstab — the wrong way (default = hard mount, hangs forever)
nfs-server:/export  /mnt/nfs  nfs  defaults  0  0

# /etc/fstab — the right way for resilient NFS
nfs-server:/export  /mnt/nfs  nfs  \
    soft,           # give up after timeout (vs hard which retries forever)
    timeo=30,       # timeout = 3 seconds (timeo is in 0.1s units)
    retrans=3,      # retry 3 times before giving up
    _netdev,        # wait for network before mounting at boot
    nofail,         # don't fail boot if NFS unavailable
    rsize=1048576,  # read buffer size
    wsize=1048576   # write buffer size
    0  0

# After editing fstab, remount:
mount -o remount /mnt/nfs
```

> ⚠️ Watch out: `soft` NFS mounts can cause data corruption if write I/O is interrupted. Use `hard` mounts for data-critical workloads and instead: fix the NFS server's availability. For read-only or non-critical mounts, `soft` prevents the hanging D-state problem.

> 💡 Key learning: D-state processes cannot be killed — the only fix is to resolve the underlying I/O issue or reboot. Always use `soft,timeo=30,retrans=3,nofail,_netdev` for NFS mounts in production. A single hung NFS mount can take down an entire server.

---

# 🔴 Scenario 8 · Hardening a Fresh Linux Server

**Context:** New Ubuntu 22.04 EC2 instance, needs to be production-ready and secure.

**Complete hardening runbook:**

```bash
# ── 1. Update everything ──
apt update && apt upgrade -y
apt autoremove -y

# ── 2. Create a non-root deploy user ──
useradd -m -s /bin/bash -G sudo deployer
mkdir -p /home/deployer/.ssh
chmod 700 /home/deployer/.ssh
# Copy your public key
echo "ssh-ed25519 AAAA... deployer@company.com" >> /home/deployer/.ssh/authorized_keys
chmod 600 /home/deployer/.ssh/authorized_keys
chown -R deployer:deployer /home/deployer/.ssh

# ── 3. Harden SSH ──
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
cat >> /etc/ssh/sshd_config <<'EOF'

# Security hardening
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
LoginGraceTime 30
AllowUsers deployer
ClientAliveInterval 300
ClientAliveCountMax 2
X11Forwarding no
EOF

sshd -t && systemctl reload sshd   # test config before reloading

# ── 4. Configure UFW firewall ──
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment "SSH"
ufw allow 80/tcp comment "HTTP"
ufw allow 443/tcp comment "HTTPS"
ufw enable
ufw status verbose

# ── 5. Install and configure fail2ban ──
apt install -y fail2ban
cat > /etc/fail2ban/jail.local <<'EOF'
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 3

[sshd]
enabled = true
port    = 22
filter  = sshd
logpath = /var/log/auth.log
EOF
systemctl enable --now fail2ban
fail2ban-client status sshd   # verify

# ── 6. Automatic security updates ──
apt install -y unattended-upgrades
cat > /etc/apt/apt.conf.d/50unattended-upgrades <<'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
};
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Mail "security@company.com";
EOF
systemctl enable --now unattended-upgrades

# ── 7. Secure sudoers ──
# deployer needs sudo for specific commands only
echo "deployer ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart myapp" > /etc/sudoers.d/deployer
chmod 440 /etc/sudoers.d/deployer
visudo -c   # validate syntax

# ── 8. Audit SUID/SGID files ──
find / -perm /4000 -type f 2>/dev/null | sort > /root/suid_baseline.txt
find / -perm /2000 -type f 2>/dev/null | sort > /root/sgid_baseline.txt
# Review and remove any unexpected SUID/SGID bits:
# chmod u-s /path/to/suspicious_file

# ── 9. Set ulimits (prevent fork bombs, resource exhaustion) ──
cat >> /etc/security/limits.conf <<'EOF'
*    soft    nofile    65536
*    hard    nofile    65536
deployer    soft    nproc    1024
deployer    hard    nproc    2048
EOF

# ── 10. Kernel hardening via sysctl ──
cat > /etc/sysctl.d/99-hardening.conf <<'EOF'
# Disable IP forwarding (unless this is a router)
net.ipv4.ip_forward = 0

# Prevent IP spoofing
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Ignore ICMP broadcasts
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Disable source routing
net.ipv4.conf.all.accept_source_route = 0

# SYN flood protection
net.ipv4.tcp_syncookies = 1

# Don't log martian packets (reduces noise)
net.ipv4.conf.all.log_martians = 0

# Disable IPv6 if not needed
net.ipv6.conf.all.disable_ipv6 = 1
EOF
sysctl -p /etc/sysctl.d/99-hardening.conf

# ── 11. Set up log monitoring ──
# Check for failed logins, sudo usage, SSH keys added
tail -f /var/log/auth.log | grep -E "Failed|sudo|NOPASSWD"
journalctl -f -u sshd

# ── 12. Verify everything ──
ufw status verbose              # firewall rules
ss -tlnp                        # open ports (only 22 should be open now)
fail2ban-client status          # fail2ban running
grep "PermitRootLogin no" /etc/ssh/sshd_config   # SSH hardened
id deployer && sudo -l -U deployer    # user configured
```

**Security verification checklist:**
```bash
# Run these to confirm hardening worked
ssh root@server            # should fail: "Permission denied"
ssh -o PasswordAuthentication=yes deployer@server  # should fail: no password auth
ss -tlnp | grep -v 'LISTEN'  # should only show your allowed ports
cat /var/log/auth.log | grep "Accepted"  # review recent successful logins
```

> 💡 Key learning: Hardening order matters — set up the non-root user and copy your SSH key BEFORE disabling root login and password auth, or you'll lock yourself out. Always run `sshd -t` before reloading sshd to catch config errors. Test each security measure from a SEPARATE terminal session while keeping the original open.

---
