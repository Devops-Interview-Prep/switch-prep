- AWS CloudTrail is a service that records all API calls made in your AWS account.
- This includes:

Who made the request (user, role, service)

What was requested (e.g., StartInstances)

When it was made

Where it came from (IP address, AWS region)

The response/result

- It captures both:

Management events (e.g., EC2 start/stop, IAM changes)

Data events (e.g., S3 object access, Lambda invokes)

# How Does It Work?

CloudTrail automatically records events across most AWS services.

You can create a trail, which is a configuration that tells CloudTrail to log events and deliver them to an S3 bucket.

Optionally, send logs to CloudWatch Logs, EventBridge, or third-party SIEM tools.


# Key Use Cases

✅ Security                             Auditing	Track changes to IAM, security groups, etc.
🔍 User Activity Tracking	            Know who did what, when, and from where
🕵️‍♂️ Incident Response	                Investigate breaches or suspicious activity
📜 Compliance	                        Required for compliance frameworks like PCI-DSS, HIPAA, ISO, etc.
📦 Resource Change History	            Identify when a resource was created, modified, or deleted
📈 Monitoring and Alerting	            Use with CloudWatch to trigger alerts on sensitive actions


# Key Features

Event History	View last 90 days of events in the console
Trails (Single/Multi-Region)	Automatically log events across regions
Data Events	Fine-grained logging for S3 and Lambda
Integration with CloudWatch Logs	For near real-time alerts and monitoring
Log File Integrity Validation	Detect tampering with logs (using SHA-256 digest files)
Organization Trails (AWS Org)	Log events across all accounts in an org centrally
Encryption with SSE-KMS	Secure logs with AWS KMS

# What is a Trail?

A trail is a CloudTrail configuration that:

Specifies where to deliver logs (S3 bucket)

Enables logging for management/data events

Can be configured per region or multi-region

You can have:

Event history (default, no config needed): View recent 90 days in console

Trail (configured): Send to S3, CloudWatch, etc., for long-term auditing


# How to Use CloudTrail (Step-by-Step)

- View recent activity (no setup needed)
Go to AWS Console > CloudTrail > Event History

See events for last 90 days (filter by user, event type, service, etc.)

- Create a Trail (for long-term logging)
Go to AWS CloudTrail > Trails

Click Create Trail

Choose:

Trail name

S3 bucket to store logs (create new or use existing)

Enable for all regions (recommended)

Optionally send logs to CloudWatch Logs

Choose events to log:

Management events

Data events (for S3, Lambda, etc.)

Insight events (for unusual activity detection)

Save

✅ Now CloudTrail will start delivering logs to your S3 bucket.


#  Tools to Use with CloudTrail
Amazon Athena – Query CloudTrail logs in S3

AWS Config – Track configuration changes (complement CloudTrail)

CloudWatch Alarms – Alert on specific events (e.g., DeleteBucket)

Amazon Detective – Investigate activity across services

AWS Security Hub – Centralized security findings