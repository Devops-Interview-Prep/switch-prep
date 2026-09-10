# Regular Expressions (Regex)

> A regular expression is a pattern that describes a set of strings. Regex is used in grep, sed, awk, bash `[[ =~ ]]`, Python `re`, and virtually every programming language. Mastering regex is essential for log parsing, configuration management, and DevOps automation.

---

## Core Pattern Reference

| Pattern | Meaning | Example Match |
|---------|---------|---------------|
| `.` | Any single character | `a`, `1`, `@`, space |
| `*` | Zero or more of preceding | `bo*` → `b`, `bo`, `boo` |
| `+` | One or more of preceding | `go+` → `go`, `goo` (not `g`) |
| `?` | Zero or one of preceding | `colou?r` → `color`, `colour` |
| `[abc]` | Any one character in set | `a`, `b`, or `c` |
| `[^abc]` | Any char NOT in set | `d`, `e`, but not `a`,`b`,`c` |
| `[a-z]` | Any lowercase letter | `a` through `z` |
| `[0-9]` | Any digit | `0` through `9` |
| `^` | Start of line | `^Error` matches lines starting with "Error" |
| `$` | End of line | `\.log$` matches lines ending in ".log" |
| `\d` | Digit (ERE/PCRE) | `0` to `9` (equiv to `[0-9]`) |
| `\w` | Word character | Letters, digits, underscore |
| `\s` | Whitespace | Space, tab, newline |
| `\b` | Word boundary | `\bcat\b` matches "cat" but not "concatenate" |
| `{n}` | Exactly n repetitions | `[0-9]{3}` → `123`, `456` |
| `{n,m}` | Between n and m | `[0-9]{2,4}` → `12`, `123`, `1234` |
| `\|` | Logical OR | `cat\|dog` → "cat" or "dog" |
| `()` | Grouping + capturing | `(foo)+` → one or more "foo" |

---

## Regex in grep

```bash
# Basic regex (BRE — Basic Regular Expression):
grep "pattern" file.txt

# Extended regex (ERE — enables +, ?, |, {} without backslash):
grep -E "pattern" file.txt
grep -E "error|warning|fatal" /var/log/syslog

# Common flags:
grep -i "error" file.txt          # case-insensitive
grep -v "debug" file.txt          # invert — lines NOT matching
grep -n "error" file.txt          # show line numbers
grep -r "TODO" ./src/             # recursive search
grep -c "error" file.txt          # count matching lines (not occurrences)
grep -l "error" *.log             # list filenames with matches

# Anchors:
grep "^ERROR" app.log             # lines starting with ERROR
grep "DONE$" app.log              # lines ending with DONE
grep -E "^(ERROR|WARN)" app.log   # lines starting with ERROR or WARN

# Character classes:
grep "[0-9]\{3\}-[0-9]\{4\}" contacts.txt   # phone number pattern (BRE)
grep -E "[0-9]{3}-[0-9]{4}" contacts.txt    # same, ERE

# Real-world examples:
grep -E "HTTP [45][0-9]{2}" access.log      # HTTP error responses
grep -E "^[0-9]{4}-[0-9]{2}-[0-9]{2}" access.log  # ISO date at start of line
grep -v "^#" /etc/nginx/nginx.conf | grep -v "^$"  # strip comments and blanks
```

---

## Regex in sed

```bash
# Basic substitution:
sed 's/old/new/' file.txt          # replace first occurrence per line
sed 's/old/new/g' file.txt         # replace all occurrences per line

# ERE in sed:
sed -E 's/[0-9]+/NUM/g' file.txt   # replace any number with NUM

# Using capture groups (back-references):
# \1 refers to first capture group (BRE uses \( \))
sed 's/\([0-9]\{3\}\)-\([0-9]{4}\)/(\1) \2/' contacts.txt

# ERE with groups:
sed -E 's/([0-9]{3})-([0-9]{4})/(\1) \2/' contacts.txt

# Real-world: extract IP from log
echo "2024-01-15 192.168.1.5 GET /api" | sed -E 's/[^ ]+ ([0-9.]+) .*/\1/'
# Output: 192.168.1.5

# Real-world: remove trailing whitespace:
sed -E 's/[[:space:]]+$//' file.txt

# Real-world: extract version number:
echo "version: 1.23.4" | sed -E 's/version: ([0-9.]+)/\1/'
# Output: 1.23.4
```

---

## Regex in awk

```bash
# Filter lines matching pattern:
awk '/ERROR/' app.log                      # print lines with ERROR
awk '!/DEBUG/' app.log                     # print lines without DEBUG
awk '/^[0-9]/' data.txt                    # lines starting with a digit

# Pattern + action:
awk '/HTTP 5[0-9]{2}/ {print $1, $7}' access.log   # 5xx errors: date + URL

# Field-specific matching:
awk '$3 ~ /^GET/' access.log               # 3rd field starts with GET
awk '$5 !~ /200/' access.log               # 5th field is NOT 200

# Extract and transform:
awk 'match($0, /[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/, arr) {print arr[0]}' app.log
# Extracts first IP address from each line
```

---

## Regex in Bash `[[ =~ ]]`

```bash
#!/bin/bash

# Test if variable matches a pattern:
email="user@example.com"
if [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo "Valid email"
fi

# Extract matched group (captured in BASH_REMATCH):
version="v1.23.4"
if [[ "$version" =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
    major="${BASH_REMATCH[1]}"   # 1
    minor="${BASH_REMATCH[2]}"   # 23
    patch="${BASH_REMATCH[3]}"   # 4
    echo "Major: $major, Minor: $minor, Patch: $patch"
fi

# Validate IP address:
ip="192.168.1.100"
if [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    echo "Looks like an IP"
fi

# Check if string contains only digits:
input="12345"
if [[ "$input" =~ ^[0-9]+$ ]]; then
    echo "Is a number"
fi
```

---

## POSIX Character Classes

```bash
# POSIX classes work in grep, sed, awk (portable across shells):
[:alpha:]   # [a-zA-Z]
[:digit:]   # [0-9]
[:alnum:]   # [a-zA-Z0-9]
[:space:]   # space, tab, newline
[:upper:]   # [A-Z]
[:lower:]   # [a-z]
[:punct:]   # punctuation characters

# Usage (must be inside outer [] brackets):
grep "[[:alpha:]]" file.txt            # lines containing at least one letter
sed 's/[[:digit:]]//g' file.txt        # remove all digits
grep "[[:upper:]]" file.txt            # lines with uppercase letters
```

---

## DevOps Practical Examples

```bash
# 1. Find all IP addresses in a log file
grep -oE "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" access.log | sort | uniq -c | sort -rn

# 2. Count HTTP 4xx errors by status code
grep -oE "HTTP/1.[01]\" [4][0-9]{2}" access.log | sort | uniq -c | sort -rn

# 3. Extract all email addresses from a file
grep -oE "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}" contacts.txt

# 4. Find Kubernetes pod crash loops in logs
grep -E "Back-off|CrashLoopBackOff|OOMKilled" kubectl_output.log

# 5. Extract environment variables from a Docker .env file
grep -E "^[A-Z_]+=.+" .env | sed 's/=.*//'  # just the variable names

# 6. Validate that all files in a directory are named properly (lowercase, dashes only)
find . -name "*.md" | grep -vE "^./[a-z0-9-]+\.md$"  # names that don't match convention

# 7. Find lines with suspicious sudo usage in auth.log
grep -E "sudo.*COMMAND=(?!.*safe_cmd)" /var/log/auth.log
```

---

## BRE vs ERE vs PCRE

| Feature | BRE (Basic) | ERE (Extended) | PCRE |
|---------|-------------|----------------|------|
| `+`, `?` | `\+`, `\?` | `+`, `?` | `+`, `?` |
| `\|` (OR) | `\|` | `\|` | `\|` |
| `{}` | `\{n\}` | `{n}` | `{n}` |
| `()` groups | `\(\)` | `()` | `()` |
| `\d`, `\w` | No | No | Yes |
| Tools | `grep`, `sed` | `grep -E`, `awk` | `grep -P`, Python `re` |

---

## Interview Q&A

**Q: What is the difference between `grep`, `grep -E`, and `grep -P`?**
`grep` uses Basic Regular Expressions (BRE) where metacharacters like `+`, `?`, `|`, `{n}` must be backslash-escaped. `grep -E` (or `egrep`) uses Extended Regular Expressions (ERE) where these metacharacters work without escaping — `grep -E "foo|bar"` vs `grep "foo\|bar"`. `grep -P` uses Perl-Compatible Regular Expressions (PCRE) which adds `\d`, `\w`, `\s`, lookaheads/lookbehinds, and other advanced features. For DevOps work, `-E` is the most common; use `-P` only when you need lookaheads or `\d`-style shortcuts.

**Q: How do you extract text (not just match lines) with grep?**
Use `grep -o` (output only matching part, not the whole line). Example: `grep -oE "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" access.log` extracts only IP addresses from each matching line. Combined with `sort | uniq -c | sort -rn` you get a frequency table of IPs. This is extremely useful for log analysis in production.

**Q: What does `^` mean inside vs outside of character classes?**
Inside `[]`: `[^abc]` means "any character except a, b, or c" — it negates the character class. Outside `[]`: `^pattern` means "beginning of line" — it's a positional anchor. This dual meaning is a common source of confusion. `^[^#]` means "start of line followed by a character that is not #" — useful for filtering out comment lines: `grep "^[^#]" config.txt`.
