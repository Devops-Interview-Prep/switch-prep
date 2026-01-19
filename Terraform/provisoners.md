Terraform Provisioners are used to performing certain custom actions and tasks either on the local machine or on the remote machine.

*Terraform docs explicitly say:*

    - Provisioners should be used as a last resort.
    - Reasons:
        - Not idempotent
        - Hard to debug
        - Breaks terraform plan
        - Tightly couples infra + config
        - Failures leave partial state

    - This is why SREs prefer:
        - user_data
        - Packer AMIs
        - Configuration management (Ansible, Chef)
        - SSM

**The custom actions can vary in nature and it can be -**

1. Running custom shell script on the local machine
2. Running custom shell script on the remote machine
3. Copy file to the remote machine


**Also there are two types of provisioners -**

1. Generic Provisioners (file, local-exec, and remote-exec)
    - Generally vendor independent and can be used with any cloud vendor(GCP, AWS, AZURE)

2. Vendor Provisioners (chef, habitat, puppet, salt-masterless)
    - It can only be used only with its vendor. For example, chef provisioner can only be used with chef for automating and provisioning the server configuration.


# file provisioner

- As the name suggests file provisioner can be used for transferring and copying the files from one machine to another machine.
- Not only file but it can also be used for transferring/uploading the directories.
➡️ copies a file or directory from the machine running terraform apply to a remote resource
➡️ using an already-established connection (SSH or WinRM)

```
resource "aws_instance" "example" {
  ami           = "ami-0abc123"
  instance_type = "t3.micro"
  key_name      = "my-key"

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/id_rsa")
    host        = self.public_ip
  }

  provisioner "file" {
    source      = "app.conf"
    #content    = "will copy the string to the destination"
    destination = "/etc/app.conf"
  }
}

```

**Internally: what actually happens**

- Behind the scenes Terraform:

- Uses Go SSH client

- Opens an SSH session

- Uses SCP-like file transfer

- Copies file over the network

- content - The content argument is useful when you do not want to copy or transfer the file instead you only want to copy the content or string.

# local-exec provisioner

- this provisioner is used when you want to perform some tasks onto your local machine where you have installed the terraform.
- So local-exec provisioner is never used to perform any kind task on the remote machine. It will always be used to perform local operations onto your local machine.
  
```
provisioner "local-exec" {
    command = "touch hello-jhooq.txt"
}
```
Example - Consider the following example where we are trying to create a file hello-jhooq.txt on the local machine


# remote-exec provisioner

- As the name suggests remote-exec it is always going to work on the remote machine. With the help of the remote-exec you can specify the commands of shell scripts that want to execute on the remote machine.

- As we discussed ssh and winrm for secure data transfer in local-exec, here also all the communication and file transfer is done securely.

```
provisioner "remote-exec" {
    inline = [
      "touch hello.txt",
      "echo helloworld remote provisioner >> hello.txt",
    ]
}
```

- inline - With the help of an inline argument you can specify the multiple commands which you want to execute in an ordered fashion.

- script - It can be used to copy the script from local machine to remote machine and it always contains a relative path.

-  scripts - Here you can specify the multiple local scripts which want to copy or transfer to the remote machine and execute over there.
-  

