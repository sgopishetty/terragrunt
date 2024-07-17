terraform {
  source = "../../../../modules/ecs/ecs-fargate-service-with-alb"
}

include "root" {
  path   = find_in_parent_folders()
  expose = true
}

include "envcommon" {
  path   = "${dirname(find_in_parent_folders())}/_envcommon/ecs-service/service.hcl"
  expose = true
}

locals {
  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))


  # Extract out common variables for reuse
  env             = local.environment_vars.locals.environment
  aws_region      = local.region_vars.locals.aws_region
  resource_naming_convention = "${local.env}-%s"
  service = format(local.resource_naming_convention, "chapi-ecs-service")
  cluster = format(local.resource_naming_convention, "chapi-ecs-cluster")
  # The default tags to apply in all environments
  tags = {
    #"epi:product-stream" = "product-engineering",
    "epi:team"           = "quality-engineering"
    #"epi:supported-by"   = "quality-engineering",
    #"epi:environment"    = "production",
    #"epi:owner"          = "quality-engineering",
  }
  commit_sha         =  get_env("COMMIT_SHA", "lates")  # Default to "latest" if COMMIT_SHA is not set
  # Run the script to generate the task definition JSON
  container_definitions_path = run_cmd("bash", "${get_terragrunt_dir()}/generate_task_definition.sh", "${get_terragrunt_dir()}/chapi-task-definition.json", "${get_terragrunt_dir()}/chapi-task-definition.json", local.commit_sha, local.service)
}



inputs = {
  # IAM role
  
  ecs_execution_role_file   = "${get_terragrunt_dir()}/ecs-task-execution-role.json"
  ecs_execution_policy_file = "${get_terragrunt_dir()}/ecs-task-execution-policy.json"
  ecs_task_role_file   = "${get_terragrunt_dir()}/ecs-task-role.json"
  ecs_task_policy_file = "${get_terragrunt_dir()}/ecs-task-policy.json"
  # Fargate service
  ecs_cluster_arn            = dependency.cluster.outputs.ecs_cluster_arn
  task_cpu                   = "512"
  task_memory                = "1024"
  #container_definitions_path = templatefile("${get_terragrunt_dir()}/chapi-task-definition.json", {
  #  image = "public.ecr.aws/ecs-sample-image/amazon-ecs-sample:${local.commit_sha}"
  #  name  = "${local.service}"
  #})
  container_definitions_path = "${get_terragrunt_dir()}/chapi-task-definition.json"

  private_subnet_ids = dependency.subnets.outputs.private_subnets
  assign_public_ip   = false

  # Auto scaling
  use_auto_scaling        = true
  min_number_of_tasks     = "1"
  max_number_of_tasks     = "2"
  desired_number_of_tasks = "1"

  # ALB information
  container_name        = "${local.service}"
  container_port        = "80"
  alb_protocol          = "HTTP"
  health_check_protocol = "HTTP"
  health_check_path     = "/"
  vpc_id                = "vpc-04706f24c5d6cadc6"

  # ALB configuration
  alb_name            = "chapi-ecs-test"
  is_internal_alb     = false
  #create_alb_listener_https_rule = true
  http_listener_ports = ["80"]
  create_alb_listener_http_rule = true
  public_subnet_ids   = dependency.subnets.outputs.public_subnets
  #https_listener_ports_and_ssl_certs_num = "1"
  #https_listener_ports_and_ssl_certs = [
  #  {
  #    port = 443
  #    tls_arn = "arn:aws:acm:us-west-2:151609635614:certificate/b4749928-1828-4a69-bf2f-f6c6571a5e7e"
  #  }
  #]
  #ssl_policy = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  # ALB Access logs
  enable_alb_access_logs = false
  // alb_access_logs_s3_bucket_name   = dependency.alb_access_logs.outputs.primary_bucket_name
  // custom_alb_access_logs_s3_prefix = "${local.team_name}-${local.name_prefix}-api-${local.env}"

  # Security group
  security_group_name = "chapi-ecs-sg-${local.aws_region}-${local.env}"
  from_port           = 80
  to_port             = 80

  # Cloudwatch alarms
  cloudwatch_log_group_name = "/ecs/aws/chapi-ecs-${local.aws_region}-${local.env}"
  ecs_cluster_name          = "${local.cluster}"
}

dependency "cluster" {
  config_path = "${get_terragrunt_dir()}/../ecs-cluster"

  mock_outputs = {
    ecs_cluster_arn = ["known-after-apply"]
  }
}

dependency "subnets" {
  config_path = "${get_terragrunt_dir()}/../subnets"
  

  mock_outputs = {
    private_subnets = ["known-after-apply"],
    public_subnets = ["known-after-apply"]
  }
}