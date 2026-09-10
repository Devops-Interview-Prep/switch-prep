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

---

## SLO Examples by Service Type

| Service | SLI | SLO Target |
|---------|-----|-----------|
| REST API | % successful requests | 99.9% over 28 days |
| REST API | p99 latency | < 300ms over 28 days |
| Payment API | % successful payments | 99.95% over 28 days |
| Database | Availability | 99.99% over 28 days |
| Batch job | Completion rate | 99.5% over 7 days |
| CDN | Cache hit ratio | ≥ 90% over 7 days |

## SLO Window Types

| Window Type | Description | Pros | Cons |
|-------------|-------------|------|------|
| **Rolling** (28-day) | Always the last 28 days | Realistic current state | "Reset" each day |
| **Calendar** (monthly) | Hard month boundary | Simple to explain | Hard reset at month end can hide issues |
| **Multi-window** | Both short (1hr) and long (30d) | Catches spikes AND trends | More complex alerts |

**Recommendation:** Use rolling windows for operational SLOs. Calendar windows for exec reporting.

## SLO Alerting — Multi-Burn-Rate

Don't alert when the SLO is breached — alert when you're burning error budget too fast:

```yaml
# Prometheus alerting rules — multi-window burn rate
groups:
  - name: slo_alerts
    rules:
      # Page: Fast burn — consuming 5% of error budget in 1 hour
      - alert: SLOErrorBudgetFastBurn
        expr: |
          (
            sli:request_availability:ratio_rate1h < (1 - 14.4 * 0.001)  # 1.44% errors/hour
          ) and (
            sli:request_availability:ratio_rate5m < (1 - 14.4 * 0.001)
          )
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Fast burn: will exhaust error budget in 1 hour"

      # Ticket: Slow burn — will exhaust budget in 3 days
      - alert: SLOErrorBudgetSlowBurn
        expr: |
          sli:request_availability:ratio_rate6h < (1 - 6 * 0.001)
        for: 15m
        labels:
          severity: warning
        annotations:
          summary: "Slow burn: error budget depleting, review needed"
```

**Burn rate concept:**
- 1x burn rate = you use 100% of budget exactly at window end
- 14.4x burn rate = you exhaust the monthly budget in 1 hour
- Alert when short-window AND long-window both show high burn rate (reduces false positives)

## SLO vs SLA vs SLI

```
SLI → what you measure (99.2% availability this week)
SLO → internal target   (99.9% availability over 28 days)
SLA → external contract (99.5% availability — refund if breached)
```

**Always set SLOs tighter than SLAs.** If your SLA is 99.5%, your SLO should be 99.9% — so you catch problems before they become SLA violations.

## Error Budget Calculation

```python
# Error budget = total acceptable downtime/errors in a window
# Formula: error_budget_seconds = window_seconds * (1 - SLO_target)

window_days = 28
slo_target = 0.999    # 99.9%

window_seconds = window_days * 24 * 3600          # 2,419,200 seconds
error_budget_seconds = window_seconds * (1 - slo_target)
# 99.9% SLO over 28 days = 2419 seconds ≈ 40 minutes of allowed downtime

print(f"Error budget: {error_budget_seconds:.0f}s = {error_budget_seconds/60:.1f} minutes")
# Error budget: 2419s = 40.3 minutes
```

```python
# Burn rate calculation: how fast are you consuming the budget?
# If your actual error rate is 1% on a 99.9% SLO:
#   error_rate = 0.01
#   budget_fraction_per_window = 1 - slo_target = 0.001
#   burn_rate = error_rate / budget_fraction_per_window = 0.01 / 0.001 = 10x

def burn_rate(actual_error_rate, slo_target):
    budget_fraction = 1 - slo_target
    return actual_error_rate / budget_fraction

# e.g., 0.5% errors on a 99.9% SLO → 5x burn rate
# Exhausts monthly budget in 28days / 5 = ~5.6 days
```

## Common Interview Questions

**Q: What's the right SLO target — 99.9% or 99.99%?**
Higher isn't always better. Ask: what level of reliability do users actually need? What's the cost to achieve vs. gain for users? A 99.99% SLO allows only 52 minutes downtime/year — achieving this requires complex multi-region setups, expensive infrastructure, and slower feature velocity. 99.9% (43 min/month) is right for most internal services. Reserve 99.99%+ for payment-critical paths. Setting an SLO tighter than necessary wastes engineering resources.

**Q: How do you handle a service that's been down all month — can the SLO "reset" next month?**
Calendar windows reset monthly, creating the "new month amnesia" problem — a service that was terrible all of November looks fine on December 1st. Use rolling windows (28-day) so recent incidents remain visible. Multi-window alerting (short window for paging, long window for budget tracking) gives both immediate response and long-term accountability.
