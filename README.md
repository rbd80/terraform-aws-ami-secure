# terraform-aws-ami-secure

Builds two AMIs one is Amazon 2 linux and the other is the KOPS recommended Debian.  Both
OS are harden and forward logs to AWS CloudWatch.  

Terraform module for generating or importing an SSH public key file into AWS.

Only AWS: the ec2 size must be above t2.small, b/c of packages installed

## Tigger
Any commit to master invokes AWS Codepipeline.

## Usage
This repo will create the pipeline and build two fresh AMIs for the environment.  This uses Ansible 
roles to configure logging, Systemd hardening, auditing and AntiVirus.  N  


## How to use
Make update the the env.rc file.  Setup the AWS configure with the account to create the IaaS
run the sh script to begin.
 
 You need to configure the [AWS profile](https://docs.aws.amazon.com/cli/latest/userguide/cli-multiple-profiles.html).

run Terraform.  

## Terraform. 
This repo used local state for terraform.  If need s3 state use the Kubernetes repo

## AWS Accounts 
Terraform and Packer have their own svc accounts.  The base account need permission to 
be able to create these policies and accounts.  [Packer IAM permissions](https://www.packer.io/docs/builders/amazon.html#using-an-iam-instance-profile)

If policies changes are needed use the bootstrap.sh and select that menu option.  Then 
update the policy json files here.  And rerun the bootstrap and select the first option.

## Ansible 

Instead of using Ansible Galaxy repo this pulls from the GITHUB repos for the roles.


## Ansible Roles

|  Name/Package                  |  Site       |  Purpose                                             | Sourced  |
|:-----------------------------|:--------------:|:---------------------------------------------------------|:---------:|
| `ClamAV`                     | [Web](https://www.clamav.net/)             | Antivirus                   | [Repo](https://github.com/rbd80/ansible-role-clamav)       |
| `Lynis`                      | ``             | Stage (e.g. `prod`, `dev`, `staging`)                    | Yes       |
| `OSSEC`                      | ``             | Application or solution name  (e.g. `app`)               | Yes       |
| `ssh_public_key_path`        | ``             | Path to SSH public key directory (e.g. `/secrets`)       | Yes       |
| `generate_ssh_key`           | `false`        | If set to `true`, new SSH key pair will be created       | No        |
| `private_key_extension`      | ``             | Private key file extension (_e.g._ `.pem`)               | No        |
| `public_key_extension`       | `.pub`         | Public key file extension (_e.g._ `.pub`)                | No        |
| `chmod_command`              | `chmod 600 %v` | Template of the command executed on the private key file | Yes(Linux), No(Windows) |

```
module "ssh_key_pair" {
  source                = "git::https://github.com/cloudposse/terraform-aws-key-pair.git?ref=master"
  namespace             = "cp"
  stage                 = "prod"
  name                  = "app"
  ssh_public_key_path   = "/secrets"
  generate_ssh_key      = "true"
  private_key_extension = ".pem"
  public_key_extension  = ".pub"
  chmod_command         = "chmod 600 %v"
}
```


## Variables

|  Name                        |  Default       |  Description                                             | Required  |
|:-----------------------------|:--------------:|:---------------------------------------------------------|:---------:|
| `namespace`                  | ``             | Namespace (e.g. `cp` or `cloudposse`)                    | Yes       |
| `stage`                      | ``             | Stage (e.g. `prod`, `dev`, `staging`)                    | Yes       |
| `name`                       | ``             | Application or solution name  (e.g. `app`)               | Yes       |
| `ssh_public_key_path`        | ``             | Path to SSH public key directory (e.g. `/secrets`)       | Yes       |
| `generate_ssh_key`           | `false`        | If set to `true`, new SSH key pair will be created       | No        |
| `private_key_extension`      | ``             | Private key file extension (_e.g._ `.pem`)               | No        |
| `public_key_extension`       | `.pub`         | Public key file extension (_e.g._ `.pub`)                | No        |
| `chmod_command`              | `chmod 600 %v` | Template of the command executed on the private key file | Yes(Linux), No(Windows) |


## Outputs

| Name                  | Description                                   |
|:----------------------|:----------------------------------------------|
| `ami_name`            | Name of AMI ready for use                     |
| `public_key`          | Contents of the generated public key          |


## Help

**Got a question?**

File a GitHub [issue](https://github.com/cloudposse/terraform-aws-key-pair/issues), send us an [email](mailto:hello@cloudposse.com) or reach out to us on [Gitter](https://gitter.im/cloudposse/).


## Contributing

### Bug Reports & Feature Requests

Please use the [issue tracker](https://github.com/rbd80/terraform-aws-ami-secure/issues) to report any bugs or file feature requests.

### Developing

If you are interested in being a contributor and want to get involved in developing `terraform-aws-ami-secure`, we would love to hear from you! Shoot us an [email](mailto:hello@cloudposse.com).

In general, PRs are welcome. We follow the typical "fork-and-pull" Git workflow.

 1. **Fork** the repo on GitHub
 2. **Clone** the project to your own machine
 3. **Commit** changes to your own branch
 4. **Push** your work back up to your fork
 5. Submit a **Pull request** so that we can review your changes

**NOTE:** Be sure to merge the latest from "upstream" before making a pull request!


## About



### Contributors
Consolidated several other repos into this one.  
Inspired by [Cloud Posse, LLC][website].