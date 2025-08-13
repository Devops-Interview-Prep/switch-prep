- A regular expression (regex or regexp) is a pattern that describes a set of strings. It’s widely used for searching, matching, and replacing text.
  

| Pattern  | Meaning                                 | Example Match                         |       |                              |
| -------- | --------------------------------------- | ------------------------------------- | ----- | ---------------------------- |
| `.`      | Any single character                    | `a`, `1`, `@`                         |       |                              |
| `*`      | Zero or more of the preceding character | `bo*` → `b`, `bo`, `boo`              |       |                              |
| `+`      | One or more of the preceding character  | `go+` → `go`, `goo`                   |       |                              |
| `?`      | Zero or one of the preceding character  | `colou?r` → `color`, `colour`         |       |                              |
| `[abc]`  | Any one of `a`, `b`, or `c`             | `a`, `b`, or `c`                      |       |                              |
| `[^abc]` | Not `a`, `b`, or `c`                    | `d`, `e`, etc.                        |       |                              |
| `[a-z]`  | Any lowercase letter                    | `a`, `b`, ..., `z`                    |       |                              |
| `^`      | Start of line                           | `^Hello` → line starting with "Hello" |       |                              |
| `$`      | End of line                             | `world$` → line ending in "world"     |       |                              |
| `\d`     | Digit                                   | `0` to `9`                            |       |                              |
| `\w`     | Word character                          | Letters, digits, underscore           |       |                              |
| `\s`     | Whitespace                              | Space, tab, newline                   |       |                              |
| \`       | \`                                      | Logical OR                            | \`cat | dog\` matches "cat" or "dog" |
| `()`     | Grouping                                | `(foo)+` → one or more `foo`          |       |                              |


- Regex Tools in Bash
  - In Bash scripting, regular expressions can be used with:
    - grep
    - sed
    - awk
    - [[]]  with =~ operator

