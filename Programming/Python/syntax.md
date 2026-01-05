# 🐍 Python Fundamentals – Complete Developer Guide

A **complete Python reference** covering syntax, concepts, and best practices every developer should know.

---

## 1. Python Basics

### Hello World

```python
print("Hello, World")
```

### Comments

```python
# Single-line comment
"""
Multi-line comment
(docstring)
"""
```

### Indentation

```python
if True:
    print("Correct indentation")
```

---

## 2. Variables & Data Types

* **Integer**: `x = 10`
* **Float**: `y = 10.5`
* **String**: `name = "Pawan"`
* **Boolean**: `is_active = True`
* **None**: `value = None`

Dynamic typing:

```python
x = 10
x = "string now"
```

Check type:

```python
type(x)
```

---

## 3. Strings

```python
s = "hello"
```

Operations:

```python
s.upper()
s.lower()
s.replace("h", "H")
len(s)
```

f-Strings:

```python
age = 25
print(f"Age is {age}")
```

---

## 4. Input & Output

```python
name = input("Enter name: ")
age = int(input("Enter age: "))
print(name, age)
```

---

## 5. Operators

**Arithmetic**: `+  -  *  /  //  %  **`

**Comparison**: `==  !=  >  <  >=  <=`

**Logical**: `and  or  not`

---

## 6. Control Flow

```python
if x > 10:
    print("Greater")
elif x == 10:
    print("Equal")
else:
    print("Smaller")
```

Ternary Operator:

```python
result = "yes" if x > 5 else "no"
```

---

## 7. Loops

For Loop:

```python
for i in range(5):
    print(i)
```

While Loop:

```python
i = 0
while i < 5:
    print(i)
    i += 1
```

Loop controls:

```python
break
continue
pass
```

---

## 8. Data Structures

**List**:

```python
nums = [1, 2, 3]
nums.append(4)
nums[0] = 100
```

Slicing:

```python
nums[1:3]
nums[::-1]
```

**Tuple**:

```python
t = (1, 2, 3)
```

**Set**:

```python
s = {1, 2, 3}
```

**Dictionary**:

```python
user = {"name": "Pawan", "age": 25}
user["name"]
user.get("email", "NA")
```

---

## 9. Functions

```python
def add(a, b):
    return a + b
```

Default arguments:

```python
def greet(name="Guest"):
    print(name)
```

Args & kwargs:

```python
def demo(*args, **kwargs):
    print(args, kwargs)
```

---

## 10. Lambda Functions

```python
square = lambda x: x * x
```

---

## 11. List Comprehensions

```python
squares = [x*x for x in range(5)]
```

With condition:

```python
evens = [x for x in range(10) if x % 2 == 0]
```

---

## 12. Exception Handling

```python
try:
    x = int("abc")
except ValueError:
    print("Error")
finally:
    print("Done")
```

---

## 13. File Handling

```python
with open("file.txt", "w") as f:
    f.write("Hello")
```

```python
with open("file.txt") as f:
    print(f.read())
```

---

## 14. Modules & Imports

```python
import math
math.sqrt(16)
```

```python
from math import sqrt
```

---

## 15. Virtual Environments

```bash
python -m venv venv
source venv/bin/activate
pip install requests
pip freeze > requirements.txt
```

---

## 16. Object-Oriented Programming

```python
class User:
    def __init__(self, name):
        self.name = name

    def greet(self):
        print(self.name)
```

Inheritance:

```python
class Admin(User):
    pass
```

---

## 17. Important Concepts

**Mutable vs Immutable**

* Mutable: list, dict, set
* Immutable: int, str, tuple

**is vs ==**

```python
a == b   # value
a is b   # memory
```

**None check**

```python
if x is None:
```

---

## 18. Built-in Functions

```python
len(), sum(), max(), min(), sorted()
zip(), enumerate(), any(), all()
```

---

## 19. Popular Libraries

* requests, json, argparse
* asyncio, pytest, boto3, kubernetes
* pandas, numpy

---

## 20. Best Practices

* Use virtual environments
* Follow PEP8
* Use `with` for resources
* Avoid global variables
* Write readable code

---

## Recommended Next Steps

* Python for DevOps scripting
* Async Python
* CLI tools with argparse
* Python interview questions

---
