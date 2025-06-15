#  string

- A string in Go is a read-only slice of bytes.
- It can contain ASCII or UTF-8 encoded Unicode characters.
  
```
s := "Hello 😊"
fmt.Println(s)          // Hello 😊
fmt.Println(len(s))     // 9 (because 😊 is 4 bytes)
```
**Basic Operations**

*1. Concatenation*
```
s1 := "Hello"
s2 := "World"
result := s1 + " " + s2
fmt.Println(result) // Hello World
```

*2. Length*
```
s := "Hello 😊"
fmt.Println(len(s)) // 9 (because 😊 is 4 bytes)
```

*3. Indexing (bytes, not characters!)*
```
s := "Go"
fmt.Println(s[0])        // 71 (ASCII of 'G') , returns a byte, so fmt.Println prints 101
fmt.Printf("%c\n", s[1]) // o
```

*4. Slicing*
```
s := "Hello"
fmt.Println(s[1:4]) // "ell" , returns a string, so fmt.Println prints "ell"
```

*5. Looping over characters (Unicode-safe)*
```
s := "Go😊Lang"
for _, r := range s {
    fmt.Printf("%c ", r)
}
// Output: G o 😊 L a n g
```

*6. Comparison*
```
s1 := "Go"
s2 := "Go"
fmt.Println(s1 == s2) // true
```

*7. Conversion to/from []byte and []rune*
```
str := "Go😊"

// Convert string to []byte
b := []byte(str)
fmt.Println(b) // [71 111 240 159 152 138]

// Convert string to []rune
r := []rune(str)
fmt.Println(r) // [71 111 128522]
```




# byte

- Alias for uint8 (i.e., an 8-bit unsigned integer).
- A byte is just a number from 0 to 255
- Represents a single raw byte.
- Useful when manipulating binary data or ASCII characters.

```
b := byte('A')          // ASCII character A
fmt.Println(b)          // 65
fmt.Printf("%c\n", b)   // A
```
**Basic Operations**

*1. Arithmetic*
```
b := byte('A')
fmt.Println(b + 1)       // 66
fmt.Printf("%c\n", b+1)  // B
```

*2. Conversion to string*
```
b := byte(65)
s := string(b)
fmt.Println(s) // A
```
*3. Byte slices*
```
bytes := []byte("hello")
bytes[0] = 'H'
fmt.Println(string(bytes)) // Hello
```

# rune

- Alias for int32, represents a Unicode code point.
- Useful for working with international characters or emoji.
- Unlike byte, it understands full Unicode characters.
  
```
r := '😊'               // Unicode character
fmt.Println(r)          // 128522
fmt.Printf("%c\n", r)   // 😊
```

**Basic Operations**

*1. Initialization and Printing*
```
r := rune('😊')
fmt.Println(r)          // 128522
fmt.Printf("%c\n", r)   // 😊
```

*2. Loop through string as runes*
```
s := "नमस्ते"
for _, r := range s {
    fmt.Printf("%c ", r)
}
// Output: न म स ् त े
```

*3. Convert rune to string*
```
r := rune(128522)
s := string(r)
fmt.Println(s) // 😊
```

*4. Get length of runes in a string*
```
str := "Go😊Lang"
fmt.Println(len(str))           // 9 (bytes)
fmt.Println(len([]rune(str)))   // 7 (characters)
```