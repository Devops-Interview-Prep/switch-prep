package main

import (
	"os"
)

func main(){
	err := os.Chmod("file.txt", 0644)
	if err != nil{
		panic(err)
	}
}