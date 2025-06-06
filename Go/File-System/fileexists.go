package main

import (
	"os"
	"fmt"
)

func fileExists(filename string) bool{
	_, err := os.Stat(filename)
	return !os.IsNotExist(err)
}
func main(){
    if fileExists("file.txt"){
		fmt.Println("file exists")
	}else {
		fmt.Println("file does not exist")
	}

}

/* 
- os.Stat(filename), which retrieves information about the file.
If the file exists, os.Stat returns its metadata (FileInfo).
If the file does not exist, os.Stat returns an error.

- The function checks if the error from os.Stat indicates that the file does not exist using os.IsNotExist(err).
If the error is os.IsNotExist(err), it means the file is missing, and the function returns false.
Otherwise, it returns true.

*/
