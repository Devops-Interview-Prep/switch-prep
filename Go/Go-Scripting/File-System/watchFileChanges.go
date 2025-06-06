package main

import (
	"fmt"
	"log"

	"github.com/fsnotify/fsnotify"
)

func main() {
	watcher, err := fsnotify.NewWatcher()
	if err != nil {
		log.Fatal(err)
	}
	defer watcher.Close()

	err = watcher.Add("file.txt")
	if err != nil {
		log.Fatal(err)
	}

	for event := range watcher.Events {
		fmt.Println("File changed:", event)
	}
}
