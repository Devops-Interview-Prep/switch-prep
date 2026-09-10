# Binary Search

> Binary Search is a divide-and-conquer algorithm for finding an element in a **sorted** collection. Instead of scanning every element (O(n)), it halves the search space each step → O(log n). A 1 billion element array takes at most ~30 comparisons.

---

## Core Conditions and Concept

```
Requirements to apply binary search:
1. The collection must be SORTED (ascending or descending)
2. Random access must be O(1) — works on arrays, not linked lists

Algorithm steps:
1. Set left=0, right=len-1
2. Find mid = left + (right-left)/2  (avoids integer overflow vs (left+right)/2)
3. If arr[mid] == target → found
4. If arr[mid] < target → target must be in right half → left = mid + 1
5. If arr[mid] > target → target must be left half → right = mid - 1
6. Repeat until left > right (not found)
```

---

## Problem — Search Insert Position (LeetCode #35)

```
Given a sorted array of distinct integers and a target, return the index if found.
If not found, return the index where it would be inserted in sorted order.

Input:  nums = [1, 3, 5, 6], target = 5   → Output: 2  (found at index 2)
Input:  nums = [1, 3, 5, 6], target = 2   → Output: 1  (insert between 1 and 3)
Input:  nums = [1, 3, 5, 6], target = 7   → Output: 4  (insert after all)
Input:  nums = [1, 3, 5, 6], target = 0   → Output: 0  (insert before all)
```

---

## Iterative Solution — Go

```go
func searchInsert(nums []int, target int) int {
    left, right := 0, len(nums)-1

    for left <= right {
        mid := left + (right-left)/2   // safe midpoint (avoids overflow)

        if nums[mid] == target {
            return mid
        } else if nums[mid] < target {
            left = mid + 1   // target is to the right
        } else {
            right = mid - 1  // target is to the left
        }
    }

    return left  // insert position when not found
}
```

**Time: O(log n)** | **Space: O(1)**

### Trace — target = 2 in [1, 3, 5, 6]

```
left=0, right=3
  mid=1 → nums[1]=3 > target=2 → right=0

left=0, right=0
  mid=0 → nums[0]=1 < target=2 → left=1

left=1 > right=0 → loop ends
return left = 1  ← insert at index 1 ✓ ([1, 2, 3, 5, 6])
```

---

## Recursive Solution — Go

```go
func searchInsert(nums []int, target int) int {
    return binarySearch(nums, target, 0, len(nums)-1)
}

func binarySearch(nums []int, target, left, right int) int {
    if left > right {
        return left  // insert position
    }

    mid := left + (right-left)/2

    if nums[mid] == target {
        return mid
    } else if nums[mid] < target {
        return binarySearch(nums, target, mid+1, right)
    } else {
        return binarySearch(nums, target, left, mid-1)
    }
}
```

**Time: O(log n)** | **Space: O(log n)** — call stack depth

---

## Python Solution

```python
def searchInsert(nums: list[int], target: int) -> int:
    left, right = 0, len(nums) - 1

    while left <= right:
        mid = (left + right) // 2
        if nums[mid] == target:
            return mid
        elif nums[mid] < target:
            left = mid + 1
        else:
            right = mid - 1

    return left

# Python built-in alternative (using bisect module):
import bisect
def searchInsert_builtin(nums: list[int], target: int) -> int:
    return bisect.bisect_left(nums, target)
```

---

## Binary Search Variants

```go
// Find FIRST occurrence of target (in array with duplicates):
func firstOccurrence(nums []int, target int) int {
    left, right, result := 0, len(nums)-1, -1
    for left <= right {
        mid := left + (right-left)/2
        if nums[mid] == target {
            result = mid       // found, but keep searching left
            right = mid - 1
        } else if nums[mid] < target {
            left = mid + 1
        } else {
            right = mid - 1
        }
    }
    return result
}

// Find LAST occurrence of target:
func lastOccurrence(nums []int, target int) int {
    left, right, result := 0, len(nums)-1, -1
    for left <= right {
        mid := left + (right-left)/2
        if nums[mid] == target {
            result = mid       // found, but keep searching right
            left = mid + 1
        } else if nums[mid] < target {
            left = mid + 1
        } else {
            right = mid - 1
        }
    }
    return result
}
```

---

## Complexity

| | Iterative | Recursive |
|---|-----------|-----------|
| **Time** | O(log n) | O(log n) |
| **Space** | O(1) | O(log n) call stack |

**Why O(log n)?** Each step halves the search space. Starting with n elements: after k steps, `n / 2^k` remain. When `n / 2^k = 1` → `k = log₂(n)`.

---

## Interview Q&A

**Q: Why use `left + (right-left)/2` instead of `(left+right)/2`?**
If `left = 1,000,000,000` and `right = 2,000,000,000`, then `left + right = 3,000,000,000` which overflows a 32-bit integer (max ~2.1 billion). `left + (right-left)/2` computes the same midpoint but keeps intermediate values in range. In Go with 64-bit int on 64-bit systems this rarely matters, but it's the correct habit for C/Java (int is 32-bit) and demonstrates understanding in interviews.

**Q: When does binary search return `left` vs `-1` for not-found?**
For "find exact match" (like LeetCode #704 Binary Search): return `-1` when `left > right`. For "find insert position" (LeetCode #35): return `left` — because when the loop ends with `left > right`, `left` points exactly where the target would be inserted to maintain sorted order. This is also what Python's `bisect.bisect_left` returns.

**Q: What's the iterative vs recursive trade-off in binary search?**
Both are O(log n) time. Iterative is O(1) space (no call stack). Recursive is O(log n) space due to the call stack — for a 1-billion-element array, that's ~30 stack frames (negligible). Iterative is preferred in practice: no risk of stack overflow, slightly faster due to no function call overhead. Recursive is more naturally expressed for divide-and-conquer problems where you need to process sub-results (e.g., merge sort). For binary search specifically: always use iterative.
