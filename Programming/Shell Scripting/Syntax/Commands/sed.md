# sed — Stream Editor

> `sed` reads input line-by-line, applies editing commands, and writes to stdout. It's non-interactive — designed for automated text transformation in scripts and pipelines. Essential for find-and-replace, line extraction, deletion, and config file manipulation.

---

## Syntax and Options

```bash
sed [OPTIONS] 'command' file
sed [OPTIONS] -e 'cmd1' -e 'cmd2' file   # multiple commands

# Common options:
-n          # suppress automatic printing (print only with p)
-e          # add expression/command (allows multiple -e commands)
-i          # edit in-place (modifies original file)
-i.bak      # in-place with backup (creates file.bak before modifying)
-E / -r     # use Extended Regular Expressions (enables + ? | without backslash)
-f file     # read commands from a sed script file
```

---

## Substitution — The Core Command

```bash
# Basic format: s/pattern/replacement/flags
sed 's/old/new/' file.txt              # replace FIRST occurrence per line
sed 's/old/new/g' file.txt             # replace ALL occurrences per line (global)
sed 's/old/new/2' file.txt             # replace only 2nd occurrence per line
sed 's/old/new/gi' file.txt            # global + case-insensitive

# In-place substitution (modifies original file):
sed -i 's/old/new/g' file.txt          # direct in-place edit
sed -i.bak 's/old/new/g' file.txt      # with backup (file.txt.bak)

# Extended regex (avoids backslash escaping for +, ?, |, {}):
sed -E 's/[0-9]+/NUM/g' file.txt       # replace any number with NUM
sed -E 's/https?:\/\///' file.txt      # strip http:// or https://

# Capture groups (back-references):
# BRE style (default): use \( \) to capture, \1 to reference
sed 's/\(hello\) \(world\)/\2 \1/' file.txt       # swap two words
# ERE style (-E): use () to capture
sed -E 's/(hello) (world)/\2 \1/' file.txt         # same, cleaner

# Real-world: extract IP from log line
echo "2024-01-15 192.168.1.5 GET /api/v1" | sed -E 's/[^ ]+ ([0-9.]+) .*/\1/'
# Output: 192.168.1.5

# Real-world: bump version number
sed -E 's/version: ([0-9]+)\./version: \1./' config.yaml
```

---

## Line Selection and Printing

```bash
# Print specific lines (requires -n to suppress default output):
sed -n '1p' file.txt                   # print only 1st line
sed -n '5p' file.txt                   # print only 5th line
sed -n '$p' file.txt                   # print last line
sed -n '1,5p' file.txt                 # print lines 1–5 (range)
sed -n '2,+4p' file.txt                # print line 2 and next 4 lines (2–6)
sed -n '1~2p' file.txt                 # print every 2nd line starting at line 1 (odd lines)
sed -n '2~2p' file.txt                 # print every 2nd line starting at line 2 (even lines)

# Pattern-based selection:
sed -n '/ERROR/p' app.log              # print lines containing ERROR
sed -n '/start/,/end/p' file.txt       # print from "start" to "end" (inclusive)

# Multiple expressions:
sed -n -e '2p' -e '5p' file.txt        # print 2nd and 5th line
```

---

## Deletion

```bash
sed '1d' file.txt                      # delete 1st line
sed '$d' file.txt                      # delete last line
sed '1,3d' file.txt                    # delete lines 1–3
sed '/pattern/d' file.txt              # delete lines matching pattern
sed '/^$/d' file.txt                   # delete empty lines
sed '/^#/d' file.txt                   # delete comment lines (starting with #)
sed '/^#/d; /^$/d' file.txt            # delete both comments and blank lines

# Delete lines NOT matching (use ! to negate):
sed '/ERROR/!d' app.log                # keep only ERROR lines (delete everything else)
```

---

## Insertion and Appending

```bash
# Append text after matching line:
sed '/pattern/a\new line content' file.txt

# Insert text before matching line:
sed '/pattern/i\new line content' file.txt

# Replace entire matching line:
sed '/pattern/c\replacement line' file.txt

# Example: add comment above every "server" block in nginx config:
sed '/^server {/i\# Auto-generated server block' nginx.conf
```

---

## DevOps Practical Examples

```bash
# 1. Update a config value in-place
sed -i 's/^port=.*/port=8080/' app.conf          # set port to 8080
sed -i 's/debug: false/debug: true/' config.yaml  # enable debug mode

# 2. Remove trailing whitespace from all lines
sed -i 's/[[:space:]]*$//' file.txt

# 3. Extract value from key=value config
grep "^DATABASE_URL=" .env | sed 's/^DATABASE_URL=//'

# 4. Strip ANSI color codes from log output
sed 's/\x1b\[[0-9;]*m//g' colored.log

# 5. Add line numbers to a file
sed = file.txt | sed 'N;s/\n/\t/'

# 6. Comment out lines matching a pattern (add # at start):
sed -i '/^DEBUG_MODE/s/^/# /' app.conf

# 7. Extract config block between markers:
sed -n '/\[database\]/,/\[/p' config.ini | sed '$d'   # last line is next section header

# 8. Replace placeholder in template:
sed "s/{{APP_NAME}}/myapp/g; s/{{PORT}}/8080/g" template.yaml > deployment.yaml

# 9. Delete blank lines from Dockerfile:
sed '/^$/d' Dockerfile
```

---

## sed vs tr vs awk

| Feature | sed | tr | awk |
|---------|-----|----|-----|
| Operates on | Lines | Characters | Fields + Lines |
| Regex support | Yes | No | Yes |
| Multi-char substitution | Yes | No | Yes |
| Field splitting | No | No | Yes |
| Arithmetic | No | No | Yes |
| In-place edit | Yes (`-i`) | No | No |
| **Best for** | Line transformation, find-replace | Char translation, stripping | Data extraction, reporting |

---

## Interview Q&A

**Q: What does `sed -n '/pattern/p'` do and why is `-n` needed?**
By default, sed prints every line after processing. `-n` suppresses this automatic output. `p` is an explicit print command. Together, `sed -n '/pattern/p'` is equivalent to `grep 'pattern'` — only lines matching the pattern are printed. Without `-n`, every line is printed (by default output) PLUS matching lines are printed again by `p`, giving duplicates.

**Q: What is the difference between `sed -i` and `sed -i.bak`?**
`sed -i` edits the file in-place with no backup — the original is permanently overwritten. `sed -i.bak` creates a backup copy with `.bak` extension before modifying (`sed -i.bak 's/old/new/' file.txt` creates `file.txt.bak`). For production scripts, always use `-i.bak` or explicitly back up first — an error in the pattern and `-i` destroys the original. On macOS, `-i ''` (empty string) is required because BSD sed's `-i` syntax differs from GNU sed.

**Q: How do you use capture groups in sed substitution?**
In BRE (default): escape the parentheses: `sed 's/\(pattern\)/\1/'`. In ERE (`-E` flag): no escaping needed: `sed -E 's/(pattern)/\1/'`. `\1` refers to the first capture group, `\2` to the second, etc. Example: swapping first and last name: `sed -E 's/^([A-Za-z]+) ([A-Za-z]+)$/\2, \1/'` transforms "John Smith" → "Smith, John".
