# Problem 

Given a string s containing just the characters '(', ')', '{', '}', '[' and ']', determine if the input string is valid.

An input string is valid if:

Open brackets must be closed by the same type of brackets.
Open brackets must be closed in the correct order.
Every close bracket has a corresponding open bracket of the same type.


# Solution 

```
func isValid(s string) bool {
	n := len(s)
	stack := []byte{} # or use []rune

	for i := 0; i < n; i++ {
		if (s[i] == ')' || s[i] == '}' || s[i] == ']') && len(stack) == 0 {
			return false
		} else if s[i] == '(' || s[i] == '{' || s[i] == '[' {
			stack = append(stack, s[i])
		} else if s[i] == ')' && len(stack) != 0 && stack[len(stack)-1] == '(' {
			stack = stack[:len(stack)-1]
		} else if s[i] == '}' && len(stack) != 0 && stack[len(stack)-1] == '{' {
			stack = stack[:len(stack)-1]
		} else if s[i] == ']' && len(stack) != 0 && stack[len(stack)-1] == '[' {
			stack = stack[:len(stack)-1]
		} else {
			return false
		}
	}

	if len(stack) == 0 {
		return true
	} else {
		return false
	}

}
```

TC = O(n)    
SC = O(n)