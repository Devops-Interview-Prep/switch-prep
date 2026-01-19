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

- Enclosed in single ' ' or double " " quotes
- Immutable → cannot be changed after creation
```python
s = "hello"
s[0] = "H"  ❌ ERROR (strings cannot be modified)
```

- Multiline String 
```python
message = """Hello
Welcome to Python"""
```

Operations:

```python
s.upper()
s.lower()
s.replace("h", "H")
len(s)

age = 25
age_str = str(age)

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

**Arithmetic**: `+  -  *  /(true devison)  //(int devison)  %  **`

```python
 10 / 3 = 3.3 
 10 // 3 = 3
 ```

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

- A list is an ordered, changeable collection of items.

```python
empty_list = []
fruits = ["apple", "banana", "mango"]
numbers = [1, 2, 3, 4]
mixed = [1, "hello", 3.5]
chars = list("python")   # ['p', 'y', 't', 'h', 'o', 'n']

fruits.append("orange")   # add item
fruits.remove("banana")   # remove item
fruits[0] = "grape"       # modify item

print(fruits)

```
```python
print(fruits[0])    # first item
print(fruits[-1])   # last item
```

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

- A tuple is like a list, but cannot be changed.

```python
empty_tuple = ()
one_item = (10,)   # comma is required
coordinates = 10, 20
nums = tuple([1, 2, 3])
coordinates = (10, 20)
days = ("Mon", "Tue", "Wed")
print(days[1])   # Tue
```
✔ Data should not change   
✔ Safer than lists     
✔ Slightly faster than lists

- When to use tuples

✔ Coordinates      
✔ Configuration values     
✔ Database records

**Set**:
- A set is an unordered collection of unique elements.
  
```python
empty_set = set()   # NOT {}
nums = set([1, 2, 2, 3]) # {1,2,3}
letters = set("hello")   # {'h', 'e', 'l', 'o'}
numbers = {1, 2, 3, 4, 4, 5}
print(numbers)

Output:  {1, 2, 3, 4, 5}
```
✔ Uses curly braces {}     
✔ No duplicates        
✔ Unordered        
✔ Mutable (you can add/remove items)

```python
numbers.add(6)
numbers.remove(2)
```

```python 
a = {1, 2, 3}
b = {3, 4, 5}

print(a | b)   # Union → {1,2,3,4,5}
print(a & b)   # Intersection → {3}
print(a - b)   # Difference → {1,2}
```


**Dictionary**:

- A dictionary stores data in key : value pairs.

✔ Uses curly braces {}         
✔ Keys must be unique          
✔ Values can be anything           
✔ Mutable

```python
empty_dict = {}
user = {"name": "Pawan", "age": 25}
user["name"].  # pawan
user.get("email", "NA")


user["age"] = 26
user["city"] = "Bangalore"
```

```python

data = [("a", 1), ("b", 2)]
my_dict = dict(data)

employee = dict(name="Amit", role="DevOps", exp=4)

```

- Looping 
```python 
for key, value in user.items():
    print(key, value)
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
