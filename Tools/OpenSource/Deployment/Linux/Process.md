# What is a Process in Linux?

- A process is an instance of a running program.
- Every process has:
    - A PID (Process ID)
    - A PPID (Parent Process ID)
    - A UID (User ID – who owns it)
    - A state (Running, Sleeping, Zombie, etc.)
    - Its own memory space
    - Access to system resources (CPU, files, sockets)

- A process is created using fork(), exec(), or a shell command (like ls, top, python).
    - fork() 
        - fork() is a system call in C that creates a copy of the current process.
        - The new process is called the child process, and the original is the parent.
        - Both processes continue executing from the same point, but they have different PIDs.
    - exec()
        - exec() replaces the current process with a new program.
        - It does not create a new PID — it just loads new code into the existing process memory.
        - Typically used after fork() by the child to run a new program.
    - shell
        - The shell (like bash) is a process.
        - The shell calls fork() to create a child.
        - The child then calls exec() to load and run the /bin/ls binary.
        - The parent shell waits until the child process exits.
  
- Every process starts as a child of another process.


# Process Lifecycle

1. Creation – via fork(), clone(), or shell.

2. Running – scheduled by the kernel.

3. Waiting – for I/O or other resources.

4. Stopped – paused, maybe by a signal.

5. Zombie – terminated, but parent hasn’t read its exit status.

6. Terminated – complete and cleaned up.


# Viewing Processes

```
Command	             Description
ps aux	             List all running processes
top / htop	         Live monitoring of CPU/memory usage
pidof <program>	     Get PID of a running process
pgrep <name>	     Search processes by name
pstree	             Show process tree
watch	             Rerun a command every few seconds
```

# Process States

- Linux process states include:
```
    - R (Running) – currently using CPU
    - S (Sleeping) – waiting for event (interruptible) ex. - bash shell waithing for input
    - D (Uninterruptible sleep) – usually I/O wait
    - T (Stopped) – paused by job control
    - Z (Zombie) – terminated, but not reaped
```

- flags:
```
| Flag  | Meaning                                                      |
| ----- | ------------------------------------------------------------ |
| **s** | The process is a **session leader** (e.g., a login shell)    |
| **+** | Process is in the **foreground process group** of a terminal |
| **<** | High-priority (not nice to others)                           |
| **N** | Low-priority (nice value > 0)                                |
| **l** | Multi-threaded (uses `CLONE_THREAD`)                         |
```
 

- A process enters D state when it is:
    - Waiting for I/O, such as:
    - Reading from a slow or blocked disk
    - Waiting for a network mount (NFS) to respond
    - Accessing a hardware device (USB, disk, etc.)
- And cannot be killed or Ctrl+C’ed during this time

- A zombie process is:
    - A process that has finished execution
    - But still has an entry in the process table
    - Because its parent hasn’t “reaped” it (i.e., hasn't called wait())
    - The parent must call wait() to read and clear it
    - Until then, the child is a zombie
    - If the parent dies before reaping, init (PID 1) adopts and reaps the zombie.
`Zombie = dead, but not buried 💀`



check using 
`ps -eo pid,stat,cmd`

# System Resources Managed by Processes

**a. CPU Usage**

- Processes get time slices on CPU via the scheduler.

- You can prioritize using nice and renice.
  
```
nice -n 10 myscript.sh   # Lower priority
renice -n -5 -p 1234     # Increase priority for PID 1234
Nice value: -20 (high) to 19 (low)
Real-time processes have fixed priorities
```

**b. Memory**

- Each process has:

    - Code (text) segment

    - Heap (dynamic allocation)

    - Stack (function calls, local vars)

    - Data segment (global/static vars)

- Monitored with:

`top, htop, vmstat, /proc/<pid>/status`

**c. I/O (Disk/Network)**

- File handles, sockets, pipes
- inode:
  - Every file in Linux is represented by a data structure called an inode.
  - An inode contains metadata about a file:
- View open files:
`lsof -p <pid>`
- Linux treats everything (files, sockets, pipes, devices) as a file. lsof shows which process has which files (or sockets) open.
```
- Problem: A log file can't be deleted (rm says file in use)
- Solution:
    `lsof | grep my.log`
    - Find which process has it open, kill or restart it.
```

- Types of I/O:
    - Disk I/O → Reading/writing files, logs, databases, etc.
    - Network I/O → Sending/receiving data over sockets (HTTP, TCP, etc.)
    - Interprocess I/O → Pipes, FIFOs, etc.

**d. File Descriptors**

- Each process gets a limited number of file descriptors (0 = stdin, 1 = stdout, 2 = stderr)

- Check with:
`ls /proc/<pid>/fd`


# Signals and Process Control

- Signals are used to communicate with processes:
```
Signal	        Description
SIGKILL (9)	    Force kill, can’t be caught
SIGTERM (15)	Graceful termination
SIGSTOP	        Pause
SIGCONT	        Resume
```

- Send signals using:
```
kill -SIGTERM <pid>
kill -9 <pid>         # SIGKILL
```

# Foreground vs Background Processes

- Foreground – Blocks the shell
- Background – Frees the shell
- Manage with:
    - jobs → list jobs
    - fg %1 → bring to foreground
    - bg %1 → resume in background

# /proc File System

- Each process has a virtual folder under /proc/<pid>/
- Key files:
    - /proc/<pid>/cmdline –        Command
    - /proc/<pid>/status  –        Memory, state
    - /proc/<pid>/fd/     –        File descriptors
    - /proc/meminfo       –        System memory info
    - /proc/cpuinfo       –        CPU details

# Threads 

- A thread is the smallest unit of execution in a process.
  
- Every process has at least one thread — the main thread. 

- A process is independent; has its own memory.

- A thread is a lightweight sub-process; shares memory.

- One thread crash can affect all

- Every thread in Linux has a TID (Thread ID).

- The main thread's TID is the same as the PID of the process.

- Other threads have their own TIDs, but belong to the same process.

- Use `ps -T -p <pid>` to see threads.

- Multithreaded apps (like browsers, JVM, etc.) spawn many threads.

- Example: A web server might spawn a new thread for each client request to improve concurrency.

** Common Pitfalls with Threads**
- Race conditions: Two threads accessing the same variable at the same time.

- Deadlocks: Two or more threads wait indefinitely for each other. Ex. one blockes a res1 and waiting for res2 , second is blocking res2 and waiting for res1

- Starvation: One thread never gets CPU time.

- Context switching: Too many threads can lead to performance issues.

# Resource Limits (ulimits)

- You can limit process resource usage with ulimit.
```
ulimit -a          # View all
ulimit -n 4096     # Max open files
ulimit -u 2048     # Max user processes
```

- Persistent settings can be added to:
    - /etc/security/limits.conf
    - ~/.bashrc or /etc/profile


# Orphan & Zombie Processes

- Zombie: Process has exited but still has an entry in process table (PPID hasn't collected it)
- Orphan: Parent has exited; init (PID 1) adopts it


# Troubleshooting Tools

```
Tool	            Use
strace	            Trace system calls by a process
lsof	            List open files by process
iotop	            Monitor I/O usage
vmstat	            Virtual memory stats
dstat	            Versatile resource monitor
perf	            Advanced performance analysis
pidstat	            Per-process CPU and I/O stats
```