🔹 What is a module?

- A module is simply a Python file.
- If Python sees a .py file, it treats it as a module.

```python
math.py        → module
utils.py       → module
config.py      → module
```

🔹 How import works

```python
# Import entire module
import math
print(math.sqrt(16))
# Import specific functions
from math import sqrt
print(sqrt(16))

# Import with alias
import datetime as dt
print(dt.datetime.now())
```

- Python searches in this order:
  - Current script directory
  - PYTHONPATH
  - Standard library (/usr/lib/python3.x)
  - Installed packages (site-packages)


🔹 Packages

- A package = folder containing modules.

```
mycli/
├── __init__.py
├── main.py
├── utils/
│   ├── __init__.py
│   ├── file.py
│   └── log.py
```

```python
from utils.file import read_file
```

👉 \__init__.py tells Python:       
    - “This folder is importable”       
    - Modern Python allows implicit packages, but still recommended


🔹 Absolute vs Relative imports

- Absolute (RECOMMENDED)
```python
from mycli.utils.file import read_file
```
- Relative (ONLY inside packages)
```python
from .file import read_file
```


🔹 Common import mistakes

❌ Circular imports

```python
# a.py
import b

# b.py
import a
```
- Move shared code to common.py

❌ Running module directly

```python 
python utils/file.py
```
- This breaks relative imports.

```python
# correct
python -m mycli.main
```


🔹 \_\_name__ == "\_\_main__"

```python
if __name__ == "__main__":
    main()

# without this in the module
Imports trigger execution
```

- Script run directly → code executes
- Imported → code doesn’t auto-run

- Think of a Python file like a TV 📺

    - Importing a file → You buy the TV (functions available)

    - Running a file → You press the power button
        - if \_\_name__ == "\_\_main__"
          = “Only turn on the TV if I press the power button”
        - if we skip this then the TV will try to get ON without pressing the power button 

