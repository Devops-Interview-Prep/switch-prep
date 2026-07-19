# Versions of the Hypertext Transfer Protocol (HTTP). 

1. HTTP/1.0 (1996):

   - Simple request-response model.

   - Connection per request: Every request opens a new TCP connection and closes it after the response.
  
   - No keep-alive by default: Leads to high overhead and latency.

   - No host header: Can’t serve multiple domains from the same IP easily.

   - Performance issues due to connection overhead for each request.


2. HTTP/1.1 (1997, still widely used):

    - Persistent connections (keep-alive): Reuses a single TCP connection for multiple requests.

    - Pipelining: Allows sending multiple requests without waiting for responses (but rarely used due to head-of-line blocking).

    - Host header: Allows virtual hosting (multiple domains on one server/IP).

    - Chunked transfer encoding: Useful for dynamically generated content.

3. HTTP/2 (2015)

    - Binary protocol: Unlike HTTP/1.x which is text-based.

    - Multiplexing: Multiple requests/responses over a single connection without blocking.

    - Header compression (HPACK): Reduces overhead from headers.

    - Stream prioritization: Clients can signal which streams are more important.

    - Server Push: Servers can preemptively send assets (e.g., CSS, JS).

    - Faster page loads, especially for complex web pages.

    - Reduced latency and connection overhead.

    - Still uses TCP → vulnerable to head-of-line blocking at the transport layer (if one packet is lost, all streams wait).

4. HTTP/3 (QUIC + HTTP/2 semantics):
   
    - Underlying transport: QUIC (built over UDP)

    - Eliminates HOL blocking at the transport layer: Because QUIC multiplexes at the protocol level.

    - Faster connection setup: Uses 0-RTT or 1-RTT for TLS, unlike TCP which needs 3-way handshake + TLS handshake.

    - Built-in encryption: QUIC encrypts more metadata compared to HTTP/2 over TLS.

    - Connection migration: QUIC can keep connections alive even if IP changes (mobile use cases).
  
        **QUIC**   
        - QUIC stands for Quick UDP Internet Connections.
  
        - It’s a transport layer protocol (like TCP), developed originally by Google, now standardized by the IETF, and used under the hood by HTTP/3.

        - Instead of relying on TCP, QUIC uses UDP, and builds a lot of TCP-like (and better) features on top of it.

        **Head-of-line blocking (HOL blocking)** 

        - It is a performance problem in computer networks where one slow or delayed item blocks others behind it, even if those others could be processed independently.

        - If a packet or message is lost or delayed, others that are queued behind it must wait, even if they are unrelated.

        - This is particularly harmful for real-time applications like video, voice, and games.

---

## Protocol Comparison

| Protocol | Transport | Direction | Use case |
|----------|-----------|-----------|---------|
| HTTP/1.1 | TCP | Request/Response | Legacy REST APIs |
| HTTP/2 | TCP + TLS | Multiplexed | Modern REST, gRPC |
| HTTP/3 | QUIC (UDP) | Multiplexed | Low-latency, mobile |
| WebSocket | TCP + TLS | Bidirectional | Chat, live dashboards |
| gRPC | HTTP/2 + protobuf | Streaming options | Microservice RPC |

## REST Status Codes to Know

```
200 OK, 201 Created, 204 No Content
301 Moved Permanently, 302 Found
400 Bad Request, 401 Unauthorized, 403 Forbidden
404 Not Found, 409 Conflict, 429 Too Many Requests
500 Internal Server Error, 502 Bad Gateway, 503 Unavailable, 504 Timeout
```

## gRPC

```protobuf
syntax = "proto3";
service UserService {
    rpc GetUser (GetUserRequest) returns (UserResponse);          // unary
    rpc StreamUsers (StreamRequest) returns (stream UserResponse); // server streaming
    rpc Chat (stream Message) returns (stream Message);            // bidirectional
}
```

**gRPC vs REST:** Binary protobuf (smaller/faster) vs JSON, HTTP/2 multiplexing, strongly typed, streaming support. Downside: not human-readable, browser needs gRPC-Web proxy. Use gRPC internally between microservices; REST for public APIs.

## WebSocket

```javascript
const socket = new WebSocket('wss://api.example.com/ws')
socket.onopen = () => socket.send(JSON.stringify({ type: 'subscribe' }))
socket.onmessage = (event) => console.log(JSON.parse(event.data))
```

Upgrade handshake: HTTP GET with `Upgrade: websocket` → `101 Switching Protocols`. After that, full-duplex TCP channel. Use for: chat, gaming, live price feeds. Use SSE instead when server-only push is needed (simpler, HTTP, auto-reconnect).

## HTTP Caching Headers

```http
Cache-Control: max-age=3600          # cache for 1 hour
Cache-Control: no-store              # never cache (sensitive data)
Cache-Control: public                # CDN can cache
Cache-Control: private               # browser only (user-specific)
Cache-Control: s-maxage=86400        # CDN TTL (shared caches)
ETag: "abc123"                       # version for conditional requests
```

## Common Interview Questions

**Q: HTTP/2 multiplexing — what problem does it solve?**
In HTTP/1.1, each request-response pair must complete sequentially on a connection. Browsers open 6 parallel TCP connections to work around this. HTTP/2 sends multiple requests concurrently on a single connection using streams — no need for multiple connections, better resource utilization, lower latency.

**Q: gRPC vs REST — when to choose each?**
REST: public APIs, browser clients, human-readable JSON, simple request/response. gRPC: internal microservice RPC (binary is smaller/faster), streaming (real-time updates), strong typing across multiple languages. Typical pattern: gRPC between services internally, REST API Gateway for external clients.

**Q: WebSocket vs Server-Sent Events (SSE)?**
WebSocket: bidirectional — both client and server send messages. Use for: chat, gaming, collaborative editing. SSE: server pushes to client only, works over HTTP/1.1, auto-reconnects. Use for: dashboards, news feeds, price tickers where client doesn't need to push data back. SSE scales better behind load balancers (standard HTTP connections).

