# Plus One — LeetCode #66

> You are given a large integer represented as an array of digits (most significant first, no leading zeros). Increment the integer by one and return the resulting array of digits.

---

## Problem Statement

```
Input:  digits = [1, 2, 3]   → represents the number 123
Output: [1, 2, 4]            → 123 + 1 = 124

Input:  digits = [1, 2, 9]   → represents 129
Output: [1, 3, 0]            → 129 + 1 = 130  (carry propagates)

Input:  digits = [9, 9, 9]   → represents 999
Output: [1, 0, 0, 0]         → 999 + 1 = 1000 (array grows by 1)

Input:  digits = [9]         → represents 9
Output: [1, 0]               → 9 + 1 = 10
```

---

## Key Insight

Adding 1 only causes a carry when the last digit is 9. The carry propagates left only as long as digits equal 9. There are three cases:

```
Case 1: Last digit < 9
        [1, 2, 3] → just increment last digit → [1, 2, 4]

Case 2: Last digit = 9, but not all 9s
        [1, 2, 9] → last digit becomes 0, carry propagates → [1, 3, 0]
        [1, 9, 9] → two 9s become 0, carry propagates → [2, 0, 0]

Case 3: ALL digits are 9
        [9, 9, 9] → all become 0, prepend 1 → [1, 0, 0, 0]
```

---

## Solution — In-Place (O(n) time, O(1) space)

```go
func plusOne(digits []int) []int {
    n := len(digits)

    // Traverse from the rightmost digit
    for i := n - 1; i >= 0; i-- {
        if digits[i] < 9 {
            // No carry — just increment and done
            digits[i]++
            return digits
        }
        // digits[i] == 9: set to 0 and carry over to the left
        digits[i] = 0
    }

    // If we're here, all digits were 9 → prepend a 1
    // e.g., [9,9,9] → [0,0,0] → [1,0,0,0]
    return append([]int{1}, digits...)
}
```

**Trace through `[1, 9, 9]`:**
```
i=2: digits[2]=9 → set to 0 → [1, 9, 0]
i=1: digits[1]=9 → set to 0 → [1, 0, 0]
i=0: digits[0]=1 < 9 → increment → [2, 0, 0] → return
```

**Trace through `[9, 9, 9]`:**
```
i=2: 9 → 0 → [9, 9, 0]
i=1: 9 → 0 → [9, 0, 0]
i=0: 9 → 0 → [0, 0, 0]
loop ends (all 9s)
prepend 1: [1, 0, 0, 0]
```

---

## Python Solution

```python
def plusOne(digits: list[int]) -> list[int]:
    for i in range(len(digits) - 1, -1, -1):
        if digits[i] < 9:
            digits[i] += 1
            return digits
        digits[i] = 0
    # All 9s case
    return [1] + digits
```

---

## Alternative — Cleaner Go with prepend

```go
func plusOne(digits []int) []int {
    for i := len(digits) - 1; i >= 0; i-- {
        if digits[i]++; digits[i] < 10 {
            return digits       // no carry needed
        }
        digits[i] = 0           // overflow: set to 0, propagate carry
    }
    return append([]int{1}, digits...)  // all 9s: [9...] → [0...] → [1,0...]
}
```

---

## Complexity Analysis

| | Value |
|---|---|
| **Time** | O(n) — worst case traverses all n digits |
| **Space** | O(1) — in-place modification; O(n) for the all-9s case (new array) |

**Typical case:** O(1) — if the last digit is not 9, we return after one step.

---

## Edge Cases

```
[0]        → [1]            single zero
[1]        → [2]            single digit, no carry
[9]        → [1, 0]         single 9, array grows
[9, 9]     → [1, 0, 0]      all 9s, 2 digits
[1, 0, 0]  → [1, 0, 1]      zeros in middle (no issue, only last digit increments)
```

---

## Interview Q&A

**Q: Why traverse from the right?**
Adding 1 starts at the least significant digit (rightmost). A carry only propagates left — you never need to look right again once you've processed a digit. Traversing right-to-left mirrors how grade-school addition works.

**Q: Why is the all-9s case special?**
When all digits are 9, every digit overflows to 0, and the carry propagates all the way past the leftmost digit — creating a new digit at position 0. The resulting array is one element longer. In Go, `append([]int{1}, digits...)` prepends 1 to the now all-zero array. In Python, `[1] + digits` does the same.

**Q: What's the time complexity in the best, average, and worst case?**
Best case O(1): last digit is not 9 — one iteration, return immediately. Average case O(1): most numbers have a non-9 last digit. Worst case O(n): all digits are 9 — traverse the entire array. Real-world: the all-9s case is rare, so amortized this is effectively O(1).
