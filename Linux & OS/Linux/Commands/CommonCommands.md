# Common Linux Commands — Quick Reference

> A comprehensive reference of the most commonly used Linux commands. Organized by category for quick lookup during interviews and on-the-job troubleshooting.

---

## Output & File Reading

```bash
# echo
echo "Hello"                 # print with newline
echo -n "Hello"              # print without newline
echo -e "Line1\nLine2"       # interpret escape sequences (\n, \t, \\, \r)
echo -e "Tab\tSeparated"

# cat — display file contents
cat file.txt                 # display file
cat file1 file2              # concatenate two files
cat -n file.txt              # show line numbers

# less / more — pager for large files
less file.txt                # /word = search forward, ?word = search backward, n = next, q = quit
more file.txt                # page by page, space to advance

# head / tail
head -n 20 file              # first 20 lines
tail -n 20 file              # last 20 lines
tail -f /var/log/app.log     # follow file (stream new lines — for watching logs live)

# tee — read stdin, write to stdout AND file simultaneously
ls | tee output.txt          # print ls output to screen AND save to file
command | tee -a log.txt     # -a = append instead of overwrite
```

---

## File & Directory Operations

```bash
# Navigation
pwd                           # print working directory
cd /var/log                   # change directory
cd -                          # go to previous directory
cd ~                          # home directory

# Listing
ls                            # list current dir
ls -la                        # long format, including hidden files
ls -lah                       # with human-readable sizes
ls -lt                        # sorted by time (newest first)
ls -lS                        # sorted by size

# Create / Delete
touch file.txt                # create empty file or update timestamp
touch file{1..10}             # create file1 through file10 (brace expansion)
mkdir mydir                   # create directory
mkdir -p a/b/c                # create parent directories as needed (-p)
mkdir -m 755 mydir            # create with specific permissions
rm file.txt                   # delete file
rm -rf mydir                  # delete directory recursively (DANGEROUS — no confirmation)
rmdir mydir                   # delete empty directory only

# Copy / Move / Rename
cp fileA fileB                # copy file
cp -r srcdir destdir          # copy directory recursively
mv fileA fileB                # rename or move file
mv dir_1 dir_2 new_dir/       # move multiple dirs into new_dir/

# File information
file filename                 # determine file type (binary, text, compressed, etc.)
wc -l file                    # count lines
wc -w file                    # count words
wc -c file                    # count bytes

# Text processing
sort file                     # sort lines alphabetically
sort -r file                  # reverse sort
sort -n file                  # numeric sort
sort file | uniq              # remove duplicate lines (must be sorted first)
split -l 1000 file parts_     # split into 1000-line chunks (parts_aa, parts_ab, ...)
cut -d, -f1 file.csv          # extract first column of CSV
awk '{print $2}' file         # print second field (whitespace-delimited)
awk -F, '{print $1}' file.csv # print first CSV column
diff -u fileA fileB           # unified diff between two files
cmp fileA fileB               # compare files byte-by-byte (silent if identical)
```

---

## Compression & Archives

```bash
# gzip
gzip file                    # compress (replaces original with file.gz)
gzip -k file                 # compress, KEEP original (-k)
gzip -d file.gz              # decompress
gunzip file.gz               # same as gzip -d

# tar
tar -czf archive.tar.gz dir/ # compress directory to tar.gz (c=create, z=gzip, f=filename)
tar -xzf archive.tar.gz      # extract tar.gz (x=extract)
tar -tzf archive.tar.gz      # list contents without extracting
tar -xzf archive.tar.gz -C /target/  # extract to specific directory

# zip
zip files.zip file1 file2    # create zip
zip -r files.zip dir/        # zip directory recursively
unzip files.zip              # extract
unzip -l files.zip           # list contents

# View compressed files without extracting
zcat file.gz                 # cat a gzipped file
zgrep "pattern" file.gz      # grep inside gzipped file
```

---

## Process Management

```bash
# View processes
ps aux                       # all processes (BSD format)
ps -ef                       # all processes (Unix format)
ps aux --sort=-%cpu | head   # top CPU consumers
pgrep nginx                  # find PID by process name

# Control processes
kill -9 PID                  # force kill (SIGKILL)
kill -15 PID                 # graceful kill (SIGTERM, default)
pkill nginx                  # kill by process name
nohup ./script.sh > /dev/null & # run in background, immune to hangup

# Job control
jobs                         # list background jobs in current shell
bg                           # resume stopped job in background
fg                           # bring background job to foreground
Ctrl+Z                       # suspend current foreground job
```

---

## System Information & Monitoring

```bash
# System identity
hostname                     # show hostname
uname -a                     # OS name, kernel version, architecture
arch                         # CPU architecture (x86_64, arm64, etc.)
cat /etc/os-release          # detailed OS info

# Resources
uptime                       # system uptime and load averages
free -h                      # RAM usage (human-readable)
df -h                        # disk usage per filesystem
du -h /var/log               # disk usage of a directory
du -sh *                     # size of each item in current dir
lsblk                        # list block devices and partitions
top                          # live CPU/memory/process view
top -bn1                     # non-interactive one-shot (for scripting)

# Hardware info
cat /proc/cpuinfo            # CPU details
cat /proc/meminfo            # detailed memory info
cat /proc/loadavg            # load averages
```

---

## Networking Commands

```bash
ping -c 4 google.com         # test connectivity (4 packets)
traceroute google.com        # trace network path (hops to destination)
telnet ip port               # test TCP connectivity to port
curl -I https://example.com  # HTTP headers only
wget -O output.txt url       # download file, save as output.txt
netstat -putan | grep 8080   # check if port 8080 is open
ss -tlnp                     # modern alternative to netstat
```

---

## User & Permissions

```bash
whoami                       # current username
id username                  # user ID, group ID, groups
printenv                     # print all environment variables
printenv PATH                # print specific variable

# User management
useradd username             # create user
passwd username              # set/change password
passwd -e username           # force password change on next login
userdel username             # delete user
usermod -aG docker username  # add user to group
groupadd groupname           # create group
groupdel groupname           # delete group

# Permissions
chmod 755 file               # set permissions (rwxr-xr-x)
chmod u+x script.sh          # add execute for owner
chown user:group file        # change owner and group
chgrp group file             # change group only
su - username                # switch user
sudo command                 # run as root
```

---

## System Services & Scheduling

```bash
# systemctl — manage services
systemctl start nginx        # start service
systemctl stop nginx         # stop service
systemctl restart nginx      # restart
systemctl status nginx       # show status + recent logs
systemctl enable nginx       # start on boot
systemctl disable nginx      # don't start on boot
systemctl list-units --type=service --all  # list all services

# Scheduling
at 3pm                       # run command at specific time (interactive)
crontab -e                   # edit user crontab
crontab -l                   # list user crontab

# Process priority
nice -n 10 ./script.sh       # run with lower priority (+10)
renice +10 -p PID            # change priority of running process
```

---

## Useful Utilities

```bash
# Search
history                      # command history
history | grep ssh           # find previous SSH commands
!42                          # re-run command #42 from history
!!                           # re-run last command
sudo !!                      # re-run last command with sudo

# Reference
man ls                       # manual page for ls
which python3                # find path of executable
type ls                      # show if ls is alias/function/binary
alias ll='ls -la'            # create a command alias

# Calculation
bc                           # basic calculator (type expressions, Ctrl+D to exit)
echo "3.14 * 2" | bc        # calculate inline

# Date
date                         # current date and time
cal 3 2024                   # calendar for March 2024

# Misc
xargs                        # build commands from stdin
ls *.log | xargs rm          # delete all .log files
shred --remove file          # securely delete file (overwrite before delete)
quota -u username            # disk quota for user
truncate -s 0 file           # empty file (set size to 0 without deleting)
```

---

## Interview Q&A

**Q: What's the difference between `>` and `>>` for output redirection?**
`>` overwrites the target file (creates if not exists, truncates if exists). `>>` appends to the file (creates if not exists, adds to end if exists). Use `>>` for logs where you want to accumulate output: `echo "$(date): done" >> run.log`. Use `>` when you want to replace the output: `cat newfile > config.txt`. A common mistake is using `>` on a file you're still reading from the same command — this truncates the file before the command reads it.

**Q: What does `tail -f` do and when do you use it?**
`tail -f` "follows" a file — it continuously reads and prints new lines as they're appended. Essential for watching live logs: `tail -f /var/log/nginx/access.log`. More advanced: `tail -F` (capital F) also handles file rotation — if the log file is rotated (deleted and recreated), `-F` reopens the new file, while `-f` stops. In Kubernetes: `kubectl logs -f pod-name` is the equivalent for pod logs.

**Q: What's the difference between `kill -9` and `kill -15`?**
`kill -15` (SIGTERM) is a polite termination request — the process receives it and can handle it gracefully (flush buffers, close connections, clean up). `kill -9` (SIGKILL) is delivered by the kernel directly — the process cannot catch or ignore it and is immediately terminated. Always try SIGTERM first (wait a few seconds), then escalate to SIGKILL. Using SIGKILL immediately can corrupt files, leave open connections, or cause zombie children.

**Q: How do you run a process that keeps running after you log out?**
`nohup ./script.sh > output.log 2>&1 &` — `nohup` makes the process immune to the SIGHUP signal sent when your terminal closes; `&` runs it in the background; `> output.log 2>&1` redirects both stdout and stderr to a log file (otherwise output goes to `nohup.out`). Alternatively: use `screen` or `tmux` to create persistent sessions, or run as a `systemd` service for proper process management on restart.
