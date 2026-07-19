# PYTHON re (Regex) MODULE — COMPLETE BEGINNER → ADVANCED NOTES

1️⃣ What is Regex? (Concept First)

- Regex = Regular Expression
- It is a pattern language used to:
    - Search text
    - Match formats
    - Extract data
    - Validate input

- Examples:
    - Find "error" in logs
    - Match IP addresses
    - Extract timestamps
    - Validate emails

- Think of regex as:
    - Ctrl+F on steroids

2️⃣ Why Python has re module

- Python provides the re module to:
    - Create regex patterns
    - Search text
    - Extract matches
    - Replace text

- Used in:
    - grep
    - log analysis
    - monitoring tools
    - input validation

3️⃣ Importing re

`import re`

4️⃣ Core Regex Functions (MOST IMPORTANT)

| Function        | Purpose                     |
| --------------- | --------------------------- |
| `re.search()`   | Find first match anywhere   |
| `re.match()`    | Match at beginning only     |
| `re.findall()`  | Find all matches            |
| `re.finditer()` | Find all matches (iterator) |
| `re.sub()`      | Replace matches             |
| `re.split()`    | Split using regex           |
| `re.compile()`  | Precompile pattern          |


5️⃣ re.search() — Most Used

`re.search(pattern, text)`


- Finds first occurrence anywhere in string.

```python

text = "error occurred at 10:30"
result = re.search("error", text)

print(result)


✔️ Match found
❌ Returns None if no match

Why we used it in pygrep
if regex.search(line):
    print(line)

```

6️⃣ re.match() — Beginning Only

```python
re.match("error", "error occurred")  # match
re.match("error", "fatal error")     # no match

```


✔️ Use only when start matters

7️⃣ re.findall() — Get All Matches

```python
text = "error error warning error"
matches = re.findall("error", text)

print(matches)


Output:

['error', 'error', 'error']
```

8️⃣ re.finditer() — Best for Large Data

```python
for match in re.finditer("error", text):
    print(match.start(), match.group())
```

✔️ Memory efficient
✔️ Gives position info

9️⃣ re.sub() — Replace Text

```python
re.sub("error", "ERROR", text)

```
- Used for:
    - Masking secrets
    - Redaction
    - Log formatting

🔟 re.split() — Split Using Pattern

```python
re.split(r"\s+", "one   two  three")


Output:

['one', 'two', 'three']

```

1️⃣1️⃣ re.compile() — PERFORMANCE & CLEAN CODE

```python
pattern = re.compile("error")
pattern.search(text)

```


- Why compile?
    - Faster for repeated use
    - Cleaner code
    - Required for flags

1️⃣2️⃣ Regex Flags (VERY IMPORTANT)

| Flag            | Meaning                 |
| --------------- | ----------------------- |
| `re.IGNORECASE` | Case-insensitive        |
| `re.MULTILINE`  | `^` and `$` match lines |
| `re.DOTALL`     | `.` matches newline     |
| `re.VERBOSE`    | Readable regex          |


Example:

`re.compile("error", re.IGNORECASE)`

1️⃣3️⃣ Basic Regex Patterns (CORE SYNTAX)

- Literal match
`error`

- Any character   `.`

- Digits / Words / Spaces 

| Pattern | Meaning    |
| ------- | ---------- |
| `\d`    | digit      |
| `\w`    | word char  |
| `\s`    | whitespace |

- Quantifiers

| Symbol | Meaning    |
| ------ | ---------- |
| `*`    | 0 or more  |
| `+`    | 1 or more  |
| `?`    | 0 or 1     |
| `{n}`  | exactly n  |
| `{n,}` | at least n |


Example:
`\d+`

1️⃣4️⃣ Anchors

| Anchor | Meaning       |
| ------ | ------------- |
| `^`    | start of line |
| `$`    | end of line   |


Example: `^error`

1️⃣5️⃣ Character Classes

```python
[abc]     # a or b or c
[a-z]     # lowercase letters
[^0-9]    # NOT digits
```

1️⃣6️⃣ Groups & Capturing

```python
match = re.search(r"(\d{2}):(\d{2})", "Time 10:45")
print(match.group(1))  # 10
print(match.group(2))  # 45
```

1️⃣7️⃣ Named Groups (Very Useful)

```python
r"(?P<hour>\d{2}):(?P<minute>\d{2})"
```

1️⃣8️⃣ Escaping Characters

- Special characters must be escaped:

`\. \* \+ \?`


- Use raw strings:

`r"\d+"`

1️⃣9️⃣ Common Regex Examples (SRE GOLD)

- IP Address        
`\d{1,3}(\.\d{1,3}){3}`

- HTTP Status Code          
`\b[1-5]\d{2}\b`

- Timestamp     
`\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}`

2️⃣0️⃣ Error Handling in Regex

- Invalid regex:       
`re.compile("[")`

- Raises:    
`re.error`


- We handled this in pygrep.

2️⃣1️⃣ Regex in pygrep (Full Context)
```python
flags = re.IGNORECASE if args.ignore_case else 0
regex = re.compile(args.pattern, flags)

if regex.search(line):
    print(line)

```

2️⃣2️⃣ When NOT to Use Regex

❌ Simple substring search      
❌ Performance-critical exact match     
❌ Overcomplicated patterns

- Use:

    - if "error" in line:

2️⃣3️⃣ Interview One-Liners (IMPORTANT)

- re.search() finds first match anywhere

- re.match() matches from beginning

- re.findall() returns all matches

- re.compile() improves performance and supports flags

