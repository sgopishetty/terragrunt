include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "git@github.com:terraform-aws-modules/terraform-aws-ecs.git//modules/service?ref=master"
}

inputs = {
  name        = "fastapi"
  cluster_arn = dependency.cluster.outputs.cluster_arn

  # Task Definition
  requires_compatibilities = ["EC2"]
  capacity_provider_strategy = {
    # On-demand instances
    ex_1 = {
      capacity_provider = dependency.asg.outputs.autoscaling_group_arn
      weight            = 1
      base              = 1
    }
  }


  # Container definition(s)
  container_definitions = {
    fastapi = {
      image = "public.ecr.aws/ecs-sample-image/amazon-ecs-sample:latest"
      port_mappings = [
        {
          name          = "fastapi"
          containerPort = 80
          protocol      = "tcp"
        }
      ]

      #entry_point = ["fastapi", "run", "/code/app/main.py", "--port", "8000"]

      # Example image used requires access to write to root filesystem
      readonly_root_filesystem = false

      enable_cloudwatch_logging              = true
      create_cloudwatch_log_group            = true
      cloudwatch_log_group_name              = "/aws/ecs/fastapi/fastapi"
      cloudwatch_log_group_retention_in_days = 7

      log_configuration = {
        logDriver = "awslogs"
      }
    }
  }
  cpu = 512
  memory = 200
  subnet_ids = ["subnet-062c00f91809492f9", "subnet-00df360198eb45c76"]
  security_group_ids = ["sg-0f26b1f964899aa0d"]
  create_task_exec_iam_role = false
  create_tasks_iam_role     = false
  task_exec_iam_role_arn    = "arn:aws:iam::590184036010:role/ECS_Task_Role"
}


dependency "cluster" {
  config_path = "../ecs_cluster"
  mock_outputs = {
    cluster_arn = "temporary-dummy-id"
  }
}

dependency "asg" {
  config_path = "../ecs_asg"
  mock_outputs = {
    autoscaling_group_arn = "temporary-dummy-id"
  }
}