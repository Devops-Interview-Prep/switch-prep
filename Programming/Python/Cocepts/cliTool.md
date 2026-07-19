- In a file every line ends with a new line /n
- if we do `print(line)` it will add an extra line to it and will print a empty line

# argparse

- argparse is Python’s standard library for building professional CLI tools.
- It handles:
  - Parsing command-line arguments
  - Flags and options
  - Validation
  - --help messages
  - Default values
  - Error handling

- Used by tools like:
  - pip
  - aws
  - kubectl

**Why argparse instead of sys.argv?**

sys.argv ❌
    - Manual parsing
    - No validation
    - No help text
    - Error-prone
    - Hard to scale
argparse ✅
    - Auto --help
    - Type conversion
    - Defaults
    - Optional & positional args
    - Clean and readable

**Basic Structure of an argparse Program**

```python
import argparse

parser = argparse.ArgumentParser(description="My CLI tool")

parser.add_argument("input")
parser.add_argument("-v", action="store_true")

args = parser.parse_args()
```

- User runs command
- argparse parses CLI input
- Values stored in args
- Your logic uses args

**ArgumentParser() – Core Object**

```python
parser = argparse.ArgumentParser(
    prog="pygrep",
    description="Search text in files",
    epilog="Example: pygrep -n error app.log"
)
```

| Parameter         | Purpose          |
| ----------------- | ---------------- |
| `prog`            | Program name     |
| `description`     | Shown in help    |
| `epilog`          | Footer help text |
| `formatter_class` | Help formatting  |

**Positional Arguments (Required)**

```python
parser.add_argument("pattern")
parser.add_argument("file")
```

- Required by default
- Order matters
- No hyphen (-)

**Optional Arguments (Flags)**

```python
parser.add_argument("-n")
```
- Start with - or --
- Optional
- Order independent

**Short Flags vs Long Flags**

```python 
parser.add_argument("-n", "--line-number")
```

- Short → frequent usage
- Long → readability

**dest — Where the Value Is Stored**
```python
parser.add_argument("-n", dest="line_numbers", action="store_true")

# Access via:
args.line_numbers
```

- If dest not specified:
  - Derived from flag name
  - --line-number → args.line_number

**help — CLI Documentation**

```python
parser.add_argument("-n", help="Show line numbers")

# Auto shown in:
pygrep --help
```
**action**

- action defines what argparse does when the argument appears.

🔹 store (DEFAULT)

```python
parser.add_argument("-o", action="store")

# usage
cmd -o output.txt

# result
args.o == "output.txt"
```
🔹 store_true (Boolean ON flag)

```python
parser.add_argument("-n", action="store_true")

# Usage:
cmd -n

# Result:
args.n == True

#Absent:
args.n == False
```
- Used for -n, -i, -v, -r


🔹 store_false (Disable feature)

```python 
parser.add_argument("--no-color", action="store_false", dest="color")

# Default:
args.color == True

# Usage:

cmd --no-color

# Result:

args.color == False
```

🔹 count (Verbosity flags)

```python 

parser.add_argument("-v", action="count", default=0)

# Usage:
cmd -v
cmd -vv
cmd -vvv

# Result:
args.v == 1 / 2 / 3
```
🔹 append (Multiple values)

```python

parser.add_argument("-e", action="append")

# Usage:

cmd -e one -e two

# Result:

args.e == ["one", "two"]

```
🔹 append_const

```python
parser.add_argument("--debug", action="append_const", const="DEBUG")

```

🔹 version

```python

parser.add_argument("--version", action="version", version="1.0")

# Usage:

cmd --version

```

**default — Value When Flag Is Absent**

```python

parser.add_argument("-n", action="store_true", default=False)

```
- store_true → False
- count → None (set explicitly)

**type — Automatic Type Conversion**

```python 
parser.add_argument("--port", type=int)

# Usage:
cmd --port 8080

# Result:

args.port == 8080

```

**choices — Allowed Values**

```python

parser.add_argument("--env", choices=["dev", "staging", "prod"])

# Usage:
cmd --env prod

# Invalid:
invalid choice
```

**required=True (Optional args only)**

```python
parser.add_argument("--config", required=True)

# Usage:
cmd --config app.yaml

```
❌ Only for optional arguments

**nargs — Number of Values**

| `nargs` | Meaning      |
| ------- | ------------ |
| `1`     | Single value |
| `?`     | Optional     |
| `*`     | Zero or more |
| `+`     | One or more  |

```python

parser.add_argument("files", nargs="+")

# Usage:
cmd file1 file2 file3
```

**metavar — Display Name in Help**

```python

parser.add_argument("--port", metavar="PORT")

# Help shows:
--port PORT

```

**parse_args() — Triggers Parsing**

`args = parser.parse_args()`

- Reads sys.argv
- Validates
- Errors & exits automatically

**Error Handling (Built-in)**

- Invalid input:
  - `cmd --unknown`
- Output:
  ```python
        usage: ...
        error: unrecognized arguments

    # Exit code:
    echo $?
    # 2
  ```

**Subcommands (Advanced / kubectl style)**

```python
subparsers = parser.add_subparsers(dest="command")

get_parser = subparsers.add_parser("get")
get_parser.add_argument("resource")

# Usage:
kubectl get pods
```










