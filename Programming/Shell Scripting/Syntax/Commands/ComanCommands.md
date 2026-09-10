# Common Linux/Shell Commands Reference

> Quick reference for shell scripting and DevOps work. Commands organized by category for fast lookup.

---

## Output and Text Manipulation

```bash
# echo — print text
echo "Hello"              # Hello (with newline)
echo -n "Hello"           # Hello (no newline)
echo -e "Line1\nLine2"    # prints two lines (interprets escape sequences)
echo -e "Tab\tSeparated"  # tab separated
echo -E "No\nInterpret"   # prints: No\nInterpret (no escape processing)

# tee — read from stdin, write to stdout AND a file simultaneously
ls | tee output.txt       # shows ls output on screen AND saves to file
ls | tee -a output.txt    # append mode

# xargs — build commands from stdin
ls | xargs echo           # echo each filename
find . -name "*.txt" | xargs rm    # delete all .txt files

# less and more — page through files
less file.txt             # up/down arrows, / to search, q to quit
more file.txt             # page by page, space for next page

# awk — field-based text processing
awk -F, '{print $1}' file.csv     # print 1st column (comma-delimited)
awk '{print $NF}' file.txt        # print last field
awk 'NR>1 {sum+=$3} END{print sum}' data.txt  # sum 3rd column, skip header

# cut — extract fields/characters
cut -c1-5 file.txt              # characters 1-5 from each line
cut -d, -f1,3 data.csv          # fields 1 and 3, comma-delimited
cut -d: -f1 /etc/passwd         # extract usernames

# tr — translate or delete characters
tr '[:lower:]' '[:upper:]' < file.txt   # uppercase conversion
tr -d '\r' < windows.txt > unix.txt     # remove Windows CRLF
tr -s ' ' < file.txt                    # squeeze multiple spaces

# sed — stream edit
sed -n '5p' file.txt              # print 5th line
sed 's/old/new/g' file.txt        # replace all occurrences
sed '/^#/d' config.txt            # delete comment lines

# bc — calculator
echo "3 * 4" | bc                 # 12
echo "scale=2; 22/7" | bc        # 3.14 (pi approximation)
```

---

## File and Directory Operations

```bash
# Navigation
pwd                         # print working directory
cd /path/to/dir             # change directory
cd ~                        # home directory
cd -                        # previous directory
ls                          # list files
ls -la                      # long listing, including hidden files
ls -lah                     # human-readable sizes
ls -lt                      # sort by modification time

# Create/remove
touch file.txt              # create empty file (or update timestamp)
touch file{1..10}           # create file1 through file10
mkdir dir                   # create directory
mkdir -p a/b/c              # create nested dirs (no error if exists)
mkdir -m 755 mydir          # set permissions while creating
rm file.txt                 # delete file
rm -rf dir/                 # delete directory recursively (dangerous!)
shred --remove file.txt     # permanently delete (overwrite first)

# Copy and move
cp fileA fileB              # copy file
cp -r dir1 dir2             # copy directory recursively
mv file.txt /path/          # move file
mv old.txt new.txt          # rename file
mv dir1 dir2 dir3 dest/     # move multiple items to destination

# View file content
cat file.txt                # print entire file
cat file1 file2             # concatenate and print
head -n 10 file.txt         # first 10 lines
tail -n 10 file.txt         # last 10 lines
tail -f app.log             # follow log (live updates)

# Compare files
cmp fileA fileB             # byte-level comparison (silent if same)
diff -u fileA fileB         # unified diff (shows changes with context)
```

---

## Text Search and Sorting

```bash
# grep — search
grep "word" file.txt               # lines containing "word"
egrep "word1|word2" file.txt       # multiple words (extended regex)
grep -r "pattern" ./src/           # recursive search
grep -n "error" app.log            # show line numbers

# find — find files
find /path -name "filename"        # find by name
find . -name "*.log" -mtime +7 -delete  # delete logs older than 7 days
find . -type f -size +100M         # files larger than 100MB

# locate — faster find (uses database)
sudo updatedb                      # update the locate database
locate filename                    # find file instantly

# sort and uniq
sort file.txt                      # sort alphabetically
sort -r file.txt                   # sort in reverse
sort -n file.txt                   # numeric sort
sort file.txt | uniq               # remove duplicate lines
sort file.txt | uniq -c            # count occurrences of each line

# wc — word/line/char count
wc -l file.txt                     # line count
wc -w file.txt                     # word count
wc -c file.txt                     # byte count

# split — split large files
split -l 1000 bigfile.txt chunk_   # split into 1000-line chunks

# truncate — resize file
truncate -s 0 file.log             # empty the file (same as > file.log)
```

---

## Compression and Archives

```bash
# gzip
gzip file.txt                 # compress → file.txt.gz (removes original)
gzip -k file.txt              # compress, keep original
gzip -d file.txt.gz           # decompress
gunzip file.txt.gz            # decompress (same as gzip -d)

# tar — archive
tar -czf archive.tar.gz dir/      # compress directory
tar -xzf archive.tar.gz           # extract
tar -tzf archive.tar.gz           # list contents without extracting
tar -xzf archive.tar.gz -C /dest/ # extract to specific directory

# zip
zip files.zip file1 file2         # create zip
unzip files.zip                   # extract
unzip -l files.zip                # list contents

# Download
wget https://example.com/file.zip              # download file
wget -O output.txt https://example.com/data    # save with specific name
curl -O https://example.com/file.zip           # download with curl
curl -s https://api.example.com | jq .         # GET API and pretty-print JSON
```

---

## Process Management

```bash
# View processes
ps -ef                         # all processes (full format)
top                            # interactive process monitor
top -b -n1                     # non-interactive, single snapshot
htop                           # improved top (color, easier navigation)

# Kill processes
pgrep nginx                    # get PID of nginx
kill -9 PID                    # force kill
kill -15 PID                   # graceful terminate (SIGTERM)
pkill nginx                    # kill by name

# Background jobs
jobs                           # list background jobs
bg %1                          # resume job 1 in background
fg %1                          # bring job 1 to foreground
nohup ./script.sh > /dev/null &   # run script immune to hangups
Ctrl+Z                         # suspend current job
Ctrl+C                         # interrupt (SIGINT)

# Priority
nice -n 10 ./script.sh         # run with lower priority (+10 nice value)
renice -n -5 PID               # change priority of running process
```

---

## System Information

```bash
# OS and hardware
uname -a                       # kernel version, OS, architecture
cat /etc/os-release            # distro name and version
arch                           # CPU architecture (x86_64, aarch64)
hostname                       # system hostname
uptime                         # system uptime and load averages

# Disk and memory
df -h                          # filesystem disk usage (human-readable)
du -h dir/                     # directory disk usage
du -sh *                       # size of each item in current directory
free -h                        # RAM usage (total/used/free)
lsblk                          # list block devices (disks, partitions)

# Environment
printenv                       # show all environment variables
printenv PATH                  # show a specific variable
echo $VARIABLE                 # print variable value
export VAR=value               # set environment variable for child processes

# Utilities
cal 7 2025                     # show calendar for July 2025
date                           # current date and time
history                        # command history
history | grep docker          # search command history
man command                    # read manual page
which command                  # find executable path
file filename                  # determine file type
stat filename                  # detailed file metadata (size, timestamps, permissions)
```

---

## Networking

```bash
ping google.com                         # check connectivity
ping -c 4 192.168.1.1                   # send exactly 4 pings
traceroute google.com                   # trace network hops
netstat -putan | grep 8080              # check if port 8080 is in use
ss -tlnp                                # show listening TCP sockets
telnet 192.168.1.10 22                  # test TCP connectivity to port 22
scp file.txt user@host:/path/           # secure copy to remote
scp -r dir/ user@host:/path/            # recursive copy
```

---

## Users, Permissions, and Services

```bash
# Users and groups
whoami                              # current username
id user                             # UID, GID, and groups for user
useradd username                    # create user
passwd username                     # set/change password
passwd -e username                  # force password change on next login
userdel username                    # delete user
usermod -aG docker username         # add user to docker group
groupadd groupname                  # create group
groupdel groupname                  # delete group
su - username                       # switch to user (- loads their environment)

# Permissions
chmod 755 file.sh                   # rwxr-xr-x
chmod +x file.sh                    # add execute bit for all
chown user:group file.txt           # change owner and group
chgrp newgroup file.txt             # change group only

# systemd services
systemctl start nginx               # start service
systemctl stop nginx                # stop service
systemctl restart nginx             # restart
systemctl status nginx              # show status
systemctl enable nginx              # start on boot
systemctl list-units --type=service # list all services

# Scheduling
at 3pm                              # run command once at 3pm
crontab -e                          # edit user crontab
crontab -l                          # list user crontab
quota -u user                       # disk quota for user
```

---

## Interview Q&A

**Q: What does `alias` do and how is it useful in scripts?**
`alias` creates a shortcut for a command: `alias ll='ls -lah'`. Aliases are expanded in interactive shells, not in scripts (scripts run in non-interactive mode). For scripts, use functions instead. Aliases are defined in `~/.bashrc` or `~/.zshrc` and only apply to that user's sessions. To remove: `unalias ll`.

**Q: What is the difference between `kill -9` and `kill -15`?**
`kill -15` sends SIGTERM (15) — a graceful shutdown request. The process can catch this signal and clean up (flush buffers, close connections, remove PID files) before exiting. `kill -9` sends SIGKILL (9) — which cannot be caught or ignored by the process. The kernel immediately destroys the process. Always try SIGTERM first; use SIGKILL only if the process doesn't respond. Processes in "D" (uninterruptible sleep) state cannot be killed even with -9.

**Q: What does `find /path -name "*.log" -mtime +7 -delete` do?**
It finds all files matching `*.log` under `/path` that were last modified more than 7 days ago (`-mtime +7`) and deletes them (`-delete`). This is the standard log rotation pattern in scripts. Use `-mtime 7` (exact 7 days) or `-mtime -7` (less than 7 days) for different ranges. Test without `-delete` first to verify which files match. `-exec rm {} \;` is an alternative but `-delete` is faster (no subprocess per file).
