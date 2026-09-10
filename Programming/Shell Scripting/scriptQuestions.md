# Shell Scripting Interview Questions

> Practice problems covering file processing, string manipulation, process management, and automation — common patterns in DevOps and SRE interviews.

---

## File Analysis — Count Lines, Words, Characters

```bash
#!/bin/bash
read -s -p "Give File Name: " file
echo

wc -l < "$file"   # line count
wc -w < "$file"   # word count
wc -c < "$file"   # character (byte) count

# Combined — one call:
wc "$file"        # prints lines, words, chars, filename
```

---

## Reverse a File Line by Line

```bash
#!/bin/bash
file="testFile.txt"

while IFS= read -r line
do
    echo "$line" | rev
done < "$file"

# Alternative — reverse line ORDER (not characters in each line):
tac "$file"

# Alternative — reverse line order using awk:
awk '{lines[NR]=$0} END {for(i=NR;i>=1;i--) print lines[i]}' "$file"
```

---

## Longest Line in a File

```bash
#!/bin/bash
file="testFile.txt"

length=0
longestLine=""
count=0

while IFS= read -r line
do
    count=$((count + 1))
    x=${#line}
    if [ "$x" -gt "$length" ]; then
        length=$x
        longestLine=$line
    fi
done < "$file"

echo "Length: $length"
echo "Line: $longestLine"

# One-liner with awk (prints length, line number, then line content):
awk '{print length($0), NR, $0}' "$file" | sort -nr | head -n 1
```

---

## Word Frequency Counter

```bash
#!/bin/bash
# Count how many times each word appears in a file

file="${1:-input.txt}"

tr -s '[:space:]' '\n' < "$file" |   # one word per line
    tr '[:upper:]' '[:lower:]' |      # normalize to lowercase
    sort |                             # group identical words
    uniq -c |                          # count occurrences
    sort -rn |                         # sort by frequency descending
    head -20                           # top 20 words

# Example output:
# 15 the
#  8 a
#  6 is
```

---

## Find Files Larger Than a Given Size

```bash
#!/bin/bash
# Find all files larger than 100MB in /var/log
find /var/log -type f -size +100M -exec ls -lh {} \;

# With user-specified threshold:
threshold="${1:-100M}"
find . -type f -size +"$threshold" -printf "%s\t%p\n" | sort -rn
```

---

## Backup Script with Date Stamp

```bash
#!/bin/bash
SOURCE="/etc/nginx"
DEST="/backups/nginx"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_DIR="$DEST/nginx_$TIMESTAMP"

mkdir -p "$BACKUP_DIR"
cp -r "$SOURCE/"* "$BACKUP_DIR/"

echo "Backup created: $BACKUP_DIR"

# Keep only last 7 backups:
ls -dt "$DEST"/nginx_* | tail -n +8 | xargs rm -rf
```

---

## Monitor a Process and Restart If Dead

```bash
#!/bin/bash
PROCESS="nginx"

while true; do
    if ! pgrep -x "$PROCESS" > /dev/null; then
        echo "$(date): $PROCESS not running, restarting..."
        systemctl start "$PROCESS"
    fi
    sleep 30
done

# Better — as a systemd service with Restart=always, but this shows the logic
```

---

## Parse CSV and Extract Specific Column

```bash
#!/bin/bash
# Extract the 3rd column from a CSV file
file="data.csv"

# Using awk (handles quoted fields poorly — for simple CSVs):
awk -F',' '{print $3}' "$file"

# Skip header row:
awk -F',' 'NR>1 {print $3}' "$file"

# Using cut:
cut -d',' -f3 "$file"

# Sum the 3rd column:
awk -F',' 'NR>1 {sum += $3} END {print "Total:", sum}' "$file"
```

---

## Check If a String Is a Number

```bash
#!/bin/bash
is_number() {
    [[ "$1" =~ ^[0-9]+$ ]]   # integer check
}

is_float() {
    [[ "$1" =~ ^[0-9]+(\.[0-9]+)?$ ]]
}

# Usage:
if is_number "42"; then echo "yes"; fi      # yes
if is_number "42.5"; then echo "yes"; fi    # no
if is_float "42.5"; then echo "yes"; fi     # yes
```

---

## Script to Check Disk and Alert

```bash
#!/bin/bash
THRESHOLD=80

df -h | awk 'NR>1' | while read -r line; do
    usage=$(echo "$line" | awk '{print $5}' | tr -d '%')
    mount=$(echo "$line" | awk '{print $6}')

    if [ "$usage" -gt "$THRESHOLD" ]; then
        echo "ALERT: $mount is at ${usage}% usage"
        # send alert: mail -s "Disk Alert" admin@example.com <<< "..."
    fi
done
```

---

## Interview Q&A

**Q: What does `IFS= read -r line` do and why use it?**
`IFS=` (empty Internal Field Separator) prevents read from trimming leading/trailing whitespace from lines — essential when reading log files or files with intentional indentation. `-r` prevents backslash interpretation: without it, a line ending in `\n` would have the `\` consumed as an escape. Together they ensure you get the line exactly as it appears in the file. This is the canonical "safe file reading" pattern in bash.

**Q: What is the difference between `$()` and backticks for command substitution?**
Both capture command output, but `$()` is strongly preferred: it nests cleanly (`$(cat $(find . -name "*.txt"))`), doesn't require backslash escaping inside, and is more readable. Backticks `` `cmd` `` are POSIX-compatible legacy syntax — required only for very old shells (older than bash 2.x). In modern bash/sh scripts, always use `$()`.

**Q: How do you safely handle filenames with spaces in shell scripts?**
Always double-quote variables: `"$file"` not `$file`. Without quotes, a filename like `my file.txt` becomes two arguments (`my` and `file.txt`). Use `find -print0` with `while IFS= read -r -d '' file` for directories with many files. For arrays: `files=( *.txt ); for f in "${files[@]}"; do ...`. The golden rule: if a variable might contain spaces, quote it.
