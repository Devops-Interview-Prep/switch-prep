# awk — Pattern Scanning & Text Processing

> `awk` is a programming language for text processing. It reads input line by line, splits each line into fields, and executes actions on lines that match patterns.

## How awk Works

```
awk 'pattern { action }' file
```

- Reads line by line
- Splits each line into fields: `$1`, `$2`, ... `$NF` (last field)
- `$0` = entire line
- `FS` = field separator (default: whitespace)
- `NR` = current line number
- `NF` = number of fields in current line

## Basic Syntax

```bash
# Print specific field
awk '{print $1}' /etc/passwd        # first field
awk '{print $1, $3}' file.txt       # fields 1 and 3 (space-separated)
awk '{print $NF}' file.txt          # last field

# Custom field separator
awk -F: '{print $1}' /etc/passwd    # use : as separator (usernames)
awk -F, '{print $2}' data.csv       # CSV second column
awk -F'\t' '{print $3}' file.tsv    # tab-separated

# Print line number with content
awk '{print NR, $0}' file.txt
```

## Pattern Matching

```bash
# Print lines matching a pattern
awk '/error/' /var/log/app.log              # lines containing "error"
awk '/ERROR|FATAL/' /var/log/app.log        # regex: ERROR or FATAL
awk '!/debug/' /var/log/app.log             # lines NOT containing "debug"

# Match specific field
awk '$3 > 100' metrics.txt                  # field 3 greater than 100
awk '$1 == "nginx"' /etc/passwd             # field 1 equals "nginx"
awk '$2 ~ /^admin/' users.txt              # field 2 starts with "admin"
awk '$2 !~ /^tmp/' users.txt              # field 2 does NOT start with "tmp"

# Range pattern (print between START and END)
awk '/START/,/END/' file.txt
awk '/\[ERROR\]/,/\[INFO\]/' app.log      # from [ERROR] to [INFO]
```

## BEGIN and END Blocks

```bash
# BEGIN: runs before processing input
# END: runs after processing all input

awk 'BEGIN {print "=== Report ==="} {print} END {print "=== Done ==="}' file.txt

# Count lines matching a pattern
awk '/error/ {count++} END {print "Errors:", count}' /var/log/app.log

# Sum values in a column
awk '{sum += $3} END {print "Total:", sum}' metrics.txt
awk '{sum += $3} END {print "Total:", sum, "Average:", sum/NR}' metrics.txt

# Add custom header to CSV
awk 'BEGIN {print "Name,Age,City"} {print}' data.csv
```

## Variables and Arithmetic

```bash
# Built-in variables
awk 'BEGIN {FS=":"; OFS=","} {print $1, $3}' /etc/passwd  # change output separator

# Custom variables
awk -v threshold=90 '$3 > threshold {print $1, "HIGH:", $3}' metrics.txt

# Arithmetic
awk '{print $1, $2 * $3, $2 + $3}' data.txt

# String concatenation
awk '{msg = "User: " $1 " logged in at " $5; print msg}' auth.log
```

## Practical DevOps Examples

```bash
# Extract memory usage from 'free' command
free -m | awk 'NR==2 {print "Used:", $3"MB", "Free:", $4"MB"}'

# Parse nginx access log — show IP and status code
awk '{print $1, $9}' /var/log/nginx/access.log

# Find top 10 IPs by request count
awk '{print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -rn | head -10

# Show CPU usage for a specific process
ps aux | awk '$11 ~ /nginx/ {print $1, $3, $11}'

# Calculate average response time from log
awk '{sum += $NF; count++} END {print "Avg response time:", sum/count "ms"}' access.log

# Extract all 5xx errors from nginx log
awk '$9 ~ /^5/' /var/log/nginx/access.log | awk '{print $1, $9, $7}'

# Show disk usage over threshold
df -h | awk 'NR>1 && $5+0 > 80 {print "ALERT:", $6, "is", $5, "full"}'

# Extract lines between timestamps
awk '$1 >= "10:00:00" && $1 <= "11:00:00"' app.log

# Parse /etc/passwd — show UID over 1000 (regular users)
awk -F: '$3 >= 1000 {print $1, "UID:", $3}' /etc/passwd

# Count HTTP status codes
awk '{codes[$9]++} END {for (code in codes) print code, codes[code]}' access.log | sort -k2 -rn

# Find containers using too much memory (kubectl top)
kubectl top pods | awk 'NR>1 && $3+0 > 500 {print $1, "Memory:", $3}'

# Extract key=value pairs from config files
awk -F= '!/^#/ && NF==2 {gsub(/[[:space:]]/, "", $2); print $1"="$2}' app.conf
```

## Conditional Logic

```bash
# if-else in awk
awk '{
  if ($3 > 90) status = "CRITICAL"
  else if ($3 > 70) status = "WARNING"
  else status = "OK"
  print $1, status, $3
}' metrics.txt

# Multiple conditions
awk '$1 == "ERROR" && $5 > 500 {print}' app.log
awk '$1 == "WARN" || $1 == "ERROR" {print NR": "$0}' app.log
```

## Arrays (Associative)

```bash
# Count occurrences
awk '{count[$1]++} END {for (k in count) print k, count[k]}' log.txt

# Group and sum
awk '{total[$1] += $3} END {for (service in total) print service, total[service]}' metrics.txt

# Track unique values
awk '!seen[$1]++ {print}' file.txt    # print first occurrence of each unique $1

# Top N pattern
awk '{count[$1]++} END {
  for (k in count) print count[k], k
}' log.txt | sort -rn | head -5
```

## Multi-file and Pipes

```bash
# Process multiple files (NR = total lines, FNR = lines in current file)
awk 'FNR==1 {print "=== " FILENAME " ==="} {print}' file1.txt file2.txt

# Pipe into awk
journalctl -u nginx | awk '/error/ {print NR, $0}'

# Combine with other tools
cat access.log | \
  awk '$9 >= 500' | \               # 5xx errors only
  awk '{print $1}' | \              # extract IP
  sort | uniq -c | sort -rn | \    # count + sort
  head -10                          # top 10 offenders

# Output to multiple files
awk '{print > "output_"NR".txt"}' input.txt    # one file per line (careful!)
awk '{print >> "summary.txt"}' input.txt       # append
```

## awk vs sed vs grep

| Tool | Best for |
|------|---------|
| `grep` | Simple pattern matching, finding lines |
| `sed` | Stream editing, substitutions, in-place edits |
| `awk` | Field-based processing, arithmetic, aggregation |

```bash
# Same task — extract 3rd field of CSV
grep -o '[^,]*,[^,]*,\([^,]*\)' file.csv        # grep — awkward
sed 's/[^,]*,[^,]*,\([^,]*\),.*/\1/' file.csv   # sed — complex
awk -F, '{print $3}' file.csv                    # awk — clean and readable
```

## Common Interview Questions

**Q: What is `NR` vs `FNR` in awk?**
`NR` (Number of Records) is the total line count across all input files processed so far. `FNR` (File Number of Records) resets to 1 for each new file. When processing a single file, they're identical. When processing multiple files, use `FNR==1` to detect the start of each new file.

**Q: How do you sum values in a column with awk?**
`awk '{sum += $3} END {print sum}' file.txt` — `sum` starts at 0 (awk initializes unset numeric variables to 0). The `END` block runs after all lines are processed, printing the accumulated total.

**Q: How do you print unique lines with awk?**
`awk '!seen[$0]++'` — `seen[$0]` is an associative array. The first time a line appears, `seen[$0]` is 0 (falsy), `!0` is true, print occurs, and `++` increments to 1. On subsequent occurrences, `seen[$0]` is 1 (truthy), `!1` is false, nothing is printed. More powerful than `sort | uniq` because it preserves original order.
