/*
Given two strings s and t, determine if they are isomorphic.

Two strings s and t are isomorphic if the characters in s can be replaced to get t.

All occurrences of a character must be replaced with another character while preserving the order of characters. No two characters may map to the same character, but a character may map to itself.

 

Example 1:

Input: s = "egg", t = "add"

Output: true

Explanation:

The strings s and t can be made identical by:

Mapping 'e' to 'a'.
Mapping 'g' to 'd'.
*/

package main

func isIsomorphic(s string, t string) bool {
    if len(s) != len(t){
        return false
    }

    mapST := make(map[byte]byte)
    mapTS := make(map[byte]byte)

for i := 0; i < len(s); i++ {
    c1, ok1 := mapST[s[i]]
    c2, ok2 := mapTS[t[i]]

    if ok1 {
        if c1 != t[i] {
            return false
        }
    } else {
        mapST[s[i]] = t[i]
    }

    if ok2 {
        if c2 != s[i] {
            return false
        }
    } else {
        mapTS[t[i]] = s[i]
    }
}

        return true

}