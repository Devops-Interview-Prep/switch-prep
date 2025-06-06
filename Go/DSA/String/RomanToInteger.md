# Problem 

Roman numerals are represented by seven different symbols: I, V, X, L, C, D and M.

Symbol       Value
I             1
V             5
X             10
L             50
C             100
D             500
M             1000
For example, 2 is written as II in Roman numeral, just two ones added together. 12 is written as XII, which is simply X + II. The number 27 is written as XXVII, which is XX + V + II.

Roman numerals are usually written largest to smallest from left to right. However, the numeral for four is not IIII. Instead, the number four is written as IV. Because the one is before the five we subtract it making four. The same principle applies to the number nine, which is written as IX. There are six instances where subtraction is used:

I can be placed before V (5) and X (10) to make 4 and 9. 
X can be placed before L (50) and C (100) to make 40 and 90. 
C can be placed before D (500) and M (1000) to make 400 and 900.
Given a roman numeral, convert it to an integer.

# Brut Force
```
func romanToInt(s string) int {
  n := len(s);
  x := 0 ;
  var i int ;
  for i=0 ; i<n ; i++ {
    if s[i] == 'V' {
        x = x+5;
        continue;
    }
    if s[i] == 'L' {
        x = x+50;
        continue;
    } 
    if s[i] == 'D' {
        x = x+500;
        continue;
    } 
    if s[i] == 'M' {
        x = x+1000;
        continue;
    } 

    if i < n-1 && s[i] == 'I' && s[i+1] == 'V' {
        x = x + 4 ;
        i = i+1 ;
        continue;
    } else if i < n-1 && s[i] == 'I' && s[i+1] != 'X'{
        x = x+1 ;
        continue;
    }else if i==n-1 && s[i] == 'I'{
        x = x+1 ;
        continue;
    }

    if i < n-1 && s[i] == 'I' && s[i+1] == 'X' {
        x = x + 9 ;
        i = i+1 ;
        continue;
    } else if s[i] == 'I'{
        x = x+1 ;
        continue;
    }

    if i < n-1 && s[i] == 'X' && s[i+1] == 'L' {
        x = x + 40 ;
        i = i+1  ;
        continue;
    } else if i < n-1 && s[i] == 'X' && s[i+1] != 'C'{
        x = x+10 ;
        continue;
    }else if i==n-1 && s[i] == 'X'{
        x = x+10 ;
        continue;
    }

    if i < n-1 && s[i] == 'X' && s[i+1] == 'C' {
        x = x + 90 ;
        i = i+1  ;
        continue;
    } else if s[i] == 'X'{
        x = x+10 ;
        continue;
    }


    if i < n-1 && s[i] == 'C' && s[i+1] == 'D'  {
        x = x + 400 ;
        i = i+1  ;
        continue;
    } else if i < n-1 && s[i] == 'C' && s[i+1] != 'M'{
        x = x+100 ;
        continue;
    }else if i==n-1 && s[i] == 'C'{
        x = x+100 ;
        continue;
    }

    if i < n-1 && s[i] == 'C' && s[i+1] == 'M' {
        x = x + 900 ;
        i = i+1  ;
        continue;
    } else if s[i] == 'C'{
        x = x+100 ;
        continue;
    }

  }
   return x;
}
```
TC = O(n)   
SC = O(1)

# Optimized Code using map

- logic : in the array of roman letters if the first letter's values is less then the 2nd the we will subtract the value of 1st letter else we will add 
ex in IX -> subtract 1 and add 10 -> 9


```
func romanToInt(s string) int {
  n := len(s);
 romanMap := map[byte]int{
    'I': 1,
    'V': 5,
    'X': 10,
    'L': 50,
    'C': 100,
    'D': 500,
    'M': 1000,
 }
    total := 0
 for i:=0 ; i<n; i++{
    if i<n-1 && romanMap[s[i]] < romanMap[s[i+1]]{
        total = total - romanMap[s[i]]
    }else{
        total = total + romanMap[s[i]]
    }
 }
    return total
}
```

- The romanMap contains only 7 fixed entries → constant space: O(1).

- Variables like total, n, and the loop index use constant space.

- We don’t use any space proportional to the input size (s) — we only read from it.



TC = O(n)
SC = O(1)


