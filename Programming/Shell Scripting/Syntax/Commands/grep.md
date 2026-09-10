# grep — Global Regular Expression Print

> `grep` searches text for lines matching a pattern and prints matching lines. One of the most-used Linux commands — essential for log analysis, code search, configuration review, and debugging.

---

## Syntax

```
grep [OPTIONS] PATTERN [FILE...]
grep [OPTIONS] -e PATTERN [FILE...]    # explicit pattern (multiple patterns)
grep [OPTIONS] -f PATTERN_FILE [FILE...] # patterns from file
```

---

## Most Common Flags

| Flag | Meaning | Example |
|------|---------|---------|
| `-i` | Case-insensitive search | `grep -i "error" app.log` |
| `-v` | Invert match (show NON-matching lines) | `grep -v "DEBUG" app.log` |
| `-r` | Recursive — search directory tree | `grep -r "TODO" ./src/` |
| `-n` | Show line numbers | `grep -n "def " main.py` |
| `-c` | Count matching lines (not content) | `grep -c "ERROR" app.log` |
| `-l` | List filenames with matches (not content) | `grep -rl "password" .` |
| `-L` | List filenames WITHOUT matches | `grep -L "version" *.yaml` |
| `-w` | Match whole word only | `grep -w "cat" file.txt` |
| `-x` | Match entire line only | `grep -x "200 OK" access.log` |
| `-A N` | N lines After match | `grep -A 5 "FATAL" app.log` |
| `-B N` | N lines Before match | `grep -B 3 "FATAL" app.log` |
| `-C N` | N lines Context (before + after) | `grep -C 3 "FATAL" app.log` |
| `-o` | Print only matched part (not whole line) | `grep -o "ip:[0-9.]*"` |
| `-q` | Quiet — no output, just exit code (0=match, 1=no match) | `grep -q "error" log && alert` |
| `-E` | Extended regex (same as `egrep`) | `grep -E "err(or)?" file` |
| `-P` | Perl-compatible regex (PCRE) | `grep -P "\d{1,3}\.\d{1,3}" file` |
| `-F` | Fixed string (no regex, faster) | `grep -F "1.2.3.4" access.log` |
| `--color=auto` | Highlight matched text | `grep --color=auto "error" log` |

---

## Practical Examples

```bash
# ─── Log analysis ────────────────────────────────────────────────
grep "ERROR" /var/log/app.log                  # find error lines
grep -i "error\|warn\|fatal" app.log           # errors, warnings, fatals (case-insensitive)
grep -c "404" access.log                       # count 404 errors
grep -A 10 "NullPointerException" app.log      # exception + 10 lines of stacktrace
grep -v "INFO\|DEBUG" app.log                  # hide INFO and DEBUG, show only errors

# ─── Process and port inspection ─────────────────────────────────
ps aux | grep nginx                            # find nginx process
ps aux | grep -v grep | grep nginx             # exclude the grep process itself
ss -tlnp | grep 8080                           # find what's on port 8080

# ─── Code search ─────────────────────────────────────────────────
grep -rn "TODO" ./src/                         # find all TODOs with line numbers
grep -rl "deprecated" ./                       # list files containing "deprecated"
grep -rn "def process_payment" .               # find function definition
grep -rn "import" ./src/ | grep -v "test"      # imports, excluding test files
grep -E "func\s+[A-Z]" main.go                # find exported Go functions

# ─── Kubernetes and DevOps ────────────────────────────────────────
kubectl get pods | grep -v "Running"           # pods NOT in Running state
kubectl logs my-pod | grep -i "error" | tail -20  # recent errors in pod
cat deployment.yaml | grep -E "image:|tag:"   # extract image references
grep -r "password\|secret\|token" ./config/ --include="*.yaml"  # secret scanning
dmesg | grep -i "oom\|killed"                  # check OOM killer events
journalctl | grep "sshd" | grep "Failed"       # failed SSH attempts

# ─── File and config inspection ───────────────────────────────────
grep -n "Listen" /etc/nginx/nginx.conf         # find port configuration
grep -rn "endpoint" . --include="*.go"        # find endpoint definitions in Go files
grep -w "root" /etc/passwd                    # find root user entry exactly
grep "^#" /etc/hosts                           # lines starting with # (comments)
grep "[^[:print:]]" file.txt                   # find non-printable characters

# ─── With regex ──────────────────────────────────────────────────
grep -E "^[0-9]{4}-[0-9]{2}-[0-9]{2}" log.txt  # lines starting with a date
grep -E "\b[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\b" access.log  # IPs
grep -P "(?<=user=)\w+" auth.log               # PCRE lookbehind: extract username after user=
```

---

## grep vs egrep vs fgrep

| Command | Equivalent | Use |
|---------|-----------|-----|
| `grep` | `grep` | BRE (basic regex) — `\+`, `\|` need backslash |
| `egrep` | `grep -E` | ERE (extended regex) — `+`, `|`, `()` work directly |
| `fgrep` | `grep -F` | Fixed string — no regex, just literal text (fastest) |

```bash
# BRE (grep): extended regex chars need backslash
grep "error\|warning" file.txt       # matches "error" OR "warning"

# ERE (grep -E or egrep): cleaner regex
grep -E "error|warning" file.txt     # same, cleaner syntax
grep -E "err(or)?" file.txt          # matches "err" or "error"
grep -E "^(GET|POST|PUT)" access.log # lines starting with GET, POST, or PUT

# Fixed string (grep -F): fastest, no regex interpretation
grep -F "192.168.1.1" access.log     # literal IP (no . = any char misinterpretation)
```

---

## Exit Codes — Use in Scripts

```bash
grep -q "error" logfile
if [ $? -eq 0 ]; then
    echo "Errors found!"
fi

# Or inline:
grep -q "error" logfile && echo "Errors found!" || echo "All clear"

# Exit codes:
# 0 = at least one match found
# 1 = no match found
# 2 = error (file not found, permission denied, etc.)
```

---

## Interview Q&A

**Q: How do you find all occurrences of a pattern in a directory recursively?**
`grep -rn "pattern" ./directory/` — `-r` is recursive, `-n` shows line numbers. Add `-l` to only list filenames without showing the matching content. To restrict to specific file types: `grep -rn "pattern" . --include="*.go"`.

**Q: How do you exclude certain lines when grepping?**
Use `-v` (invert match). Chain multiple greps: `grep "error" app.log | grep -v "DEBUG"` — first finds lines with "error", then the second pipe removes DEBUG lines. Or combine patterns: `grep -E "error|fatal" app.log | grep -v "test"`.

**Q: What's the difference between `grep -w` and `grep -x`?**
`-w` matches a whole word — the pattern must be surrounded by non-word characters (spaces, punctuation), so `grep -w cat` won't match "concatenate". `-x` matches the entire line — the pattern must match the complete line exactly. Use `-w` when searching for a variable name that might appear as a substring in other identifiers. Use `-x` for config validation where a line must exactly equal a value.

**Q: How do you count the number of matching lines vs the number of occurrences?**
`grep -c "pattern" file` counts LINES with a match (not total occurrences — a line with 3 matches counts as 1). To count total occurrences: `grep -o "pattern" file | wc -l` — `-o` prints each match on its own line, so `wc -l` gives the total count.
