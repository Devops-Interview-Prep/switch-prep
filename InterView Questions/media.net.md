# media.net — Interview Questions & Answers

> Company interview questions with detailed answers for reference.

---

## Round 1

### Q1: If a Linux server is slow, what measures would you take to debug it?

**Systematic triage — narrow down the bottleneck:**

**Step 1 — Identify the resource being starved:**
```bash
# CPU — is it overloaded?
top                          # %us (user), %sy (kernel), %wa (iowait)
uptime                       # load average vs number of CPUs
# If load > CPU count = CPU bottleneck

# Memory — is it swapping?
free -h                      # check available vs used
vmstat 1 5                   # si/so columns = swap I/O (non-zero = bad)
# If si/so > 0 = memory pressure, system is swapping to disk

# Disk I/O — is the disk saturated?
iostat -x 1 5                # %util near 100% = disk saturated
iotop                        # which process is doing the I/O?
df -h                        # is disk full?

# Network — is it saturated or dropping packets?
sar -n DEV 1 5               # bytes/sec per interface
ss -s                        # socket statistics
netstat -i                   # RX/TX errors, drops
```

**Step 2 — Find the offending process:**
```bash
ps aux --sort=-%cpu | head -10    # top CPU consumers
ps aux --sort=-%mem | head -10    # top memory consumers
lsof -p <PID>                     # what files/sockets is it using?
strace -p <PID> -c                # what syscalls is it making?
```

**Step 3 — Check for obvious issues:**
```bash
dmesg | tail -50             # kernel messages: OOM killer, hardware errors
journalctl -xe               # recent system logs with errors
tail -f /var/log/syslog      # application/system events
uptime                       # how long since boot (new vs persistent slowness)
```

**Common root causes:**
- CPU: runaway process (`kill -9`), or legitimate load spike (scale horizontally)
- Memory: memory leak → OOM kills → app keeps restarting (check `dmesg | grep -i "oom killed"`)
- Disk: log rotation missing → disk full → app writes fail
- Network: DDoS, high connection count, DNS resolution slow (`/etc/resolv.conf` issue)
- NFS: stale NFS mount → D-state processes that can't be killed

---

### Q2: Difference between Linux process and threads

| | Process | Thread |
|---|---|---|
| **Definition** | Separate program instance with own memory space | Lightweight execution unit within a process — shares process memory |
| **Memory** | Own virtual address space (isolated from other processes) | Shares heap/global memory with other threads in same process |
| **Creation cost** | Expensive — `fork()` copies the process image | Cheap — `clone()` with shared memory flags |
| **Communication** | IPC (pipes, sockets, shared memory, message queues) | Direct — shared memory (but needs synchronization: mutex/locks) |
| **Failure isolation** | Process crash doesn't affect other processes | Thread crash can take down the entire process |
| **Context switch** | Expensive (TLB flush, full context switch) | Cheaper (same address space) |
| **Visibility in Linux** | Both appear as "tasks" in the kernel; `ps aux` shows processes; `ps -T` shows threads |

```bash
# See threads of a process:
ps -T -p 1234          # show all threads of PID 1234
ls /proc/1234/task/    # each subdirectory = one thread
htop                   # press F5 for tree view, then H to show threads
```

**The key insight:** In Linux, the kernel doesn't actually distinguish processes from threads at the scheduling level. Both are "tasks". A process is just a task with its own address space and file descriptor table; threads are tasks that share these with the parent. This is why Linux uses the `clone()` syscall for both `fork()` and `pthread_create()` — with different flags controlling what gets shared.

**When to use processes vs threads:**
- Processes: isolation matters (different services), CPU-bound (Python GIL bypass), crash isolation
- Threads: I/O-bound workloads (web servers), need fast data sharing, goroutines (Go), Java threads

---

### Q3: CIDR Block

**CIDR (Classless Inter-Domain Routing)** — a method to allocate and describe IP address ranges using a network prefix length:

```
Format: IP_ADDRESS / PREFIX_LENGTH

Example: 192.168.1.0/24
                     │
                     └── 24 bits are the network part
                         (256 - 24 = 8 bits for host addresses)
                         → 2^8 = 256 addresses
                         → 254 usable hosts (subtract network + broadcast)
```

**Subnet size quick reference:**

| CIDR | Addresses | Usable Hosts | Example use |
|------|-----------|-------------|-------------|
| /32 | 1 | 1 host | Single host route, security group rule for one IP |
| /31 | 2 | 2 | Point-to-point link |
| /30 | 4 | 2 | Small point-to-point links |
| /28 | 16 | 14 | Small subnet, AWS prefix delegation |
| /27 | 32 | 30 | Small team subnet |
| /24 | 256 | 254 | Standard small subnet (most common) |
| /22 | 1,024 | 1,022 | Medium environment |
| /20 | 4,096 | 4,094 | Large environment |
| /16 | 65,536 | 65,534 | Large VPC, entire office network |

**How to calculate:**
- Prefix /N → network bits = N, host bits = 32 - N
- Total addresses = 2^(32-N)
- Usable hosts = 2^(32-N) - 2 (subtract network address and broadcast)

```bash
# Useful commands:
ipcalc 192.168.1.0/24         # shows network, broadcast, host range, mask
sipcalc 10.0.0.0/20           # extended subnet calculator
python3 -c "import ipaddress; n=ipaddress.IPv4Network('10.0.0.0/20'); print(n.num_addresses)"
```

**In AWS context:**
- VPC: typically /16 (65,536 IPs)
- Subnets: typically /24 (256 IPs) per AZ
- AWS reserves 5 IPs per subnet (first 4 + last 1)
- So /24 → 251 usable for instances

---

### Q4: Coding Problem — Max Occurred Number in Array

**Problem:** Find the number(s) with maximum occurrences. If multiple numbers tie for max, return all of them.

**Example:**
```
Input:  [1, 2, 2, 3, 3, 4]
Output: [2, 3]   (both appear twice — tied for max)

Input:  [1, 1, 1, 2, 2]
Output: [1]      (appears 3 times — clear winner)
```

**Solution (Python):**
```python
from collections import Counter

def max_occurred(arr):
    if not arr:
        return []
    
    counts = Counter(arr)           # {2: 2, 3: 2, 1: 1, 4: 1}
    max_count = max(counts.values())  # 2
    
    return [num for num, cnt in counts.items() if cnt == max_count]

# Test
print(max_occurred([1, 2, 2, 3, 3, 4]))   # [2, 3]
print(max_occurred([1, 1, 1, 2, 2]))       # [1]
print(max_occurred([5, 5, 5]))             # [5]
print(max_occurred([]))                    # []
```

**Alternative — without Counter (manual HashMap):**
```python
def max_occurred_manual(arr):
    if not arr:
        return []
    
    freq = {}
    for num in arr:
        freq[num] = freq.get(num, 0) + 1
    
    max_count = max(freq.values())
    return [num for num, cnt in freq.items() if cnt == max_count]
```

**Complexity:**
- Time: O(n) — single pass to build frequency map, single pass to find max
- Space: O(k) where k = number of unique elements

**Go solution:**
```go
func maxOccurred(arr []int) []int {
    freq := make(map[int]int)
    for _, v := range arr {
        freq[v]++
    }
    
    maxCount := 0
    for _, cnt := range freq {
        if cnt > maxCount {
            maxCount = cnt
        }
    }
    
    var result []int
    for num, cnt := range freq {
        if cnt == maxCount {
            result = append(result, num)
        }
    }
    return result
}
```
