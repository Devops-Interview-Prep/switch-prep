# Format Your Terraform Code

1. `terraform fmt`  
    Format your Terraform configuration files using the HCL language standard.

2. `terraform fmt --recursive`   
    Also format files in subdirectories

3. `terraform fmt --diff`   
   Display differences between original configuration files and formatting changes.

4. `terraform fmt --check`   
   Useful in automation CI/CD pipelines, the check flag can be used to ensure the configuration files are formatted correctly, if not the exit status will be non-zero. If files are formatted correctly, the exit status will be zero.

# Initialize Your Directory

5. `terraform init`   
    In order to prepare the working directory for use with Terraform, the terraform init command performs Backend Initialization, Child Module Installation, and Plugin Installation.

   - Initializes the Backend:
     - Sets up the backend configuration (e.g., local, S3, etcd) for storing the Terraform state.
     - If you're using a remote backend, it may create or fetch the remote state file.
  
   - Downloads Provider Plugins:
     - Terraform identifies which providers (e.g., AWS, Google, Azure) are required from the .tf files and downloads the correct versions.
     - These are stored in the .terraform directory.

   - Installs Modules (if any):
     - If your configuration uses modules (local or remote), Terraform downloads and caches them.
  
   - Generates a Lock File:
     - Terraform creates or updates a terraform.lock.hcl file to ensure consistent provider plugin versions across machines.

# Validate Your Terraform Code

6. `terraform validate`   
   Validate the configuration files in your directory and does not access any remote state or services. terraform init should be run before this command.

7. `terraform validate -json`    
   To see easier the number of errors and warnings that you have.

# Apply your Changes

8. `terraform apply`
9. `terraform apply -auto-approve` 
    Apply changes without having to interactively type ‘yes’ to the plan. Useful in automation CI/CD pipelines.
10. `terraform apply -var-file="varfile.tfvars"`
11. `terraform apply -var="environment=dev"`
12. `terraform apply -target=aws_instance.ec2_example`
13. `terraform apply -target=aws_instance.ec2_1 -target=aws_instance.ec2_2 `   
    Apply changes only to the targeted resource

# Import resources not created by Terraform

14. `terraform import <RESOURCE_TYPE>.<RESOURCE_NAME> <RESOURCE_ID> `   
ex. `terraform import aws_s3_bucket.my_bucket my-bucket-name`

- This would import the S3 bucket with the name my-bucket-name into Terraform and create a resource block for it in your Terraform configuration.
- Keep in mind that you will need to have a resource block in your Terraform configuration for the resource type you are importing. The resource block should include all of the required arguments for the resource type, as well as any optional arguments that you want to set.

**Steps to Import**
1. Create an empty resource 
2. Import the resource using the terraform command
3. Fill the empty resource 
4. Verify with terraform plan 

**In which situation you should use terraform import?**

- When you want to move infrastructure between environments: If you have the infrastructure in one environment (e.g. a staging environment) and you want to move it to another environment (e.g. production), you can use terraform import to bring the infrastructure into Terraform in the target environment, and then use the standard Terraform workflow to apply the changes.

- When you want to switch from manual management to Terraform management: If you have been manually managing infrastructure and you want to switch to using Terraform, you can use terraform import to bring the existing infrastructure under Terraform management. This allows you to start using the standard Terraform workflow to manage the infrastructure going forward.

**Drawbacks of terraform import?**

- It is a one-time operation: terraform import is a one-time operation, and it should not be used as a replacement for the standard Terraform workflow. After you have imported a resource, you should continue to use the standard Terraform workflow to make changes to it.

- It can be difficult to use with complex infrastructure: terraform import can be difficult to use with infrastructure that has many dependencies or is otherwise complex. It may be easier to recreate the infrastructure from scratch using the standard Terraform workflow.

- It does not import the resource's history: terraform import does not import the history of the resource, so you will not be able to see the changes that were made to the resource before it was brought under Terraform management.

# Remove a single resource from terraform state file

15. `terraform state list`    
    List all the resources

16. `terraform state rm my_resource`     
    
    - Previous command will remove the resource and all of its associated data from the state file. You can then use the $terraform apply command to apply the changes and remove the resource from your infrastructure.
    - It's important to note that removing a resource from the Terraform state does not destroy the resource itself. If you want to destroy the resource and remove it from your infrastructure, you will need to use the $terraform destroy command.






    
   


