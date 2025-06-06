# list of Resource Meta Arguments 
1. depends_on
2. count
3. for_Each
4. provider
5. lifecycle

**1. depends_on**  

Terraform normally figures out the order to create resources automatically by analyzing references (like aws_instance using a security_group).

But sometimes you have indirect or hidden dependencies that Terraform can’t detect. That’s when you use depends_on.

It forces Terraform to create one resource only after another has been created or changed.
```
resource "aws_instance" "my_instance" {
  # ... instance config

  depends_on = [aws_security_group.my_sg]
}
```

**2. count**   

As the name suggests count can be used inside the aws_instance block to specify how many resources you would like to create.

```
provider "aws" {
   region     = "eu-central-1"
   access_key = "AKIATQ37NXB2HS7IVM5R"
   secret_key = "MJy5JX6HIqHwP9gLAv+22kffS/jiDsMo2XLP9mZn"
}

resource "aws_instance" "ec2_example" {

   count         = 2 
   ami           = "ami-0767046d1677be5a0"
   instance_type =  "t2.micro"

   tags = {
           Name = "Terraform EC2"
   }
}

```

**3. for_each**

Similar to the count for_each can also be used for creating similar kinds of resources instead of creating a writing duplicate terraform block.

```
provider "aws" {
   region     = "eu-central-1"
   access_key = "AKIATQ37NXB2HS7IVM5R"
   secret_key = "MJy5JX6HIqHwP9gLAv+22kffS/jiDsMo2XLP9mZn"
}

resource "aws_instance" "ec2_example" {

    for_each = {
      instance1 = "t2.micro"
      instance2 = "t2.micro" 
    }

   ami           = "ami-0767046d1677be5a0"
   instance_type =  each.value

   tags = {
           Name = "Terraform ${each.key}"
   }
} 
```

**4. provider**

This meta argument is one of my favorite because it lets you override Terraform's default behavior. It can help you to create multiple configurations for a single cloud service provider (.e.g - AWS, GCP).

One simple example would be - "Suppose you want to create two aws_instance one in eu-central-1 and another one in eu-nort-1 region, would it be possible for you to create in single main.tf file?"

Well, YES you can do that but to achieve this you need to use provider inside your terraform file along with the alias.

```
provider "aws" {
  alias  = "north"
  region = "eu-north-1"
  access_key = "AKIATQ37NXB2HS7IVM5R"
  secret_key = "MJy5JX6HIqHwP9gLAv+22kffS/jiDsMo2XLP9mZn"
}

provider "aws" {
   region     = "eu-central-1"
   access_key = "AKIATQ37NXB2HS7IVM5R"
   secret_key = "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"
}

resource "aws_instance" "ec2_eu_north" {
   provider      = aws.north
   ami           = "ami-0ff338189efb7ed37"
   instance_type =  "t3.micro"
   count = 1
   tags = {
           Name = "Terraform EC2"
   }

}

resource "aws_instance" "ec2_eu_central" {
   ami           = "ami-0767046d1677be5a0"
   instance_type =  "t2.micro"
   count = 1
   tags = {
           Name = "Terraform EC2"
   }
}
```

**5. lifecycle**

There are three arguments which you can pass inside the lifecycle block -

*1. create_before_destroy*    
 Once you set this argument the resource will be created once again after you issue the terraform destroy command   

*2. prevent_destroy*        
It prevents from destroying your terraform resource, once you set this terraform argument then the resource can not be destroyed    

*3. ignore_changes*    
Suppose you have manually made some changes on aws or GCP but you want to prevent those changes to be saved inside your terraform terraform.tfstate file then you can use ignore_changes arguments.

```
provider "aws" {
   region     = "eu-central-1"
   access_key = "AKIATQ37NXB2HS7IVM5R"
   secret_key = "MJy5JX6HIqHwP9gLAv+22kffS/jiDsMo2XLP9mZn"
}

resource "aws_instance" "ec2_example" {

   count         = 2 
   ami           = "ami-0767046d1677be5a0"
   instance_type =  "t2.micro"

   tags = {
           Name = "Terraform EC2"
   }
   
       lifecycle {
      create_before_destroy = true
      #prevent_destroy       = true
      #ignore_changes        = [tags]
   }
}
```


