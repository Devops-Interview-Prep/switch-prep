Terraform worksapces is a very logical concept where you can have multiple states of your infrastructure configuration. To put this in simple words if you are running an infrastructure configuration in development environment then the same infrastructure can be run in the production environment.

The main benefit of terraforming workspaces we get is we can have more than one state associated with a single terraform configuration.

If you have not defined any workspace then there is always a default workspace created by terraform, so you always work in a default workspace of terraform. You can list the number of terraform workspaces by running the command `terraform workspace show`. Also, you can not delete the default workspace


- When you feel that you need a parallel, distinct copy of your infrastructure which you can test and verify in the development, test, and staging environment before putting it into the production environment.
  
- Secondly terraform workspaces acts as feature branch. If you have ever worked with a versioning tool then you might be familiar with main or master where every developer merges their code from the feature branch. So assume the default workspace as your main or master and the workspaces` as your featured branch where you will test and verify your changes.

- Do not presume that with terraform workspaces you can separate or decompose your infrastructure component. Terraform workspaces are not meant to decompose your infrastructure. If you really want to separate or decompose your infrastructure then I would recommend using a separate set of configuration and backend to achieve that.

- If you have your infrastructure where each deployment requires you to put different setup credentials then you should not use Terraform workspaces for that.


`terraform workspace new <name>`  
    create new workspace  

`terraform workspace list`   
    List all Workspaces

`terraform workspace show`     
    Show active workspace

`terraform workspace select test`   
Switch between workspoaces

`locals {
  instance_name = "${terraform.workspace}-instance" 
}`    
    Can define and use workspace in resource creation


- Whenever you work with terraform workspace and when you create multiple workspaces then you will get one directory created for each workspace inside your terraform project.
under terraform.tfstate.d


