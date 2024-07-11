terraform {
  source = "../../../../modules/ecs-service"
}

include "root" {
  path   = find_in_parent_folders()
  expose = true
}

include "envcommon" {
  path   = "${dirname(find_in_parent_folders())}/_envcommon/ecs-service/service.hcl"
  expose = true
}

inputs = {
  desired_number_of_tasks = 2
  ecs_cluster_arn = dependency.cluster.outputs.ecs_cluster_arn
  ecs_task_container_definitions = jsonencode([
    {
      name          = "fastapi-test"
      image         = "public.ecr.aws/ecs-sample-image/amazon-ecs-sample:latest"
      portMappings  = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      enable_cloudwatch_logging              = true
      create_cloudwatch_log_group            = true
      cloudwatch_log_group_name              = "/aws/ecs/fastapi"
      cloudwatch_log_group_retention_in_days = 7

      log_configuration = {
        logDriver = "awslogs"
      }
      # Uncomment and adjust the entry point if necessary
      # entryPoint    = ["fastapi", "run", "/code/app/main.py", "--port", "8000"]
      memory = 200
    }
  ])
  elb_target_group_vpc_id = "vpc-04706f24c5d6cadc6"
  health_check_enabled = true
  enable_ecs_deployment_check = false
}


dependency "cluster" {
  config_path = "${get_terragrunt_dir()}/../ecs-cluster"

  mock_outputs = {
    ecs_cluster_arn = ["known-after-apply"]
  }
}