package main

import (
	"os"
)

func main() {
	err := os.Remove("newfile.txt")
	if err != nil {
		panic(err)
	}
}

// Use os.RemoveAll for directories and nested files.