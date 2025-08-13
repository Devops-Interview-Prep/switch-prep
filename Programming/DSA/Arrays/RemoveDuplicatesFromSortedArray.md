# Problem Statement
Given an integer array nums sorted in non-decreasing order, remove the duplicates in-place such that each unique element appears only once. The relative order of the elements should be kept the same. Then return the number of unique elements in nums.

Consider the number of unique elements of nums to be k, to get accepted, you need to do the following things:

Change the array nums such that the first k elements of nums contain the unique elements in the order they were present in nums initially. The remaining elements of nums are not important as well as the size of nums.
Return k.

# Solution 

```
func removeDuplicates(nums []int) int {

length := len(nums)

if length == 0 {
    return 0
}

j := 0

for i:=1; i<length; i++ {
   if nums[i] != nums[i-1]{
    j = j+1
    nums[j] = nums[i]
   }else{
    continue
   }
}
   return j+1
}
```

TC = O(n)    
SC = O(1)

- Check the ith element of the array if it is equal to the i-1th element then we wont increase the index to update the array otherwise will increase and will put the new element in the next index.