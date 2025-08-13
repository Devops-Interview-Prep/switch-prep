package main

import (
	"fmt"
	"os"
)

func main() {
    err := os.WriteFile("file1.txt", []byte("this is file 1 \nthis is created by write function."), 0644)
	if err != nil {
		fmt.Print(err)
		return
	}
}

/*
panic(err)
Behavior:

Prints the error message along with a stack trace.
Executes any deferred functions before terminating the program.
Can be recovered using recover() inside a defer function.
Usage:

When something unexpected happens that should cause the program to stop, but you might want to recover from it.
Often used in library code where an error is unrecoverable by the caller.
Typically avoided in production services unless for truly exceptional cases.

In Go, string data must be converted to a byte slice ([]byte) before being written to a file 
because file operations work with raw bytes.
Go's os.WriteFile() function expects the data as a []byte, not a string.

*/
