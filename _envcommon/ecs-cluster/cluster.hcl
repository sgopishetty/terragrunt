locals {
  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))


  # Extract out common variables for reuse
  env             = local.environment_vars.locals.environment
  aws_region      = local.region_vars.locals.aws_region
  resource_naming_convention = "${local.env}-%s"
  cluster = format(local.resource_naming_convention, "chapi-ecs-cluster")
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
  cluster_name = local.cluster
  custom_iam_role_name = format(local.resource_naming_convention, "chapi-ecs-role")
  cluster_instance_user_data = <<-EOF
              #!/bin/bash
              cat <<EOL >> /etc/ecs/ecs.config
                ECS_CLUSTER=${local.cluster}
                ECS_LOGLEVEL=debug
                ECS_ENABLE_TASK_IAM_ROLE=true
              EOL     
            EOF
  custom_tags_ecs_cluster = "${local.tags}"
}

