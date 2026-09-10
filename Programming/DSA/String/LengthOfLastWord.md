# Length of Last Word — LeetCode #58

> Given a string `s` consisting of words and spaces, return the length of the last word. A word is a maximal substring consisting of non-space characters.

---

## Problem Statement

```
Input:  s = "Hello World"
Output: 5
Reason: last word is "World" → length 5

Input:  s = "   fly me   to   the moon  "
Output: 4
Reason: last word is "moon" (trailing spaces ignored) → length 4

Input:  s = "luffy is still joyboy"
Output: 6
Reason: last word is "joyboy" → length 6

Input:  s = "a"
Output: 1

Input:  s = "a  "
Output: 1  (trailing spaces ignored)
```

---

## Key Insight — Scan Right-to-Left

Scan from the end of the string. First skip any trailing spaces, then count characters until the next space (or start of string).

```
s = "   fly me   to   the moon  "

Start from right: index = len-1 = 27
  s[27]=' ', s[26]=' ' → skip trailing spaces
  s[25]='n' → start counting: count=1
  s[24]='o' → count=2
  s[23]='o' → count=3
  s[22]='m' → count=4
  s[21]=' ' → count > 0 → return 4 ✓
```

---

## Solution — Go

```go
func lengthOfLastWord(s string) int {
    i := len(s) - 1
    count := 0

    for i >= 0 {
        if s[i] != ' ' {
            count++                          // counting a word character
        } else if s[i] == ' ' && count != 0 {
            return count                     // hit space after word → done
        }
        // else: s[i]==' ' && count==0 → still in trailing spaces, skip
        i--
    }

    return count  // handles case where string has no trailing spaces
}
```

**Time: O(n)** — at most one pass through the string  
**Space: O(1)** — only index and counter

---

## Cleaner Version

```go
func lengthOfLastWord(s string) int {
    s = strings.TrimRight(s, " ")   // remove trailing spaces
    lastSpace := strings.LastIndex(s, " ")
    return len(s) - lastSpace - 1
}
```

---

## Python Solution

```python
def lengthOfLastWord(s: str) -> int:
    # Python one-liner (but might not be what interviewer wants):
    return len(s.rstrip().split()[-1])

# Explicit right-to-left approach:
def lengthOfLastWord_explicit(s: str) -> int:
    i = len(s) - 1
    count = 0
    while i >= 0:
        if s[i] != ' ':
            count += 1
        elif count > 0:
            return count
        i -= 1
    return count
```

---

## Edge Cases

```
s = "a"             → 1  (single char, no spaces)
s = "a  "           → 1  (trailing spaces, last word "a")
s = "Hello World"   → 5  (standard case)
s = " "             → 0  (all spaces, no words — though problem guarantees at least 1 word)
s = "one"           → 3  (no spaces at all)
```

---

## Complexity

| | Value |
|---|---|
| **Time** | O(n) — single pass |
| **Space** | O(1) — no extra storage |

---

## Interview Q&A

**Q: Why scan right-to-left rather than left-to-right?**
The problem asks for the LAST word. Scanning left-to-right means you'd track the start of each word and update the length each time you find a new word — requiring full traversal. Scanning right-to-left lets you stop as soon as you've measured the last word, which is often much faster for strings with many words. In the best case (last word is short), right-to-left is O(last_word_length) rather than O(n).

**Q: What is the tricky edge case to handle?**
Trailing spaces. The problem says "words and spaces" and examples include `"   fly me   to   the moon  "` with trailing spaces. The right-to-left approach naturally handles this: keep scanning until you find the first non-space character before starting to count. The second tricky case is a string with no trailing spaces — return `count` at the end of the loop, not 0.
