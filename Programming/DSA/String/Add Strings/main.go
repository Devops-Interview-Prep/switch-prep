package main 

import("fmt")

func addStrings(num1 string, num2 string) string {
    n1 := len(num1)
    n2 := len(num2)
    i := n1-1
    j := n2-1
    carry := 0
    sum := 0
    sumS := []rune{}

    for i >= 0 && j >=0{
        sum = int(num1[i]-'0') + int(num2[j]-'0') + carry
        if sum > 10 {
            sum = sum - 10
            carry = 1
        }else if sum == 10{
            sum = 0
            carry = 1
        }else {
            carry = 0
        }
        i--
        j--
        sumS = append(sumS, rune(sum)+'0')
    } 




    for i<0 && j >= 0{
        sum = int(num2[j]-'0') + carry
        if sum == 10{
            sum = 0
            carry = 1
        }else {
            carry = 0
        }
        sumS = append(sumS, rune(sum)+'0')
        j--
    }




    for j<0 && i >= 0{
        sum = int(num1[i]-'0') + carry
		
        if sum == 10{
            sum = 0
            carry = 1
        }else {
            carry = 0
        }
        sumS = append(sumS, rune(sum)+'0')
		
        i--
    }


    if carry == 1{
        sumS = append(sumS, rune(carry)+'0')
    }

    m := len(sumS)
    var temp rune
    for k:=0 ; k < m/2 ; k++{
        temp = sumS[k]
        sumS[k] = sumS[m-1-k]
        sumS[m-1-k] = temp
    }

    return string(sumS)
}


func main() {
    num1 := "9133"
	num2 := "0"

	fmt.Println(addStrings(num1, num2))
}