# tr — Translate or Delete Characters

> `tr` translates, squeezes, or deletes characters from standard input. Unlike `sed`, `tr` works on individual characters (not patterns or lines) and always reads from stdin.

---

## Syntax & Options

```
tr [OPTIONS] SET1 [SET2]
```

- **SET1**: characters to match (input set)
- **SET2**: replacement characters (output set)
- Both sets must be the same length unless deleting or squeezing

| Option | Meaning |
|--------|---------|
| `-d` | Delete characters in SET1 (no SET2 needed) |
| `-s` | Squeeze repeated characters in SET1 into one |
| `-c` | Complement SET1 — match characters NOT in SET1 |
| `-cd` | Combine: delete everything not in SET1 |

---

## Basic Examples

```bash
# ─── Case conversion ─────────────────────────────────────────────
tr 'a-z' 'A-Z' < file.txt             # lowercase → UPPERCASE
tr 'A-Z' 'a-z' < file.txt             # UPPERCASE → lowercase
echo "Hello World" | tr 'a-z' 'A-Z'   # inline: HELLO WORLD

# ─── Character substitution ──────────────────────────────────────
tr ' ' '_' < file.txt                  # spaces → underscores
tr ':' '\n' < /etc/passwd              # split colon-separated into lines
echo "path:/usr/bin:/usr/local/bin" | tr ':' '\n'

# ─── Delete characters (-d) ──────────────────────────────────────
tr -d '!' < file.txt                   # remove all exclamation marks
tr -d '0-9' < file.txt                 # remove all digits
tr -d '\r' < windows-file.txt          # remove Windows carriage returns (DOS → Unix)
echo "he110 w0rld" | tr -d '0-9'       # he w rld

# ─── Squeeze repeated chars (-s) ─────────────────────────────────
tr -s ' ' < file.txt                   # collapse multiple spaces into one
tr -s '\n' < file.txt                  # remove blank lines (squeeze newlines)
echo "aabbccdd" | tr -s 'a-z'         # abcd (squeeze consecutive dupes)

# ─── Complement (-c) ─────────────────────────────────────────────
tr -cd 'a-zA-Z' < file.txt             # keep ONLY letters (delete everything else)
tr -cd '0-9\n' < file.txt              # keep only digits and newlines
tr -cd '[:print:]\n' < file.txt        # keep only printable characters (strip control chars)
```

---

## Character Classes

POSIX character classes work with both `tr` and `sed`/`grep`:

| Class | Matches |
|-------|---------|
| `[:lower:]` | All lowercase letters (a-z) |
| `[:upper:]` | All uppercase letters (A-Z) |
| `[:alpha:]` | All alphabetic characters |
| `[:digit:]` | All decimal digits (0-9) |
| `[:alnum:]` | All alphanumeric characters |
| `[:space:]` | All whitespace (space, tab, newline, etc.) |
| `[:punct:]` | All punctuation characters |
| `[:print:]` | All printable characters |
| `[:cntrl:]` | Control characters (\n, \t, \r, etc.) |

```bash
# Using character classes (portable across locales)
tr '[:lower:]' '[:upper:]' < file.txt    # preferred over tr 'a-z' 'A-Z'
tr -d '[:digit:]' < file.txt              # remove all digits
tr -d '[:space:]' < file.txt              # remove ALL whitespace
tr -s '[:space:]' ' ' < file.txt          # compress any whitespace to single space
```

---

## Practical DevOps Use Cases

```bash
# ─── Log processing ──────────────────────────────────────────────
# Count comma-separated fields in a CSV row
echo "a,b,c,d,e" | tr -cd ',' | wc -c   # 4 (count commas)

# Convert CSV to one-per-line
head -1 data.csv | tr ',' '\n'

# ─── Fix Windows line endings ─────────────────────────────────────
# Windows files have \r\n; Linux expects \n
tr -d '\r' < windows.txt > linux.txt
# Alternative: sed 's/\r//' windows.txt > linux.txt

# ─── Generate random strings ──────────────────────────────────────
cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 32   # 32-char random password

# ─── Clean input before processing ────────────────────────────────
# Strip non-printable control characters from a file
tr -cd '[:print:]\n' < messy.log > clean.log

# ─── Case normalization in scripts ────────────────────────────────
ENV=$(echo "$INPUT" | tr '[:upper:]' '[:lower:]')  # normalize env var to lowercase

# ─── Count words or characters ────────────────────────────────────
echo "hello world foo bar" | tr ' ' '\n' | wc -l   # 4 words
```

---

## tr vs sed vs awk — When to Use Which

| Tool | Operates on | Use for |
|------|------------|---------|
| `tr` | Individual characters | Character substitution/deletion/squeezing — single characters only |
| `sed` | Lines / patterns | Line editing, multi-char substitutions, regex patterns |
| `awk` | Fields / records | Structured data processing (CSV, logs with multiple columns) |

**`tr` cannot:**
- Match multi-character strings (`tr` works char-by-char, not string-by-string)
- Use `grep`-style regex (use `sed` for that)
- Process specific lines (it processes all input; use `sed` for line selection)

```bash
# ❌ tr can't do this (multi-char pattern):
tr 'hello' 'world'   # does NOT replace "hello" with "world"
                      # replaces h→w, e→o, l→r, l→l, o→d individually

# ✅ Use sed instead:
sed 's/hello/world/g' file.txt
```

---

## Interview Q&A

**Q: What does `tr -d '\r'` do and why is it commonly needed?**
It removes carriage return (`\r`) characters. Windows text files use `\r\n` (CRLF) as line endings, while Linux uses just `\n` (LF). When a Windows-created file is processed on Linux, the `\r` at the end of each line causes issues — scripts may fail to parse the content correctly, and you see `^M` at the end of lines in vim. `tr -d '\r' < windows.txt > linux.txt` strips the carriage returns, converting to Unix format. Alternatively: `sed 's/\r//'` or `dos2unix` utility.

**Q: How is `tr` different from `sed` for character replacement?**
`tr` replaces one CHARACTER with another CHARACTER — it's a character-to-character mapping. `sed s/old/new/g` replaces one STRING with another STRING. `echo "hello" | tr 'eo' 'EO'` gives "hEllO" — each character is replaced independently. `tr` cannot replace multi-character sequences. For "hello" → "world", you must use `sed 's/hello/world/g'` — `tr` would substitute individual characters in a position-based mapping, giving a wrong result.

**Q: How do you generate a random password with Linux built-in tools?**
`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 32` — `/dev/urandom` is the kernel's cryptographically secure random byte source; `tr -dc 'a-zA-Z0-9'` keeps only alphanumeric characters (deletes everything else with `-d`, complement with `-c`); `head -c 32` takes the first 32 characters. This is one of the most common `tr` interview examples. For passwords needing special characters: add them to the character set: `tr -dc 'a-zA-Z0-9!@#$%'`.
