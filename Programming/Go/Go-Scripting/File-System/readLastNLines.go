package main

import (
	"bufio"
	"fmt"
	"os"
)

func readNLines(filepath string, n int) ([]string, error) {

	file, err := os.Open(filepath)
	if err != nil {
		fmt.Println(err)
		return nil, err
	}

	defer file.Close()

    scanner := bufio.NewScanner(file)

	var allLines []string

   for scanner.Scan(){
	allLines = append(allLines, scanner.Text())
   }

   if err := scanner.Err(); err != nil {
	return nil, err
}

totalLines := len(allLines)

   return allLines[totalLines-n:], err
}


func main(){

	var n int
	fmt.Print("Enter a number: ")
	fmt.Scan(&n)
	var filepath string
	fmt.Print("Enter fileName: ")
	fmt.Scan(&filepath)


	lines, err := readNLines(filepath, n)
	if err != nil{
		fmt.Println(err)
		return
	}

	for _,line := range lines{
		fmt.Println(line)
	}

}