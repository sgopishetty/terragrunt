include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "git@github.com:terraform-aws-modules/terraform-aws-ecs.git//modules/service?ref=master"
}

inputs = {
  name        = "fastapi"
  cluster_arn = dependency.cluster.outputs.cluster_arn
  create_task_definition = false
  create_security_group = true
  task_definition_arn = dependency.task.outputs.arn
  enable_autoscaling = false
  launch_type = "EC2"
  cpu = 256
  memory = 200
  subnet_ids = ["subnet-062c00f91809492f9", "subnet-00df360198eb45c76"]
  deployment_maximum_percent = 200
  load_balancer = {
    service = {
      target_group_arn = dependency.alb.outputs.target_groups["ex_ecs"].arn
      container_name   = "fastapi-test"
      container_port   = 80
    }
  }
  security_group_rules = {
    alb_http_ingress = {
      type                     = "ingress"
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      description              = "Service port"
      source_security_group_id = dependency.alb.outputs.security_group_id
    }
  }
  
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

dependency "task" {
  config_path = "../task"
  mock_outputs = {
    arn = "temporary-dummy-id"
  }
}

dependency "alb" {
  config_path = "../alb"
  mock_outputs = {
    target_groups = {
      ex_ecs = {
        arn = "arn:aws:elasticloadbalancing:us-east-1:590184036010:targetgroup/tf-20240527023830081200000002/1749562d2510f6a1"
      }
    }
    security_group_id = "sg-037e53624f1a4bff3"
  }
}