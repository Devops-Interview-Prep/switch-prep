```python 
stack = []

# push
stack.append(10)
stack.append(20)
stack.append(30)

# pop
top = stack.pop()
print(top)     # 30
print(stack)   # [10, 20]

```

| Stack Operation | Python list       |
| --------------- | ----------------- |
| push            | `append()`        |
| pop             | `pop()`           |
| peek            | `stack[-1]`       |
| isEmpty         | `len(stack) == 0` |


2️⃣ Using collections.deque (BEST for large stacks)

- If your stack grows very large or needs high performance:

```python

from collections import deque

stack = deque()

stack.append(10)
stack.append(20)

stack.pop()

```

- O(1) push/pop from both ends

- No resizing overhead like list

- Example code : valid paranthesis

```python 
class Solution:
    def isValid(self, s: str) -> bool:
        stack = []
        pairs = {')': '(', '}': '{', ']': '['}

        for ch in s:
            if ch in pairs.values():      # opening
                stack.append(ch)
            else:                         # closing
                if not stack or stack[-1] != pairs[ch]:
                    return False
                else :
                    stack.pop()

        return not stack
```