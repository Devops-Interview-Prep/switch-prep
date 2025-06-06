package main

import (
	"io"
	"os"
)

func copyFile(src, dst string) error{
      srcFile, err := os.Open(src)
	  if err != nil{
          return err
	  }
	  defer srcFile.Close()

	  destFile, err := os.Create(dst)
	  if err != nil {
		return err
	  }

	  defer destFile.Close()

	  _, err = io.Copy(destFile, srcFile)
		return err
	
}

func main(){
	err := copyFile("file.txt", "newfile.txt")
	if err != nil {
		panic(err)
	  }
}