Terragrunt is an additional wrapper that is built on top of the Terraform. Terraform is a great Infrastructure as Code tool for managing your cloud infrastructure. But as the project size grows and you have multiple environments (Development, Testing, Staging, Production, etc..) to manage then you will realize Terraform has a lot of gaps for managing a complex and large project.


- Challenges with Terraform - If you are managing multiple environments (Development, Testing, Staging, and Production etc..) infrastructure with Terraform then here are the challenges you might face with Terraform -

1. Redundancy of code - Multiple copies of the same code for each environment.
2. Manual update of code - If there are the same variables that are being used for all the environments then you have to remember and manually update each variable.


- with terragrunt we can define the provider and backend configuration for all the resource configurations in root directory 
- We can create all the resources at once with terragrunt no need to run commands separetly for every resource 

**Dir. Structure :**   
Root -> terragrunt.hcl -> will contain provider and backend info
Resource Directory -> main.tf & terragrunt.hcl ( this will be calling the root terragrunt config)