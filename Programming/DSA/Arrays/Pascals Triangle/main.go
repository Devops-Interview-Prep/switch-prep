/*
Given an integer numRows, return the first numRows of Pascal's triangle.

In Pascal's triangle, each number is the sum of the two numbers directly above it as shown:

Example 1:

Input: numRows = 5
Output: [[1],[1,1],[1,2,1],[1,3,3,1],[1,4,6,4,1]]
Example 2:

Input: numRows = 1
Output: [[1]]
*/

package main

func generate(rowIndex int) [][]int {
	triangleMap := make(map[int][]int)

   triangleMap[0] = []int{1}
   triangleMap[1] = []int{1,1}

   var val []int

   for i:=2 ; i<rowIndex ; i++ {
	   val = append(val,1)

	   for j:=1; j<i;j++{
		   val = append(val,triangleMap[i-1][j-1] + triangleMap[i-1][j])
	   }
	   val = append(val,1)
	   triangleMap[i] = val
	   val = []int{}
   }    

   var result [][]int
   for i := 0 ; i < rowIndex; i++{
	   result = append(result, triangleMap[i])
   }

   return result
}