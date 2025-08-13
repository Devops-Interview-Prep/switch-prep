/*
Given two strings ransomNote and magazine, return true if ransomNote can be constructed by using the letters from magazine and false otherwise.

Each letter in magazine can only be used once in ransomNote.

 

Example 1:

Input: ransomNote = "a", magazine = "b"
Output: false
Example 2:

Input: ransomNote = "aa", magazine = "ab"
Output: false
Example 3:

Input: ransomNote = "aa", magazine = "aab"
Output: true
*/
package main

func canConstruct(ransomNote string, magazine string) bool {
	if len(magazine) < len(ransomNote){
		return false
	}

	charCount := make(map[rune]int)

	for _,ch := range ransomNote{
		charCount[ch]++
	}

	for _,ch := range magazine{
		_,ok := charCount[ch]
		if ok{
		charCount[ch]--
		}
	}

	for _,value := range charCount{
		if value > 0 {
			return false
		}
	}

	return true
}