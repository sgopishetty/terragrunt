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
  service_name = local.service
  service_tags = "${local.tags}"
  task_definition_tags = "${local.tags}"
  lb_target_group_tags = "${local.tags}"
  elb_target_groups = {
     alb = {
       name                          = local.service
       container_name                = local.service
       container_port                = 80
       protocol                      = "HTTP"
       health_check_protocol         = "HTTP"
       load_balancing_algorithm_type = "round_robin"
     }
   }
}