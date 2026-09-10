# Python Modules and Packages

> A module is a Python file (`.py`). A package is a directory with an `__init__.py`. Modules let you organize code into reusable units, avoid name collisions, and control what gets executed when imported vs run directly.

---

## What Is a Module?

```python
# Any .py file is a module:
math.py         # module
utils.py        # module
config.py       # module

# Import and use:
import math
print(math.sqrt(16))   # 4.0
print(math.pi)         # 3.141592...

# Import specific names:
from math import sqrt, floor
print(sqrt(9))          # 3.0

# Import with alias:
import datetime as dt
print(dt.datetime.now())

# Import everything (avoid — pollutes namespace):
from math import *
```

---

## How Python Finds Modules (Import Search Order)

```python
# When you write `import utils`, Python searches in this order:
# 1. sys.modules (cache — already imported modules)
# 2. Current script directory
# 3. PYTHONPATH environment variable directories
# 4. Standard library (/usr/lib/python3.x)
# 5. Installed packages (site-packages: pip installs go here)

import sys
print(sys.path)    # see the actual search paths

# Add a directory to search path:
sys.path.insert(0, '/my/custom/path')
```

---

## Packages — Folders of Modules

```python
# A package = folder with __init__.py
mycli/
├── __init__.py          # marks the directory as a package
├── main.py
├── utils/
│   ├── __init__.py
│   ├── file.py
│   └── log.py

# Import from a package:
from mycli.utils.file import read_file
import mycli.utils.log as logger

# __init__.py can re-export for cleaner imports:
# In mycli/__init__.py:
from .utils.file import read_file   # now: from mycli import read_file
```

---

## Absolute vs Relative Imports

```python
# ── Absolute imports (recommended for most cases) ─────────────────────
# Always specify the full path from the project root
from mycli.utils.file import read_file
from mycli.utils.log import setup_logger

# ── Relative imports (only inside packages, not scripts) ───────────────
# Use . for current package, .. for parent package
from .file import read_file           # same package
from ..config import settings         # parent package
from .log import setup_logger         # sibling module

# ── When relative imports break ───────────────────────────────────────
# Running a module directly: python utils/file.py
# → relative imports FAIL (no package context)

# Fix: run as a module from project root:
python -m mycli.main

# Or: use absolute imports consistently
```

---

## Common Import Mistakes

```python
# ── Mistake 1: Circular imports ────────────────────────────────────────
# a.py:
import b
# b.py:
import a     # ← ImportError: circular import

# Fix: move shared code to a third file (common.py)
# Or: import inside a function (deferred import)
def get_something():
    import a   # only imported when function is called

# ── Mistake 2: Running module directly breaks relative imports ─────────
# utils/file.py has: from .log import setup_logger
python utils/file.py   # ❌ ModuleNotFoundError: relative import with no known parent

# Fix: always run from project root as a module:
python -m utils.file   # ✓ package context is set

# ── Mistake 3: Shadowing standard library ──────────────────────────────
# If you name your file math.py, it shadows the built-in math module
# import math → imports YOUR math.py, not the standard library
# Fix: don't name files after built-in modules
```

---

## `__name__ == "__main__"` — Script vs Module Guard

```python
# Every Python file has __name__ set:
# - When RUN directly: __name__ = "__main__"
# - When IMPORTED: __name__ = "module_name" (e.g., "utils")

# utils.py:
def process():
    print("processing...")

if __name__ == "__main__":
    process()   # only runs when file is executed directly, NOT when imported

# Without this guard:
# import utils   ← would execute process() immediately on import!

# Real-world use:
# - Module: import my_module  → functions available, nothing auto-executes
# - Script: python my_module.py → main() runs
def main():
    print("starting the app...")

if __name__ == "__main__":
    main()
```

---

## Interview Q&A

**Q: What is the difference between `import math` and `from math import sqrt`?**
`import math` imports the entire module as a namespace — you access functions as `math.sqrt`, `math.pi`. `from math import sqrt` imports only `sqrt` directly into the current namespace — you call it as `sqrt()`. The `from ... import` form is more convenient but can cause name collisions and makes the code less explicit (you can't tell where `sqrt` came from without seeing the import). For standard library modules with clear names (like `math.sqrt`), explicit namespace is often preferable for readability.

**Q: What does `__init__.py` do in a package?**
`__init__.py` tells Python "this directory is a package" — without it (in Python 2 and sometimes 3), the directory can't be imported as a module. It can be empty, or it can contain initialization code and re-exports to create a cleaner public API. Example: `mycli/__init__.py` can have `from .utils.file import read_file` so callers can write `from mycli import read_file` instead of `from mycli.utils.file import read_file`. In Python 3.3+, "namespace packages" (without `__init__.py`) are supported, but `__init__.py` is still recommended for explicit package boundaries.

**Q: How do you avoid a circular import error?**
The root cause is two modules importing each other at the module level. Solutions: (1) **Refactor**: extract shared code to a third module that neither A nor B imports from each other. (2) **Deferred import**: move the import inside a function so it's executed when the function is called, not at module load time. (3) **Import the module, not the name**: `import b` instead of `from b import something` — you defer the attribute lookup to call time.
