- An error is something that interrupts the normal flow of a program.

# Errors vs Exceptions (Important distinction)

🔴 Syntax Errors (NOT handleable)
- These happen before execution.
  
```python
if True
    print("hi")

# SyntaxError: invalid syntax

```
👉 You cannot catch syntax errors with try/except.


🟢 Exceptions (Handleable)

- These happen at runtime.

- Examples:
  - FileNotFoundError
  - ZeroDivisionError
  - ValueError
  - TypeError
  - IndexError
  - KeyError
  - re.error

- These can be caught and handled.

# The basic structure: try / except

```python 
try:
    risky_code()
except SomeError:
    handle_error()
```
- Example

```python 
try:
    x = int("abc")
except ValueError:
    print("Invalid number")
```

✔ Program continues
✔ No crash

# Why error handling is needed (Real-world view)

- Without error handling:

`open("file.txt")`

❌ If file missing → program crashes

- With error handling:
  
```python 
try:
    open("file.txt")
except FileNotFoundError:
    print("File not found")
```

✔ Program survives
✔ User-friendly message
✔ Other tasks continue

👉 Critical for CLI tools, services, automation, SRE scripts

# Multiple except blocks

- You can handle different errors differently.

```python 
try:
    f = open("data.txt")
    x = int("abc")
except FileNotFoundError:
    print("File missing")
except ValueError:
    print("Invalid integer")
```

# Catching multiple exceptions together

```python 
except (FileNotFoundError, PermissionError):
    print("File access problem")
```

- Use this when handling logic is the same.

# The else block (rare but useful)

- Runs only if no exception occurred.

```python
try:
    x = int("10")
except ValueError:
    print("Error")
else:
    print("Success:", x)
```

✔ Cleaner logic
✔ Avoids flags like success = True

# The finally block (VERY important)

- Runs always, whether error occurs or not.

```python
try:
    f = open("file.txt")
    data = f.read()
except FileNotFoundError:
    print("File missing")
finally:
    print("Cleaning up")
```

- Used for:
    - Closing files
    - Releasing resources
    - Cleaning temporary data

