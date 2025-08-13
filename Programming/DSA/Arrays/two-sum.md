# Brut Force Solution

```
func twoSum(nums []int, target int) []int {
	len := len(nums);
	var i int;
	var j int;
	var sum int;
	for i = 0; i<len-1; i++ {
	  for j = i+1; j<len; j++ {
		 sum = nums[i] + nums[j];
		 if sum == target {
			 break;
		 }
	  }
	 if sum == target {
			 break;
		 }
	} 

	result := []int{i,j};
	return result;
}
```

Time Complexicty - O(n2)   
Space Complexity - O(1)

# Optimized Code 

```
func twoSum(nums []int, target int) []int {
var m map[int]int
m = make(map[int]int)
len := len(nums)

for i:=0 ;i < len; i++ {
    m[nums[i]] = i
}

for j:=0 ;j < len-1; j++ {
    key := target - nums[j]
    index2, ok := m[key]
    if ok && index2 != j{
     return []int{j , index2}
    }
}
   return[]int{}
}
```
- passed values of array as key of map and index as values 
- (target - value of array at that index) will give you the other value and with the help of map you can find the index corresponding to the key 
 
Time Complexicty - O(n)   
Space Complexity - O(n)