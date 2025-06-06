package main

import (
	"fmt"
	"os"
	"log"
)

func main() {
	data, err := os.ReadFile("file.txt") // Read the entire file into memory
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(string(data)) // Print file contents
}


/* 

log.Fatal(err)
Behavior:

Logs the error message to standard error (stderr).
Calls os.Exit(1), which terminates the program immediately.
Does not run deferred functions.
Usage:

When you encounter a critical error and want to exit the program immediately.
Typically used in main() or initialization functions (e.g., failing to start a server or load configuration). 


 - file, err :=

This is short variable declaration (:=), which declares and initializes two variables:
file: A pointer to an os.File object (if the file is successfully opened).
err: An error value (if something goes wrong).
The := operator is used for declaring new variables and automatically infers their types.

*/

