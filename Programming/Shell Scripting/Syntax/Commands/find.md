# find — Search for Files and Directories

> `find` recursively searches a directory tree for files matching specified criteria. Unlike `ls`, it can search nested directories and execute commands on matches.

Syntax: `find /path [options] [expression]`

---

## File Type Filters (`-type`)

```bash
find . -type f          # regular files only
find . -type d          # directories only
find . -type l          # symbolic links only
find . -type c          # character devices (/dev/tty, /dev/null)
find . -type b          # block devices (/dev/sda)
find . -type p          # named pipes (FIFOs)
find . -type s          # sockets
```

---

## Name Matching

```bash
find . -name "*.log"             # case-sensitive name match
find . -iname "*.Log"            # case-insensitive
find . -name "app.py"            # exact filename
find . -name "*.go" -not -name "*_test.go"  # go files, excluding tests
find . -regex ".*/[0-9].*\.log"  # regex match on full path
find . -path "*/templates/*"     # match full path pattern
find . -path "*/node_modules/*" -prune -o -name "*.js" -print  # exclude node_modules
```

---

## Time-Based Filters

```bash
# mtime = modified time, atime = access time, ctime = metadata change time
find . -mtime -1              # modified in last 24 hours (< 1 day)
find . -mtime +7              # modified more than 7 days ago
find . -mtime 0               # modified today (within last 24h)
find . -mmin -30              # modified in last 30 minutes
find . -newer reference.txt   # modified more recently than reference.txt
find . -type f -mtime +30 -name "*.log"  # log files older than 30 days
```

---

## Size Filters

```bash
find . -size +100M            # files larger than 100MB
find . -size -1k              # files smaller than 1KB
find . -size +10M -size -100M # between 10MB and 100MB
find . -empty                 # empty files and directories

# Size units: c (bytes), k (KB), M (MB), G (GB)
```

---

## Permission and Owner Filters

```bash
find . -perm 644              # exact permission match
find . -perm -644             # at least these permissions set
find . -perm /644             # any of these permission bits set
find . -perm -u+x             # user has execute permission
find . -perm -4000            # SUID bit set (security scanning)
find . -perm -2000            # SGID bit set
find . -user root             # owned by root
find . -group nginx           # owned by nginx group
find . -nouser                # no matching user in /etc/passwd (orphaned files)
find . -nogroup               # no matching group
```

---

## Logical Operators

```bash
# AND (default when chaining predicates):
find . -type f -name "*.py" -size +1k    # .py files larger than 1K

# Explicit AND (-a):
find . -type f -a -name "*.sh" -a -perm -u+x    # executable shell scripts

# OR (-o):
find . -name "*.log" -o -name "*.txt"    # files ending in .log OR .txt
find . \( -name "*.c" -o -name "*.h" \) # use parens to group

# NOT (!):
find . ! -name "*.md"                    # exclude markdown files
find . -type f ! -user root              # non-root owned files
```

---

## Execute Commands on Results

```bash
# -exec CMD {} \;  → run CMD once per file ({} = placeholder for filename)
find . -name "*.log" -exec rm {} \;
find . -type f -exec chmod 644 {} \;
find . -name "*.go" -exec gofmt -w {} \;

# -exec CMD {} +  → run CMD once with ALL filenames as args (faster!)
find . -type f -exec ls -lh {} +         # equivalent to ls -lh file1 file2 file3...
find . -name "*.log" -exec gzip {} +     # compress all logs in one gzip call

# -ok CMD {} \;  → prompt for confirmation before each execution
find . -name "*.conf" -ok rm {} \;

# -delete  → delete found files (more efficient than -exec rm)
find . -name "*.tmp" -delete
find . -type f -mtime +30 -name "*.log" -delete

# Pipe to xargs (alternative to -exec):
find . -name "*.py" | xargs wc -l       # count lines in all Python files
find . -name "*.log" -print0 | xargs -0 grep "ERROR"  # handle filenames with spaces
```

---

## Depth Control

```bash
find . -maxdepth 1 -type f      # only current directory, no subdirs
find . -maxdepth 2 -name "*.md" # up to 2 levels deep
find . -mindepth 2 -name "*.log" # skip current dir, search from level 2
find . -maxdepth 1 -type d       # list immediate subdirectories
```

---

## Real-World DevOps Use Cases

```bash
# ─── Disk cleanup ────────────────────────────────────────────────
find /var/log -name "*.log" -mtime +7 -delete          # delete logs older than 7 days
find /tmp -type f -atime +1 -delete                     # clear tmp files not accessed in 24h
find / -size +1G -type f 2>/dev/null                    # find large files on system
find /var/log -type f -name "*.gz" -exec ls -lh {} \;  # list compressed logs

# ─── Security scanning ────────────────────────────────────────────
find / -perm -4000 -type f 2>/dev/null                  # find SUID binaries
find / -perm -2000 -type f 2>/dev/null                  # find SGID binaries
find /home -name ".ssh" -type d -exec ls -la {} \;      # list all .ssh directories
find / -name "*.pem" -o -name "*.key" 2>/dev/null       # find private keys
find / -nouser -o -nogroup 2>/dev/null                  # orphaned files (no owner)

# ─── Code and config search ──────────────────────────────────────
find . -name "*.go" -exec grep -l "TODO" {} +           # Go files with TODOs
find . -name "*.yaml" -exec grep -l "password:" {} +    # YAML files with passwords
find . -name "Dockerfile" -maxdepth 3                   # find all Dockerfiles (shallow)
find . -newer go.mod -name "*.go"                       # Go files changed after go.mod

# ─── Permission repair ────────────────────────────────────────────
find /var/www -type d -exec chmod 755 {} \;             # set dirs to 755
find /var/www -type f -exec chmod 644 {} \;             # set files to 644
find . -name "*.sh" -exec chmod +x {} \;                # make all shell scripts executable

# ─── Docker and Kubernetes operations ────────────────────────────
find /var/lib/docker/containers -name "*.log" -size +100M  # large container logs
find . -name "kustomization.yaml" | xargs grep "namespace"  # find namespace configs
```

---

## Common Patterns & Gotchas

```bash
# Redirect permission errors to /dev/null to clean output
find / -name "*.conf" 2>/dev/null

# Handle filenames with spaces when piping
find . -name "*.log" -print0 | xargs -0 rm -f     # -print0 + xargs -0 = null-delimited

# Find and display with full path + size
find . -type f -name "*.log" -printf "%s %p\n" | sort -rn | head -10

# Count files matching a pattern
find . -name "*.go" | wc -l

# Find recently modified files (good for "what changed?"):
find . -mmin -5 -type f         # modified in last 5 minutes
find . -newer some-reference-file -type f  # newer than a specific file
```

---

## Interview Q&A

**Q: What's the difference between `-exec CMD {} \;` and `-exec CMD {} +`?**
With `\;`, `find` runs the command once per file — if find returns 100 files, the command runs 100 times. With `+`, find collects all matching files and passes them all as arguments in a single invocation — much faster because you avoid process startup overhead 100 times. The `+` form is equivalent to `xargs`. Use `\;` only when the command must run on one file at a time (e.g., when it doesn't accept multiple arguments). Use `+` or `xargs` for bulk operations.

**Q: How do you find and delete files older than 30 days?**
`find /var/log -name "*.log" -mtime +30 -delete` — `-mtime +30` matches files modified more than 30 days ago (the `+` means "greater than"), and `-delete` removes them in one step. Safer alternative: first do a dry run with `-print` to see what would be deleted: `find /var/log -name "*.log" -mtime +30 -print`, then add `-delete` when you're confident.

**Q: How do you exclude a directory from a find search?**
Use `-prune`: `find . -path "*/node_modules" -prune -o -name "*.js" -print`. The `-prune` stops find from descending into matching directories. Without `-prune`, you'd have to use `grep -v` on the output. The `-o` (OR) and `-print` at the end are required — without them, find prints nothing for non-pruned paths.

**Q: How do you find all SUID binaries on a system?**
`find / -perm -4000 -type f 2>/dev/null` — `-perm -4000` matches files where the SUID bit is set (4000 in octal). Redirecting stderr to /dev/null suppresses permission-denied errors for directories you can't access. SUID binaries run as their owner (often root) regardless of who executes them — finding unexpected SUID binaries is a key step in Linux security audits.
