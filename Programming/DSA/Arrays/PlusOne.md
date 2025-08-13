# Problem 
You are given a large integer represented as an integer array digits, where each digits[i] is the ith digit of the integer. The digits are ordered from most significant to least significant in left-to-right order. The large integer does not contain any leading 0's.

Increment the large integer by one and return the resulting array of digits.

```
func plusOne(digits []int) []int {
    length := len(digits)

    for i:=length-1 ; i>=0 ; i-- {
        if digits[i] == 9{
            digits[i] = 0
            if i==0 {
                digits[i] = 1
                digits = append(digits, 0)
            }
        }else{
            digits[i] = digits[i]+1
            break
        }
    }
     return digits
}
```

TC = O(n)   
SC = O(1)


- we will traverse the array from last, if anywhere we see 9 just make it 0, and the element which is not 9, increase it by 1.
- if all the elements are 9 the make the first element as 1 and append one 0 in the array 
  