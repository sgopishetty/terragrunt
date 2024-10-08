locals {
  
  # Automatically load region-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # Automatically load common variables shared across all accounts
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))

  aws_region      = local.region_vars.locals.aws_region

  tags            = local.common_vars.locals.tags
  
  remote_state_prefix = local.common_vars.locals.remote_state_prefix
  # Merge the default tags with the override tags
  #tags = merge(local.default_tags, local.override_tags)

  bucket_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "AllowSSLRequestsOnly",
        Effect = "Deny",
        Principal = "*",
        Action = "s3:*",
        Resource = [
          "arn:aws:s3:::${local.remote_state_prefix}-tf-state",
          "arn:aws:s3:::${local.remote_state_prefix}-tf-state/*"
        ],
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })

}

# Generate an AWS provider block
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"
  default_tags {
    tags = ${jsonencode(local.tags)}
  }
}
 experiments = [ "module_variable_optional_attrs" ]
EOF
}

# Configure Terragrunt to automatically store tfstate files in an S3 bucket
remote_state {
  backend = "s3"
  config  = {
    encrypt        = true
    bucket         = lower("${local.remote_state_prefix}-tf-state")
    key            = "new/${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    skip_bucket_enforced_tls       = true
    #policy = "${local.bucket_policy}"
    s3_bucket_tags = "${local.tags}"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

inputs = merge(
  local.region_vars.locals,
  local.environment_vars.locals,
)