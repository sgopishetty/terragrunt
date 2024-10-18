locals {
  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))


  # Extract out common variables for reuse
  
  env             = local.environment_vars.locals.environment
  aws_region      = local.region_vars.locals.aws_region
  resource_naming_convention = "${local.env}-%s"
  waf_name        = format(local.resource_naming_convention, "waf_web_acl")
  # The default tags to apply in all environments
  tags = {
    #"epi:product-stream" = "product-engineering",
    "epi:team"           = "quality-engineering"
    #"epi:supported-by"   = "quality-engineering",
    #"epi:environment"    = "production",
    #"epi:owner"          = "quality-engineering",
  }
}


inputs = {
  name = local.waf_name
  tags = local.tags
}