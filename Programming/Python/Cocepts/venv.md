# Virtual Environments

🔹 The problem venv solves

- Without venv:
  - Global Python
  - Conflicting dependencies
  - System breakage
  - Works on my machine” syndrome
- Example:
  - Project A needs requests==2.25
  - Project B needs requests==2.31  
    
✔ You create two separate virtual environments     
✔ You activate them separately     
✔ You install dependencies separately      
✔ They do NOT conflict


```
cd project-A
python3 -m venv venv
source venv/bin/activate
pip install requests==2.25

cd project-B
python3 -m venv venv
source venv/bin/activate
pip install requests==2.31

```

🔹 What is a virtual environment?
- An isolated Python + site-packages directory

```
Project/
├── venv/
│   ├── bin/python
│   ├── bin/pip
│   └── lib/python3.x/site-packages
```

- Each project gets its own Python world

🔹 Create a virtual environment

```python
python3 -m venv venv

# or 
python3.9 -m venv venv

# or 

python3.11 -m venv venv

```

❓ What happens WITHOUT venv

```python
pip install requests==2.25

import requests
print(requests.__version__)

# output 2.25

# for project B

pip install requests==2.31

# Now Project A runs again:
print(requests.__version__)

# Output 2.31
# Project A is now broken

```

- Copies Python binary
- Creates isolated pip

🔹 Activate virtual environment

```python
source venv/bin/activate
```

🔹 What activation REALLY does

- Updates PATH
- Points python → venv/bin/python
- Points pip → venv/bin/pip

🔹 Install packages safely

```python
pip install click requests rich
```
🔹 Freeze dependencies

```python
pip freeze > requirements.txt
```

🔹 Why venv is CRITICAL for CLI tools

- when you build , package and distribute cli you need Predictable versions, Reproducible builds, No dependency hell.

🔹 venv vs pipx vs poetry

| Tool   | Use case                        |
| ------ | ------------------------------- |
| venv   | Project isolation               |
| pipx   | Install global CLI tools safely |
| poetry | Dependency + packaging manager  |

