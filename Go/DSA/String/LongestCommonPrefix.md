# Problem

Write a function to find the longest common prefix string amongst an array of strings.

If there is no common prefix, return an empty string "".

 

Example 1:

Input: strs = ["flower","flow","flight"]
Output: "fl"


# Solution 

```
func longestCommonPrefix(strs []string) string {
	length := len(strs)
	length1 := len(strs[0])

	var output strings.Builder
	var j int

	if len(strs) == 0 {
		return ""
	}

	for i := 0; i < length1; i++ {
		for j = 1; j < length; j++ {
			if len(strs[j])-1 < i || strs[0][i] != strs[j][i] {
				break
			}
		}
		if j == length {
			output.WriteByte(strs[0][i])
		} else {
			break
		}
	}
	return output.String()
}
```

TC = O(n*m)    
SC = O(m)

- pick the first string and check if the characters are same in all the string, if somewhere it is not true come out of the loop and return the string 
- if the length of first string is more and we are iterating over some string whose length is less than the itration then break and return the output string
  