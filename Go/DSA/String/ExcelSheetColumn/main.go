package main

import (
	"fmt"
	"strings"
)

func convertToTitle(columnNumber int) string {
 
	 var reverseResult strings.Builder
	 var divident,remainder int
	  
	  divident = columnNumber
 
	  for divident>0 {
		   remainder = divident % 26
		   //fmt.Println(remainder)
	
		   reverseResult.WriteRune(rune('A' + remainder))
		   divident = divident / 26
		   fmt.Println(divident)
	  }

        var result strings.Builder
     length := len(reverseResult.String())

	 for j:=0 ; j<length; j++{
		result.WriteByte(reverseResult.String()[length-1-j])
	 }

		 return result.String()
 }

 func main(){
	columnNumber := 52

	fmt.Print(convertToTitle(columnNumber))
 }