# Remove Duplicates from Sorted Array — LeetCode #26

> Given an integer array `nums` sorted in non-decreasing order, remove duplicates in-place. Each unique element appears only once. Return the count of unique elements (k). The first k elements of nums must contain the unique elements in order.

---

## Problem Statement

```
Input:  nums = [1, 1, 2]
Output: 2, nums = [1, 2, _]
        2 unique elements: 1 and 2

Input:  nums = [0, 0, 1, 1, 1, 2, 2, 3, 3, 4]
Output: 5, nums = [0, 1, 2, 3, 4, _, _, _, _, _]
        5 unique elements: 0, 1, 2, 3, 4
```

**Key constraint:** Sorted input — duplicates are always adjacent, which enables the two-pointer solution.

---

## Key Insight

Because the array is **sorted**, duplicates are always adjacent. Compare each element to its predecessor: if they differ, it's a new unique element worth keeping.

Use a write pointer `j` starting at 0 (first element is always kept). For each element from index 1 onward:
- If `nums[i] != nums[i-1]` → new unique element → write to `nums[j+1]`, advance `j`
- If `nums[i] == nums[i-1]` → duplicate → skip

```
nums = [0, 0, 1, 1, 2]

j starts at 0 (always keep first element)
i=1: nums[1]=0 == nums[0]=0 → duplicate, skip, j=0
i=2: nums[2]=1 != nums[1]=0 → new! nums[1]=1, j=1   → [0,1,1,1,2]
i=3: nums[3]=1 == nums[2]=1 → duplicate, skip, j=1
i=4: nums[4]=2 != nums[3]=1 → new! nums[2]=2, j=2   → [0,1,2,1,2]

return j+1 = 3   (first 3 elements: [0, 1, 2])
```

---

## Solution — Go

```go
func removeDuplicates(nums []int) int {
    if len(nums) == 0 {
        return 0
    }

    j := 0  // write pointer (position of last unique element)

    for i := 1; i < len(nums); i++ {
        if nums[i] != nums[i-1] {   // new unique element
            j++
            nums[j] = nums[i]
        }
        // if equal: duplicate — skip
    }

    return j + 1  // j is 0-indexed, count = j+1
}
```

**Time: O(n)** — single pass  
**Space: O(1)** — in-place

---

## Solution — Python

```python
def removeDuplicates(nums: list[int]) -> int:
    if not nums:
        return 0

    j = 0
    for i in range(1, len(nums)):
        if nums[i] != nums[i - 1]:
            j += 1
            nums[j] = nums[i]

    return j + 1
```

---

## Why Sorted Array Matters

```
Unsorted array: [1, 3, 1, 2, 3]
→ Duplicates are NOT adjacent → two-pointer comparison to prev doesn't work
→ Need a HashSet: O(n) time, O(n) space

Sorted array: [1, 1, 2, 3, 3]
→ Duplicates ARE adjacent → compare nums[i] to nums[i-1]: O(n) time, O(1) space
```

The sorted constraint is what makes O(1) space possible. Without it, you'd need a `Set` to track seen elements.

---

## Variant — Allow at Most 2 Duplicates (LeetCode #80)

```go
// Allow each element to appear at most twice
func removeDuplicatesTwice(nums []int) int {
    j := 0
    for _, num := range nums {
        // Keep if: fewer than 2 elements written, OR this element != the one 2 positions back
        if j < 2 || num != nums[j-2] {
            nums[j] = num
            j++
        }
    }
    return j
}
```

The pattern generalizes: for at most K duplicates, check `nums[j-K]`.

---

## Complexity

| | Value |
|---|---|
| **Time** | O(n) — single pass |
| **Space** | O(1) — in-place, no extra storage |

---

## Interview Q&A

**Q: Why does this problem require the array to be sorted?**
Because duplicates must be adjacent for a single O(1) space comparison to work. The key insight is `nums[i] == nums[i-1]` — this only reliably detects duplicates when equal elements are grouped together (adjacent), which is guaranteed only in a sorted array. For an unsorted array with duplicates, you'd need a HashSet to track all previously seen values, costing O(n) extra space.

**Q: Walk me through the two-pointer pattern used here.**
We have a read pointer `i` starting at 1 (the second element — the first is always unique) and a write pointer `j` at 0 (pointing to the last confirmed unique element written). We advance `i` through the array. When `nums[i] != nums[i-1]` (new unique element found), we increment `j` and write `nums[i]` to `nums[j]`. When it's a duplicate, we just advance `i` without touching `j`. Return `j+1` as the count.

**Q: How do you extend this to allow at most 2 duplicates?**
Instead of comparing `nums[i]` to `nums[i-1]`, compare it to `nums[j-2]` (the element 2 positions before the write head). If they differ, we can write. This works because at most 2 copies of any value would mean the value 2 positions ago is the same only if we've already written 2 of them. Generalizes to K duplicates: check `nums[j-K]`.
