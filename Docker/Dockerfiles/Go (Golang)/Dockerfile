# Build stage
FROM golang:1.21 AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download       # prefetches your dependencies early in the Dockerfile for speed and caching

COPY . .

# This command compiles your Go source code (in the current directory .) 
# and produces an executable binary named main.

RUN go build -o main .


# Runtime stage
FROM alpine:latest

WORKDIR /app

COPY --from=builder /app/main .

EXPOSE 8080

CMD ["./main"]
