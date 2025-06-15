package main

import (
	"os"
	"bufio"
	"fmt"
)


func main(){
file, err := os.Open("file.txt")
 if err != nil {
	fmt.Println(err)
	return
 }

scanner := bufio.NewScanner(file)

for scanner.Scan(){
fmt.Println(scanner.Text())
}

err = scanner.Err()

if err != nil {
	fmt.Println(err)
	return
}


}