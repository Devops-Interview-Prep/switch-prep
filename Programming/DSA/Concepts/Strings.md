# Strings, Bytes, and Runes in Go

> Go strings are immutable UTF-8 byte sequences. Understanding the difference between `string`, `byte` (uint8), and `rune` (int32/Unicode code point) is essential for string manipulation problems and avoiding common bugs with non-ASCII characters.

---

## String — Read-Only Byte Slice

```go
// A string is a read-only slice of bytes (UTF-8 encoded)
s := "Hello 😊"
fmt.Println(s)           // Hello 😊
fmt.Println(len(s))      // 9 (bytes! not characters — 😊 is 4 bytes in UTF-8)

// ── Concatenation ─────────────────────────────────────────────────────
s1 := "Hello"
s2 := "World"
result := s1 + " " + s2
fmt.Println(result)      // Hello World

// For many concatenations, use strings.Builder (efficient — avoids O(n²)):
var b strings.Builder
for i := 0; i < 1000; i++ {
    b.WriteString("word ")
}
s := b.String()

// ── Length (bytes vs characters) ──────────────────────────────────────
s := "Hello 😊"
fmt.Println(len(s))          // 9 — byte count (len is ALWAYS bytes)
fmt.Println(len([]rune(s)))  // 7 — character count (Unicode-safe)

// ── Indexing — returns BYTES, not characters ───────────────────────────
s := "Go"
fmt.Println(s[0])            // 71 — ASCII value of 'G' (returns byte)
fmt.Printf("%c\n", s[0])    // G  — format as character

// ── Slicing ──────────────────────────────────────────────────────────
s := "Hello"
fmt.Println(s[1:4])          // "ell" (byte positions 1,2,3)
// WARNING: slicing a multi-byte string by byte index can split a rune!
s2 := "Go😊"
fmt.Println(s2[2:4])         // garbled! — splits the 😊 emoji (4 bytes)

// ── Iteration ─────────────────────────────────────────────────────────
// Range over string = iterate by RUNE (Unicode-safe):
s := "Go😊Lang"
for _, r := range s {
    fmt.Printf("%c ", r)     // G o 😊 L a n g  (7 iterations)
}

// Iterate by BYTE index (ASCII only):
for i := 0; i < len(s); i++ {
    fmt.Printf("%d ", s[i])  // prints byte values (9 iterations)
}

// ── Comparison ────────────────────────────────────────────────────────
s1, s2 := "Go", "Go"
fmt.Println(s1 == s2)        // true
fmt.Println(s1 < "Python")   // true (lexicographic comparison)

// ── Conversion ────────────────────────────────────────────────────────
s := "Go😊"
b := []byte(s)               // [71 111 240 159 152 138] — raw UTF-8 bytes
r := []rune(s)               // [71 111 128522] — Unicode code points
back := string(b)            // convert []byte back to string
back2 := string(r)           // convert []rune back to string
```

---

## byte — Raw Byte (uint8)

```go
// byte is an alias for uint8 — an 8-bit number (0-255)
// Represents a single raw byte, works well for ASCII characters

b := byte('A')               // ASCII value of 'A' = 65
fmt.Println(b)               // 65
fmt.Printf("%c\n", b)       // A

// ── Arithmetic on bytes ───────────────────────────────────────────────
b := byte('A')
fmt.Printf("%c\n", b+1)    // B (shift one ASCII code up)
fmt.Printf("%c\n", b+25)   // Z

// Convert digit char to int:
ch := byte('5')
num := ch - '0'             // 5 (common interview trick: '5' - '0' = 53-48 = 5)

// Convert lowercase to uppercase:
ch := byte('a')
upper := ch - ('a' - 'A')  // equivalent to ch - 32

// ── []byte — mutable string ───────────────────────────────────────────
bytes := []byte("hello")
bytes[0] = 'H'
fmt.Println(string(bytes))  // Hello

// Append to []byte:
b := []byte("foo")
b = append(b, 'b', 'a', 'r')
fmt.Println(string(b))       // foobar

// Common interview pattern — build result as []byte:
func reverse(s string) string {
    b := []byte(s)
    for i, j := 0, len(b)-1; i < j; i, j = i+1, j-1 {
        b[i], b[j] = b[j], b[i]
    }
    return string(b)
}
```

---

## rune — Unicode Code Point (int32)

```go
// rune is an alias for int32 — represents a Unicode code point
// Handles ALL Unicode characters including emoji, CJK, Arabic, etc.

r := '😊'                   // Unicode character
fmt.Println(r)              // 128522 (the Unicode code point)
fmt.Printf("%c\n", r)      // 😊

// ── Iterate string as runes (Unicode-safe) ────────────────────────────
s := "नमस्ते"               // Hindi text
for _, r := range s {
    fmt.Printf("%c ", r)    // न म स ् त े
}

// ── Convert string ↔ rune ─────────────────────────────────────────────
str := "Go😊Lang"
runes := []rune(str)
fmt.Println(len(runes))     // 7 — correct character count

// Access characters safely:
fmt.Printf("%c\n", runes[2])  // 😊 (correct — index 2)
// vs: fmt.Println(str[2])    // 240 (raw byte — not what you want)

// Convert rune back to string:
r := rune(128522)
s := string(r)
fmt.Println(s)              // 😊
```

---

## When to Use Which

| Type | Use when |
|------|----------|
| `string` | Immutable text; comparison, concatenation, passing around |
| `[]byte` | Modifying content character-by-character (ASCII); I/O operations |
| `[]rune` | Modifying Unicode text; indexing by character position |
| `strings.Builder` | Building long strings incrementally (avoids O(n²) allocations) |

```go
// Rule of thumb:
// ASCII-only string problem → []byte (simpler, no conversion overhead)
// Unicode string problem → []rune (correct, handles multi-byte chars)
// Read-only, comparing, passing → string (no conversion needed)
```

---

## Interview Q&A

**Q: Why does `len("Hello 😊")` return 9 instead of 7?**
`len()` in Go returns the number of **bytes**, not characters. The string "Hello 😊" has 6 ASCII characters (1 byte each = 6 bytes) plus 1 space (1 byte) plus the 😊 emoji (4 bytes in UTF-8) = 9 bytes. To get character count, convert to `[]rune` first: `len([]rune("Hello 😊"))` returns 7. This is one of the most common Go interview gotchas.

**Q: What happens if you index a Go string directly with `s[i]`?**
You get the byte at position i, not the character. For ASCII strings this works fine since every character is 1 byte. For Unicode strings with multi-byte characters (Chinese, emoji, etc.), `s[i]` gives a raw byte that may be the middle of a multi-byte character — meaningless as a character. Always use `range s` (which iterates by rune) or convert to `[]rune` first if you need character-level indexing.

**Q: When should you use `[]byte` vs `[]rune` for string manipulation?**
Use `[]byte` when the problem guarantees ASCII input (LeetCode usually states "lowercase English letters" or "digits") — it's faster and has no conversion overhead. Use `[]rune` when the problem involves arbitrary Unicode (international characters, emoji). Converting between them: `[]byte(s)` and `[]rune(s)` both create a copy, costing O(n) time and space. For in-place modifications on ASCII strings, `[]byte` is the idiomatic Go choice.
