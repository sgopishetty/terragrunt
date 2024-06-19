locals {
  
  # Automatically load region-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  aws_region      = local.region_vars.locals.aws_region


  # The default tags to apply in all environments
  tags = {
    #"epi:product-stream" = "product-engineering",
    "epi:team"           = "quality-engineering",
    #"epi:supported-by"   = "quality-engineering",
    #"epi:environment"    = "production",
    #"epi:owner"          = "quality-engineering",
  }
   
  # Merge the default tags with the override tags
  #tags = merge(local.default_tags, local.override_tags)

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
EOF
}

# Configure Terragrunt to automatically store tfstate files in an S3 bucket
remote_state {
  backend = "s3"
  config  = {
    encrypt        = true
    bucket         = "terragrunt-st"
    key            = "new/${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
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