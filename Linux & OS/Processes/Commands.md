# Process Management Commands — Complete Reference

> A process is a running instance of a program. Linux process management involves viewing, controlling, prioritizing, and killing processes. These commands are essential for debugging performance issues, managing services, and understanding system behavior.

---

## ps — Process Snapshot

`ps` takes a snapshot of currently running processes (unlike `top` which is live).

```bash
# ─── Most common forms ────────────────────────────────────────────
ps aux                    # ALL processes, BSD format: USER PID %CPU %MEM VSZ RSS TTY STAT START TIME COMMAND
ps -ef                    # ALL processes, Unix format: UID PID PPID C STIME TTY TIME CMD
ps -ef --forest           # process tree (shows parent-child relationships)
ps aux --sort=-%cpu       # sort by CPU descending (find CPU hogs)
ps aux --sort=-%mem       # sort by memory descending

# ─── Targeted queries ─────────────────────────────────────────────
ps -p 1234                # show specific PID
ps -p 1234,5678           # multiple PIDs
ps -u root                # processes owned by root
ps -u $(whoami)           # your own processes
ps -C nginx               # find processes by command name
ps -T -p 1234             # show all threads of PID 1234
ps -o pid,ppid,cmd,%cpu,%mem --sort=-%cpu  # custom output columns

# ─── Combine with grep ────────────────────────────────────────────
ps aux | grep nginx                     # find nginx processes
ps aux | grep -v grep | grep nginx      # exclude the grep process itself
pgrep -a nginx                          # cleaner alternative: print PIDs + names
```

**ps aux output columns:**
```
USER  PID  %CPU  %MEM    VSZ   RSS  TTY   STAT  START    TIME  COMMAND
root  1234  0.5   2.1  256000 21000  ?    Ss    10:00  0:01.34  nginx
```

| Column | Meaning |
|--------|---------|
| `PID` | Process ID |
| `PPID` | Parent Process ID |
| `%CPU` | CPU usage averaged since process started |
| `%MEM` | Physical memory (RSS) as % of total RAM |
| `VSZ` | Virtual memory size (includes shared libs, mapped files) |
| `RSS` | Resident Set Size — actual physical RAM used |
| `TTY` | Terminal (? = no terminal / daemon) |
| `STAT` | Process state (see below) |

**Process states (STAT):**
| Code | Meaning |
|------|---------|
| `R` | Running or runnable (on CPU or waiting for CPU) |
| `S` | Sleeping (interruptible) — waiting for event |
| `D` | Uninterruptible sleep — waiting for I/O (cannot be killed!) |
| `Z` | Zombie — process finished but parent hasn't called wait() |
| `T` | Stopped (SIGSTOP or Ctrl+Z) |
| `s` | Session leader |
| `+` | In foreground process group |
| `<` | High priority (negative nice value) |
| `N` | Low priority (positive nice value) |

---

## top & htop — Live Process Monitor

```bash
# top — built-in, real-time
top                       # interactive process list
top -d 2                  # refresh every 2 seconds
top -p 1234,5678          # monitor specific PIDs
top -u nginx              # only show processes for user nginx
top -bn1                  # batch mode, 1 iteration (good for scripting)

# Inside top:
# Press: k → kill, r → renice, M → sort by memory, P → sort by CPU
# Press: f → field management, 1 → toggle per-CPU view
# Press: q → quit, h → help

# htop — better UI (install: apt/yum install htop)
htop                      # color, mouse-clickable, easy kill/renice
htop -p 1234              # monitor specific PID
htop -u nginx             # filter by user
# F5 = tree view, F6 = sort, F9 = kill, F10 = quit
```

**top output header:**
```
top - 14:32:01 up 5 days,  2:14,  3 users,  load average: 0.52, 0.38, 0.33
Tasks: 213 total,   1 running, 212 sleeping,   0 stopped,   0 zombie
%Cpu(s):  3.2 us,  1.1 sy,  0.0 ni, 94.8 id,  0.8 wa,  0.0 hi,  0.1 si
MiB Mem :  15887.5 total,   1234.2 free,   8902.3 used,  5751.0 buff/cache
MiB Swap:   2048.0 total,   1900.2 free,    147.8 used.   6234.7 avail Mem
```

- `load average` — processes waiting for CPU over last 1/5/15 min (above # of CPUs = overloaded)
- `wa` (%wa = iowait) — CPU idle waiting for I/O; high iowait = disk/network bottleneck
- `us` = user space CPU, `sy` = kernel/system CPU

---

## kill & signals — Terminate Processes

```bash
# ─── Kill by PID ──────────────────────────────────────────────────
kill 1234                 # send SIGTERM (15) — graceful shutdown request
kill -9 1234              # send SIGKILL (9) — force kill (cannot be caught or ignored)
kill -15 1234             # explicit SIGTERM (same as default)
kill -HUP 1234            # send SIGHUP (1) — reload config (for many daemons like nginx)
kill -STOP 1234           # pause process (same as Ctrl+Z)
kill -CONT 1234           # resume stopped process

# ─── Kill by name ─────────────────────────────────────────────────
pkill nginx               # kill all processes named nginx (SIGTERM)
pkill -9 nginx            # force kill all nginx processes
pkill -HUP nginx          # send SIGHUP to reload nginx config
pkill -u www-data         # kill all processes owned by user www-data

# ─── killall ──────────────────────────────────────────────────────
killall nginx             # kill all processes exactly matching the name
killall -9 -u baduser     # kill all processes owned by baduser

# ─── pidof and pgrep ─────────────────────────────────────────────
pidof nginx               # find PID of named process (exact match)
pgrep nginx               # like pidof but with pattern matching
pgrep -l nginx            # also show the process name
pgrep -a nginx            # show full command line
```

**Common signals:**
| Signal | Number | Meaning |
|--------|--------|---------|
| `SIGTERM` | 15 | Graceful termination (default kill) — process can catch and clean up |
| `SIGKILL` | 9 | Forced termination — kernel kills immediately, cannot be caught |
| `SIGHUP` | 1 | Hang up — traditionally reload config for daemons |
| `SIGINT` | 2 | Interrupt (Ctrl+C) — graceful shutdown |
| `SIGSTOP` | 19 | Pause process (cannot be caught) |
| `SIGCONT` | 18 | Resume paused process |
| `SIGUSR1/2` | 10/12 | Application-defined signals |

**SIGTERM vs SIGKILL — always try SIGTERM first:**
- SIGTERM gives the process a chance to: flush buffers, close DB connections, write PID files, log shutdown
- SIGKILL: immediate, but can leave temp files, corrupt state, or leave child processes orphaned
- In containers: `docker stop` sends SIGTERM, waits 10s, then SIGKILL

---

## nice & renice — Process Priority

Linux schedules CPU time using priority. Nice values range from -20 (highest priority) to +19 (lowest priority).

```bash
# ─── Start with a priority ────────────────────────────────────────
nice -n 10 my-script.sh           # run with low priority (+10 nice)
nice -n -5 ./high-priority-app    # high priority (requires root for negative values)
nice ./cpu-intensive-task          # default: +10 nice value

# ─── Change priority of running process ───────────────────────────
renice +15 -p 1234                # lower priority of PID 1234
renice -5 -p 1234                 # raise priority (requires root)
renice +10 -u nginx               # lower priority of all nginx processes
renice +10 -g 1001                # lower priority of all processes in group 1001

# ─── Check current priority ───────────────────────────────────────
ps -o pid,ni,pri,cmd -p 1234      # ni = nice, pri = kernel priority
top                               # NI column shows nice value
```

**When to use nice:**
- Batch jobs / backup scripts: `nice -n 19 rsync -av /data /backup`
- Build systems: `nice -n 10 make -j4`
- Prevent a CPU-heavy job from starving interactive workloads

---

## Background & Foreground — Job Control

```bash
# ─── Run in background ────────────────────────────────────────────
./long-task.sh &                  # start in background; prints [1] PID
nohup ./long-task.sh &            # background + ignore hangup (keeps running after logout)
nohup ./long-task.sh > output.log 2>&1 &  # redirect stdout+stderr

# ─── Control running jobs ─────────────────────────────────────────
Ctrl+Z                            # suspend foreground process (sends SIGSTOP)
bg                                # resume suspended job in background
bg %2                             # resume job 2 in background
fg                                # bring most recent background job to foreground
fg %1                             # bring job 1 to foreground
jobs                              # list current shell's background jobs
jobs -l                           # with PIDs

# ─── Disown (detach from shell) ───────────────────────────────────
./task.sh &
disown -h %1                      # remove from job table; won't be killed on logout
```

---

## Monitoring CPU & Memory

```bash
# ─── vmstat — overall system statistics ──────────────────────────
vmstat 2 5                        # sample every 2s, 5 times
vmstat -s                         # summary of memory stats

# vmstat output columns:
# r = processes waiting for CPU (runnable queue length)
# b = processes in uninterruptible sleep (D state — I/O wait)
# si/so = swap in/out (non-zero = memory pressure)
# wa = CPU time waiting for I/O

# ─── iostat — disk and CPU I/O ───────────────────────────────────
iostat -x 2                       # extended I/O stats every 2s
iostat -xz 1                      # skip idle devices, update every 1s
# %util > 90% on a disk = disk is saturated
# await = average time (ms) for I/O to complete

# ─── pidstat — per-process CPU and I/O ───────────────────────────
pidstat 2                         # CPU usage per process, every 2s
pidstat -d 2                      # disk I/O per process
pidstat -p 1234 2                 # monitor specific PID
pidstat -u -p ALL 1               # like top but one line per process

# ─── sar — historical system activity ────────────────────────────
sar -u 2 5                        # CPU usage, every 2s, 5 samples
sar -r 2                          # memory utilization
sar -d 2                          # disk activity
sar -n DEV 2                      # network interface stats
sar -f /var/log/sa/sa20           # replay a historical recording
```

---

## strace & lsof — What Is a Process Doing?

```bash
# ─── strace — trace system calls ─────────────────────────────────
strace ls                         # trace system calls made by ls
strace -p 1234                    # attach to running process
strace -p 1234 -e trace=read,write  # only trace specific syscalls
strace -p 1234 -c                 # summary: count syscalls, show timing
strace -p 1234 -f                 # follow child processes too
strace -e openat,close,read,write -p 1234 2>&1 | grep -v ^--- # filter noise

# Use case: process hanging in D state?
strace -p <PID>                   # see what syscall it's stuck in

# ─── lsof — list open files ───────────────────────────────────────
lsof                              # all open files (can be huge)
lsof -p 1234                      # files opened by PID 1234
lsof -u nginx                     # files opened by user nginx
lsof -i :8080                     # process listening on port 8080
lsof -i TCP:80                    # TCP connections on port 80
lsof +D /var/log                  # all processes with open files in /var/log
lsof /var/log/app.log             # who has this specific file open?

# Common use cases:
lsof -i :8080 | grep LISTEN       # find what's listening on port 8080
lsof -p 1234 | grep REG           # show only regular files (not sockets/pipes)
```

---

## /proc Filesystem — Process Information

```bash
# /proc/<PID>/ contains runtime info about every process
ls /proc/1234/

cat /proc/1234/status             # human-readable process status (VmRSS, threads, etc.)
cat /proc/1234/cmdline            # full command line (null-separated)
cat /proc/1234/environ            # environment variables (null-separated)
cat /proc/1234/fd/                # file descriptors (symlinks to open files)
ls -la /proc/1234/fd/             # count: how many FDs is this process using?
cat /proc/1234/maps               # memory mappings (code, stack, heap, shared libs)
cat /proc/1234/net/tcp            # TCP connections (hex encoded)

# System-wide /proc:
cat /proc/loadavg                 # load averages + running/total processes
cat /proc/meminfo                 # detailed memory breakdown
cat /proc/cpuinfo                 # CPU cores, speeds, features
cat /proc/uptime                  # seconds since boot
cat /proc/net/dev                 # network interface statistics
```

---

## Zombie & Orphan Processes

```bash
# ─── Find zombie processes (Z state) ─────────────────────────────
ps aux | awk '$8=="Z" {print $0}'      # show zombies
ps aux | grep -w Z                      # alternative

# Zombie processes can't be killed — they're already dead.
# They exist because the parent hasn't called wait() to collect the exit code.
# Fix: kill the PARENT process (parent cleans up its zombies)
# If parent is PID 1 (init/systemd), it will auto-reap zombies.

# ─── Find orphan processes ────────────────────────────────────────
# Orphans: parent died, adopted by PID 1 (init)
ps -o pid,ppid,cmd | awk '$2 == 1 {print}'   # processes whose parent is init

# ─── In Docker containers: zombie gotcha ─────────────────────────
# PID 1 in container must be an init process that reaps zombies.
# If your app runs as PID 1 directly, child processes become zombies.
# Fix: use --init flag in docker run, or tini as ENTRYPOINT:
#   ENTRYPOINT ["/usr/bin/tini", "--", "node", "server.js"]
```

---

## Interview Q&A

**Q: What is a zombie process and how do you fix it?**
A zombie process is one that has completed execution but still has an entry in the process table because its parent hasn't called `wait()` to collect its exit code. It's not consuming CPU or memory — just a PID slot. You can't kill a zombie directly with `kill -9` because it's already dead. Fix: send SIGCHLD to the parent (to trigger wait()), or kill the parent (init/systemd will then reparent and reap the zombie). In containers, use `--init` flag or tini as PID 1 to handle zombie reaping automatically.

**Q: Process is in D state and won't die — what do you do?**
D (uninterruptible sleep) means the process is waiting for kernel I/O — typically a disk or NFS operation. It cannot be killed, not even with `kill -9`, because SIGKILL is not delivered during kernel I/O waits. Use `strace -p <PID>` to see what syscall it's stuck in. Common causes: NFS server unreachable (causes indefinite D-state for processes on NFS mounts with `hard` mount option), failing disk, SCSI/iSCSI issues. Fix depends on cause: unmount the NFS share (`umount -l` for lazy unmount), repair the storage subsystem, or in the worst case reboot the machine (a process in D state is essentially unremovable without fixing the underlying I/O issue).

**Q: What's the difference between `kill -9` and `kill -15`?**
`kill -15` (SIGTERM) is a polite request to terminate — the process receives it and can handle it gracefully: flush buffers, close database connections, delete temp files, log a shutdown message. Most well-written daemons handle SIGTERM. `kill -9` (SIGKILL) is delivered directly by the kernel — the process never sees it and cannot intercept or ignore it. Use SIGTERM first, wait a few seconds, then escalate to SIGKILL if the process doesn't exit. Never reach for -9 immediately unless you're certain the process is hung and incapable of cleanup.

**Q: What does high iowait (%wa) in top mean?**
%wa (iowait) is the percentage of time the CPU is idle but at least one process is waiting for I/O to complete. High iowait means there's an I/O bottleneck — disk, NFS, or database is slow. To investigate: `iostat -x 1` to find which disk is saturated (%util near 100%), `iotop` to find which process is generating I/O, check if `await` (average I/O wait time in ms) is high. Important distinction: iowait is CPU idle time, not CPU busy time — the system load can be high (processes stuck in D state) while CPU usage appears low but iowait is high.

**Q: How does process priority (nice value) affect scheduling?**
The Linux completely fair scheduler (CFS) uses nice values (-20 to +19) as a weight to allocate CPU time. Lower nice = higher priority = more CPU share under contention. Nice -20 gets ~40x more CPU time than nice +19 when both are runnable. Nice values only matter under CPU contention — if the system isn't CPU-saturated, all processes run at full speed regardless of priority. Use `nice -n 19` for batch jobs so interactive workloads are never starved. Only root can set negative nice values.
