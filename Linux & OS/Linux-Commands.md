# ⚡ Linux Commands — Full Reference
**Comprehensive command slides with flags, examples, and DevOps use cases**

---

# 🗂️ File Operations

---

# 📁 ls — List Files

```bash
ls                        # basic listing
ls -l                     # long format (permissions, size, owner, date)
ls -la                    # include hidden files (starting with .)
ls -lh                    # human-readable sizes (K, M, G)
ls -ltr                   # sort by modification time, oldest first (-r reverses)
ls -lS                    # sort by file size (largest first)
ls -R                     # recursive listing of all subdirectories
ls -d */                  # only directories
ls -i                     # show inode numbers
ls --color=auto           # colorize output (type-based)
ls -1                     # one file per line (good for piping)
```

**Reading `ls -la` output:**
```
drwxr-xr-x  3 ubuntu devs 4096 Jan 15 09:22 project/
-rw-r--r--  1 ubuntu devs 1234 Jan 15 09:20 config.yaml
lrwxrwxrwx  1 ubuntu devs   15 Jan 15 09:18 latest -> /opt/app/v2.1/
```
- Column 1: type + permissions (d=dir, -=file, l=symlink)
- Column 2: hard link count
- Columns 3-4: owner, group
- Column 5: size in bytes (or blocks for dirs)
- Column 6-8: last modification time
- Column 9: name (symlink shows target after `->`)

**Practical patterns:**
```bash
ls -ltr /var/log/nginx/      # see which log was modified most recently
ls -lhS /var/log/ | head -10 # find top 10 largest log files
ls -la ~/.ssh/               # check SSH key permissions
```

---

# 🔍 find — Search the Filesystem

**Basic syntax:** `find <path> <conditions> <actions>`

**By name:**
```bash
find . -name "*.log"              # case-sensitive match
find . -iname "*.LOG"             # case-insensitive
find . -name "app*"               # wildcard prefix
find /etc -name "sshd*"           # find SSH config files
```

**By type:**
```bash
find . -type f                    # regular files only
find . -type d                    # directories only
find . -type l                    # symbolic links only
find /dev -type b                 # block devices
find /dev -type c                 # character devices
```

**By time:**
```bash
find /var/log -mtime +7           # modified more than 7 days ago
find /var/log -mtime -1           # modified in the last 24 hours
find . -mmin -30                  # modified in the last 30 minutes
find . -newer reference.txt       # modified more recently than reference.txt
find . -atime +30                 # last accessed > 30 days ago (candidates for cleanup)
```

**By size:**
```bash
find / -size +100M                # larger than 100MB
find . -size -10k                 # smaller than 10KB
find /var -size +1G -type f       # files over 1GB
find . -size +50M -size -500M     # between 50M and 500M
```

**By permissions/owner:**
```bash
find / -perm /4000 -type f        # SUID files (security audit)
find / -perm /2000 -type f        # SGID files
find /home -perm 777              # world-writable files (security risk)
find /home -user alice            # all files owned by alice
find /var -group www-data         # files owned by group www-data
find . -perm -u+x                 # files where owner has execute permission
```

**Actions:**
```bash
find . -name "*.log" -delete                  # delete found files
find . -name "*.tmp" -exec rm {} \;           # exec command on each (one at a time)
find . -name "*.log" -exec gzip {} \;         # compress all logs
find . -type f -exec ls -lh {} +              # exec on many at once (faster)
find . -name "*.conf" -ok rm {} \;            # exec with confirmation prompt
find . -name "*.py" -exec grep -l "TODO" {} + # find py files containing TODO
```

**Combining conditions:**
```bash
find . -type f -name "*.sh" -a -perm -u+x    # AND: shell scripts that are executable
find . -name "*.log" -o -name "*.tmp"         # OR: logs or tmp files
find . ! -name "*.py"                          # NOT: everything except .py files
find . -name "*.log" -not -mtime -7           # logs older than 7 days
```

**Depth control:**
```bash
find . -maxdepth 1 -type f        # only current directory (no recursion)
find . -maxdepth 2 -name "*.conf" # at most 2 levels deep
find . -mindepth 2 -name "*.log"  # skip top-level files
find . -path "./node_modules" -prune -o -name "*.js" -print  # skip node_modules
```

**Practical DevOps use cases:**
```bash
# Clean up old logs
find /var/log -name "*.log" -mtime +30 -delete

# Find all world-writable files (security audit)
find / -perm -o+w -type f -not -path "/proc/*" -not -path "/sys/*"

# Find large files consuming disk space
find / -size +100M -type f -exec ls -lh {} \; 2>/dev/null | sort -k5 -rh

# Find config files modified in the last hour (who changed what?)
find /etc -mmin -60 -type f

# Compress logs older than 7 days
find /var/log/app -name "*.log" -mtime +7 -exec gzip {} \;
```

> ✅ Rule: Always use `-maxdepth` when searching from `/` to avoid scanning `/proc` and `/sys`. Or use `-not -path "/proc/*"` to exclude them.

---

# ✂️ grep — Search File Contents

```bash
grep "pattern" file               # basic search
grep "pattern" file1 file2        # search multiple files
grep -r "pattern" /path/          # recursive search in directory
grep -rn "pattern" /path/         # with line numbers
```

**Key flags:**
```bash
grep -i "error" app.log           # case-insensitive
grep -v "DEBUG" app.log           # invert: lines NOT matching
grep -n "ERROR" app.log           # show line numbers
grep -c "ERROR" app.log           # count matching lines
grep -l "pattern" /var/log/*.log  # only print filenames (not matches)
grep -L "pattern" /var/log/*.log  # files WITHOUT the pattern
grep -w "error" app.log           # whole word only (not "errors", "Xerror")
grep -x "exact line" file         # match entire line
grep -o "pattern" file            # print only matched part, not whole line
grep -q "pattern" file            # quiet mode (just exit code: 0=found, 1=not)
grep -s "pattern" file            # suppress "no such file" errors
```

**Context lines:**
```bash
grep -A 3 "ERROR" app.log         # 3 lines After match
grep -B 3 "ERROR" app.log         # 3 lines Before match
grep -C 5 "CRITICAL" app.log      # 5 lines before AND after
```

**Regular expressions:**
```bash
grep -E "error|fail|warn" app.log         # extended regex (OR)
grep -E "^\d{4}-\d{2}-\d{2}" app.log     # lines starting with date
grep -P "(?i)error" app.log               # Perl-compatible regex (PCRE)
grep "^ERROR" app.log                      # anchored at start of line
grep "\.log$" file                         # anchored at end
grep "[0-9]\{3\}" file                    # exactly 3 digits (BRE)
egrep "[0-9]{3}" file                     # same with ERE
```

**Practical DevOps patterns:**
```bash
# Count errors in today's log
grep -c "ERROR" /var/log/app/$(date +%Y-%m-%d).log

# Find all unique IPs that hit nginx with 5xx errors
grep " 5[0-9][0-9] " /var/log/nginx/access.log | grep -oE "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | sort | uniq -c | sort -rn

# Find config files containing a specific value
grep -rl "password" /etc/ 2>/dev/null

# Search compressed logs
zgrep "ERROR" /var/log/app/app.log.gz

# Highlight matches while still showing full line
grep --color=always "ERROR" app.log | less -R

# Find processes by name (avoid matching grep itself)
ps aux | grep "[n]ginx"           # bracket trick: matches nginx but not [n]ginx
```

> ✅ Rule: `grep -r` on `/` is slow. Prefer `find + grep` with constraints, or use `ripgrep (rg)` which is 10x faster and respects `.gitignore`.

---

# 🔄 sed — Stream Editor

```bash
# Basic substitution
sed 's/old/new/' file             # replace first occurrence per line
sed 's/old/new/g' file            # replace ALL occurrences per line (global)
sed 's/old/new/2' file            # replace only 2nd occurrence
sed 's/old/new/gi' file           # global + case-insensitive

# In-place editing
sed -i 's/old/new/g' file                # DANGER: overwrites file directly
sed -i.bak 's/old/new/g' file            # safe: creates file.bak backup first
sed -i'' 's/old/new/g' file             # macOS syntax (empty string for no extension)
```

**Line operations:**
```bash
sed -n '5p' file                  # print line 5 only (-n suppresses default)
sed -n '5,10p' file               # print lines 5-10
sed -n '$p' file                  # print last line
sed '5d' file                     # delete line 5
sed '5,10d' file                  # delete lines 5-10
sed '/pattern/d' file             # delete lines matching pattern
sed '/DEBUG/d' app.log            # remove debug lines from log
sed '/^$/d' file                  # remove blank lines
sed '/^#/d' file                  # remove comment lines
```

**Between patterns:**
```bash
sed -n '/START/,/END/p' file      # print everything between START and END
sed '/BEGIN/,/END/d' file         # delete everything between markers
```

**Insertions:**
```bash
sed 's/^/PREFIX: /' file          # add prefix to every line
sed 's/$/ SUFFIX/' file           # add suffix to every line
sed '5a\new line text' file       # append line after line 5
sed '5i\new line text' file       # insert line before line 5
sed '1s/^/header\n/' file         # insert header at top
```

**Practical DevOps examples:**
```bash
# Update a config value in place
sed -i 's/port=8080/port=9090/' /etc/app/config.properties

# Remove all comments and blank lines for cleaner output
sed '/^#/d; /^$/d' /etc/ssh/sshd_config

# Extract specific block from config
sed -n '/\[database\]/,/\[/p' config.ini | head -n -1

# Replace a specific line containing a pattern
sed -i '/^JAVA_OPTS=/c\JAVA_OPTS="-Xmx2g -Xms512m"' /etc/app/env

# Add a line after a match
sed -i '/server_name example.com;/a\    return 301 https://$host$request_uri;' nginx.conf
```

> ⚠️ Watch out: `sed -i` without a backup suffix permanently modifies files. Always use `-i.bak` in scripts, especially in production. Test with `sed -n 's/.../.../p' file` first to see what would change.

---

# 📊 awk — Pattern Scanning and Processing

```bash
awk '{print}' file                # print all lines (like cat)
awk '{print $1}' file             # print first field (space-separated)
awk '{print $NF}' file            # print last field (NF = number of fields)
awk '{print $1, $3}' file         # print fields 1 and 3
awk -F: '{print $1}' /etc/passwd  # use colon as separator
awk -F, '{print $2}' data.csv     # CSV processing
awk 'NR==5' file                  # print only line 5
awk 'NR>=5 && NR<=10' file        # print lines 5-10
```

**Built-in variables:**
```bash
awk '{print NR": "$0}' file       # NR = row number, $0 = whole line
awk 'END{print NR}' file          # print total line count
awk '{print NF}' file             # print number of fields per line
awk 'NF>0' file                   # skip empty lines
```

**Conditions:**
```bash
awk '$3 > 100 {print $1, $3}' file        # print if field 3 > 100
awk '$1 == "ERROR" {print $0}' app.log    # lines where field 1 is ERROR
awk '/pattern/ {print $0}' file           # lines matching regex
awk '!/pattern/ {print}' file             # lines NOT matching
awk '$5 ~ /nginx/ {print NR, $0}' file   # field 5 matches regex
```

**Arithmetic:**
```bash
awk '{sum += $3} END {print "Total:", sum}' data
awk '{sum += $3; count++} END {print "Average:", sum/count}' data
awk 'NR>1 {total += $2} END {printf "Sum: %d\nAvg: %.2f\n", total, total/(NR-1)}' file
```

**Output formatting:**
```bash
awk 'BEGIN{OFS=","} {print $1,$2,$3}' file     # change output field separator
awk 'BEGIN{OFS="\t"} {print $1,$2}' file       # tab-separated output
awk '{printf "%-20s %5d\n", $1, $2}' file      # formatted output
```

**Practical DevOps examples:**
```bash
# Parse nginx access log: IP, status, size
awk '{print $1, $9, $10}' /var/log/nginx/access.log

# Find IPs with more than 100 requests
awk '{print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -rn | awk '$1 > 100'

# Sum disk usage from du output
du -sh /var/log/* | awk '{sum += $1} END {print sum "K total"}'

# Extract specific field from ps output
ps aux | awk 'NR>1 {print $1, $2, $11}' | sort -k1

# Process CSV and format as table
awk -F, 'NR==1{next} {printf "%-20s %-10s %s\n", $1, $2, $3}' data.csv

# Find lines where a number exceeds threshold
awk -F: '$5 > 99000 {print $1, "expires soon"}' /etc/shadow
```

> 💡 Takeaway: Use `awk` when you need column-based processing or math. Use `sed` for line-based text substitution. Use `grep` for pattern matching only.

---

# 🗂️ Text Utilities

---

# 🔢 sort, uniq, wc, cut, tr

**sort:**
```bash
sort file                         # alphabetical ascending
sort -r file                      # reverse (descending)
sort -n file                      # numeric sort
sort -rn file                     # numeric descending (for sizes, counts)
sort -k2 file                     # sort by 2nd column
sort -k2 -n file                  # sort by 2nd column numerically
sort -t: -k3 -n /etc/passwd       # colon-separated, sort by UID (column 3)
sort -u file                      # sort + remove duplicates
sort file | uniq                  # same as -u
sort -h file                      # human-readable sizes (1K, 2M, 3G)
```

**uniq:**
```bash
sort file | uniq                  # remove duplicates (must be sorted first)
sort file | uniq -c               # count occurrences of each line
sort file | uniq -d               # show only duplicate lines
sort file | uniq -u               # show only unique lines (appear once)
sort file | uniq -c | sort -rn    # most frequent lines first
```

**wc:**
```bash
wc -l file                        # line count
wc -w file                        # word count
wc -c file                        # byte count
wc -m file                        # character count
wc file                           # all three (lines, words, bytes)
cat file | wc -l                  # count lines from stdin
ls /etc | wc -l                   # count files in /etc
```

**cut:**
```bash
cut -d: -f1 /etc/passwd           # delimiter=colon, field 1 (usernames)
cut -d: -f1,3 /etc/passwd         # fields 1 and 3
cut -d, -f2 data.csv              # CSV second column
cut -c1-10 file                   # characters 1 to 10 of each line
cut -c5- file                     # from character 5 to end
```

**tr:**
```bash
tr 'a-z' 'A-Z' < file            # lowercase to uppercase
tr 'A-Z' 'a-z' < file            # uppercase to lowercase
tr -d '\r' < windows.txt > unix.txt  # remove Windows carriage returns
tr -d ' ' < file                  # remove all spaces
tr -s ' ' < file                  # squeeze multiple spaces to one
tr ',' '\t' < file.csv            # replace commas with tabs
echo "hello" | tr 'aeiou' '*'    # replace vowels with *
```

---

# 🔀 Pipelines: xargs, tee, head, tail

**xargs — build command args from stdin:**
```bash
find . -name "*.log" | xargs rm                    # delete all .log files
find . -name "*.py" | xargs grep -l "TODO"         # find py files with TODO
echo "a b c" | xargs -n1 echo                      # one arg per invocation
cat hosts.txt | xargs -I{} ssh {} 'uptime'         # {} as placeholder
find . -type f | xargs -P4 gzip                    # 4 parallel workers
find . -name "*.tmp" | xargs -r rm                 # -r: do nothing if input empty
```

**tee — write to file AND pass through:**
```bash
command | tee output.txt                           # write to file + stdout
command | tee -a output.txt                        # append to file
command | tee output.txt | grep "ERROR"            # filter after saving
long-script 2>&1 | tee /tmp/script.log            # capture all output
# Useful in CI: see output in real-time AND save it
```

**head/tail:**
```bash
head -n 20 file                   # first 20 lines
tail -n 20 file                   # last 20 lines
tail -f /var/log/nginx/access.log # follow (live streaming) — Ctrl+C to stop
tail -F /var/log/app.log          # follow + reopen if file rotated (-F is smarter)
tail -n +5 file                   # from line 5 to end (skip first 4)
head -n 100 file | tail -n 50     # lines 51-100 (between head and tail)
```

---

# 🗂️ Process Commands

---

# 👁️ ps — Process Status

```bash
ps aux                            # all processes, user format
ps -ef                            # all processes, full format (with PPID)
ps -eo pid,ppid,user,stat,pcpu,pmem,cmd    # custom columns
ps -eo pid,comm,pcpu --sort=-pcpu          # sort by CPU descending
ps -eo pid,comm,pmem --sort=-pmem | head   # top memory consumers
ps -T -p 1234                     # show threads of PID 1234
ps -C nginx                       # processes named "nginx"
ps --ppid 1234                    # children of PID 1234
ps -u ubuntu                      # processes owned by ubuntu user
```

**Reading `ps aux` output:**
```
USER  PID  %CPU  %MEM  VSZ    RSS   TTY  STAT  START  TIME  COMMAND
root  1    0.0   0.1   168M   8M    ?    Ss    Jan01  0:05  /sbin/init
ubuntu 1234 25.0 2.5   512M   200M  pts/0 Sl+  09:00  5:23  python app.py
```
- VSZ = virtual memory size (all mapped, including unused)
- RSS = resident set size (actually in RAM right now)
- STAT: S=sleeping, R=running, D=disk wait, Z=zombie, T=stopped, s=session leader, +=foreground, l=multithreaded

---

# 💀 kill, pgrep, pkill — Process Signals

```bash
# kill — by PID
kill 1234                         # send SIGTERM (default, graceful)
kill -15 1234                     # SIGTERM explicitly
kill -9 1234                      # SIGKILL (force, last resort)
kill -1 1234                      # SIGHUP (reload config)
kill -0 1234                      # check if process exists (no signal sent)
kill -STOP 1234                   # pause process (SIGSTOP)
kill -CONT 1234                   # resume process (SIGCONT)

# killall — by name
killall nginx                     # SIGTERM all nginx processes
killall -9 nginx                  # SIGKILL all nginx
killall -HUP sshd                 # reload sshd config

# pkill — by name or pattern (more flexible)
pkill nginx                       # match by process name
pkill -f "python app.py"          # match by full command line
pkill -u alice                    # kill all alice's processes
pkill -9 -f "defunct_script"      # force kill by command pattern

# pgrep — find PIDs by name
pgrep nginx                       # print PIDs of nginx
pgrep -l nginx                    # print PID and name
pgrep -a nginx                    # print PID and full command
pgrep -u ubuntu                   # all PIDs owned by ubuntu
pgrep -f "python app"             # match full command line
```

> ✅ Rule: Order of escalation: SIGTERM → wait 5-10s → SIGKILL. Many apps (nginx, PostgreSQL, Java) need time after SIGTERM to flush buffers, finish transactions, drain connections. SIGKILL skips all of that.

---

# ⚡ Background Jobs: nohup, jobs, fg, bg

```bash
# Run in background
command &                         # run in background (tied to terminal)
nohup command &                   # run in background, immune to terminal close
nohup command > /tmp/output.log 2>&1 &   # capture output

# Job control
jobs                              # list background/stopped jobs
jobs -l                           # with PIDs
fg                                # bring last job to foreground
fg %1                             # bring job 1 to foreground
bg %1                             # resume stopped job 1 in background
Ctrl+Z                            # pause (SIGSTOP) current foreground job
Ctrl+C                            # terminate (SIGINT) current foreground job

# disown — detach from shell (survives terminal close)
long-command &
disown %1                         # detach job from shell job table
disown -h %1                      # don't send SIGHUP on shell exit
```

---

# 🔬 strace, lsof — Deep Inspection

**strace — trace system calls:**
```bash
strace ls                         # trace all syscalls of ls
strace -c ls                      # summary: count, time per syscall
strace -p 1234                    # attach to running process (live)
strace -p 1234 -e trace=read,write  # only trace specific calls
strace -o /tmp/trace.txt ls       # save output to file
strace -f -p 1234                 # follow child processes
strace -T ls                      # show time spent in each syscall
strace -e trace=network curl https://google.com  # only network calls
```

**Practical strace uses:**
```bash
# Why is this command slow?
strace -c mycommand               # shows which syscalls take most time

# What files does this program open?
strace -e trace=open,openat mycommand 2>&1 | grep -v "ENOENT"

# Is it stuck on a network call?
strace -p 1234 -e trace=network  # attach and watch network calls live
```

**lsof — list open files:**
```bash
lsof                              # ALL open files (overwhelming — filter it)
lsof -p 1234                      # all files opened by PID 1234
lsof -u alice                     # all files opened by user alice
lsof /var/log/nginx/access.log    # who has THIS file open?
lsof +D /var/log/nginx/           # all open files in this directory
lsof -i                           # all network connections
lsof -i :8080                     # what's using port 8080?
lsof -i tcp                       # all TCP connections
lsof -i tcp:80,443                # specific ports
lsof -c nginx                     # files opened by processes named nginx
lsof | grep deleted               # files deleted but still held open (disk leak!)
```

**Critical pattern — disk full but du shows free space:**
```bash
lsof | grep deleted | awk '{print $1, $2, $7}'
# Shows: process_name PID file_size_of_deleted_file
# Fix: restart that process to release the file descriptor
```

---

# 👀 watch — Repeat a Command Periodically

```bash
watch -n 2 "df -h"               # run 'df -h' every 2 seconds
watch -n 1 "ss -tlnp"            # watch open ports every second
watch -d "free -h"               # -d: highlight differences between runs
watch -n 5 "systemctl status nginx"  # monitor service status
watch -n 1 'ps aux | sort -k3 -rn | head'  # live top CPU processes
```

---

# 🗂️ Disk and Storage Commands

---

# 💾 df, du — Disk Space

```bash
# df — filesystem level
df -h                             # all filesystems, human-readable
df -h /                           # just root filesystem
df -i                             # inode usage (can be full even if space free!)
df -h --type=ext4                 # only ext4 filesystems
df -h --total                     # add total line at bottom

# du — directory level
du -sh /var/log                   # summary: total size of directory
du -sh /var/log/*                 # each item in /var/log
du -h --max-depth=1 /var          # one level deep, human-readable
du -ah /var | sort -rh | head -20 # top 20 largest items anywhere under /var
du -sh --exclude='*.git' .        # exclude git objects
```

**Disk full investigation workflow:**
```bash
df -h          # Step 1: which filesystem is full?
du -sh /var/*  # Step 2: find the big directory
du -sh /var/log/*  # Step 3: drill down
lsof | grep deleted  # Step 4: deleted-but-open files
journalctl --disk-usage  # journald consuming space?
journalctl --vacuum-size=500M  # trim journal
```

---

# 🔧 mount, umount, fstab

```bash
# Mount
mount /dev/sdb1 /mnt/data          # mount device to directory
mount -t ext4 /dev/sdb1 /mnt/data  # explicit filesystem type
mount -o ro /dev/sdb1 /mnt/data    # read-only mount
mount -o remount,rw /              # remount root as read-write
mount -a                           # mount everything in /etc/fstab
mount | grep sdb                   # verify mount is active
mount --bind /source /dest         # bind mount (mirror a directory)

# Umount
umount /mnt/data                   # unmount (fails if busy)
umount -l /mnt/data                # lazy unmount (detach when no longer busy)
umount -f /mnt/nfs                 # force (for stuck NFS)
fuser -m /mnt/data                 # find processes using mount point (why busy?)
lsof /mnt/data                     # alternative: see open files on mount
```

**/etc/fstab fields explained:**
```bash
# device    mountpoint  fstype  options       dump  pass
UUID=abc123  /           ext4    defaults       0     1
UUID=def456  /boot       ext4    defaults       0     2
UUID=ghi789  /data       ext4    defaults,nofail 0   2
//server/share /mnt/smb cifs    credentials=/etc/smb,uid=1000 0 0
server:/export /mnt/nfs  nfs     defaults,_netdev,soft,timeo=30 0 0

# pass: 0=no fsck, 1=root (fsck first), 2=other (fsck after root)
# nofail: don't fail boot if device is missing
# _netdev: wait for network before mounting
# soft: NFS gives up after timeout (vs hard which retries forever)
```

---

# 📋 rsync — The Right Way to Copy Data

```bash
# Local copy
rsync -av source/ dest/                          # archive + verbose
rsync -avz source/ dest/                         # with compression
rsync -av --progress source/ dest/               # show progress per file
rsync -av --stats source/ dest/                  # show transfer summary

# Remote copy (over SSH)
rsync -avz source/ user@server:/dest/            # local → remote
rsync -avz user@server:/source/ dest/            # remote → local
rsync -avze "ssh -i ~/.ssh/id_ed25519" source/ user@server:/dest/  # custom key

# Sync options
rsync -av --delete source/ dest/                 # mirror: delete extra in dest
rsync -av --dry-run source/ dest/                # test without making changes
rsync -av --exclude='*.log' source/ dest/        # exclude pattern
rsync -av --exclude-from=.rsyncignore source/ dest/  # exclude from file
rsync -avP source/ dest/                         # -P = --progress + --partial (resume)

# Backup use case
rsync -avz --delete --backup --backup-dir=../backup-$(date +%Y%m%d) source/ dest/
```

> ✅ Rule: Always use `--dry-run` first when using `--delete`. One wrong path with `--delete` can wipe a directory.

---

# 🗂️ Network Commands

---

# 🌐 curl — HTTP Client

```bash
# Basic requests
curl https://api.example.com                       # GET
curl -X POST https://api.example.com               # POST
curl -X PUT https://api.example.com/resource/1     # PUT
curl -X DELETE https://api.example.com/resource/1  # DELETE

# Request body and headers
curl -X POST -H "Content-Type: application/json" \
     -d '{"name":"alice","age":30}' https://api.example.com

curl -H "Authorization: Bearer TOKEN" https://api.example.com

# Response handling
curl -o file.zip https://example.com/file.zip      # save to file
curl -O https://example.com/file.zip               # save with original filename
curl -L https://example.com                        # follow redirects
curl -I https://example.com                        # HEAD only (show headers)
curl -D headers.txt https://example.com            # save response headers

# Debugging
curl -v https://example.com                        # verbose (request + response headers)
curl -vvv https://example.com                      # very verbose (SSL details)
curl -w "\nStatus: %{http_code}\nTime: %{time_total}s\n" https://example.com

# TLS/Auth
curl -k https://self-signed.example.com            # skip SSL verification
curl --cacert /etc/ssl/certs/ca.crt https://internal.example.com
curl -u user:password https://example.com           # basic auth

# Resilience
curl --retry 3 --retry-delay 2 https://api.example.com
curl --connect-timeout 5 --max-time 30 https://api.example.com

# Upload file
curl -F "file=@/path/to/file.txt" https://api.example.com/upload
curl -T file.txt ftp://ftp.example.com/            # FTP upload
```

**Health check pattern:**
```bash
STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://app.example.com/health)
if [ "$STATUS" != "200" ]; then
  echo "Health check failed: $STATUS"
  exit 1
fi
```

---

# 🔌 ss — Socket Statistics

```bash
ss -tunap          # tcp+udp, no-resolve, all, with-process — the most useful
ss -tlnp           # tcp, listening, numeric, with-process (which app owns each port?)
ss -s              # summary stats (total connections by state)

# Filter
ss state established              # only established connections
ss state listening                # only listening sockets
ss -tnp dport :80                 # connections going TO port 80
ss -tnp sport :443                # connections FROM port 443
ss -tnp dst 10.0.0.5              # connections to specific host

# Find what's on a port
ss -tlnp | grep :8080

# Count connections
ss -s                             # summary by state
ss state established | wc -l      # count established TCP connections
ss -tn | awk '{print $1}' | sort | uniq -c  # count by state
```

---

# 🌍 dig — DNS Lookup

```bash
dig google.com                    # full DNS response (A record)
dig +short google.com             # just the IP addresses
dig google.com MX                 # mail records
dig google.com NS                 # nameserver records
dig google.com TXT                # TXT records (SPF, DKIM, etc.)
dig google.com AAAA               # IPv6 records
dig -x 8.8.8.8                    # reverse lookup (IP → hostname)

# Query specific nameserver
dig google.com @8.8.8.8           # query Google's DNS
dig google.com @1.1.1.1           # query Cloudflare's DNS
dig google.com @ns1.google.com    # query authoritative NS

# Trace resolution path
dig +trace google.com             # trace from root NS down (full DNS chain)

# Check TTL
dig +nocmd +noall +answer google.com  # clean output with TTL
```

> ✅ Rule: Use `dig +trace` when DNS resolution is broken — it shows exactly where in the chain (root → TLD → authoritative) resolution fails.

---

# 📡 tcpdump — Packet Capture

```bash
tcpdump -i eth0                          # capture all on eth0
tcpdump -i any                           # all interfaces
tcpdump -i eth0 -n                       # no DNS resolution (faster)
tcpdump -i eth0 port 80                  # only port 80
tcpdump -i eth0 host 192.168.1.100       # only from/to this host
tcpdump -i eth0 src 192.168.1.100        # only FROM this host
tcpdump -i eth0 dst 192.168.1.100        # only TO this host

# Save to file (open in Wireshark)
tcpdump -i eth0 -w /tmp/capture.pcap
tcpdump -r /tmp/capture.pcap             # read back from file

# Combine filters (BPF syntax)
tcpdump -i eth0 'tcp and port 443'
tcpdump -i eth0 'host 10.0.0.5 and port 5432'
tcpdump -i eth0 'tcp and (port 80 or port 443)'
tcpdump -i eth0 'not port 22'            # exclude SSH

# Practical captures
tcpdump -i eth0 -n port 53               # watch DNS queries
tcpdump -i eth0 -n -A port 80 | head -100  # read HTTP traffic (-A = ASCII)
tcpdump -i eth0 -c 1000 -w capture.pcap  # capture exactly 1000 packets
```

---

# 🗂️ System Commands

---

# 🏥 System Info: uname, dmesg, sysctl

```bash
# System info
uname -a           # kernel version, hostname, arch, date
uname -r           # kernel version only
uname -m           # machine architecture (x86_64, aarch64)
hostnamectl        # OS name, kernel, hostname, virtualization type
lscpu              # CPU topology (cores, threads, cache, NUMA)
lsmem              # memory banks
arch               # cpu arch shorthand

# dmesg — kernel ring buffer
dmesg -T           # with human-readable timestamps
dmesg -T -l err    # only errors
dmesg -T | grep -i "fail\|error\|warn\|oom\|kill"
dmesg -w           # follow (like tail -f for kernel messages)
dmesg -C           # clear ring buffer

# sysctl — kernel parameters
sysctl -a                          # all parameters
sysctl net.ipv4.ip_forward         # specific parameter
sysctl -w net.ipv4.ip_forward=1    # set temporarily
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p                          # reload /etc/sysctl.conf

# Common sysctl settings
sysctl vm.swappiness=10            # prefer RAM over swap (0-100, lower=less swap)
sysctl net.core.somaxconn=65535    # max connection backlog
sysctl fs.file-max=2097152         # max open files system-wide
```

---

# 📊 Performance: vmstat, iostat, free

```bash
# vmstat — virtual memory + CPU
vmstat 2 5         # every 2 seconds, 5 iterations
# Key columns:
#   r = processes waiting for CPU (> CPUs = overloaded)
#   b = processes blocked on I/O (D state)
#   si/so = swap in/out per second (non-zero = memory pressure)
#   wa = %CPU idle waiting for I/O (high = disk bottleneck)
#   us/sy = user/system CPU %

# iostat — block device I/O
iostat -x 2        # extended, every 2s
# Key columns:
#   %util = how busy the device is (near 100% = saturated)
#   await = avg wait for I/O request (ms) — <10ms good, >50ms = problem
#   r/s, w/s = reads/writes per second
iostat -x -d sda   # specific device

# free — memory at a glance
free -h             # human readable
free -h -s 2        # refresh every 2 seconds
# Key: watch 'available' column — not 'free' — Linux caches disk in free RAM

# sar — historical stats
sar 1 5            # CPU every 1s, 5 times
sar -r 1 5         # memory stats
sar -b 1 5         # disk I/O stats
sar -n DEV 1 5     # network interface stats
sar -q 1 5         # load average + run queue
sar -u -f /var/log/sa/sa20   # CPU stats from 20th (saved data)
```

---

# 🗂️ User Commands

---

# 👤 User Management

```bash
# Create users
useradd -m -s /bin/bash alice              # create with home dir + bash shell
useradd -m -s /bin/bash -G sudo alice     # also add to sudo group
useradd -r -s /usr/sbin/nologin appuser   # system user, no login
adduser alice                              # interactive (Debian/Ubuntu)

# Modify users
usermod -aG docker alice                   # ADD to docker group (keep existing!)
usermod -aG sudo,docker alice             # add to multiple groups
usermod -s /bin/zsh alice                 # change shell
usermod -d /new/home alice                # change home directory
usermod -l newname alice                  # rename user

# Passwords
passwd alice                              # set password interactively
passwd -e alice                           # expire: force change at next login
passwd -l alice                           # lock account
passwd -u alice                           # unlock account
chage -l alice                            # show password aging info
chage -M 90 alice                         # set password max age 90 days

# Delete
userdel alice                             # delete user (keep home)
userdel -r alice                          # delete user + home dir + mail spool

# Inspect
id alice                                  # UID, GID, all groups
groups alice                              # group memberships
finger alice                              # detailed user info (if installed)
who                                       # who is currently logged in
w                                         # who + what they're doing
last                                      # login history
lastfail                                  # failed login attempts
```

> ⚠️ Watch out: `usermod -G` without `-a` REPLACES all supplementary groups. `usermod -aG` APPENDS. Forgetting `-a` removes a user from all groups except the one you just specified.

---

# 🔐 chmod, chown — Permission Commands

```bash
# chmod — change mode (permissions)
chmod 755 script.sh            # rwxr-xr-x
chmod 644 file.txt             # rw-r--r--
chmod 600 ~/.ssh/id_rsa        # rw------- (required for SSH keys)
chmod 700 ~/.ssh/              # rwx------ (required for .ssh dir)
chmod +x script.sh             # add execute for owner (symbolic)
chmod a+x script.sh            # add execute for ALL
chmod u+x,g-w,o= file          # combine symbolic ops
chmod -R 755 /var/www/html     # recursive

# chown — change owner
chown alice file.txt                    # change owner
chown alice:devs file.txt              # change owner and group
chown :devs file.txt                   # change group only
chown -R ubuntu:ubuntu /home/ubuntu/   # recursive
chown --reference=other.txt file.txt   # copy ownership from reference file

# chgrp — change group
chgrp devs file.txt
chgrp -R www-data /var/www/

# Special permissions
chmod u+s /usr/bin/myapp       # SUID: runs as owner
chmod g+s /shared/             # SGID: files inherit dir's group
chmod +t /tmp/                 # sticky: only owner can delete files

# Find SUID/SGID files (security audit)
find / -perm /4000 -type f 2>/dev/null   # SUID
find / -perm /2000 -type f 2>/dev/null   # SGID
```

---

# 🗂️ Archive Commands

---

# 📦 tar, gzip, zip

```bash
# tar — THE archive command
tar -czf archive.tar.gz dir/           # create: compress with gzip
tar -cjf archive.tar.bz2 dir/          # create: compress with bzip2 (better ratio)
tar -cJf archive.tar.xz dir/           # create: compress with xz (best ratio)
tar -cf archive.tar dir/               # create: no compression

tar -xzf archive.tar.gz               # extract gzip archive
tar -xzf archive.tar.gz -C /target/   # extract to specific dir
tar -xzf archive.tar.gz file.txt       # extract single file

tar -tzf archive.tar.gz               # list contents without extracting
tar -xzf archive.tar.gz --strip-components=1  # strip leading directory

# Useful patterns
tar -czf - /etc/ | ssh user@server "cat > /backup/etc-$(date +%Y%m%d).tar.gz"
tar -czf archive.tar.gz --exclude='*.log' --exclude='.git' dir/

# gzip/gunzip
gzip file                 # compress (replaces file with file.gz)
gzip -k file              # keep original
gzip -d file.gz           # decompress (= gunzip)
gunzip file.gz
gzip -l file.gz           # list: size, compression ratio
zcat file.gz              # read without decompressing
zgrep "pattern" file.gz   # grep inside gz

# zip/unzip
zip archive.zip file1 file2
zip -r archive.zip dir/
zip -r archive.zip dir/ -x "*.git*"
unzip archive.zip
unzip -l archive.zip       # list without extracting
unzip -d /target archive.zip  # extract to directory
```

---

# 🗂️ Interview Q&A — Commands

---

# 🎤 Command Q&A — grep and awk

**Q: How do you find all files containing a pattern recursively, but only show the filenames?**
```bash
grep -rl "pattern" /path/
# -r recursive, -l print only filenames (not the matching lines)
```

**Q: In an nginx access log, how do you find the top 10 IPs making the most requests?**
```bash
awk '{print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -rn | head -10
```

**Q: How do you replace a string in multiple files at once?**
```bash
# Using sed with find:
find . -name "*.conf" -exec sed -i.bak 's/old_value/new_value/g' {} \;

# Or grep to find files first, then sed:
grep -rl "old_value" . | xargs sed -i.bak 's/old_value/new_value/g'
```

**Q: What's the difference between `sed -i` and `sed -i.bak`?**
`sed -i` modifies the file in place with no backup — if you made a mistake, there's no recovery without git. `sed -i.bak` creates a backup with `.bak` extension before modifying. Always use `-i.bak` in scripts touching production files.

---

# 🎤 Command Q&A — Process and System

**Q: How do you run a command that survives terminal close?**
```bash
nohup command > /tmp/output.log 2>&1 &
# or:
command &; disown
# or use tmux/screen to create a persistent terminal session
```

**Q: How do you find which process is using a deleted file (disk not freeing space)?**
```bash
lsof | grep deleted
# Shows: COMMAND PID USER FD TYPE DEVICE SIZE FILE_NAME(deleted)
# Fix: restart that process to close its file descriptor and free the space
```

**Q: What does `2>&1` mean and what order does it matter?**
`2>&1` redirects file descriptor 2 (stderr) to wherever fd 1 (stdout) currently points. Order matters: `command > file 2>&1` sends both stdout and stderr to file. `command 2>&1 > file` sends stderr to terminal (original stdout), then stdout to file — not what you want. `&>` is bash shorthand that always does it correctly: `command &> file`.

**Q: How do you check what system calls a hanging process is waiting on?**
```bash
strace -p <PID>          # attach and watch live system calls
# If it's stuck on read(fd,...) or recv(...) — waiting for network data
# If it's stuck on futex(...) — waiting for a lock (possible deadlock)
# If it's stuck on nanosleep — sleeping in a loop
```

---
