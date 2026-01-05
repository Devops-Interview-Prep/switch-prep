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
