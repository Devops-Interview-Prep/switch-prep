# Go `strings` Package — Complete Reference

> The `strings` package provides functions for UTF-8 string manipulation. It's one of the most-used packages in Go — essential for interview problems, log parsing, config handling, and API development. Import: `import "strings"`.

---

## Search and Match Functions

```go
import "strings"

s := "Hello, World!"

// Existence checks:
strings.Contains(s, "World")          // true
strings.ContainsAny(s, "aeiou")       // true (contains any of the chars)
strings.ContainsRune(s, 'W')          // true

// Prefix/Suffix:
strings.HasPrefix(s, "Hello")         // true
strings.HasSuffix(s, "World!")        // true

// Position:
strings.Index(s, "World")             // 7 (first occurrence, -1 if not found)
strings.LastIndex(s, "l")             // 10 (last occurrence)
strings.IndexByte(s, 'W')             // 7 (faster for single byte)
strings.IndexRune(s, 'W')             // 7 (Unicode-safe single char)

// Count:
strings.Count(s, "l")                 // 3 (count of non-overlapping occurrences)
strings.Count("aababab", "ab")        // 3
```

---

## Modification and Transformation

```go
// Case:
strings.ToUpper("hello")              // "HELLO"
strings.ToLower("WORLD")              // "world"
strings.Title("hello world")          // "Hello World" (deprecated, use cases.Title)

// Trimming:
strings.TrimSpace("  hello  ")        // "hello" (remove leading/trailing whitespace)
strings.Trim("***hello***", "*")      // "hello" (remove leading/trailing chars in cutset)
strings.TrimLeft("***hello", "*")     // "hello" (leading only)
strings.TrimRight("hello***", "*")    // "hello" (trailing only)
strings.TrimPrefix("hello_world", "hello_")  // "world"
strings.TrimSuffix("hello_world", "_world")  // "hello"

// Replace:
strings.Replace("aabaa", "a", "x", 2)       // "xxbaa" (replace first 2)
strings.ReplaceAll("aabaa", "a", "x")        // "xxbxx" (replace all)

// Repeat:
strings.Repeat("ab", 3)               // "ababab"
```

---

## Split and Join

```go
// Split:
strings.Split("a,b,c", ",")           // ["a", "b", "c"]
strings.Split("hello", "")            // ["h", "e", "l", "l", "o"] (each char)
strings.SplitN("a,b,c,d", ",", 2)    // ["a", "b,c,d"] (split into max 2 parts)
strings.SplitAfter("a,b,c", ",")      // ["a,", "b,", "c"] (keeps delimiter)

// Fields — split by any whitespace:
strings.Fields("  foo   bar  baz  ")  // ["foo", "bar", "baz"] (handles multiple spaces)
strings.Fields("a\tb\nc")             // ["a", "b", "c"] (tabs and newlines too)

// Join:
parts := []string{"a", "b", "c"}
strings.Join(parts, "-")              // "a-b-c"
strings.Join(parts, "")              // "abc" (concatenate)
strings.Join(parts, ", ")            // "a, b, c"
```

---

## Comparison

```go
// Case-insensitive comparison:
strings.EqualFold("Go", "go")         // true
strings.EqualFold("Hello", "HELLO")   // true

// Lexicographic comparison (same as == but returns -1/0/1):
strings.Compare("a", "b")            // -1
strings.Compare("b", "a")            // 1
strings.Compare("a", "a")            // 0

// Use == for equality (more idiomatic than Compare):
"hello" == "hello"   // true
"hello" < "world"    // true (lexicographic)
```

---

## Builder — Efficient String Concatenation

```go
// Don't use + in a loop (creates O(n²) temporary strings):
// BAD:
result := ""
for i := 0; i < 1000; i++ {
    result += "word "   // O(n²) total — each += creates a new string
}

// GOOD: use strings.Builder (O(n) total):
var sb strings.Builder
for i := 0; i < 1000; i++ {
    sb.WriteString("word ")
}
result := sb.String()

// Builder methods:
sb.WriteString("hello")    // write string
sb.WriteByte(' ')          // write single byte
sb.WriteRune('😊')         // write Unicode rune
sb.Len()                   // current length
sb.Reset()                 // clear (reuse without allocation)
```

---

## Common Interview Patterns

```go
// Pattern 1: Check if string is palindrome
func isPalindrome(s string) bool {
    s = strings.ToLower(s)
    runes := []rune(s)
    for i, j := 0, len(runes)-1; i < j; i, j = i+1, j-1 {
        if runes[i] != runes[j] {
            return false
        }
    }
    return true
}

// Pattern 2: Count word frequency in a sentence
func wordFreq(s string) map[string]int {
    freq := make(map[string]int)
    for _, w := range strings.Fields(strings.ToLower(s)) {
        freq[w]++
    }
    return freq
}

// Pattern 3: Reverse words in a sentence
func reverseWords(s string) string {
    words := strings.Fields(s)     // split and strip extra spaces
    for i, j := 0, len(words)-1; i < j; i, j = i+1, j-1 {
        words[i], words[j] = words[j], words[i]
    }
    return strings.Join(words, " ")
}
```

---

## Interview Q&A

**Q: What is the difference between `strings.Split` and `strings.Fields`?**
`strings.Split(s, " ")` splits on exactly a single space — consecutive spaces produce empty strings in the result: `Split("a  b", " ")` → `["a", "", "b"]`. `strings.Fields(s)` splits on any whitespace (space, tab, newline) and ignores leading/trailing whitespace — `Fields("  a  b  ")` → `["a", "b"]`. For parsing human-readable text, use `Fields`; for parsing structured data with a specific delimiter, use `Split`.

**Q: When should you use `strings.Builder` instead of `+` concatenation?**
Use `+` for 2-3 concatenations — it's readable and the compiler may optimize it. Use `strings.Builder` when concatenating in a loop or building a string from many parts. Each `+` creates a new string (immutable in Go), so n concatenations with average length m = O(n²m) total allocations. `strings.Builder` maintains a growing buffer internally — O(n) total work, one final allocation for the result. This matters for building log lines, CSV rows, or HTML templates in loops.

**Q: How do you check if a string is a prefix of another in Go?**
`strings.HasPrefix(s, prefix)` — returns true if s begins with prefix. For suffix: `strings.HasSuffix(s, suffix)`. These are O(len(prefix)) and O(len(suffix)) respectively. Internally they're equivalent to `s[:len(prefix)] == prefix` but more readable and safe (no panic if prefix is longer than s). Common use case in interview problems: finding the longest common prefix — use `strings.HasPrefix` in a loop trimming from the right.
