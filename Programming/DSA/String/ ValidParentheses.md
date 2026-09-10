# Valid Parentheses — LeetCode #20

> Given a string containing only `'('`, `')'`, `'{'`, `'}'`, `'['`, `']'`, determine if the input string is valid. Brackets must close in the correct order and with the correct matching type.

---

## Problem Statement

```
Input:  "()"         → true
Input:  "()[]{}"     → true
Input:  "([])"       → true  (nested, correctly ordered)
Input:  "(]"         → false (wrong closing bracket type)
Input:  "([)]"       → false (wrong order)
Input:  "{"          → false (unclosed bracket)
Input:  "]"          → false (closing bracket with no opener)
```

---

## Key Insight — Stack

Opening brackets push onto a stack. Closing brackets pop from the stack and check if they match. If any mismatch or the stack is empty when a closer arrives → invalid. At the end, the stack must be empty (all openers were closed).

```
Process "([])":
Push (    → stack: [(]
Push [    → stack: [(, []
Pop ] → checks top [: matches! → stack: [(]
Pop ) → checks top (: matches! → stack: []
End: stack empty → true ✓

Process "([)]":
Push (    → stack: [(]
Push [    → stack: [(, []
Pop ) → checks top [: MISMATCH! (expected ']') → false ✗
```

---

## Solution — Go (with HashMap for cleaner matching)

```go
func isValid(s string) bool {
    stack := []byte{}

    // Map closing bracket → expected opening bracket
    match := map[byte]byte{
        ')': '(',
        '}': '{',
        ']': '[',
    }

    for i := 0; i < len(s); i++ {
        ch := s[i]
        if ch == '(' || ch == '{' || ch == '[' {
            // Opening bracket: push
            stack = append(stack, ch)
        } else {
            // Closing bracket: check if stack top matches
            if len(stack) == 0 || stack[len(stack)-1] != match[ch] {
                return false
            }
            stack = stack[:len(stack)-1]  // pop
        }
    }

    return len(stack) == 0  // all openers must be closed
}
```

---

## Solution — Go (verbose, explicit cases)

```go
func isValid(s string) bool {
    n := len(s)
    stack := []byte{}

    for i := 0; i < n; i++ {
        switch s[i] {
        case '(', '{', '[':
            stack = append(stack, s[i])   // push opener
        case ')':
            if len(stack) == 0 || stack[len(stack)-1] != '(' {
                return false
            }
            stack = stack[:len(stack)-1]
        case '}':
            if len(stack) == 0 || stack[len(stack)-1] != '{' {
                return false
            }
            stack = stack[:len(stack)-1]
        case ']':
            if len(stack) == 0 || stack[len(stack)-1] != '[' {
                return false
            }
            stack = stack[:len(stack)-1]
        }
    }

    return len(stack) == 0
}
```

---

## Solution — Python

```python
def isValid(s: str) -> bool:
    stack = []
    match = {')': '(', '}': '{', ']': '['}

    for ch in s:
        if ch in '({[':
            stack.append(ch)
        else:
            if not stack or stack[-1] != match[ch]:
                return False
            stack.pop()

    return len(stack) == 0
```

---

## Edge Cases

```
""        → true  (empty string is valid — no unmatched brackets)
"("       → false (unclosed)
")"       → false (closer with empty stack)
"()"      → true
"((()))"  → true (deeply nested)
"(())"    → true
"())"     → false (extra closer)
```

---

## Complexity

| | Value |
|---|---|
| **Time** | O(n) — single pass through string |
| **Space** | O(n) — worst case: string of all openers "((((" fills stack |

---

## Interview Q&A

**Q: Why is a stack the right data structure for this problem?**
Brackets have LIFO (Last In, First Out) matching — the most recently opened bracket must be closed first. A stack naturally models this: push openers, pop when you see a closer and verify it matches the top. Any other structure (queue, array scanned from the front) doesn't capture this "innermost first" constraint. Valid parentheses is one of the canonical interview examples showing why stacks are useful.

**Q: What are the three failure cases to check?**
(1) **Closer with empty stack** — a closing bracket arrives but no opener is waiting (stack is empty → immediately return false). (2) **Type mismatch** — a closing bracket doesn't match the most recent opener on the stack (e.g., `[)` — opened `[` but closed with `)`). (3) **Unclosed openers** — after processing all characters, the stack is not empty (some openers were never closed). Handle all three and you've covered every invalid case.

**Q: How do you make the matching logic cleaner than a chain of if-else?**
Use a HashMap to map each closer to its expected opener: `{')': '(', '}': '{', ']': '['}`. Then for any closing bracket, one lookup gives you what should be on the stack. This avoids repeating the `if stack[top] == '('` check three times and makes it easy to extend if you add new bracket types (e.g., `<`, `>`).
