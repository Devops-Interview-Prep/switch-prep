# Core File-Operation Concepts

## File Tests

```bash
[[ -f file ]]   # regular file exists
[[ -d dir ]]    # directory exists
[[ -L link ]]   # symbolic link
[[ -s file ]]   # file exists and non-empty
[[ -r file ]]   # readable
[[ -w file ]]   # writable
[[ -x file ]]   # executable
[[ -e path ]]   # exists (any type)

# Example
if [[ -f /etc/nginx/nginx.conf ]]; then
    echo "Nginx config exists"
fi
```

## Permissions & Ownership

```bash
# View permissions
ls -la file.sh
# -rwxr-xr-- 1 user group  → owner:rwx, group:r-x, others:r--

# chmod — change permissions
chmod +x script.sh          # add execute for all
chmod 755 script.sh         # rwxr-xr-x
chmod 600 private_key       # rw------- (SSH key permissions)
chmod -R 644 /var/www/      # recursive: all files readable

# chown — change owner
chown user:group file.txt
chown -R www-data:www-data /var/www/html/

# Special permissions
chmod +s binary             # setuid: run as file owner
chmod g+s dir               # setgid: new files inherit group
chmod +t /tmp               # sticky bit: only owner can delete
```

## File Traversal

```bash
# Find and process files
find /var/log -name "*.log" -mtime +7 -exec rm {} \;    # delete logs older than 7 days
find . -type f -name "*.sh" -exec chmod +x {} \;         # make scripts executable
find . -size +100M                                         # files > 100MB

# Loop over files safely (handles spaces in filenames)
while IFS= read -r -d '' file; do
    echo "Processing: $file"
done < <(find . -name "*.txt" -print0)
```

## Safe File Handling

```bash
# Atomic write (temp file + rename = no partial reads)
tmpfile=$(mktemp /tmp/output.XXXXXX)
generate_data > "$tmpfile"
mv "$tmpfile" /etc/config.json    # atomic on same filesystem

# Lock file (prevent concurrent runs)
LOCKFILE=/tmp/myscript.lock
exec 200>"$LOCKFILE"
flock -n 200 || { echo "Already running"; exit 1; }

# Cleanup on exit
trap 'rm -f "$tmpfile"' EXIT
```

## Large File Processing

```bash
# Process line by line (never load entire file into memory)
while IFS= read -r line; do
    echo "$line"
done < large_file.txt

# Split large file into chunks
split -l 10000 huge.csv chunk_       # 10k lines per chunk: chunk_aa, chunk_ab...
split -b 100M huge.tar.gz part_      # 100MB chunks

# Process in parallel with xargs
find . -name "*.log" | xargs -P 4 gzip    # gzip 4 files at a time
```

## Log Rotation Logic

```bash
#!/bin/bash
LOG_DIR="/var/log/myapp"
MAX_LOGS=5
CURRENT_LOG="$LOG_DIR/app.log"

rotate_logs() {
    # Remove oldest
    rm -f "$LOG_DIR/app.log.$MAX_LOGS"
    # Shift existing logs
    for i in $(seq $((MAX_LOGS-1)) -1 1); do
        [[ -f "$LOG_DIR/app.log.$i" ]] && \
            mv "$LOG_DIR/app.log.$i" "$LOG_DIR/app.log.$((i+1))"
    done
    # Rotate current
    [[ -f "$CURRENT_LOG" ]] && mv "$CURRENT_LOG" "$LOG_DIR/app.log.1"
}

rotate_logs
systemctl restart myapp   # restart to open new log file
```

## Common Interview Questions

**Q: How do you safely write to a file that's being read by another process?**
Use atomic write: write to a temp file on the same filesystem, then `mv` it to the target. `mv` is atomic (rename syscall) on the same filesystem — readers either see the old file or the new file, never a partial write. Never redirect (`>`) directly to a file being actively read by another process.

**Q: How do you prevent a script from running twice simultaneously?**
Use `flock` with a lock file: `flock -n /tmp/myscript.lock ./script.sh`. The `-n` flag means non-blocking — if lock is held, exit immediately instead of waiting. Alternatively, use pid files: check if a pid file exists AND the process is still running (`kill -0 $pid`).
