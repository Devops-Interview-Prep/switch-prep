# Service Level Objectives (SLOs)

- An SLO is a target value or range for an SLI. It's a clearly defined goal for how well your service should perform. 
- SLOs are commitments you make to your users (internal or external) about the expected level of service.

- **DevOps Engineer Perspective:**

  - Examples (building on SLIs):

    - Latency SLO: "99% of API requests will have a latency of less than 200ms over a 28-day rolling window."

    - Availability SLO: "The service will be available 99.9% of the time over a 30-day period." (This is often referred to as "three nines availability").

    - Error Rate SLO: "The error rate for critical user journeys will not exceed 0.1% over a 7-day period."

  - Your Role:

    - Collaboration:      
        You'll likely work with product owners, SREs (if it's a separate team), and other stakeholders to define meaningful SLOs. These shouldn't be arbitrary numbers; they should reflect what users reasonably expect and what the business needs.

    - Implementation:       
        You'll configure your monitoring systems to alert when SLIs are trending towards violating an SLO or when an SLO has been breached.

    - Dashboards and Reporting: 
        You'll build dashboards that clearly show the current status of SLOs and how your service is performing against them. This helps in communicating system health to everyone.

    - Impact on Development: 
        SLOs drive engineering decisions. If an SLO is consistently missed, it signals that engineering effort needs to be focused on improving that aspect of the service (e.g., performance tuning, architectural changes, better testing).

- Key takeaway: SLOs are the how well you want to perform. They provide a clear, measurable target.