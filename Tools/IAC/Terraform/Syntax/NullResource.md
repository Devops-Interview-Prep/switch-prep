# Null Resource

- As in the name you see a prefix null which means this resource will not exist on your Cloud Infrastructure(AWS, Google Cloud, Azure). The reason is there is no terraform state associated with it, due to you can update the null_resource inside your Terraform file as many times as you can.

- Terraform null_resource can be used in the following scenario -

1. Run shell command
2. You can use it along with local provisioner and remote provisioner
3. It can also be used with Terraform Module, Terraform count, Terraform Data source, Local variables
4. It can even be used for output block


# handle null value with default value

- In Terraform, null represents the absence of a value or an unknown state. It can occur when variables are not explicitly set, when resources are not yet created, or when certain data is unavailable.

- When null values are encountered, Terraform typically throws an error if the null value is assigned to a required argument. Additionally, null values may disrupt the desired state of the infrastructure and cause issues with resource management or configuration.

- Terraform's conditional expressions allow you to evaluate conditions and assign default values based on the presence of null values. You can use the coalesce() function to achieve this.

```
# Region variable with default value null 
variable "region" {
  description = "AWS region"
  default     = null
}

# Use coalesce to set the region value - us-west-2, if the value is null
resource "aws_instance" "example" {
  ami           = var.ami_id
  instance_type = var.instance_type
  region        = coalesce(var.region, "us-west-2")
}
 
```