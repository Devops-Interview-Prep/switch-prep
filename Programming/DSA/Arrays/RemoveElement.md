# Remove Element — LeetCode #27

> Given an integer array `nums` and an integer `val`, remove all occurrences of `val` in-place. Return the count of elements not equal to `val`. The first k elements of the array must contain the remaining elements; order may be changed.

---

## Problem Statement

```
Input:  nums = [3, 2, 2, 3], val = 3
Output: 2, nums = [2, 2, _, _]
        (underscore = don't care, only first 2 elements matter)

Input:  nums = [0, 1, 2, 2, 3, 0, 4, 2], val = 2
Output: 5, nums = [0, 1, 4, 0, 3, _, _, _]
        (5 elements remain: 0, 1, 3, 0, 4 in any order)
```

**Constraint:** In-place — O(1) extra space. No copying to a new array.

---

## Key Insight — Two-Pointer Technique

Use a write pointer `j` that only advances when we keep an element. For each element at `i`:
- If `nums[i] == val` → skip it (don't write, don't advance `j`)
- If `nums[i] != val` → write it to position `j`, then advance `j`

At the end, `j` equals the number of valid elements.

```
nums = [3, 2, 2, 3], val = 3

i=0: nums[0]=3 == val → skip, j stays 0   → [3, 2, 2, 3]  j=0
i=1: nums[1]=2 != val → nums[0]=2, j++    → [2, 2, 2, 3]  j=1
i=2: nums[2]=2 != val → nums[1]=2, j++    → [2, 2, 2, 3]  j=2
i=3: nums[3]=3 == val → skip, j stays 2   → [2, 2, 2, 3]  j=2

return j=2  (first 2 elements: nums[0]=2, nums[1]=2)
```

---

## Solution — Go

```go
func removeElement(nums []int, val int) int {
    j := 0  // write pointer

    for i := 0; i < len(nums); i++ {
        if nums[i] != val {
            nums[j] = nums[i]
            j++
        }
        // if nums[i] == val: skip, j doesn't move
    }

    return j   // j = count of non-val elements
}
```

**Time: O(n)** — single pass through the array  
**Space: O(1)** — in-place, no extra memory

---

## Solution — Python

```python
def removeElement(nums: list[int], val: int) -> int:
    j = 0
    for i in range(len(nums)):
        if nums[i] != val:
            nums[j] = nums[i]
            j += 1
    return j
```

---

## Alternative — When val is Rare (Swap from End)

If `val` appears rarely, this approach avoids unnecessary writes:

```go
func removeElement(nums []int, val int) int {
    left, right := 0, len(nums)-1

    for left <= right {
        if nums[left] == val {
            nums[left] = nums[right]  // overwrite with last element
            right--                   // shrink right boundary
        } else {
            left++
        }
    }

    return left   // left = count of non-val elements
}
```

**Trade-off:** Fewer writes when val is rare, but changes element order.

---

## Complexity

| Approach | Time | Space | Notes |
|----------|------|-------|-------|
| Forward two-pointer | O(n) | O(1) | Stable order, simple |
| Swap from end | O(n) | O(1) | Fewer writes when val is rare, unstable order |

---

## Interview Q&A

**Q: Why use two pointers instead of creating a new array?**
The problem requires in-place modification with O(1) extra space — you can't allocate a new array. Two pointers solve this elegantly: the read pointer `i` scans all elements, and the write pointer `j` only moves forward when an element should be kept. This overwrites "deleted" elements with the next valid ones — the original array becomes the output array with valid elements at the front.

**Q: What's the difference between RemoveElement and RemoveDuplicates?**
Both use the same two-pointer pattern (i=read, j=write), but the condition differs. In RemoveElement, we keep elements where `nums[i] != val` (keep anything that's NOT the target). In RemoveDuplicates, we keep elements where `nums[i] != nums[i-1]` (keep an element only if it's different from the previous). The two-pointer pattern is the same; only the filtering condition changes.
