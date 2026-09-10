# Longest Common Prefix — LeetCode #14

> Write a function to find the longest common prefix string amongst an array of strings. Return empty string "" if there is no common prefix.

---

## Problem Statement

```
Input:  strs = ["flower", "flow", "flight"]
Output: "fl"
Reason: "fl" is the longest prefix common to all three strings

Input:  strs = ["dog", "racecar", "car"]
Output: ""
Reason: No common prefix — d ≠ r ≠ c

Input:  strs = ["abc"]
Output: "abc"
Reason: Single string — whole string is the prefix

Input:  strs = ["abc", "abc", "abc"]
Output: "abc"
Reason: All identical — full string is the prefix
```

---

## Approach 1 — Horizontal Scanning (compare first string to all others)

Take the first string as the candidate prefix. For each subsequent string, shorten the prefix until it matches the start of that string.

```
strs = ["flower", "flow", "flight"]

prefix = "flower"
Compare with "flow":
    "flower" starts with "flower"? No → trim → "flowe"
    "flow" starts with "flowe"? No → trim → "flow"
    "flow" starts with "flow"? Yes → prefix = "flow"
Compare with "flight":
    "flight" starts with "flow"? No → trim → "flo"
    "flight" starts with "flo"? No → trim → "fl"
    "flight" starts with "fl"? Yes → prefix = "fl"
Return "fl"
```

```go
import "strings"

func longestCommonPrefix(strs []string) string {
    if len(strs) == 0 {
        return ""
    }

    prefix := strs[0]   // start with first string as prefix

    for _, s := range strs[1:] {
        // Shrink prefix until s starts with it
        for !strings.HasPrefix(s, prefix) {
            prefix = prefix[:len(prefix)-1]   // trim last char
            if prefix == "" {
                return ""
            }
        }
    }

    return prefix
}
```

**Time: O(S)** where S = total characters across all strings  
**Space: O(1)** — only the prefix string

---

## Approach 2 — Vertical Scanning (column by column)

Compare the same position across all strings. Stop when any string ends or characters differ.

```
strs = ["flower", "flow", "flight"]

Position 0: f, f, f → all same → continue
Position 1: l, l, l → all same → continue
Position 2: o, o, i → DIFFER (o ≠ i) → stop

Return strs[0][0:2] = "fl"
```

```go
func longestCommonPrefix(strs []string) string {
    if len(strs) == 0 {
        return ""
    }

    // Iterate by column (character position)
    for i := 0; i < len(strs[0]); i++ {
        ch := strs[0][i]   // reference character from first string

        // Compare with same position in all other strings
        for j := 1; j < len(strs); j++ {
            // Stop if: any string is shorter, or characters differ
            if i >= len(strs[j]) || strs[j][i] != ch {
                return strs[0][:i]   // prefix is first i characters
            }
        }
    }

    return strs[0]   // all strings start with strs[0]
}
```

**Time: O(S)** — at worst, scan all characters  
**Space: O(1)**

---

## Approach 3 — Sort and Compare First/Last

Sort the strings lexicographically. The longest common prefix of ALL strings must be a prefix of both the first (alphabetically smallest) and last (alphabetically largest) strings after sorting.

```go
import "sort"

func longestCommonPrefix(strs []string) string {
    if len(strs) == 0 {
        return ""
    }

    sort.Strings(strs)
    first, last := strs[0], strs[len(strs)-1]

    i := 0
    for i < len(first) && i < len(last) && first[i] == last[i] {
        i++
    }

    return first[:i]
}
```

**Time: O(n log n)** — dominated by sort  
**Space: O(1)** — or O(log n) for sort stack

---

## Complexity Comparison

| Approach | Time | Space | Best when |
|----------|------|-------|-----------|
| Horizontal scanning | O(S) | O(1) | General case, simple to understand |
| Vertical scanning | O(S) | O(1) | Early exit when prefix is short |
| Sort + first/last compare | O(n log n) | O(1) | Elegant, but slower due to sort |

Where S = sum of all characters across all strings.

---

## Edge Cases

```
[]                          → ""  (empty array)
[""]                        → ""  (empty string in array)
["", "abc"]                 → ""  (first string is empty → no common prefix)
["abc"]                     → "abc" (single string)
["abc", "abc"]              → "abc" (identical strings)
["a", "b"]                  → ""  (first characters differ)
["ab", "a"]                 → "a" (second string is shorter)
```

---

## Interview Q&A

**Q: How does horizontal scanning work for this problem?**
Start with the first string as the candidate prefix. For each subsequent string, check if it starts with the current prefix. If not, shorten the prefix by one character from the right and check again. Repeat until the prefix matches the beginning of the current string, then move to the next string. If the prefix ever becomes empty, return "". This is O(S) where S is the total number of characters.

**Q: Why does comparing only the sorted first and last strings work?**
After sorting lexicographically, the first string is alphabetically smallest and the last is alphabetically largest. Any character position where these two strings differ means that strings in between also differ at that position — because sorting creates a total order where the first and last strings are the "most different." So their common prefix is the common prefix of the whole array. The sort costs O(n log n), which is worse than the O(S) direct scanning approaches.

**Q: What's the time complexity, and what does S represent?**
O(S) where S is the total number of characters across all strings. In the worst case — when all strings are identical — you scan every character of every string. The worst case is when all strings are the same: comparing n strings of length m each = n×m = S total comparisons. The sort approach trades O(S) scanning for O(n log n) sorting, which may be faster when strings are long but there are few of them.
