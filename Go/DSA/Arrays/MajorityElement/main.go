/*
Given an array nums of size n, return the majority element.

The majority element is the element that appears more than ⌊n / 2⌋ times. You may assume that the majority element always exists in the array.

 

Example 1:

Input: nums = [3,2,3]
Output: 3
Example 2:

Input: nums = [2,2,1,1,1,2,2]
Output: 2
*/


package main

import (
	"fmt"
)

func majorityElement(nums []int) int {
	countMap := make(map[int]int)

	n := len(nums)

	for i := 0; i < n; i++ {
		countMap[nums[i]]++
		if countMap[nums[i]] > n/2 {
			return nums[i]
		}
	}
	return -1

}


func main() {
	nums := []int{3, 2, 3}
	fmt.Println(majorityElement(nums))
}
