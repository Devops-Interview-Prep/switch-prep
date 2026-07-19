# Go File System Operations

> Practical Go patterns for file I/O, used heavily in DevOps tooling, log processors, and CLI utilities.

## Read File

```go
// readfile.go — read entire file into memory
package main

import (
    "fmt"
    "os"
)

func main() {
    content, err := os.ReadFile("file.txt")
    if err != nil {
        fmt.Println("Error:", err)
        os.Exit(1)
    }
    fmt.Println(string(content))
}
```

## Read File Line by Line (Large Files)

```go
// readfilelinebyline.go — memory efficient
package main

import (
    "bufio"
    "fmt"
    "os"
)

func main() {
    file, err := os.Open("file.txt")
    if err != nil {
        fmt.Println("Error:", err)
        os.Exit(1)
    }
    defer file.Close()  // always close when done

    scanner := bufio.NewScanner(file)
    lineNum := 0
    for scanner.Scan() {
        lineNum++
        fmt.Printf("%d: %s\n", lineNum, scanner.Text())
    }

    if err := scanner.Err(); err != nil {
        fmt.Println("Scanner error:", err)
    }
}
```

## Write File

```go
// writefile.go
package main

import (
    "fmt"
    "os"
)

func main() {
    content := []byte("Hello, Go!\nLine 2\n")

    // Write (creates or overwrites)
    err := os.WriteFile("output.txt", content, 0644)
    if err != nil {
        fmt.Println("Error:", err)
    }
}
```

## Append to File

```go
// append.go
package main

import (
    "fmt"
    "os"
)

func main() {
    file, err := os.OpenFile("log.txt", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
    if err != nil {
        fmt.Println("Error:", err)
        os.Exit(1)
    }
    defer file.Close()

    _, err = fmt.Fprintln(file, "New log entry")
    if err != nil {
        fmt.Println("Write error:", err)
    }
}
```

## File Exists Check

```go
// fileexists.go
package main

import (
    "errors"
    "fmt"
    "os"
)

func fileExists(path string) bool {
    _, err := os.Stat(path)
    return !errors.Is(err, os.ErrNotExist)
}

func main() {
    if fileExists("config.json") {
        fmt.Println("Config file found")
    } else {
        fmt.Println("Config file missing — using defaults")
    }
}
```

## Copy File

```go
// copyFile.go
package main

import (
    "fmt"
    "io"
    "os"
)

func copyFile(src, dst string) error {
    source, err := os.Open(src)
    if err != nil {
        return fmt.Errorf("open source: %w", err)
    }
    defer source.Close()

    dest, err := os.Create(dst)
    if err != nil {
        return fmt.Errorf("create dest: %w", err)
    }
    defer dest.Close()

    _, err = io.Copy(dest, source)
    return err
}

func main() {
    if err := copyFile("original.txt", "backup.txt"); err != nil {
        fmt.Println("Copy failed:", err)
        os.Exit(1)
    }
    fmt.Println("Copied successfully")
}
```

## Change File Permissions

```go
// changeFilePermission.go
package main

import (
    "fmt"
    "os"
)

func main() {
    // Make file executable
    err := os.Chmod("script.sh", 0755)  // rwxr-xr-x
    if err != nil {
        fmt.Println("Error:", err)
    }

    // Make file read-only
    err = os.Chmod("config.json", 0444)  // r--r--r--
    if err != nil {
        fmt.Println("Error:", err)
    }
}
```

## Watch File Changes

```go
// watchFileChanges.go — using fsnotify
// go get github.com/fsnotify/fsnotify
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

    go func() {
        for {
            select {
            case event, ok := <-watcher.Events:
                if !ok {
                    return
                }
                if event.Has(fsnotify.Write) {
                    fmt.Println("File modified:", event.Name)
                }
                if event.Has(fsnotify.Create) {
                    fmt.Println("File created:", event.Name)
                }
            case err, ok := <-watcher.Errors:
                if !ok {
                    return
                }
                log.Println("Watcher error:", err)
            }
        }
    }()

    err = watcher.Add("/var/log/app/")
    if err != nil {
        log.Fatal(err)
    }

    // Block forever
    <-make(chan struct{})
}
```

## Read Last N Lines (Like `tail`)

```go
// readLastNLines.go — efficient tail implementation
package main

import (
    "bufio"
    "fmt"
    "os"
)

func readLastNLines(filename string, n int) ([]string, error) {
    file, err := os.Open(filename)
    if err != nil {
        return nil, err
    }
    defer file.Close()

    // Circular buffer — keep last N lines
    lines := make([]string, 0, n)
    scanner := bufio.NewScanner(file)

    for scanner.Scan() {
        if len(lines) >= n {
            lines = lines[1:]  // remove oldest
        }
        lines = append(lines, scanner.Text())
    }
    return lines, scanner.Err()
}

func main() {
    lines, err := readLastNLines("app.log", 10)
    if err != nil {
        fmt.Println("Error:", err)
        os.Exit(1)
    }
    for _, line := range lines {
        fmt.Println(line)
    }
}
```

## Temp File (Atomic Write Pattern)

```go
// tempfile.go — atomic write
package main

import (
    "fmt"
    "os"
)

func atomicWriteFile(filename string, data []byte) error {
    // Create temp file in same dir (same filesystem for atomic rename)
    dir := "."
    tmpFile, err := os.CreateTemp(dir, "tmp-")
    if err != nil {
        return fmt.Errorf("create temp: %w", err)
    }
    tmpName := tmpFile.Name()

    _, err = tmpFile.Write(data)
    tmpFile.Close()
    if err != nil {
        os.Remove(tmpName)
        return fmt.Errorf("write temp: %w", err)
    }

    // Atomic rename — readers see either old or new file, never partial
    return os.Rename(tmpName, filename)
}

func main() {
    data := []byte(`{"version": "1.2.3", "updated": "2026-06-17"}`)
    if err := atomicWriteFile("config.json", data); err != nil {
        fmt.Println("Error:", err)
    }
}
```

## Common Interview Questions

**Q: Why use `defer file.Close()` immediately after opening?**
It's a Go idiom: place `defer` immediately after the `os.Open` success check so you never forget to close the file, regardless of how the function exits (early return, panic, normal return). Without `defer`, every return path would need `file.Close()`. Resources like files, DB connections, and HTTP responses should always be deferred.

**Q: `os.ReadFile` vs `bufio.Scanner` — when to use each?**
`os.ReadFile`: reads the entire file into memory — fine for small config files/scripts. Use for files < a few MB. `bufio.Scanner`: reads line by line, constant memory usage regardless of file size — use for large logs, CSV files, or any file that could be large. Streaming is the default choice for production log processors.

**Q: How do you do an atomic file write in Go?**
Write to a temp file (`os.CreateTemp`) on the same filesystem as the target, then `os.Rename` to the final path. `rename(2)` is atomic at the OS level — consumers see either the old or new file, never a half-written state. This is critical for config files or any file that another process might be reading concurrently.
