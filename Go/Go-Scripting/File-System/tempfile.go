package main

import(
	"os"
	"fmt"
)


func main(){
	tempFile, err := os.CreateTemp("./","tempfile-*.txt")
	if err != nil {
		panic(err)
	}

	defer os.Remove(tempFile.Name())

	fmt.Println("Tempfile created:", tempFile.Name())
}


/*
First argument (dir): Specifies the directory where the temporary file should be created.

If "" (empty string) is passed, the default system temp directory is used (e.g., /tmp on Linux/macOS, C:\Users\...\AppData\Local\Temp on Windows).
You can also provide a custom directory path.
Second argument (pattern): Specifies the filename pattern for the temporary file.

The pattern should contain a wildcard *, which Go replaces with a unique random string to ensure the filename is unique.
Example: "example-*.txt" might create a file like example-abc123.txt.

*/