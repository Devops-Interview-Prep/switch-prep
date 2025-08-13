// Given a non-empty array of integers nums, every element appears twice except for one. Find that single one.

// You must implement a solution with a linear runtime complexity and use only constant extra space.

package main

import "fmt"

func singleNumber(nums []int) int {

    n := len(nums)
    result := 0

for i:=0 ; i< n ; i++ {
    result = result ^ nums[i]  
	// If we XOR all numbers in the array:
// Duplicate numbers cancel each other (x ^ x = 0)
// The unique number remains (0 ^ unique = unique)

}
   return result
}

func main(){
	nums := []int{2,2,1}

	fmt.Println(singleNumber(nums))
}