# Python Error Handling

> Python distinguishes between Syntax Errors (caught before execution) and Exceptions (caught at runtime). The `try/except/else/finally` block is the core tool for handling errors gracefully — essential for CLI tools, services, API clients, and SRE automation scripts.

---

## Errors vs Exceptions

```python
# ── Syntax Errors — NOT catchable ────────────────────────────────────
# These fail at parse time — program never starts
if True
    print("hi")
# SyntaxError: invalid syntax

# ── Runtime Exceptions — catchable with try/except ────────────────────
x = int("abc")         # ValueError
y = 10 / 0             # ZeroDivisionError
z = [1, 2][5]          # IndexError
d = {}; d["key"]       # KeyError
open("nope.txt")       # FileNotFoundError
None.upper()           # AttributeError
"a" + 1               # TypeError
```

---

## Common Exception Types

| Exception | When it occurs |
|-----------|----------------|
| `ValueError` | Invalid value for the type (e.g., `int("abc")`) |
| `TypeError` | Wrong type (e.g., `"a" + 1`) |
| `ZeroDivisionError` | Division by zero |
| `IndexError` | List index out of range |
| `KeyError` | Dict key doesn't exist |
| `FileNotFoundError` | File doesn't exist |
| `PermissionError` | No access rights |
| `AttributeError` | Object has no such attribute |
| `ImportError` | Module not found |
| `RuntimeError` | Generic runtime problem |
| `StopIteration` | Iterator exhausted |
| `OSError` | OS-level error (wraps IOError, EnvironmentError) |

---

## Full try/except/else/finally Structure

```python
try:
    # Code that might raise an exception
    result = risky_operation()

except SpecificError as e:
    # Handle one specific exception type
    print(f"Specific error: {e}")

except (TypeError, ValueError) as e:
    # Handle multiple exception types the same way
    print(f"Type/Value error: {e}")

except Exception as e:
    # Catch-all for any unexpected exception (use sparingly)
    print(f"Unexpected error: {type(e).__name__}: {e}")

else:
    # Runs ONLY if no exception occurred
    # Better than putting code at end of try (more explicit)
    print(f"Success: {result}")

finally:
    # Runs ALWAYS — exception or not
    # Use for cleanup: close files, release locks, disconnect DB
    cleanup()
```

---

## Practical Examples

```python
# ── File handling ─────────────────────────────────────────────────────
try:
    with open("config.txt") as f:    # 'with' auto-closes even on error
        data = f.read()
except FileNotFoundError:
    print("Config file not found, using defaults")
    data = default_config()
except PermissionError:
    print("Cannot read config file — check permissions")

# ── API calls ─────────────────────────────────────────────────────────
import requests

try:
    response = requests.get("https://api.example.com/data", timeout=5)
    response.raise_for_status()   # raises HTTPError for 4xx/5xx
    data = response.json()
except requests.exceptions.Timeout:
    print("Request timed out")
except requests.exceptions.HTTPError as e:
    print(f"HTTP error: {e.response.status_code}")
except requests.exceptions.ConnectionError:
    print("Network connection failed")

# ── Type conversion with default ──────────────────────────────────────
def safe_int(s, default=0):
    try:
        return int(s)
    except (ValueError, TypeError):
        return default

# ── Database operations with rollback ────────────────────────────────
try:
    conn.execute("INSERT INTO users VALUES (?)", (user_id,))
    conn.commit()
except Exception as e:
    conn.rollback()    # undo partial changes
    raise              # re-raise after cleanup
```

---

## Raising and Custom Exceptions

```python
# ── raise an exception ────────────────────────────────────────────────
def divide(a, b):
    if b == 0:
        raise ValueError("Denominator cannot be zero")
    return a / b

# ── raise from another exception (exception chaining) ─────────────────
try:
    result = int("abc")
except ValueError as e:
    raise RuntimeError("Failed to parse input") from e
# Shows both exceptions: "The above exception was the direct cause of..."

# ── Custom exception classes ──────────────────────────────────────────
class InsufficientFundsError(Exception):
    def __init__(self, amount, balance):
        self.amount = amount
        self.balance = balance
        super().__init__(f"Cannot withdraw {amount}: balance is {balance}")

class DatabaseConnectionError(RuntimeError):
    pass   # just a renamed RuntimeError for more specific catching

# Usage:
try:
    withdraw(account, 1000)
except InsufficientFundsError as e:
    print(f"Error: {e}")  # "Cannot withdraw 1000: balance is 500"
    print(f"Short by: {e.amount - e.balance}")
```

---

## Context Managers — The `with` Statement

```python
# with statement = try/finally + __enter__/__exit__
# Ensures cleanup runs even if an exception occurs

# File (auto-close):
with open("file.txt") as f:
    data = f.read()
# f.close() called automatically, even if f.read() raises

# Multiple context managers:
with open("input.txt") as src, open("output.txt", "w") as dst:
    dst.write(src.read())

# Custom context manager:
from contextlib import contextmanager

@contextmanager
def timer(label):
    import time
    start = time.time()
    try:
        yield          # code in 'with' block runs here
    finally:
        elapsed = time.time() - start
        print(f"{label}: {elapsed:.2f}s")

with timer("database query"):
    results = db.query("SELECT ...")
```

---

## Interview Q&A

**Q: What is the difference between `except Exception` and bare `except:`?**
`except Exception` catches all exceptions that inherit from `Exception` — which is nearly everything you'd encounter. Bare `except:` also catches `SystemExit`, `KeyboardInterrupt`, and `GeneratorExit` — signals that are meant to terminate the program. Using bare `except:` can hide bugs and prevent Ctrl+C from working. The rule: always use `except Exception` as the catch-all, never bare `except`. Even better: catch specific exceptions first, then `Exception` as a last resort.

**Q: When should you use `else` in a try/except block?**
The `else` block runs only when the `try` block completes without raising an exception. Use it for code that should run only on success — it's semantically cleaner than putting that code inside `try`. Example: if you're opening a file and processing it, put the file processing in `else` (not in `try`), so that any `IOError` in processing is separate from the `FileNotFoundError` in opening. It also prevents "accidentally catching" exceptions raised by the success-path code.

**Q: What is the purpose of `raise ... from e` vs just `raise`?**
Bare `raise` inside an except block re-raises the current exception unchanged — useful for after cleanup. `raise NewError() from e` creates a new exception while preserving the original as `__cause__` — this is "explicit exception chaining." Python prints both: "The above exception was the direct cause of...". This is the correct pattern when translating low-level errors to domain errors (e.g., `requests.ConnectionError` → `DatabaseUnavailableError`). It preserves the debug trail without exposing library internals to callers.
