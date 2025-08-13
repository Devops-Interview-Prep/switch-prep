/*You are given two integer arrays nums1 and nums2, sorted in non-decreasing order, and two integers m and n, representing the number of elements in nums1 and nums2 respectively.

Merge nums1 and nums2 into a single array sorted in non-decreasing order.

The final sorted array should not be returned by the function, but instead be stored inside the array nums1. To accommodate this, nums1 has a length of m + n, where the first m elements denote the elements that should be merged, and the last n elements are set to 0 and should be ignored. nums2 has a length of n.

 

Example 1:

Input: nums1 = [1,2,3,0,0,0], m = 3, nums2 = [2,5,6], n = 3
Output: [1,2,2,3,5,6]
Explanation: The arrays we are merging are [1,2,3] and [2,5,6].
The result of the merge is [1,2,2,3,5,6] with the underlined elements coming from nums1.
*/


package main

import (
	"fmt"
)

func merge(nums1 []int, m int, nums2 []int, n int) []int {

	if m == 0 {
		for i := 0; i < n; i++ {
			nums1[i] = nums2[i]
		}
	} else if n == 0 {
		return nums1
	}

	max := nums1[m-1]
	j := m - 1
	k := n - 1

	for i := m + n - 1; i >= 0; i-- {
		if j >= 0 && nums1[j] > nums2[k] {
			max = nums1[j]
			j--
			fmt.Println(max)

		} else {
			max = nums2[k]
			k--
		}

		nums1[i] = max

		if k < 0 {
			break
		}
	}

	return nums1
}

func main() {
	nums1 := []int{1, 2, 3, 0, 0, 0}
	m := 3
	nums2 := []int{2, 5, 6}
	n := 3

	fmt.Println(merge(nums1, m, nums2, n))
}
