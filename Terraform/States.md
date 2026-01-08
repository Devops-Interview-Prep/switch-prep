Terraform has its backbone known as terraform.tfstate file any change you do with your infrastructure will have its presence in the terraform.tfstate file. So when you work with Terraform for managing and provisioning your infrastructure then terraform will always create a terraform.tfstate file for you.


Terraform state file acts as a recorder for your infrastructure setup. Terraform state file(terraform.tfstate) is created from the very beginning when you run your first terraform apply command.

**How does Terraform state file store information?**

- Terraform state file stores the information(metadata) about the infrastructure resources. Any change you plan to make or already made into your infrastructure then that changed information will be stored inside the Terraform state file.

- You do not have to store the information inside the Terraform state file. terraform plan will update terraform state file before making any change to infrastructure.


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

