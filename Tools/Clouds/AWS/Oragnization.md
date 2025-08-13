- AWS Organizations is a service that allows you to centrally manage and govern multiple AWS accounts. It helps with:
  - Grouping multiple AWS accounts into one organization
  - Applying policies across accounts (like service control policies)
  - Consolidated billing (one bill for all accounts)
  - Managing accounts through Organizational Units (OUs)

| Term                                | Description                                                                                               |
| ----------------------------------- | --------------------------------------------------------------------------------------------------------- |
| **Organization**                    | A collection of AWS accounts with one **management (root) account** and zero or more **member accounts**  |
| **Management Account**              | The first account created; used to create/manage the organization and billing                             |
| **Member Account**                  | An AWS account that is part of the organization but not the management account                            |
| **Organizational Unit (OU)**        | A group of accounts within the org. You can apply policies to an OU, and all accounts inside inherit them |
| **Service Control Policies (SCPs)** | Used to manage permissions at the account/OU level — acts as a **guardrail**                              |
| **Consolidated Billing**            | Combines bills for all accounts into a single payment method (no extra cost)                              |

# Typical AWS Org Structure

```
Root Account
├── Security OU
│   ├── Logging Account
│   └── GuardDuty Account
├── Infrastructure OU
│   ├── Network Account
│   └── Shared Services Account
├── Workloads OU
│   ├── Dev Account
│   ├── QA Account
│   └── Prod Account
```

# Enable AWS SSO
**IAM Identity Center:**
- Enable SSO and get the URL
- Create a group 
- Add Users to it 
- Define Permission set 
  - Predefined Permission set
  - Customized Permission Set
- Define the Session Timeout
- Assign Group to an AWS account
  - Assighn Permission Set to the group






