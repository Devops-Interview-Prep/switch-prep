
# Input Variables
Terraform variables are a way to store values that can be reused throughout your Terraform configuration.

- Variables are defined in the variables block in your Terraform configuration file, where you can give a name and a default value.
- Terraform variables can have various type such as string, number, boolean, list, map etc.
- Variables can be set in the command line when running Terraform commands using the -var flag.
  
# Output Variables

In Terraform, output variables allow you to easily extract information about the resources that were created by Terraform. They allow you to easily reference the values of resources after Terraform has finished running.

output blocks are meant for displaying values, not passing values between resources.

But the resource or data source values used in output blocks can definitely be reused elsewhere.

Output variables are defined in the outputs block in the Terraform configuration file. Here's an example of an output variable that references the IP address of an EC2 instance:

```

output "instance_ip" {
   value = aws_instance.example.public_ip
}
```

In this example, the output variable is named "instance_ip" and its value is set to the public IP of an EC2 instance named "example" that is defined in the Terraform configuration.

You can use the terraform output command to access the value of an output variable:
```
 terraform output instance_ip
 52.11.222.33
```

In addition to being able to reference output variables from the command line, you can also reference them in other parts of the Terraform configuration files using output function. For example:

```
resource "aws_security_group_rule" "example" {
   ...
cidr_blocks = [output.instance_ip]
}
 
```

It's worth noting that you can also set the output variable to be sensitive, in that case, Terraform will mask the output value when it appears in output, making it more secure.

# tfvars Files

In Terraform, you can pass variables from a tfvars file as command-line arguments using the -var-file flag. The -var-file flag allows you to specify a file containing variable values, which will be used when running Terraform commands.

```
# You need to supply variable during the terraform init
terraform init -var-file=terraform.tfvars 

# You need to supply variable during the terraform plan
terraform plan -var-file=terraform.tfvars
 
# You need to supply variable during the terraform apply
terraform apply -var-file=terraform.tfvars 
```


A typical tfvars file should contain the variables that you want to pass to Terraform. Each variable should be in the form of variable_name = value. For example

```
project_id = "gcp-terraform-307119"
location   = "europe-central2"
```


You can also specify multiple variable files by using the -var-file flag multiple times on the command line. For example:
```
terraform apply -var-file=myvars-1.tfvars -var-file=myvars-2.tfvars
```



**In programming world we have concept of variables, similar to that in Terraform we also have concept of Terraform Locals.**
```
## Example of local with static & dynamic value 

locals {
  my_local = "value"
}
# or
locals {
  my_local = "${var.my_variable_value}"
}
```

