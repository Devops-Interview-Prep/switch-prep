# Stack in Python

> A stack is a LIFO (Last In, First Out) data structure. Python has two main implementations: `list` (simple, good for most cases) and `collections.deque` (better for large stacks due to O(1) operations on both ends).

---

## Implementation 1 — Python List

```python
stack = []

# Push — O(1) amortized
stack.append(10)
stack.append(20)
stack.append(30)
print(stack)     # [10, 20, 30]

# Peek — O(1)
top = stack[-1]
print(top)       # 30

# Pop — O(1) amortized
top = stack.pop()
print(top)       # 30
print(stack)     # [10, 20]

# IsEmpty — O(1)
if not stack:
    print("empty")
if len(stack) == 0:
    print("empty")

# Size — O(1)
print(len(stack))  # 2
```

| Operation | Python List | Time |
|-----------|------------|------|
| Push | `stack.append(x)` | O(1) amortized |
| Pop | `stack.pop()` | O(1) amortized |
| Peek | `stack[-1]` | O(1) |
| IsEmpty | `not stack` | O(1) |
| Size | `len(stack)` | O(1) |

---

## Implementation 2 — collections.deque (Recommended for Production)

```python
from collections import deque

stack = deque()

# Push
stack.append(10)
stack.append(20)
stack.append(30)

# Peek
top = stack[-1]    # 30

# Pop
popped = stack.pop()   # 30

# IsEmpty
if not stack:
    print("empty")

print(stack)   # deque([10, 20])
```

**Why `deque` over `list` for large stacks?**
- `list.pop()` from the right is O(1) amortized, but occasional resizes make it O(n)
- `deque` is implemented as a doubly-linked list of fixed-size blocks — always O(1) for append/pop at both ends, no resizing
- For stacks with millions of elements, `deque` is more predictable

---

## Classic Interview Problems

### Valid Parentheses

```python
def isValid(s: str) -> bool:
    stack = []
    pairs = {')': '(', '}': '{', ']': '['}

    for ch in s:
        if ch in pairs.values():    # opening bracket
            stack.append(ch)
        else:                       # closing bracket
            if not stack or stack[-1] != pairs[ch]:
                return False
            stack.pop()

    return not stack  # stack must be empty at end

# Tests:
print(isValid("()[]{}"))  # True
print(isValid("(]"))      # False
print(isValid("([)]"))    # False
```

### Min Stack — O(1) Get Minimum

```python
class MinStack:
    def __init__(self):
        self.stack = []
        self.min_stack = []   # parallel stack tracking minimums

    def push(self, val: int) -> None:
        self.stack.append(val)
        # Push current minimum to min_stack
        if self.min_stack:
            self.min_stack.append(min(val, self.min_stack[-1]))
        else:
            self.min_stack.append(val)

    def pop(self) -> None:
        self.stack.pop()
        self.min_stack.pop()

    def top(self) -> int:
        return self.stack[-1]

    def getMin(self) -> int:
        return self.min_stack[-1]   # always O(1)
```

### Evaluate Reverse Polish Notation (RPN)

```python
def evalRPN(tokens: list[str]) -> int:
    stack = []
    ops = {'+', '-', '*', '/'}

    for t in tokens:
        if t not in ops:
            stack.append(int(t))
        else:
            b = stack.pop()   # second operand
            a = stack.pop()   # first operand
            if t == '+': stack.append(a + b)
            elif t == '-': stack.append(a - b)
            elif t == '*': stack.append(a * b)
            elif t == '/': stack.append(int(a / b))   # truncate toward zero

    return stack[0]

# Example: ["2","1","+","3","*"] → ((2+1)*3) = 9
```

---

## Stack vs Queue vs Deque

| Property | Stack | Queue | Deque |
|----------|-------|-------|-------|
| Order | LIFO | FIFO | Both ends |
| Python impl | `list` or `deque` | `deque` or `queue.Queue` | `deque` |
| Push | `append()` (right) | `append()` (right) | Both sides |
| Pop | `pop()` (right) | `popleft()` (left) | Both sides |
| Use case | DFS, undo, brackets, RPN | BFS, scheduling | Sliding window max |

---

## Interview Q&A

**Q: When should you use `deque` instead of `list` for a stack?**
For most interview problems, `list` is fine — `append()` and `pop()` are O(1) amortized. Use `deque` when: (1) you need a double-ended queue (add/remove from both ends), (2) the stack will be very large and you need consistent O(1) (no occasional O(n) resize), or (3) you need `popleft()` which is O(n) on a list but O(1) on a deque. In competitive programming and interviews, `list` is idiomatic and simpler.

**Q: What are the two failure modes when checking for valid parentheses?**
(1) **Stack is empty when a closing bracket arrives** — a closer with no corresponding opener. Check `not stack` before popping. (2) **Stack is not empty at the end** — unclosed openers remain. Return `not stack` (or `len(stack) == 0`), not just `True`. Without checking both conditions, you'll miss edge cases like `"((("` (returns True incorrectly if you only check the pop condition).

**Q: How does a monotonic stack work and when is it used?**
A monotonic stack maintains elements in strictly increasing or decreasing order. When a new element violates the order, you pop until the order is restored. Use cases: "Next Greater Element", "Largest Rectangle in Histogram", "Trapping Rain Water". Example for "Next Greater Element": scan right-to-left, push each element. For each element, pop the stack while top ≤ current — the first element greater than current is the answer. The stack maintains a decreasing sequence of "candidates" for future elements.
