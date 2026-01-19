Terraform has its backbone known as terraform.tfstate file any change you do with your infrastructure will have its presence in the terraform.tfstate file. So when you work with Terraform for managing and provisioning your infrastructure then terraform will always create a terraform.tfstate file for you.

🔹 What does the state contain?

  - Resource IDs

  - Metadata

  - Attributes returned by provider

  - Dependency graph


Terraform state file acts as a recorder for your infrastructure setup. Terraform state file(terraform.tfstate) is created from the very beginning when you run your first terraform apply command.

**How does Terraform state file store information?**

- Terraform state file stores the information(metadata) about the infrastructure resources. Any change you plan to make or already made into your infrastructure then that changed information will be stored inside the Terraform state file.

- You do not have to store the information inside the Terraform state file. terraform plan will update terraform state file before making any change to infrastructure.

```
{
  "version": 4,
  "terraform_version": "1.6.0",
  "serial": 12,
  "lineage": "a1b2c3d4",
  "resources": [
    {
      "type": "aws_instance",
      "name": "example",
      "instances": [
        {
          "attributes": {
            "id": "i-0abcd",
            "instance_type": "t3.micro",
            "private_ip": "10.0.1.5"
          }
        }
      ]
    }
  ]
}
```

🔹 lineage
  - Unique ID of the state
  - Prevents accidental overwrite with a different state
🔹 serial
  - Incremented on every successful write
  - Used for optimistic locking

- What Terraform does NOT store

❌ Entire cloud configuration
❌ Full provider response
❌ Secrets (usually redacted)
❌ History (unless backend versions it)

- Why state is sensitive
  - State may contain:
  - Private IPs
  - DNS names
  - IAM ARNs
  - Passwords (if provider leaks them)


**How to save terraform state file?**

*1. Saving Locally*  
   If you are the only developer working with Terraform and managing your infrastructure then you do not have to do anything special terraform apply command will generate terraform state file for your workspace and save it inside your working directory.

*2. Saving Remotely*  
    If you are working in a team where multiple developers writing the terraform code to manage the infrastructure then it is highly recommended to store terraform files remotely(AWS S3 Bucket) on a central location so that with every infrastructure change your terraform state file is up to date and in sync with other.

**What is the Purpose of Terraform state file?**

- Any change which you make to your resource will be first reflected into the terraform state file before updating it onto the cloud infrastructure. So terraform state file will start storing each action which you take on the terraform resource.

- Before you use terraform apply or terraform destroy command terraform always validates your resource configuration with the terraform state file and if the changes seem to be valid then your terraform state the file is first going to be updated and then your actual resource will be updated.

- Terraform has its own local database known as Terraform state file where each resource is tagged with its own unique id and this unique id is stored in the state file in the form of metadata.


**Terraform State Performance and Caching**

- The next benefit of Terraform state is file Caching. As terraform, state file acts as a local database for your terraform code, so before making any request to cloud infrastructure it first checks the local terraform state file to show the current status of the cloud infrastructure

- terraform plan - Terraform plan command is a really good example of caching and information return from terraform state file. Whenever we run terraform plan command it returns you back with 3 information -

  - Resources to be added
  - Resources to be changed
  - Resources to be destroyed


**Terraform state locking using DynamoDB**

- The problems arise when two developers try to update the same terraform state file which is stored remotely(S3 Bucket). Ideally, the update on the state file should be done incrementally so that when one developer finishes pushing its state file changes another developer can push their changes after taking the update.

- But because of the agile working environment, we can not guarantee that incremental updates on terraform state files will be performed one after another. Any developer can update and push terraform state file at any point in time, so there should be some provision to prevent a developer from writing or updating terraform file when it is already being used by another developer.

- It prevents Terraform state file(terraform.tfstate) from accidental updates by putting a lock on file so that the current update can be finished before processing the new change. The feature of Terraform state locking is supported by AWS S3 and Dynamo DB.

```
provider "aws" {
   region     = "eu-central-1"
   access_key = var.access_key
   secret_key = var.secret_key
}

resource "aws_dynamodb_table" "state_locking" {
  hash_key = "LockID"
  name     = "dynamodb-state-locking"
  attribute {
    name = "LockID"
    type = "S"
  }
  billing_mode = "PAY_PER_REQUEST"
}

resource "aws_instance" "ec2_example" {
    ami = "ami-0767046d1677be5a0"
    instance_type = "t2.micro"
    tags = {
      Name = "EC2 Instance with remote state"
    }
}

terraform {
    backend "s3" {
        bucket = "jhooq-terraform-s3-bucket"
        key    = "jhooq/terraform/remote/s3/terraform.tfstate"
        region     = "eu-central-1"
       dynamodb_table  = "dynamodb-state-locking"
    }
} 
```

# Drift 

- when someone else other than the terraform updates the resource so the state file wont have that change and when you will do the terraform plan again , it will show the difference between actual resource and the state file 

- *sync state with actual resources*
  - 🔹 Option 1: terraform refresh (This command is deprecated-ish)
    - Reads actual resource values
    - Updates state file
    - Does NOT change real infrastructure
  - 🔹 Option 2: terraform plan -refresh-only (recommended)
    - `terraform plan -refresh-only`
    - `terraform apply -refresh-only`
    - Syncs state to real infra

# State Corruption & Recovery (Real-world scenarios)

- Common state corruption causes

| Cause               | Example                    |
| ------------------- | -------------------------- |
| Concurrent writes   | No locking                 |
| Force-unlock misuse | Unlock while apply running |
| Manual edits        | Editing JSON               |
| Provider crash      | Partial write              |
| Network failure     | Write interrupted          |


- Symptoms of corrupted state
  - Missing resources
  - Duplicate resources
  - Apply wants to recreate everything
  - inconsistent result after apply
  - Invalid JSON

**Recovery strategies (ORDER MATTERS)**

✅ Option 1: Backend version rollback (BEST)

- If using:
    - S3 with versioning
    - Terraform Cloud
👉 Restore previous version

✅ Option 2: terraform refresh
- If infra is correct but state is stale

✅ Option 3: Import missing resources
- Resource exists
- State entry is missing

⚠️ Option 4: Manual state surgery (LAST RESORT)

**How Drift Is Handled in CI/CD**

- Scheduled plan
  - `terraform plan -detailed-exitcode`
    - 0 → No changes
    - 2 → Drift detected
    - 1 → Error
- What happens next?
  🔹 Option A: Accept drift
      - Update Terraform code
      - Apply changes
      - State updated
  🔹 Option B: Revert Drift 
    - `terraform apply`
    - Restores infra to code-defined state. 