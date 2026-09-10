# Add Binary — LeetCode #67

> Given two binary strings `a` and `b`, return their sum as a binary string.

---

## Problem Statement

```
Input:  a = "11", b = "1"
Output: "100"
Reason: 11 (binary) = 3, 1 (binary) = 1, 3+1=4 = 100 (binary)

Input:  a = "1010", b = "1011"
Output: "10101"
Reason: 1010 = 10, 1011 = 11, 10+11=21 = 10101 (binary)

Input:  a = "0", b = "0"
Output: "0"

Input:  a = "1", b = "1"
Output: "10"
Reason: 1+1 = 2 = 10 in binary
```

---

## Key Insight — Carry Propagation

Process from right-to-left (LSB first), just like pen-and-paper binary addition:
- Add the corresponding bits
- Add any carry from the previous position
- Result bit = sum % 2, new carry = sum / 2

```
"1010" + "1011"

Position:  3  2  1  0    (right-to-left, 0 = LSB)
a:         1  0  1  0
b:         1  0  1  1
           ─────────────
carry=0

pos 0: 0 + 1 + carry=0 → sum=1 → bit='1', carry=0
pos 1: 1 + 1 + carry=0 → sum=2 → bit='0', carry=1
pos 2: 0 + 0 + carry=1 → sum=1 → bit='1', carry=0
pos 3: 1 + 1 + carry=0 → sum=2 → bit='0', carry=1
done:  carry=1 → add extra '1'

Result bits built (right-to-left): '1','0','1','0','1'
Reverse: "10101" ✓
```

---

## Solution — Go

```go
func addBinary(a string, b string) string {
    i := len(a) - 1     // pointer from right end of a
    j := len(b) - 1     // pointer from right end of b
    carry := 0
    result := []byte{}

    for i >= 0 || j >= 0 || carry > 0 {
        sum := carry

        if i >= 0 {
            sum += int(a[i] - '0')  // convert '0'/'1' byte to int 0/1
            i--
        }
        if j >= 0 {
            sum += int(b[j] - '0')
            j--
        }

        result = append(result, byte(sum%2)+'0')  // append '0' or '1'
        carry = sum / 2
    }

    // Result was built LSB first — reverse it
    for left, right := 0, len(result)-1; left < right; left, right = left+1, right-1 {
        result[left], result[right] = result[right], result[left]
    }

    return string(result)
}
```

**Time: O(max(n, m))** — single pass through both strings  
**Space: O(max(n, m))** — result string

---

## Solution — Python

```python
def addBinary(a: str, b: str) -> str:
    i, j = len(a) - 1, len(b) - 1
    carry = 0
    result = []

    while i >= 0 or j >= 0 or carry:
        total = carry
        if i >= 0:
            total += int(a[i])
            i -= 1
        if j >= 0:
            total += int(b[j])
            j -= 1
        result.append(str(total % 2))
        carry = total // 2

    return ''.join(reversed(result))

# Python one-liner (using built-ins, not suitable for interview whiteboard):
def addBinary_oneliner(a: str, b: str) -> str:
    return bin(int(a, 2) + int(b, 2))[2:]  # [2:] strips "0b" prefix
```

---

## Why Not Just Convert to Int?

| Approach | Time | Space | Problem |
|----------|------|-------|---------|
| `int(a,2) + int(b,2)` | O(n) | O(n) | Integer overflow for very long strings (10^4 digits) |
| Carry propagation | O(n) | O(n) | No overflow — works for arbitrarily long binary strings |

The constraint says `1 <= a.length, b.length <= 10^4`. That's a 10,000-bit number, which overflows standard 64-bit integers. The carry propagation approach works for any length.

---

## Edge Cases

```
a="0", b="0"         → "0"
a="1", b="1"         → "10"
a="11", b="1"        → "100"
a="1111", b="1111"   → "11110"   (both all-ones)
a="1", b="111"       → "1000"    (different lengths, carry propagates)
a="0", b="1"         → "1"       (result doesn't have leading zeros)
```

---

## Interview Q&A

**Q: Why do you process the strings right-to-left?**
Binary addition, like decimal addition, starts from the least significant bit (rightmost). We process right-to-left because a carry from position i flows left to position i+1. Processing left-to-right would require knowing future carries before we can compute current sums. Right-to-left lets us handle carry naturally as a single running variable.

**Q: What happens when the strings have different lengths?**
We handle this by using independent pointers `i` for string `a` and `j` for string `b`, each starting from the right end. When one pointer goes below 0, we stop reading from that string and only contribute its carry. The loop continues as long as either pointer is valid OR there's still a carry — this handles the case where the result is longer than both inputs (e.g., "1111" + "1" = "10000").

**Q: How would you extend this to add binary strings representing negative numbers (two's complement)?**
Two's complement is a fixed-width representation. For arbitrary-precision signed binary, you'd need to define a convention (sign bit, sign-magnitude, etc.). For two's complement specifically: if the strings have the same width and the high bit represents the sign, the addition itself is identical — two's complement addition works naturally with overflow wraparound. But for interview purposes, LeetCode #67 only deals with non-negative binary integers.
