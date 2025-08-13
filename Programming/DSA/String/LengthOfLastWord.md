# Problem 

Given a string s consisting of words and spaces, return the length of the last word in the string.

A word is a maximal substring consisting of non-space characters only.

 

Example 1:

Input: s = "Hello World"
Output: 5
Explanation: The last word is "World" with length 5.


# Solution 

```
func lengthOfLastWord(s string) int {
    length := len(s)

    count := 0

    for i:=length-1 ; i>=0; i-- {
        if s[i] != ' ' {
            count++
        }else if s[i] == ' ' && count != 0{
            return count
        }else {
            continue
        }
    }

    return count
}
```

TC = O(n)
SC = O(1)

- we will see if there is a space in the end of the array, if not we will count the words until a space comes 
- if the array has space in the end the we will move untill a character comes and then again start counting the words until the next space comes 