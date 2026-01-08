# count, for_each and for loop

**1. Loops with count**  
    -  *Iterate List using count*

```
variable "user_names" {
  description = "IAM usernames"
  type        = list(string)
  default     = ["user1", "user2", "user3"]
}
```

```
resource "aws_iam_user" "example" {
  count = length(var.user_names)
  name  = var.user_names[count.index]
}
```
   - *Iterate Set using count*
  
 ```
  #Step 1: Create a set
variable "my_set" {
   type    = set(string)
   default = ["value1", "value2", "value3"]
}

#Step 2: Convert set to list
locals {
   my_list = tolist(var.my_set)
}

#Step 3: Use count to iterate
resource "my_resource" "example" {
   count = length(local.my_list)

   name = local.my_list[count.index]
   # Additional resource configuration...
}
```

-  *Iterate map using count*
  
Ideally the count meta-argument are not meant to be used for iterating over the map or set but there are some alternates by which you can iterate over the map using the count meta-argument.

```
#Step 1: Create a map variable
variable "my_map" {
  type = map(string)
  default = {
    key1 = "value1"
    key2 = "value2"
    key3 = "value3"
  }
}

#Step 2: Fetch keys of map
locals {
  my_keys = keys(var.my_map)
}

#Step 3: iterate over map using keys and count.index meta argument
resource "my_resource" "example" {
  count = length(local.my_keys)

  name  = local.my_keys[count.index]
  value = var.my_map[local.my_keys[count.index]]
  # Additional resource configuration...
}
```



**2. Loops with for_each**    

It can only be used on set(string) or map(string).
The reason why for_each does not work on list(string) is because a list can contain duplicate values but if you are using set(string) or map(string) then it does not support duplicate values.

- *Iterate List using for_each*   
  Not the ideal way to do it but we can manage.   
  It wont work for duplicate values 
 
 ```
 #Step 1: Create a list varible
variable "my_list" {
   type    = list(string)
   default = ["value1", "value2", "value3"]
}

resource "my_resource" "example" {
   
   #Step 2: Convert list to set using toset() function 
   for_each = toset(var.my_list)

   #Step 3: Iterate over the list
   name = each.value
   # Additional resource configuration...
}
```

- *Iterate Set using for_each*

```
provider "aws" {
   region     = "eu-central-1"
   access_key = "AKIATQ37NXB2NN3D4ARS"
   secret_key = "3v9mlwZQvmccL3ou1dxiDeEf1bWaG3kccpVlXXXX"
}
resource "aws_instance" "ec2_example" {

   ami           = "ami-0767046d1677be5a0"
   instance_type =  "t2.micro"
   count = 1

   tags = {
           Name = "Terraform EC2"
   }

}

resource "aws_iam_user" "example" {
  for_each = var.user_names
  name  = each.value
}

variable "user_names" {
  description = "IAM usernames"
  type        = set(string)
  default     = ["user1", "user2", "user3"]
}
```


- *Iterate map using for_each*

```

#Step 1: Create a map 
variable "my_map" {
  type = map(string)
  default = {
    key1 = "value1"
    key2 = "value2"
    key3 = "value3"
  }
}

#Step 2: Iterate over the map using for_each
resource "my_resource" "example" {
  for_each = var.my_map

  name  = each.key
  value = each.value
  # Additional resource configuration...
}
```

**3. for loop**

- *How to iterate over Set using for?*

```
#Step 1: Create a set
variable "my_set" {
  type    = set(string)
  default = ["value1", "value2", "value3"]
}

#Step 2: Conver it to the list
locals {
  my_list = tolist(var.my_set)
}

#Step 3: Use for loop
resource "my_resource" "example" {
  for_each = { for idx, value in local.my_list : idx => value }

  name = each.value
  # Additional resource configuration...
} 
```


- *How to iterate over List using for?*

Same as above use string inplace of set

```
for_each = { for idx, value in var.my_list : idx => value }
```


- *How to iterate over MAP using for?*

```
{for <KEY>, <VALUE> in <MAP> : <OUTPUT_KEY> => <OUTPUT_VALUE>}

variable "iam_users" {
  description = "map"
  type        = map(string)
  default     = {
    user1      = "normal user"
    user2  = "admin user"
    user3 = "root user"
  }
}

output "user_with_roles" {
  value = [for name, role in var.iam_users : "${name} is the ${role}"]
}
```

**Difference between for_each and count**

1. count : count is an argument that takes a integer value that tells how many copies of a resource to make. When you use count, each instance gets a number (starting with 0), which you can use to get to that instance.
   
2. for_each : This option can be either a map or a set of strings. For each item in the map or set of strings, a new instance is made. The map or set gives each instance a key that can be used to get to that instance.

- count works on a list and uses IDs that are whole numbers. for_each works with a map or set, and string keys are used as keys.
- If you remove an item from the middle of your list using count, every item after it will move down to take its place, and Terraform will make them all over again. With for_each, each instance has a stable identity based on its key, and Terraform won't make new instances if you delete one.
- for_each gives you more freedom and control, especially when you want to make resources with different traits, because you can map different resource options to values in each map or set.


