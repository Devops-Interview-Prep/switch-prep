/*
Given a string columnTitle that represents the column title as appears in an Excel sheet,
return its corresponding column number.

For example:

A -> 1
B -> 2
C -> 3
...
Z -> 26
AA -> 27
AB -> 28 

*/


package main

import (
	"fmt"
	"math"
    )



func titleToNumber(columnTitle string) int {
    mapChar := make(map[byte]int)
    alphabets := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    idx := 1
    for _,ch := range alphabets{
        mapChar[byte(ch)] = idx
         idx++
    }

      n := len(columnTitle)
	
      columnNumber := 0

      for i:=n-1; i>=0 ; i--{
           columnNumber = columnNumber + mapChar[columnTitle[i]] * int(math.Pow(26,float64(n-1-i)))
      }

           return columnNumber
}


func main(){
	columnTitle := "AB"
	fmt.Println(titleToNumber(columnTitle))
}