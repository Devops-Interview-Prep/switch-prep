# Service Level Indicators (SLIs)

- An SLI is a quantifiable measure of some aspect of the service you provide. Think of it as a raw metric that tells you how your system is performing.

- **DevOps Engineer Perspective:**

  - Examples:

    - Latency: The time it takes for a request to be served (e.g., "99% of API requests complete in under 200ms").

    - Throughput/QPS (Queries Per Second): The number of requests a system can handle per unit of time.

    - Error Rate: The percentage of requests that result in an error (e.g., HTTP 5xx responses).

    - Availability: The percentage of time a service is operational and accessible.

    - Durability: For storage systems, the likelihood that data will be preserved (e.g., "99.999% of objects stored will be available over a year").

  - Your Role: You'll be instrumental in instrumenting your applications and infrastructure to collect these metrics.
  - This means setting up monitoring tools (Prometheus, Grafana, Datadog, ELK stack, etc.), configuring logs, and ensuring that the data you're collecting is accurate and representative of the user experience.

- Key takeaway: SLIs are the what you measure. They should directly relate to user experience or business objectives.