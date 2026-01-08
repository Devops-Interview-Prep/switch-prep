- Here are three different ways of handling AWS Credentials:

1. Hard coding AWS Credentials(ACCESS_KEY, SECRET_KEY) inside terraform file (*Not recommended)
2. Using /.aws/credentials file along with terraform's shared_credentials_file settings
```
provider "aws" {
   profile    = "test"
   region     = "eu-central-1"
   shared_credentials_file = "~/.aws/credentials"
}
```
3. Configure AWS Credentials as environment variables

```
export AWS_ACCESS_KEY_ID="A0LPA509NDFKJ74HW0CPAGH0FNM3"
 ```

