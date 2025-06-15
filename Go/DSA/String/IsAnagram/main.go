package main 

import (
	"fmt"
)

func isAnagram(s string, t string) bool {
    if len(s) != len(t) {
        return false
    }

    charCount := make(map[rune]int)

    for _, ch := range s {
        charCount[ch]++
    }

    for _, ch := range t {
        charCount[ch]--
        if charCount[ch] < 0 {
            return false
        }
    }

    for _, count := range charCount {
        if count != 0 {
            return false
        }
    }

    return true
}



func main(){
	s := "anagram"
	t := "nagaram"

	fmt.Println(isAnagram(s,t))
}