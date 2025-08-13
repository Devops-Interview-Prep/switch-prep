/*
You are given a sorted unique integer array nums.

A range [a,b] is the set of all integers from a to b (inclusive).

Return the smallest sorted list of ranges that cover all the numbers in the array exactly. That is, each element of nums is covered by exactly one of the ranges, and there is no integer x such that x is in one of the ranges but not in nums.

Each range [a,b] in the list should be output as:

"a->b" if a != b
"a" if a == b
 

Example 1:

Input: nums = [0,1,2,4,5,7]
Output: ["0->2","4->5","7"]
Explanation: The ranges are:
[0,2] --> "0->2"
[4,5] --> "4->5"
[7,7] --> "7"
*/




package main
import("fmt")

func summaryRanges(nums []int) []string {
    output := []string{}
    n := len(nums)
    if n==0{
        return output
    }else if n==1{
        formatNums := fmt.Sprintf("%d",nums[0])
        output = append(output,formatNums)
        return output
    }


    minIdx := 0
    maxIdx := 0

    for i:=0;i<n-1;i++{
        minIdx = i
        maxIdx = i
        for j:=i ; j<n-1;j++{
            if nums[j] + 1 == nums[j+1]{
            maxIdx = j + 1
        }else{
            break
        }
        }

        if minIdx == maxIdx {
            arrow := fmt.Sprintf("%d",nums[minIdx])
            output = append(output,arrow) 
        }else{
            arrow := fmt.Sprintf("%d->%d", nums[minIdx], nums[maxIdx]) 
            output = append(output,arrow)
        }

        i = maxIdx
    }
    if maxIdx != n-1{
        arrow := fmt.Sprintf("%d",nums[n-1])
        output = append(output,arrow)
    }
        return output
}