# Introduction

Terraform Dynamic Block is important when you want to create multiple resources inside of similar types, so instead of copy and pasting the same terraform configuration in the terraform file does not make sense and it is not feasible if you need to create hundreds of resources using terraform.

If we describe terraform dynamic block in simple words then it is for loop which is going to iterate over and will help you to create a dynamic resource. With the help of dynamic blocks you can create nested repeatable blocks such as settings, ingress rules etc...

# Syntax

1. Collections - You need to have collections .e.g. - list, map, set
2. Iterator - To create a dynamic block you need to define an iterator.
3. Content - Content is something onto which you wanna iterate.

```
locals {
   ingress_rules = [{
      port        = 443
      description = "Ingress rules for port 443"
   },
   {
      port        = 80
      description = "Ingree rules for port 80"
   }]
}

resource "aws_security_group" "main" {
   name   = "resource_with_dynamic_block"
   vpc_id = data.aws_vpc.main.id

   dynamic "ingress" {
      for_each = local.ingress_rules

      content {
         description = ingress.value.description
         from_port   = ingress.value.port
         to_port     = ingress.value.port
         protocol    = "tcp"
         cidr_blocks = ["0.0.0.0/0"]
      }
   }

   tags = {
      Name = "AWS security group dynamic block"
   }
}
```