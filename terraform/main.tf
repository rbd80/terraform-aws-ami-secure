terraform {
  required_version = ">= 0.11.3"
}

provider "aws" {
  region = "us-east-1"
  profile = "${var.profile}"
}

# ---------------------------------------------------------------------------------------------------------------------
# Built a clean AMI
# ---------------------------------------------------------------------------------------------------------------------
module "build" {
  source              = "git::https://github.com/cloudposse/terraform-aws-cicd?ref=master"
  namespace        = "${var.NAMESPACE}"
  stage            = "${var.STAGE}"
  name                = "ami-builder"
  # Enable the pipeline creation
  enabled             = "true"

  # Application repository on GitHub
  repo_owner          = "${var.GITOWNER}"
  repo_name           = "${var.GITREPO}"
  branch              = "master"
  github_oauth_token  = "${var.GITTOKEN}"

  # http://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref.html
  # http://docs.aws.amazon.com/codebuild/latest/userguide/build-spec-ref.html
  build_image         = "aws/codebuild/docker:1.12.1"
  build_compute_type  = "BUILD_GENERAL1_SMALL"

  # These attributes are optional, used as ENV variables when building Docker images and pushing them to ECR
  # For more info:
  # http://docs.aws.amazon.com/codebuild/latest/userguide/sample-docker.html
  # https://www.terraform.io/docs/providers/aws/r/codebuild_project.html
  privileged_mode     = "true"
#  aws_region          = "${data.aws.region}"
  aws_account_id      = "${var.AWS_ACCOUNT_ID}"
  image_repo_name     = "ecr-repo-name"
  image_tag           = "latest"
}


