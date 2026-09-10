# Python re Module — Regular Expressions

> Regex (Regular Expression) is a pattern language for searching, matching, extracting, and validating text. Python's `re` module provides full regex support — used in log analysis, input validation, CLI tools, and monitoring automation.

---

## What Is Regex?

```python
import re

# Regex is a pattern that describes a set of strings
# Think of it as Ctrl+F on steroids:
# - Find "error" in logs
# - Match IP addresses:  \d{1,3}(\.\d{1,3}){3}
# - Extract timestamps:  \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}
# - Validate emails:     ^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$
```

---

## Core Functions

| Function | Purpose | Returns |
|----------|---------|---------|
| `re.search()` | Find first match anywhere in string | Match object or None |
| `re.match()` | Match only at the beginning | Match object or None |
| `re.findall()` | Find all matches | List of strings |
| `re.finditer()` | Find all matches (iterator) | Iterator of Match objects |
| `re.sub()` | Replace matches | New string |
| `re.split()` | Split string using pattern | List of strings |
| `re.compile()` | Pre-compile pattern for reuse | Pattern object |

---

## re.search() — Most Used

```python
import re

text = "error occurred at 10:30"

# Find first occurrence anywhere in string:
result = re.search("error", text)
print(result)          # <re.Match object; span=(0, 5), match='error'>
print(result.group())  # 'error'
print(result.start())  # 0

# Returns None if no match (always check before calling .group()):
result = re.search("fatal", text)
if result:
    print(result.group())
else:
    print("no match")

# Practical use — log grep:
for line in log_lines:
    if re.search(r"ERROR|FATAL", line, re.IGNORECASE):
        print(line)
```

---

## re.match() vs re.search()

```python
# re.match() only matches at the START of the string:
re.match("error", "error occurred")   # match (starts with "error")
re.match("error", "fatal error")      # None (doesn't start with "error")

# re.search() finds anywhere:
re.search("error", "fatal error")     # match (found at position 6)
```

**When to use which:** use `re.search()` almost always. Use `re.match()` only when you specifically need to validate the beginning of a string (e.g., checking if a string starts with a particular format).

---

## re.findall() and re.finditer()

```python
text = "error error warning error"

# findall — returns all matches as a list:
matches = re.findall("error", text)
print(matches)    # ['error', 'error', 'error']

# findall with groups — returns list of tuples:
matches = re.findall(r"(\d{1,3})\.(\d{1,3})", "10.0 192.168")
print(matches)    # [('10', '0'), ('192', '168')]

# finditer — memory efficient, gives position info:
for match in re.finditer("error", text):
    print(match.start(), match.group())
    # 0 error
    # 6 error
    # 20 error

# Use finditer for large log files (doesn't load all matches into memory)
```

---

## re.sub() and re.split()

```python
# re.sub() — replace text:
re.sub("error", "ERROR", text)
# Result: "ERROR ERROR warning ERROR"

# Practical use — mask secrets in logs:
log = "API key: abc123xyz, user: john"
masked = re.sub(r"key: \w+", "key: [REDACTED]", log)
# "API key: [REDACTED], user: john"

# re.sub() with function as replacement:
re.sub(r"\d+", lambda m: str(int(m.group()) * 2), "1 plus 2 is 3")
# "2 plus 4 is 6"

# re.split() — split using pattern:
re.split(r"\s+", "one   two  three")   # ['one', 'two', 'three']
re.split(r"[,;]", "a,b;c,d")          # ['a', 'b', 'c', 'd']
```

---

## re.compile() — Reuse and Flags

```python
# Compile once, use many times (faster in loops):
pattern = re.compile(r"ERROR|FATAL", re.IGNORECASE)

for line in log_lines:
    if pattern.search(line):
        print(line)

# Important flags:
pattern = re.compile(r"^error", re.MULTILINE | re.IGNORECASE)
# re.IGNORECASE  → case-insensitive matching
# re.MULTILINE   → ^ and $ match each line start/end (not just string)
# re.DOTALL      → . matches any char including newlines
# re.VERBOSE     → allows comments and whitespace in pattern

# Verbose mode — readable complex patterns:
email_pattern = re.compile(r"""
    ^           # start of string
    [\w.+-]+    # username part
    @           # at symbol
    [\w-]+      # domain name
    \.          # dot (escaped)
    [a-zA-Z]{2,} # TLD
    $           # end of string
""", re.VERBOSE)
```

---

## Pattern Syntax Reference

```python
# Metacharacters:
.        # any character except newline
^        # start of string/line
$        # end of string/line
\d       # digit [0-9]
\D       # non-digit
\w       # word char [a-zA-Z0-9_]
\W       # non-word char
\s       # whitespace
\S       # non-whitespace
\b       # word boundary
\B       # non-word boundary

# Quantifiers:
*        # 0 or more
+        # 1 or more
?        # 0 or 1 (optional)
{n}      # exactly n
{n,}     # at least n
{n,m}    # between n and m
*? +? ?? # lazy (non-greedy) versions

# Character classes:
[abc]    # a or b or c
[a-z]    # range
[^0-9]   # NOT digits
(a|b)    # a or b (alternation)

# Grouping:
(expr)         # capturing group
(?:expr)       # non-capturing group
(?P<name>expr) # named capturing group

# Examples:
ip_pattern  = r"\d{1,3}(\.\d{1,3}){3}"
http_status = r"\b[1-5]\d{2}\b"
timestamp   = r"\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}"
```

---

## Named Groups and Capturing

```python
# Named groups — most readable approach:
match = re.search(
    r"(?P<hour>\d{2}):(?P<minute>\d{2}):(?P<second>\d{2})",
    "Log at 10:45:32"
)
if match:
    print(match.group("hour"))    # "10"
    print(match.group("minute"))  # "45"
    print(match.groupdict())      # {'hour': '10', 'minute': '45', 'second': '32'}

# Using sub with named groups:
re.sub(r"(?P<month>\d{2})/(?P<day>\d{2})/(?P<year>\d{4})",
       r"\g<year>-\g<month>-\g<day>",
       "12/25/2024")
# "2024-12-25"
```

---

## re.search vs re.match vs re.fullmatch — Comparison

| Function | Where it searches | Use case |
|----------|------------------|----------|
| `re.match()` | Beginning only | Validate format of a string prefix |
| `re.search()` | Anywhere | Find pattern in text |
| `re.fullmatch()` | Entire string | Validate complete string format |

```python
# e.g., validating an IP address completely:
if re.fullmatch(r"\d{1,3}(\.\d{1,3}){3}", user_input):
    print("valid IP format")
# re.search() would also match "192.168.1.1xyz" — fullmatch requires complete match
```

---

## When NOT to Use Regex

```python
# Use simple string methods for simple tasks:
# ❌ Slow, overkill:
if re.search("error", line):
    ...

# ✓ Faster, cleaner:
if "error" in line:
    ...

# When to use regex:
# ✓ Pattern matching (variable formats)
# ✓ Extracting parts of strings
# ✓ Complex validation (email, IP, timestamps)
# ✓ Log parsing with structure
```

---

## Interview Q&A

**Q: What is the difference between `re.search()` and `re.match()`?**
`re.search()` scans the entire string for the pattern and returns the first match wherever it appears. `re.match()` only checks for a match at the very beginning of the string — it won't find a match if the pattern appears anywhere else. In practice, `re.search()` is almost always what you want. Use `re.match()` specifically when validating a string format that must start a particular way (e.g., verifying a line starts with a timestamp). Remember: `re.match()` on `"fatal error"` for pattern `"error"` returns None — use `re.search()` instead.

**Q: Why use `re.compile()` and when does it actually help?**
`re.compile()` pre-compiles a regex pattern into a pattern object, so the pattern isn't reparsed on every call. This is most beneficial in tight loops — e.g., grepping through millions of log lines. Python's `re` module does cache compiled patterns internally (small LRU cache), so the speedup from explicit `compile()` depends on whether you'd hit the cache limit. The other reason to use `compile()` is code clarity: naming the compiled pattern (`error_pattern = re.compile(...)`) makes code more readable and allows adding flags like `re.IGNORECASE` in one place.
