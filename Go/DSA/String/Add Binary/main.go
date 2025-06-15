package main

import (
	"fmt"
)



func addBinary(a string, b string) string {

	n := len(a)
	m := len(b)

	result := []byte{}

	 carry := 0
	 i     := 0
	 j     := 0
     sum   := 0

	for i < n || j < m {
	   if i<n && j<m{

	   sum = int(a[n-1-i] + b[m-1-j] - 2 * '0')+ carry

	   }else if i>=n{

		 sum = int(b[m-1-j] - '0') + carry

	   }else{

		sum = int(a[n-1-i] - '0') + carry

	   }


	   result = append(result,byte(sum%2)+'0')
	   carry = sum/2
	   i++
	   j++
	}
	    
	if carry != 0{
		result = append(result, byte(carry)+'0')
        }
		


		for k:=0 ; k < len(result)/2 ;k++{
		   temp := result[k]
		   result[k] = result[len(result)-1-k]
		   result[len(result)-1-k] = temp
		}
	   
	    return string(result)

}

func main() {

	a := "11"
	b := "1"
	fmt.Println(addBinary(a,b))

}