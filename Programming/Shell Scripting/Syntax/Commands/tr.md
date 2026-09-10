# tr — Translate, Squeeze, or Delete Characters

> `tr` works on character streams (stdin → stdout). Unlike sed/awk, it operates on individual characters only — no pattern matching, no line awareness, no string operations. Essential for case conversion, character stripping, and text normalization.

---

## Syntax and Options

```bash
tr [OPTIONS] SET1 [SET2]

# SET1: characters to translate FROM (or delete)
# SET2: characters to translate TO (must be same length as SET1 for translation)
```

| Option | Meaning |
|--------|---------|
| `-d` | **Delete** characters in SET1 (SET2 not needed) |
| `-s` | **Squeeze** repeated characters in SET1 to one occurrence |
| `-c` | **Complement** — match characters NOT in SET1 |
| `-cd` | Complement + delete — keep only SET1 characters |

---

## Basic Examples

```bash
# Case conversion
echo "hello world" | tr 'a-z' 'A-Z'     # HELLO WORLD
echo "HELLO WORLD" | tr 'A-Z' 'a-z'     # hello world
tr '[:lower:]' '[:upper:]' < file.txt   # file-based conversion

# Character substitution
echo "hello world" | tr ' ' '_'          # hello_world
echo "hello/world" | tr '/' '-'          # hello-world
echo "a:b:c" | tr ':' ' '               # a b c (colon to space)

# Delete characters
echo "hello123" | tr -d '0-9'           # hello (remove digits)
echo "hello!world?" | tr -d '!?'        # helloworld (remove punctuation)
echo "line1\r\nline2" | tr -d '\r'      # fix Windows CRLF line endings

# Squeeze repeated characters
echo "hello   world" | tr -s ' '        # hello world (multiple spaces → one)
echo "aabbccdd" | tr -s 'a-z'          # abcd (squeeze repeated letters)
echo "1---2---3" | tr -s '-'            # 1-2-3

# Keep only specific characters (complement + delete)
echo "abc123!@#" | tr -cd '[:alnum:]'   # abc123 (strip non-alphanumeric)
echo "abc123!@#" | tr -cd '[:alpha:]'   # abc (keep only letters)
echo "abc123!@#" | tr -cd '[:digit:]'   # 123 (keep only digits)
```

---

## POSIX Character Classes

```bash
# Use inside brackets with tr:
[:lower:]   → all lowercase letters (a-z)
[:upper:]   → all uppercase letters (A-Z)
[:alpha:]   → all letters (a-zA-Z)
[:digit:]   → all digits (0-9)
[:alnum:]   → letters + digits
[:space:]   → space, tab, newline, CR, form feed
[:punct:]   → punctuation characters
[:cntrl:]   → control characters (\n, \t, etc.)

# Examples:
echo "Hello World" | tr '[:upper:]' '[:lower:]'   # hello world
echo "Hello123" | tr -d '[:digit:]'               # Hello
echo "Hello World" | tr -s '[:space:]'            # Hello World (squeeze spaces)
```

---

## DevOps Practical Use Cases

```bash
# 1. Fix Windows CRLF line endings on Linux (common cause of script failures)
tr -d '\r' < windows_file.sh > unix_file.sh
# Or in-place via process substitution:
tr -d '\r' < script.sh | bash

# 2. Generate a random password (alphanumeric, 16 chars)
tr -dc '[:alnum:]' < /dev/urandom | head -c 16
# With special chars:
tr -dc '[:print:]' < /dev/urandom | head -c 20

# 3. Normalize CSV — convert all text to lowercase
tr '[:upper:]' '[:lower:]' < data.csv > normalized.csv

# 4. Convert newlines to spaces (for one-line output)
cat list.txt | tr '\n' ' '

# 5. Convert spaces to newlines (one word per line, for further processing)
echo "word1 word2 word3" | tr ' ' '\n'

# 6. Strip non-printable characters from a file
tr -cd '[:print:]\n' < messy_file.txt > clean_file.txt

# 7. Count lines (alternative to wc -l):
tr -cd '\n' < file.txt | wc -c
```

---

## tr vs sed vs awk

| Tool | Operates on | Supports patterns? | Multi-char substitution? |
|------|-------------|-------------------|--------------------------|
| `tr` | Individual characters | No — char-by-char only | No |
| `sed` | Lines (can target chars) | Yes — regex | Yes |
| `awk` | Fields + lines | Yes — regex | Yes |

**When to use tr:** simple character-level translation (case conversion, delimiter swap, stripping specific chars). Anything that needs patterns or string-level logic → use sed or awk.

```bash
# tr: swap colons to spaces — simpler
echo "a:b:c" | tr ':' ' '

# sed: swap "foo" to "bar" — tr can't do multi-char substitution
echo "foobar" | sed 's/foo/bar/g'
```

---

## Interview Q&A

**Q: What is the key limitation of `tr` compared to `sed`?**
`tr` works on individual characters only — it cannot match or substitute strings or patterns. `tr 'foo' 'bar'` does NOT replace the string "foo" with "bar"; it replaces each 'f'→'b', 'o'→'a', 'o'→'r' independently. For string substitution, use `sed 's/foo/bar/g'`. `tr` is also not line-aware — it processes the entire input stream as a sequence of characters, which is why you can convert newlines to spaces with `tr '\n' ' '`.

**Q: How do you fix Windows line endings (CRLF) on Linux?**
Windows text files end lines with `\r\n` (carriage return + newline). Linux expects only `\n`. When a Windows file is run as a bash script, the `\r` causes `/bin/bash^M: bad interpreter: No such file or directory`. Fix: `tr -d '\r' < script.sh > script_fixed.sh`. In git, use `git config core.autocrlf input` to auto-strip on checkout.

**Q: What does `tr -cd '[:alnum:]' < file` do?**
`-c` complements SET1 (matches everything NOT in `[:alnum:]` — i.e., all non-alphanumeric characters). `-d` deletes those matched characters. Combined: delete all non-alphanumeric characters, keeping only letters and digits. Useful for sanitizing input before processing.
