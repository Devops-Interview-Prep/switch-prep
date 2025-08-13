package main

import (
	"fmt"
)

func getRow(rowIndex int) [][]int {
    triangleMap := make(map[int][]int)

    triangleMap[0] = []int{1}
    triangleMap[1] = []int{1,1}

	var val []int

    for i:=2 ; i<=rowIndex ; i++ {
		val = append(val,1)

		for j:=1; j<i;j++{
            val = append(val,triangleMap[i-1][j-1] + triangleMap[i-1][j])
		}
		val = append(val,1)
		triangleMap[i] = val
		val = []int{}
    }    

	var result [][]int
	for i := 0 ; i <= rowIndex; i++{
		result = append(result, triangleMap[i])
	}

    return result
}

func main(){
	
	rowIndex := 10
     fmt.Print(getRow(rowIndex))
}