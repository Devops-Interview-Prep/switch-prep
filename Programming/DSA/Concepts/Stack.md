# Stack — Data Structure

> A Stack is a linear data structure following **LIFO** (Last In, First Out) order. The last element pushed is the first to be popped. Go has no built-in stack type — implement with slices (most common) or `container/list`.

---

## Core Operations and Complexity

| Operation | Description | Time | Space |
|-----------|-------------|------|-------|
| `Push(x)` | Add element to top | O(1) | O(1) |
| `Pop()` | Remove and return top element | O(1) | O(1) |
| `Peek()` | Return top without removing | O(1) | O(1) |
| `IsEmpty()` | Check if stack has no elements | O(1) | O(1) |
| `Size()` | Number of elements | O(1) | O(1) |

---

## Implementation — Go Slice (Idiomatic)

```go
// Simple slice-based stack (most common interview approach)
stack := []int{}

// Push: append to end
stack = append(stack, 10)
stack = append(stack, 20)
stack = append(stack, 30)
// stack = [10, 20, 30] — top is rightmost element

// Peek: read last element
top := stack[len(stack)-1]   // 30

// Pop: slice off last element
popped := stack[len(stack)-1]
stack = stack[:len(stack)-1]  // [10, 20]

// IsEmpty:
if len(stack) == 0 { /* empty */ }

// Iterate (top to bottom):
for i := len(stack)-1; i >= 0; i-- {
    fmt.Println(stack[i])
}
```

---

## Struct-based Stack (Reusable)

```go
package main

import "fmt"

type Stack struct {
    items []int
}

func (s *Stack) Push(item int) {
    s.items = append(s.items, item)
}

func (s *Stack) Pop() (int, bool) {
    if s.IsEmpty() {
        return 0, false
    }
    last := len(s.items) - 1
    val := s.items[last]
    s.items = s.items[:last]
    return val, true
}

func (s *Stack) Peek() (int, bool) {
    if s.IsEmpty() {
        return 0, false
    }
    return s.items[len(s.items)-1], true
}

func (s *Stack) IsEmpty() bool {
    return len(s.items) == 0
}

func (s *Stack) Size() int {
    return len(s.items)
}

func main() {
    s := &Stack{}
    s.Push(10)
    s.Push(20)
    s.Push(30)

    fmt.Println(s.Peek())  // 30, true
    val, _ := s.Pop()
    fmt.Println(val)       // 30
    fmt.Println(s.Size())  // 2
}
```

---

## Rune Stack (for String Problems)

```go
// When working with Unicode strings in stack problems:
// Use []rune instead of []byte to handle multi-byte chars correctly

s := "Hello"
runes := []rune(s)   // convert string to rune slice

stack := []rune{}
for _, r := range runes {
    stack = append(stack, r)   // push each rune
}

// rune is just int32 — represents a Unicode code point
// []byte works only for ASCII; []rune handles all Unicode
```

---

## Classic Interview Problems Using Stack

```go
// Problem: Valid Parentheses (LeetCode #20)
func isValid(s string) bool {
    stack := []byte{}
    match := map[byte]byte{')': '(', '}': '{', ']': '['}
    for i := 0; i < len(s); i++ {
        ch := s[i]
        if ch == '(' || ch == '{' || ch == '[' {
            stack = append(stack, ch)
        } else {
            if len(stack) == 0 || stack[len(stack)-1] != match[ch] {
                return false
            }
            stack = stack[:len(stack)-1]
        }
    }
    return len(stack) == 0
}

// Problem: Reverse a string using stack
func reverseString(s string) string {
    stack := []rune(s)   // push all chars
    result := make([]rune, len(stack))
    for i := range result {
        result[i] = stack[len(stack)-1-i]  // pop in reverse
    }
    return string(result)
}

// Problem: Evaluate RPN (Reverse Polish Notation)
// e.g., ["2","1","+","3","*"] → ((2+1)*3) = 9
func evalRPN(tokens []string) int {
    stack := []int{}
    for _, t := range tokens {
        switch t {
        case "+", "-", "*", "/":
            b, a := stack[len(stack)-1], stack[len(stack)-2]
            stack = stack[:len(stack)-2]
            switch t {
            case "+": stack = append(stack, a+b)
            case "-": stack = append(stack, a-b)
            case "*": stack = append(stack, a*b)
            case "/": stack = append(stack, a/b)
            }
        default:
            n, _ := strconv.Atoi(t)
            stack = append(stack, n)
        }
    }
    return stack[0]
}
```

---

## Stack vs Queue vs Deque

| Property | Stack | Queue | Deque |
|----------|-------|-------|-------|
| Order | LIFO | FIFO | Both ends |
| Add | Push (top) | Enqueue (back) | Both ends |
| Remove | Pop (top) | Dequeue (front) | Both ends |
| Use case | DFS, undo, brackets | BFS, scheduling | Sliding window |
| Go impl | `[]T` (append/pop last) | `[]T` (append back/remove front) | `container/list` |

---

## Interview Q&A

**Q: Why is a stack the right data structure for bracket matching?**
Brackets have LIFO matching — the most recently opened bracket must be closed first. A stack naturally models this: when you see `(`, push it. When you see `)`, pop and verify it matches `(`. If the stack is empty when a closer arrives, or non-empty at the end, it's invalid. No other structure captures this "innermost first" constraint as cleanly.

**Q: What is the difference between `[]byte` and `[]rune` when building a stack for string problems?**
`[]byte` treats each byte independently — fine for ASCII (a-z, 0-9) where every character is 1 byte. `[]rune` (int32) represents Unicode code points — safe for multi-byte characters like Chinese, Arabic, emoji. For interview problems that only involve ASCII brackets or digits, `[]byte` is fine and avoids the conversion overhead. If the problem says "string of Unicode characters" or includes non-English text, use `[]rune`.

**Q: How would you implement a stack that returns the minimum element in O(1)?**
Use a secondary "min stack" alongside the main stack. For every Push, also push to min_stack the minimum of (new_val, min_stack.top). For Pop, pop from both stacks. `GetMin()` just peeks the top of min_stack — always O(1). This is LeetCode #155 Min Stack. Trade-off: doubles memory usage (2 stacks instead of 1), but all operations remain O(1).
