# Two Sum — LeetCode #1

> Given an array of integers `nums` and an integer `target`, return the **indices** of the two numbers that add up to `target`. You may assume each input has exactly one solution, and you may not use the same element twice.

---

## Problem Statement

```
Input:  nums = [2, 7, 11, 15], target = 9
Output: [0, 1]
Reason: nums[0] + nums[1] = 2 + 7 = 9

Input:  nums = [3, 2, 4], target = 6
Output: [1, 2]
Reason: nums[1] + nums[2] = 2 + 4 = 6

Input:  nums = [3, 3], target = 6
Output: [0, 1]
Reason: same value, different indices
```

---

## Approach 1 — Brute Force (O(n²))

Check every pair of elements:

```go
func twoSum(nums []int, target int) []int {
    n := len(nums)
    for i := 0; i < n-1; i++ {
        for j := i + 1; j < n; j++ {
            if nums[i]+nums[j] == target {
                return []int{i, j}
            }
        }
    }
    return []int{}
}
```

**Time: O(n²)** — two nested loops over n elements  
**Space: O(1)** — no extra storage

**Problem:** Too slow for large inputs (10^4 elements = 10^8 operations).

---

## Approach 2 — HashMap One-Pass (O(n)) ← Optimal

**Key insight:** For each number `nums[i]`, the complement needed is `target - nums[i]`. If we've already seen that complement, we're done. Use a HashMap to store each number's index as we iterate.

```go
func twoSum(nums []int, target int) []int {
    seen := make(map[int]int)   // value → index

    for i, num := range nums {
        complement := target - num
        if j, found := seen[complement]; found {
            return []int{j, i}
        }
        seen[num] = i           // store current number for future lookups
    }
    return []int{}
}
```

**Trace through `[2, 7, 11, 15]`, target=9:**
```
i=0, num=2,  complement=7  → not in seen → seen={2:0}
i=1, num=7,  complement=2  → found! seen[2]=0 → return [0, 1] ✓
```

**Time: O(n)** — single pass through the array  
**Space: O(n)** — HashMap stores up to n entries

---

## Approach 2b — HashMap Two-Pass (also O(n))

Build the full map first, then look up complements. Slightly easier to understand, same complexity:

```go
func twoSumTwoPass(nums []int, target int) []int {
    // Pass 1: build value → index map
    m := make(map[int]int)
    for i, v := range nums {
        m[v] = i
    }

    // Pass 2: find complement
    for j := 0; j < len(nums)-1; j++ {
        key := target - nums[j]
        index2, ok := m[key]
        if ok && index2 != j {   // must not be the same element
            return []int{j, index2}
        }
    }
    return []int{}
}
```

**Why one-pass is better:** It handles duplicates naturally (e.g., `[3, 3]`, target=6) because we check before storing — when we're at index 1 (value=3), complement=3 is already in the map at index 0.

---

## Python Solution

```python
def twoSum(nums: list[int], target: int) -> list[int]:
    seen = {}                      # value → index
    for i, num in enumerate(nums):
        complement = target - num
        if complement in seen:
            return [seen[complement], i]
        seen[num] = i
    return []
```

---

## Edge Cases

```
# Same value twice (must use different indices)
nums = [3, 3], target = 6  → [0, 1]   ✓  (one-pass handles this correctly)

# Negative numbers
nums = [-1, -2, -3, -4, -5], target = -8  → [2, 4]  (-3 + -5 = -8)

# Zero involved
nums = [0, 4, 3, 0], target = 0  → [0, 3]

# Large input (correctness at scale)
# O(n²) brute force → TLE; O(n) HashMap → passes
```

---

## Complexity Summary

| Approach | Time | Space | Notes |
|----------|------|-------|-------|
| Brute force | O(n²) | O(1) | Fails for large n |
| HashMap one-pass | O(n) | O(n) | Optimal — recommended |
| Sorted + two pointers | O(n log n) | O(1) | Only if indices don't matter (returns values) |

---

## Interview Q&A

**Q: Why does the HashMap approach work?**
For each element `x`, we need to find `y = target - x` somewhere in the array. Instead of scanning the full array for `y` on each step (O(n²)), we remember every number we've seen so far in a HashMap keyed by value. Lookups in a HashMap are O(1). So for each element, we check if its complement was already seen — one pass, O(n) total.

**Q: Why does one-pass work for duplicates like `[3, 3]`, target=6?**
In the one-pass approach, we check if the complement is in `seen` BEFORE adding the current element. So when we're at index 1 (value=3), complement=3 IS in `seen` (stored at index 0), and we return `[0, 1]`. In a two-pass approach, we'd store both 3s in the map (with index 1 overwriting index 0), so we'd need the `index2 != j` guard to avoid using the same element twice.

**Q: What if there are multiple valid answers?**
LeetCode's Two Sum guarantees exactly one solution. If multiple solutions were possible, you'd collect all pairs and return them — same HashMap approach, just collect into a result list instead of returning immediately.
