```
my-go-app/
├── go.mod
├── go.sum
├── main.go
└── Dockerfile
```

🔸 Files in Go Modules
1. go.mod
    - Defines:
        - Your module name (usually your repo path)
        - Required dependencies + versions
        - Go version

```
module github.com/yourusername/myapp

go 1.21

require (
    github.com/gin-gonic/gin v1.9.1
    github.com/lib/pq v1.10.9
)
```

2. go.sum
    - Stores the cryptographic hash of every version of every dependency.
    - Ensures you always get the same dependency with go mod download

`RUN CGO_ENABLED=0 GOARCH=amd64 GOOS=linux go build -a -installsuffix cgo -o main .`

- CGO_ENABLED=0: Disables CGO (C bindings) for a fully static binary
- GOARCH=amd64: Target architecture is x86_64
- GOOS=linux: Target OS is Linux
- -a: Force rebuilding of packages
- -installsuffix cgo: Tags binary with non-cgo suffix
- -o main: Outputs the binary as main