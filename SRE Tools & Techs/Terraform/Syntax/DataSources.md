- Terraform data sources can be beneficial if you want to retrieve or fetch the data from the cloud service providers such as AWS, AZURE, and GCP

 - We need to use the data sources to get the resource information back.

 - So Terraform Data Sources are a kind of an API that fetches the data/information from the resources running under the cloud infra and sending it back to terraform configuration for further use.

- This is when you're outputting values from existing infrastructure fetched using a data source, not created by Terraform.

```
provider "aws" {
    region     = "eu-central-1"
    access_key = "AKIATQ37NXB2JMXVGYPG"
    secret_key = "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"
}

data "aws_instance" "myawsinstance" {
    filter {
        name = "tag:Name"
        values = ["Terraform EC2"]
    }

    depends_on = [
      "aws_instance.ec2_example"
    ]
}

output "fetched_info_from_aws" {
  value = data.aws_instance.myawsinstance.public_ip
}
```

**1. filter:**  
 Although we have created only one instance but still we have used filter because in a production-like environment you might have multiple aws_instance running, so you need to filter the instance anyhow. And since we have tagged our aws_instance with the name Terraform EC2 so we are going to use the same name inside the filter also. 


**2. depends_on:**   
 The second important parameter is depends_on because data source does not know by its own which resource it belongs to, so we are going to add the depends_on parameter.