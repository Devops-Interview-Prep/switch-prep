/*
Given a pattern and a string s, find if s follows the same pattern.

Here follow means a full match, such that there is a bijection between a letter in pattern and a non-empty word in s. Specifically:

Each letter in pattern maps to exactly one unique word in s.
Each unique word in s maps to exactly one letter in pattern.
No two letters map to the same word, and no two words map to the same letter.
 

Example 1:

Input: pattern = "abba", s = "dog cat cat dog"

Output: true

Explanation:

The bijection can be established as:

'a' maps to "dog".
'b' maps to "cat".
*/

package main

import (
	"strings"
)

func wordPattern(pattern string, s string) bool {
    a := strings.Split(s," ")
    n := len(a)
    if len(pattern) != len(a){
        return false 
    }
      mapPS := make(map[byte]string)
      mapSP := make(map[string]byte)


      for i:=0 ;i < n; i++{
        
        val1, ok1 := mapPS[pattern[i]]
        val2, ok2 := mapSP[a[i]]

        if ok1 && a[i] != val1{
            return false 
        }else{
            mapPS[pattern[i]] = a[i]
        }

        if ok2 && pattern[i] != val2{
            return false 
        }else{
            mapSP[a[i]] = pattern[i]
        }    
      }

      return true

}

func main(){

}