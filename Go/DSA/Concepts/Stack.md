- In Go (Golang), a stack is a data structure that follows the Last In, First Out (LIFO) principle. This means the last element added to the stack is the first one to be removed.

- Go doesn't have a built-in stack type, but you can easily implement it using slices.

```
package main

import "fmt"

type Stack struct {
	items []int
}

// Push adds an element and returns a new updated stack
func (s Stack) Push(item int) Stack {
	s.items = append(s.items, item)
	return s
}

// Pop removes the top element and returns the updated stack and popped value
func (s Stack) Pop() (Stack, int) {
	if len(s.items) == 0 {
		panic("Stack is empty")
	}
	lastIndex := len(s.items) - 1
	popped := s.items[lastIndex]
	s.items = s.items[:lastIndex]
	return s, popped
}

// Peek returns the top element without removing it
func (s Stack) Peek() int {
	if len(s.items) == 0 {
		panic("Stack is empty")
	}
	return s.items[len(s.items)-1]
}

// IsEmpty checks if the stack is empty
func (s Stack) IsEmpty() bool {
	return len(s.items) == 0
}

func main() {
	var stack Stack

	stack = stack.Push(10)
	stack = stack.Push(20)
	stack = stack.Push(30)

	fmt.Println("Top element:", stack.Peek()) // Output: 30

	var popped int
	stack, popped = stack.Pop()
	fmt.Println("Popped:", popped) // Output: 30

	fmt.Println("Is empty?", stack.IsEmpty()) // Output: false

	stack, _ = stack.Pop()
	stack, _ = stack.Pop()

	fmt.Println("Is empty?", stack.IsEmpty()) // Output: true
}
```


# []rune

- A rune is just an alias for int32 in Go.
- It represents a Unicode code point.
- Using rune allows you to handle characters beyond basic ASCII (like emojis, accented characters, etc.).  
`var ch rune = 'A' // rune holds the Unicode value of 'A', which is 65`

- In Go, strings are immutable, so if you want to treat a string as a modifiable sequence of characters, use a []rune.

- Unicode is a universal standard for representing text from all languages and symbols in a consistent way.

- It's like a giant dictionary of characters, where every letter, digit, emoji, symbol, etc. from every writing system has a unique number (called a code point).

# Why Not []byte for isValid(s string)?

UTF-8 encoded strings (which Go uses) can have multi-byte characters.

Bracket characters like (, [, { are ASCII (1-byte), so []byte might seem to work.

But if any non-ASCII character appears in the string (like 你, 😀), then:

[]byte treats them as multiple bytes

You may break characters apart unintentionally

This leads to invalid logic, especially in character-based comparisons
