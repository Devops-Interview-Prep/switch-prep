package main

import(
	"fmt"
	"strings"
)

func isPalindrome(s string) bool {
    s = strings.ToLower(s)
    
    alphanumeric := []byte{}
    reverseAlphanumeric := []byte{}

    for _,ch := range s{
        if (ch >= '0' && ch <= '9') || (ch >= 'a' && ch <= 'z'){
          alphanumeric = append(alphanumeric, byte(ch))  
        }
    }

    n := len(alphanumeric)

    for j:=0 ;j<n; j++{
        reverseAlphanumeric = append(reverseAlphanumeric, alphanumeric[n-1-j])
    }


    if string(alphanumeric) == string(reverseAlphanumeric) {
        return true 
    }

    return false
}

func main(){
	s := "A man, a plan, a canal: Panama"

	fmt.Println(isPalindrome(s))
}