locals {
  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))


  # Extract out common variables for reuse
  env             = local.environment_vars.locals.environment
  aws_region      = local.region_vars.locals.aws_region
  resource_naming_convention = "${local.env}-%s"
  service = format(local.resource_naming_convention, "chapi-ecs-service")
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
  # IAM role
  ecs_execution_role   = "chapi-ecs-role-${local.aws_region}-${local.env}"
  ecs_execution_policy = "chapi-ecs-policy-${local.aws_region}-${local.env}"
  ecs_task_role   = "chapi-ecs-task-role-${local.aws_region}-${local.env}"
  ecs_task_policy = "chapi-ecs-task-policy-${local.aws_region}-${local.env}"
  # Fargate service
  service_name               = "${local.service}"
  
}