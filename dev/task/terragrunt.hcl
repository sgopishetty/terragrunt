include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "https://github.com/geekcell/terraform-aws-ecs-task-definition.git"
}

inputs = {
  name        = "fastapi-test"
  
  # Task Definition
  requires_compatibilities = ["EC2"]
  create_execution_role = "false"
  create_task_role = "false"
  task_role_arn       = "arn:aws:iam::590184036010:role/ECS_Task_Role"
  execution_role_arn       = "arn:aws:iam::590184036010:role/ECS_Task_Role"


  # Container definition(s)
  container_definitions = jsonencode([
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
      # Uncomment and adjust the entry point if necessary
      # entryPoint    = ["fastapi", "run", "/code/app/main.py", "--port", "8000"]
    }
  ])
  cpu = 256
  memory = 200
}