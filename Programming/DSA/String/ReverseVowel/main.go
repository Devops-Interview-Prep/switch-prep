package main

import (
	"fmt"
)


func reverseVowels(p string) string {
    
	n := len(p)
	s := []byte(p)

   left := 0
   right := n-1
   var temp byte 
   
   for right > left {
		 if s[left] == 'A' || s[left] == 'E' || s[left] == 'I' || s[left] == 'O' || s[left] == 'U' || s[left] == 'a' || s[left] == 'e' || s[left] == 'i' || s[left] == 'o' || s[left] == 'u'{
		  temp = s[left]

		  if s[right] == 'A' || s[right] == 'E' || s[right] == 'I' || s[right] == 'O' || s[right] == 'U' || s[right] == 'a' || s[right] == 'e' || s[right] == 'i' || s[right] == 'o' || s[right] == 'u'{
					 s[left] = s[right]
					 s[right] = temp
					 right--
					 left++
		      }else{
			        right--
					
		  }
		 }else{
		  left++
		 }
	  
   }
	   return string(s)
   }


   func main(){
	p := "IceCreAm"

	fmt.Println(reverseVowels(p))
   }