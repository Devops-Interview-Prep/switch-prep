Binary Search Algorithm is a searching algorithm used in a sorted array by repeatedly dividing the search interval in half. The idea of binary search is to use the information that the array is sorted and reduce the time complexity to O(log N). 

# Conditions to apply Binary Search Algorithm in a Data Structure

- To apply Binary Search algorithm:
    - The data structure must be sorted.
    - Access to any element of the data structure should take constant time.


# Binary Search Algorithm

- Below is the step-by-step algorithm for Binary Search:

1. Divide the search space into two halves by finding the middle index "mid". 
2. Compare the middle element of the search space with the key. 
3. If the key is found at middle element, the process is terminated.
4. If the key is not found at middle element, choose which half will be used as the next search space.
5. If the key is smaller than the middle element, then the left side is used for next search.
6. If the key is larger than the middle element, then the right side is used for next search.
7. This process is continued until the key is found or the total search space is exhausted.


# Problem 

Given a sorted array of distinct integers and a target value, return the index if the target is found. If not, return the index where it would be if it were inserted in order.

You must write an algorithm with O(log n) runtime complexity.

# Recursive method 

```
func searchInsert(nums []int, target int) int {
    return binarySearch(nums, target, 0, len(nums)-1)
}

func binarySearch(nums []int, target, left, right int) int {
    if left > right {
        return left // Position to insert
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

# Itrative Method

```
func searchInsert(nums []int, target int) int {
    left, right := 0, len(nums)-1

    for left <= right {
        mid := left + (right-left)/2

        if nums[mid] == target {
            return mid
        } else if nums[mid] < target {
            left = mid + 1
        } else {
            right = mid - 1
        }
    }

    return left // Position to insert if not found
}
```
