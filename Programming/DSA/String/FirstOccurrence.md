# First Occurrence of Needle in Haystack — LeetCode #28

> Given two strings `needle` and `haystack`, return the index of the first occurrence of `needle` in `haystack`. Return `-1` if `needle` is not part of `haystack`.

---

## Problem Statement

```
Input:  haystack = "sadbutsad", needle = "sad"
Output: 0
Reason: "sad" occurs at index 0 and 6. First occurrence is at 0.

Input:  haystack = "leetcode", needle = "leeto"
Output: -1
Reason: "leeto" is not in "leetcode"

Input:  haystack = "abc", needle = ""
Output: 0
Reason: empty needle — convention is to return 0

Input:  haystack = "a", needle = "a"
Output: 0

Input:  haystack = "a", needle = "b"
Output: -1
```

---

## Approach 1 — Naive Sliding Window (O(n * m))

Start at each position in haystack. If the first character matches, check if the full needle matches from that position. Time: O(n * m) where n = len(haystack), m = len(needle).

```go
func strStr(haystack string, needle string) int {
    n := len(haystack)
    m := len(needle)
    if m == 0 {
        return 0
    }
    if m > n {
        return -1
    }

    for i := 0; i <= n-m; i++ {        // outer: each starting position
        if haystack[i] == needle[0] {   // quick first-char check
            j := 0
            for j < m && haystack[i+j] == needle[j] {
                j++
            }
            if j == m {                 // matched all m characters
                return i
            }
        }
    }

    return -1
}
```

**Time: O(n * m)** — worst case: "aaaaaab" in "aaaaaaaaab" (lots of partial matches)  
**Space: O(1)**

---

## Approach 1 Trace

```
haystack = "sadbutsad", needle = "sad"

i=0: haystack[0]='s' == needle[0]='s' → check full match:
     s==s, a==a, d==d → j=3 == m=3 → FOUND! return 0

haystack = "aabcaa", needle = "bca"

i=0: 'a' != 'b' → skip
i=1: 'a' != 'b' → skip
i=2: 'b' == 'b' → check: b==b, c==c, a==a → j=3==m → return 2
```

---

## Approach 2 — Go's Built-in (strings.Index)

```go
import "strings"

func strStr(haystack string, needle string) int {
    return strings.Index(haystack, needle)
}
```

`strings.Index` returns -1 if not found. Internally Go uses a combination of Rabin-Karp and Boyer-Moore for O(n) average case.

---

## Approach 3 — KMP Algorithm (O(n + m))

KMP (Knuth-Morris-Pratt) avoids re-checking characters when a partial match fails by precomputing a **failure function** (also called the LPS array — Longest Proper Prefix which is also Suffix).

**Key insight:** When a mismatch occurs at position `j` in needle, we don't restart from `j=0`. Instead we use `lps[j-1]` to jump to the longest proper prefix of needle[0..j-1] that is also a suffix — skipping characters we know match.

```go
func strStr(haystack string, needle string) int {
    n, m := len(haystack), len(needle)
    if m == 0 {
        return 0
    }

    // Build LPS (failure) array
    lps := buildLPS(needle)

    i, j := 0, 0   // i = haystack index, j = needle index
    for i < n {
        if haystack[i] == needle[j] {
            i++
            j++
            if j == m {           // full match found
                return i - m
            }
        } else if j > 0 {
            j = lps[j-1]          // fall back using failure function (don't advance i)
        } else {
            i++                   // no fallback possible, advance haystack
        }
    }

    return -1
}

// buildLPS computes the Longest Proper Prefix-Suffix array for needle
func buildLPS(pattern string) []int {
    m := len(pattern)
    lps := make([]int, m)
    length := 0  // length of previous longest prefix-suffix
    i := 1

    for i < m {
        if pattern[i] == pattern[length] {
            length++
            lps[i] = length
            i++
        } else if length > 0 {
            length = lps[length-1]   // try shorter prefix
        } else {
            lps[i] = 0
            i++
        }
    }

    return lps
}
```

**Time: O(n + m)** — O(m) to build LPS, O(n) to search  
**Space: O(m)** — LPS array of size m

---

## KMP Trace

```
needle = "aaab"

Build LPS:
  i=1: 'a'=='a' → lps[1]=1, length=1
  i=2: 'a'=='a' → lps[2]=2, length=2
  i=3: 'b'!='a' → length>0 → length=lps[1]=1 → 'b'!='a' → length>0 → length=lps[0]=0 → 'b'!='a' → lps[3]=0
  lps = [0, 1, 2, 0]

haystack = "aaabaaab"
i=0,j=0: 'a'=='a' → i=1,j=1
i=1,j=1: 'a'=='a' → i=2,j=2
i=2,j=2: 'a'=='a' → i=3,j=3
i=3,j=3: 'b'=='b' → i=4,j=4==m → return i-m = 4-4 = 0 ✓
```

---

## Python Solution

```python
def strStr(haystack: str, needle: str) -> int:
    return haystack.find(needle)  # returns -1 if not found

# Or naive approach:
def strStr_naive(haystack: str, needle: str) -> int:
    n, m = len(haystack), len(needle)
    if m == 0:
        return 0
    for i in range(n - m + 1):
        if haystack[i:i+m] == needle:
            return i
    return -1
```

---

## Complexity Comparison

| Approach | Time | Space | Notes |
|----------|------|-------|-------|
| Naive sliding window | O(n * m) | O(1) | Simple, works for most interview cases |
| Built-in `strings.Index` | O(n) avg | O(1) | Best for production code |
| KMP | O(n + m) | O(m) | Best theoretical worst-case |

---

## Edge Cases

```
needle = ""           → 0 (empty needle is found at index 0 by convention)
needle == haystack    → 0
len(needle) > len(haystack) → -1
haystack = "a", needle = "a"  → 0
haystack = "aa", needle = "aaa" → -1 (needle longer than haystack)
```

---

## Interview Q&A

**Q: What is the time complexity of the naive approach and when does it degrade?**
O(n * m) where n = len(haystack) and m = len(needle). It degrades to its worst case when there are many partial matches that fail only at the last character of needle. Example: haystack = "aaaaaab", needle = "aaab" — every position starts matching (a==a, a==a, a==a) before failing, so almost every position triggers a full m-length inner loop. For interview problems where the input is not adversarial, the naive approach is often acceptable.

**Q: How does KMP improve on the naive approach?**
KMP precomputes a failure function (LPS array) that tells us: "after a mismatch at position j in needle, how far back should we jump in needle without advancing i in haystack?" This avoids re-checking characters we already know match. The precomputation is O(m); the search phase is O(n) — at most n characters are compared and the needle pointer j never decreases the total by more than it increased. Combined: O(n + m) time, O(m) space.

**Q: What does the LPS array represent?**
LPS stands for Longest Proper Prefix that is also a Suffix. For a pattern like "aaab": lps = [0, 1, 2, 0]. `lps[2] = 2` means the prefix "aa" of "aaa" is also a suffix of "aaa". When we mismatch at position 3 (at 'b'), we know the first 2 characters ('aa') of the pattern still match the current position in the text — so we jump j to lps[j-1] = 2 instead of resetting j to 0, saving work.
