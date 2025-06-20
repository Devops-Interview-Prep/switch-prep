package main

import (
	"os"
)

func main() {
	file, err := os.OpenFile("file.txt", os.O_APPEND | os.O_WRONLY, 0644)
	if err != nil {
		panic(err)
	}

	defer file.Close()

	_, err = file.WriteString("\nThis is appended line3")
	if err != nil {
		panic(err)
	}

}