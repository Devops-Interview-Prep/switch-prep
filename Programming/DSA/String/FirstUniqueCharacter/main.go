/*
Given a string s, find the first non-repeating character in it and return its index. If it does not exist, return -1.

 

Example 1:

Input: s = "leetcode"

Output: 0

Explanation:

The character 'l' at index 0 is the first character that does not occur at any other index.
*/

package main

import("fmt")

// func firstUniqChar(s string) int {
// 	charMap := make(map[byte]int)

// 	for i:=0 ; i< len(s) ; i++ {
// 		_,ok := charMap[s[i]]
// 		if ok {
// 			charMap[s[i]] = -1
// 		}else{
// 			charMap[s[i]] = i
// 		}
// 	}
//      fmt.Println(charMap)

// 	for j:=0;j<len(s);j++{
// 		if charMap[s[j]] != -1{
// 			return j
// 		}
// 	}
// 	return -1
// }

func firstUniqChar(s string) int {
    pos := [26]int{}

    // Fill frequency/counts (+1 to differentiate from default 0)
    for i := 0; i < len(s); i++ {
        pos[s[i]-'a']++
    }

    // Find first character with count == 1
    for i := 0; i < len(s); i++ {
        if pos[s[i]-'a'] == 1 {
            return i
        }
    }

    return -1
}

func main(){
	s := "leetcode"

	fmt.Println(firstUniqChar(s))
}