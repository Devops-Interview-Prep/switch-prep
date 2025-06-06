# Problem 

Given two strings needle and haystack, return the index of the first occurrence of needle in haystack, or -1 if needle is not part of haystack.

 

Example 1:

Input: haystack = "sadbutsad", needle = "sad"
Output: 0
Explanation: "sad" occurs at index 0 and 6.
The first occurrence is at index 0, so we return 0.


# Solution 

```
func strStr(haystack string, needle string) int {
	n := len(haystack)
	m := len(needle)
	if m > n || m == 0 {
		return -1
	}

	for i := 0; i <= n-m; i++ {
		if haystack[i] == needle[0] {
			for j := 0; j < m; j++ {
				if haystack[i+j] != needle[j] {
					break
				} else if j == m-1 {
					return i
				} else {
					continue
				}
			}
		}
	}

	return -1
}
```

TC = O(n*m)    
SC = O(1)

- will check for the first element of needle in haystack, as soon as we find the first element we will check further if the it completes the needle string or not 
- if anywhere we find that its not the same we will break and run the loop again and see 