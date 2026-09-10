# Python Virtual Environments

> A virtual environment (`venv`) is an isolated Python + pip directory. Each project gets its own dependencies with specific versions — no conflicts, reproducible builds, and the foundation of professional Python development.

---

## The Problem venv Solves

```python
# Without venv — dependency conflicts:
# Project A needs requests==2.25
pip install requests==2.25

# Later, Project B needs requests==2.31
pip install requests==2.31   # overwrites the global install

# Now Project A is broken — uses requests 2.31 silently
import requests
print(requests.__version__)  # 2.31 — NOT what Project A expected!
```

**With venv:** each project has its own isolated directory with its own Python and pip — they never interfere.

---

## Virtual Environment Structure

```
project-a/
├── venv/                        # isolated environment directory
│   ├── bin/
│   │   ├── python -> python3    # points to isolated Python binary
│   │   ├── pip                  # isolated pip
│   │   └── activate             # shell script to activate this env
│   └── lib/
│       └── python3.11/
│           └── site-packages/   # packages installed for THIS project only
├── src/
│   └── app.py
└── requirements.txt
```

---

## Create and Activate

```bash
# Create a virtual environment (in 'venv' directory):
python3 -m venv venv

# Use a specific Python version:
python3.11 -m venv venv

# Activate (Linux/macOS):
source venv/bin/activate
# Shell prompt changes to: (venv) $

# Activate (Windows):
venv\Scripts\activate

# Deactivate (any platform):
deactivate

# Verify you're using the venv python:
which python          # should show /project/venv/bin/python
python --version

# One complete workflow:
mkdir project-a && cd project-a
python3 -m venv venv
source venv/bin/activate
pip install requests==2.25
pip freeze > requirements.txt
```

---

## Managing Dependencies

```bash
# Install packages (only goes to this venv):
pip install requests flask sqlalchemy

# Install exact versions (production):
pip install requests==2.28.0

# Install from requirements.txt (reproduce another environment):
pip install -r requirements.txt

# Freeze current packages (snapshot for sharing/deploying):
pip freeze > requirements.txt
# Produces: requests==2.28.0\nflask==2.3.2\n...

# Upgrade a package:
pip install --upgrade requests

# List installed packages:
pip list
pip list --outdated       # find packages with newer versions

# Uninstall:
pip uninstall requests

# Delete the whole venv (just delete the directory):
rm -rf venv
```

---

## What Activation Actually Does

```bash
# 'source venv/bin/activate' modifies your shell environment:
# 1. Prepends venv/bin to PATH
# 2. Sets VIRTUAL_ENV=/path/to/venv
# 3. Modifies PS1 prompt to show (venv)

# Before activation:
which python    # /usr/bin/python3 (system python)
which pip       # /usr/bin/pip3 (system pip)

# After activation:
which python    # /path/to/project/venv/bin/python
which pip       # /path/to/project/venv/bin/pip
# Any pip install now goes to venv/lib/python3.x/site-packages/
```

---

## venv vs pipx vs poetry

| Tool | Purpose | Use when |
|------|---------|----------|
| `venv` | Project isolation | Every Python project (standard) |
| `pipx` | Install global CLI tools safely | `pip install black`, `pip install httpie` — tools not project deps |
| `poetry` | Dependency manager + packaging | Publishing packages, complex dependency resolution |
| `conda` | Data science environments | When you need non-Python packages (CUDA, HDF5, etc.) |

```bash
# pipx example — install black globally without polluting system Python:
pipx install black        # black is isolated, still works globally
pipx install httpie

# poetry example — modern dependency management:
poetry new my-project
poetry add requests
poetry install
poetry shell              # activates the venv
```

---

## Interview Q&A

**Q: What is the difference between `pip install` with and without a virtual environment?**
Without a venv (or outside one), `pip install` installs packages into the system Python's `site-packages` — shared by all projects. This causes version conflicts: Project A needs `django==3.2` but Project B upgraded it to `django==4.2`. With a venv activated, packages go into the venv's isolated `site-packages`. Each project has its own dependency tree, no conflicts, and `pip freeze > requirements.txt` captures exact versions for reproduction on other machines or in CI/CD.

**Q: Should you commit the `venv/` directory to git?**
No. Add `venv/` to `.gitignore`. The venv contains compiled files, absolute paths, and OS-specific binaries — it's not portable. Instead, commit `requirements.txt` (or `pyproject.toml` for poetry). Anyone cloning the repo recreates the venv with `python3 -m venv venv && pip install -r requirements.txt`. In Docker, the venv isn't needed at all — Docker provides isolation through the container filesystem.

**Q: How does Python decide which `python` or `pip` to use when you type a command?**
The shell searches directories in `PATH` from left to right and uses the first match. Activating a venv prepends `venv/bin` to PATH, so `python` resolves to `venv/bin/python` before the system Python. Deactivating removes that prefix. This is why the same command (`python app.py`) uses different Python interpreters depending on whether a venv is active — they're different executables, each with their own package installations.
