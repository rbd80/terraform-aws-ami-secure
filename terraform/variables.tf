variable "AWS_REGION" {
  description = "AWS Region"
}
variable "profile" {
  description = "AWS profile"
  default = "terraform_svc"
}
variable "NAMESPACE" {
  description = "Owner of Application or Service"
}
variable "STAGE" {
  description = "Workspace or Envirnment"
}
variable "GITTOKEN" {
  description = "GIT token"
}
variable "AWS_ACCOUNT_ID" {
  description = "AWS Account"
}
variable "GITREPO" {
  description = "GIT Repo"
}
variable "GITOWNER" {
  description = "GITOwner"
}