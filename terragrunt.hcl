remote_state {
  backend = "s3"
  config  = {
    encrypt        = true
    bucket         = "terragrunt-st"
    key            = "terragrunt/${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Configure common provider settings
generate "provider.tf" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
provider "aws" {
  region = "us-east-1"
}
EOF
}