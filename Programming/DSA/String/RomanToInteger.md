# Roman to Integer — LeetCode #13

> Given a roman numeral string, convert it to an integer. Roman numerals are usually written largest to smallest from left to right — but 6 specific two-character combinations use subtraction.

---

## Problem Statement

```
Symbol values:
  I = 1,  V = 5,  X = 10,  L = 50,
  C = 100, D = 500, M = 1000

Subtraction rule: when a smaller value appears BEFORE a larger value, subtract it:
  IV = 4 (5-1), IX = 9 (10-1)
  XL = 40 (50-10), XC = 90 (100-10)
  CD = 400 (500-100), CM = 900 (1000-100)

Examples:
  "III"    → 3      (I+I+I)
  "IV"     → 4      (5-1)
  "IX"     → 9      (10-1)
  "LVIII"  → 58     (L+V+I+I+I)
  "MCMXCIV"→ 1994   (M+CM+XC+IV = 1000+900+90+4)
```

---

## Key Insight

```
When s[i] < s[i+1] → SUBTRACT s[i] (subtraction case)
When s[i] >= s[i+1] → ADD s[i] (normal case)

For "IX":
  i=0: romanMap['I']=1, romanMap['X']=10 → 1 < 10 → subtract: total -= 1 → total=-1
  i=1: last char, add: total += 10 → total=9 ✓

For "MCMXCIV":
  M: 1000 >= 1 (C follows... wait, next is C=100)
     1000 > 100 → ADD 1000, total=1000
  C: 100 < 1000 (M follows) → SUBTRACT 100, total=900
  M: 1000, nothing large after... 1000 > 900 → ADD... wait, next is X=10
     1000 > 10 → ADD 1000, total=1900
  X: 10 < 100 (C follows) → SUBTRACT 10, total=1890
  C: 100 > 4 (next is I=1... no, next is I)... 100 > 1 → ADD 100, total=1990... 
  
  Let's do it cleanly:
  M  C  M  X  C  I  V
  +  -  +  -  +  -  +    ← sign based on comparing to next char
  1000-100+1000-10+100-1+5 = 1994 ✓
```

---

## Optimized Solution — Go (HashMap Approach)

```go
func romanToInt(s string) int {
    romanMap := map[byte]int{
        'I': 1,
        'V': 5,
        'X': 10,
        'L': 50,
        'C': 100,
        'D': 500,
        'M': 1000,
    }

    total := 0
    n := len(s)

    for i := 0; i < n; i++ {
        curr := romanMap[s[i]]
        // If not last char and current < next → subtraction case
        if i < n-1 && curr < romanMap[s[i+1]] {
            total -= curr
        } else {
            total += curr
        }
    }

    return total
}
```

**Time: O(n)** | **Space: O(1)** — map has only 7 fixed entries

---

## Trace Through "MCMXCIV"

```
i=0: s[0]='M' (1000), s[1]='C' (100) → 1000 > 100 → ADD 1000    total=1000
i=1: s[1]='C' (100),  s[2]='M' (1000)→ 100 < 1000 → SUB 100     total=900
i=2: s[2]='M' (1000), s[3]='X' (10)  → 1000 > 10  → ADD 1000    total=1900
i=3: s[3]='X' (10),   s[4]='C' (100) → 10 < 100   → SUB 10      total=1890
i=4: s[4]='C' (100),  s[5]='I' (1)   → 100 > 1    → ADD 100     total=1990
i=5: s[5]='I' (1),    s[6]='V' (5)   → 1 < 5      → SUB 1       total=1989
i=6: s[6]='V' (5), last char          →             ADD 5        total=1994 ✓
```

---

## Python Solution

```python
def romanToInt(s: str) -> int:
    roman_map = {
        'I': 1, 'V': 5, 'X': 10,
        'L': 50, 'C': 100, 'D': 500, 'M': 1000
    }

    total = 0
    for i in range(len(s)):
        curr = roman_map[s[i]]
        # If not last and current < next: subtract
        if i + 1 < len(s) and curr < roman_map[s[i + 1]]:
            total -= curr
        else:
            total += curr

    return total
```

---

## Brute Force vs Optimized

| Approach | Code | Time | Space | Notes |
|----------|------|------|-------|-------|
| Brute force (if/else per char) | 80+ lines | O(n) | O(1) | Hard to maintain |
| HashMap + subtract rule | 15 lines | O(n) | O(1) | Clean, interview-preferred |

The brute force explicitly checks each combination (IV, IX, XL, etc.) with nested if-else. The HashMap approach uses the single insight that a smaller-before-larger means subtract — handles all 6 subtraction cases automatically.

---

## Edge Cases

```
"I"      → 1  (single character)
"III"    → 3  (no subtraction)
"IV"     → 4  (subtraction)
"VIII"   → 8  (no subtraction, multiple same chars)
"MCMXCIX"→ 1999 (M+CM+XC+IX = 1000+900+90+9)
"MMMCMXCIX" → 3999 (maximum valid Roman numeral)
```

---

## Interview Q&A

**Q: What is the core insight that makes the HashMap approach work?**
In valid Roman numerals, a character should be subtracted when it appears before a larger-valued character. Rather than hardcoding all 6 special cases (IV, IX, XL, XC, CD, CM), we use one rule: if `value[s[i]] < value[s[i+1]]`, subtract `value[s[i]]`; otherwise add it. This single comparison handles all subtraction cases and works because Roman numerals are always constructed so smaller symbols precede a single larger symbol for subtraction, never more complex patterns.

**Q: Why can you use `s[i]` as a byte key in the map instead of converting to a rune?**
All 7 Roman numeral symbols (I, V, X, L, C, D, M) are ASCII characters — each is exactly 1 byte in UTF-8. `s[i]` in Go returns a `byte` (uint8), and we can use `byte` as a map key directly. This is safe here because the problem guarantees the input consists only of these 7 ASCII symbols. For strings with non-ASCII characters, we'd need `[]rune(s)[i]` for correct character indexing.

**Q: What is the time and space complexity, and why is the map considered O(1) space?**
Time: O(n) where n = length of the string — single pass through all characters. Space: O(1) — the `romanMap` has exactly 7 entries regardless of input size. When we say a data structure has constant size, it's O(1) space even if it uses memory. The 7-entry map's memory is independent of n, so the algorithm uses no space proportional to input.
