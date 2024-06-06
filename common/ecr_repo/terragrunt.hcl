include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "git@github.com:terraform-aws-modules/terraform-aws-ecr.git"
}

inputs = {
  region            = "us-east-1"
  repository_name   = "test-ecr"
  image_tag_mutability = "IMMUTABLE"
  create_lifecycle_policy = false
  }
