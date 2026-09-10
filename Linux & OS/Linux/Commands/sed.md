# sed — Stream Editor

> `sed` is a non-interactive stream editor — it reads text line by line, applies editing commands (substitution, deletion, insertion), and outputs the result. Processes input without opening a file in a text editor.

---

## Syntax & Options

```
sed [OPTIONS] 'command' file
sed [OPTIONS] -e 'cmd1' -e 'cmd2' file    # multiple commands
sed -f script.sed file                     # commands from a file
```

| Option | Meaning |
|--------|---------|
| `-n` | Suppress automatic printing (use with `p` to print selectively) |
| `-e` | Specify multiple commands inline |
| `-i` | Edit file in-place (modifies the actual file) |
| `-i.bak` | In-place with backup (creates file.bak before editing) |
| `-f file` | Read commands from a sed script file |
| `-E` | Use extended regular expressions (ERE, same as `grep -E`) |

---

## Substitution — The Most Common Command

```bash
# Basic syntax: s/pattern/replacement/flags
sed 's/old/new/' file             # replace FIRST occurrence per line
sed 's/old/new/g' file            # replace ALL occurrences per line (g = global)
sed 's/old/new/2' file            # replace only 2nd occurrence per line
sed 's/old/new/gi' file           # global + case-insensitive

# Real examples:
sed 's/http/https/' nginx.conf            # upgrade http to https
sed 's/localhost/prod.example.com/g' config.yaml  # change hostname
sed 's/\s\+$//g' file.txt                 # remove trailing whitespace
sed 's/^  *//' file.txt                   # remove leading spaces
sed 's/[0-9]\+/NUMBER/g' log.txt         # mask all numbers in logs

# In-place edit (modifies file directly):
sed -i 's/DEBUG/INFO/g' app.conf          # change log level in-place
sed -i.bak 's/v1/v2/g' deployment.yaml   # edit + keep backup as deployment.yaml.bak

# Using different delimiters (useful when pattern contains /):
sed 's|/old/path|/new/path|g' file       # use | as delimiter
sed 's#config#settings#g' file           # use # as delimiter
```

---

## Line Selection & Printing

```bash
# Print specific lines (use with -n to suppress auto-print)
sed -n '1p' file                  # print only line 1
sed -n '5p' file                  # print only line 5
sed -n '$p' file                  # print last line
sed -n '1,5p' file                # print lines 1 through 5
sed -n '2,+4p' file               # print lines 2 through 2+4=6 (5 lines)
sed -n '1~2p' file                # print every 2nd line starting from line 1 (odd lines)
sed -n '2~2p' file                # print every 2nd line starting from line 2 (even lines)

# Pattern-based printing
sed -n '/ERROR/p' app.log         # print only lines containing ERROR
sed -n '/START/,/END/p' file      # print from START to END (inclusive)

# Combined with substitution:
sed -n 's/ERROR/CRITICAL/gp' log  # replace and print only changed lines
```

---

## Deletion

```bash
sed '1d' file                     # delete line 1
sed '1,5d' file                   # delete lines 1-5
sed '$d' file                     # delete last line
sed '/^#/d' file                  # delete comment lines (starting with #)
sed '/^$/d' file                  # delete empty lines
sed '/pattern/d' file             # delete all lines matching pattern
sed '/START/,/END/d' file         # delete range from START to END
```

---

## Insertion & Modification

```bash
# Append text after a matching line
sed '/server_name/a\  listen 443;' nginx.conf

# Insert text before a matching line
sed '/server_name/i\# SSL configuration' nginx.conf

# Replace entire matching line
sed '/^version:/c\version: 2.0' config.yaml

# Transform characters (like tr but in sed context)
sed 'y/abc/ABC/' file             # translate a→A, b→B, c→C (one-to-one mapping)
```

---

## Multiple Commands

```bash
# Multiple -e expressions:
sed -e 's/foo/bar/g' -e 's/baz/qux/g' file   # apply two substitutions

# Semicolon-separated (in single quotes):
sed 's/foo/bar/g; s/baz/qux/g' file

# Apply to specific lines only:
sed '5 s/old/new/g' file          # substitute only on line 5
sed '5! s/old/new/g' file         # substitute on all lines EXCEPT line 5
sed '1,10 s/old/new/g' file       # substitute only on lines 1-10
```

---

## Real-World DevOps Use Cases

```bash
# ─── Config management ────────────────────────────────────────────
# Update version in Kubernetes manifest
sed -i "s/image: myapp:.*/image: myapp:${NEW_VERSION}/" deployment.yaml

# Enable/disable feature flags in config
sed -i 's/^#FEATURE_X/FEATURE_X/' config.conf    # uncomment a line

# Remove comment lines and blank lines to see clean config
sed '/^#/d; /^$/d' /etc/nginx/nginx.conf | less

# ─── Log processing ──────────────────────────────────────────────
sed -n '/ERROR\|FATAL/p' app.log          # extract only error lines
sed 's/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}/DATE/g' log  # mask dates

# ─── CI/CD pipelines ──────────────────────────────────────────────
# Replace placeholder in template
sed "s/\${APP_VERSION}/${VERSION}/g" template.yaml > output.yaml

# ─── Fix common issues ────────────────────────────────────────────
sed -i 's/\r//' windows.txt               # remove Windows carriage returns (CRLF → LF)
sed -i 's/[[:space:]]*$//' file.txt       # remove trailing whitespace from all lines
```

---

## sed vs tr vs awk — When to Use Which

| Tool | Operates on | Best for |
|------|------------|---------|
| `tr` | Characters | Single-character translation/deletion |
| `sed` | Lines / patterns | Line editing, multi-char substitution, in-place file editing |
| `awk` | Fields / records | Structured data with multiple columns, calculations |

```bash
# sed advantages over tr:
sed 's/hello/world/g' file    # replace a WORD (tr can't do this)
sed '/pattern/d' file         # delete matching lines (tr can't do this)
sed '5p' file                 # work on specific line numbers

# awk advantages over sed:
awk '{sum += $2} END {print sum}' data   # aggregate columns (sed can't do math)
awk -F, '{print $3}' file.csv            # reliable column extraction
```

---

## Interview Q&A

**Q: What's the difference between `sed 's/old/new/'` and `sed 's/old/new/g'`?**
Without `g`, sed replaces only the FIRST occurrence of the pattern on each line. With `g` (global), it replaces ALL occurrences on each line. Example: on the line `foo foo foo`, `s/foo/bar/` gives `bar foo foo`, while `s/foo/bar/g` gives `bar bar bar`. Note that `g` is per-line global, not per-file global — to process all lines, sed already does that by default.

**Q: How do you edit a file in-place with sed?**
`sed -i 's/old/new/g' file` — the `-i` flag modifies the file directly instead of printing to stdout. On macOS, `-i` requires an empty string argument: `sed -i '' 's/old/new/g' file`. For safety, use `-i.bak` to create a backup first: `sed -i.bak 's/old/new/g' file` creates `file.bak` before editing. In scripts, always test the `sed` command without `-i` first to verify the substitution is correct.

**Q: How do you delete all comment lines and blank lines from a config file?**
`sed '/^#/d; /^$/d' /etc/nginx/nginx.conf` — `/^#/d` deletes lines starting with `#` (comments in most config formats), `/^$/d` deletes empty lines. You can chain multiple commands with semicolons or multiple `-e` flags. Add `| less` to page through the output, or redirect to a new file. For in-place editing: `sed -i '/^#/d; /^$/d' config.conf`.

**Q: How is sed different from grep for searching?**
`grep` finds and prints matching lines — it's read-only. `sed` can find AND modify — it's an editor. Both can print matching lines (`sed -n '/pattern/p'` = `grep 'pattern'`), but only `sed` can substitute, delete, or insert. For pure searching, `grep` is simpler and faster. Use `sed` when you need to also transform the matched content.
