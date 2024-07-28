# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DEPLOY A DOCKER APP
# These templates show an example of how to run a Docker app on top of Amazon's Fargate Service
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

terraform {
  required_version = ">= 1.0.0"
}

/* role that the Amazon ECS container agent and the Docker daemon can assume */
resource "aws_iam_role" "ecs_execution_role" {
  name = var.ecs_execution_role
  # assume_role_policy = file("${path.module}/policies/ecs-task-execution-role.json")
  assume_role_policy = file(var.ecs_execution_role_file)

}

resource "aws_iam_role_policy" "ecs_execution_policy" {
  name = var.ecs_execution_policy
  # policy = file("${path.module}/policies/ecs-task-execution-policy.json")
  policy = file(var.ecs_execution_policy_file)
  role   = aws_iam_role.ecs_execution_role.id
}

/* role that the Amazon ECS container agent and the Docker daemon can assume */
resource "aws_iam_role" "ecs_task_role" {
  count              = var.create_task_role ? 1 : 0
  name               = var.ecs_task_role
  assume_role_policy = file(var.ecs_task_role_file)

}

resource "aws_iam_role_policy" "ecs_task_policy" {
  count  = var.create_task_role ? 1 : 0
  name   = var.ecs_task_policy
  policy = file(var.ecs_task_policy_file)
  role   = aws_iam_role.ecs_task_role[0].id
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A FARGATE SERVICE TO RUN MY ECS TASK
# ---------------------------------------------------------------------------------------------------------------------

module "fargate_service" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-ecs.git//modules/ecs-service?ref=v1.0.8"
  source = "/github/workspace/modules/ecs/ecs-service"

  service_name    = var.service_name
  ecs_cluster_arn = var.ecs_cluster_arn

  desired_number_of_tasks    = var.desired_number_of_tasks
  container_definitions_path = var.container_definitions_path
  #ecs_task_container_definitions = jsonencode(var.container_definitions)
  launch_type = "FARGATE"

  # Network information is necessary for Fargate, as it required VPC type
  ecs_task_definition_network_mode = "awsvpc"
  ecs_service_network_configuration = {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_task_security_group.id]
    assign_public_ip = var.assign_public_ip
  }

  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html#fargate-tasks-size.
  # Specify memory in MB
  task_cpu    = var.task_cpu
  task_memory = var.task_memory

  existing_ecs_task_execution_role_name = aws_iam_role.ecs_execution_role.name
  existing_ecs_task_role_name           = aws_iam_role.ecs_task_role[0].name

  # Auto scaling
  use_auto_scaling                   = var.use_auto_scaling
  min_number_of_tasks                = var.min_number_of_tasks
  max_number_of_tasks                = var.max_number_of_tasks
  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_controller              = var.deployment_controller

  # Configure ALB
  elb_target_groups = {
    alb = {
      name                  = var.service_name
      container_name        = var.container_name
      container_port        = var.container_port
      protocol              = var.alb_protocol
      health_check_protocol = var.health_check_protocol
    }
  }
  elb_target_group_vpc_id = var.vpc_id
  elb_slow_start          = 30

  # Give the container 30 seconds to boot before having the ALB start checking health
  health_check_grace_period_seconds = 30
  health_check_interval             = var.health_check_interval
  health_check_path                 = var.health_check_path

  enable_ecs_deployment_check      = var.enable_ecs_deployment_check
  deployment_check_timeout_seconds = var.deployment_check_timeout_seconds

  deployment_circuit_breaker = {
    enable   = var.deployment_circuit_breaker_enabled
    rollback = var.deployment_circuit_breaker_rollback
  }

  # Make sure all the ECS cluster and ALB resources are deployed before deploying any ECS service resources. This is
  # also necessary to avoid issues on 'destroy'.
  depends_on = [
    aws_security_group.ecs_task_security_group,
    #    aws_cloudwatch_log_group.cloudwatch_log_group,
    aws_iam_role.ecs_execution_role,
    aws_iam_role.ecs_task_role,
    module.alb

  ]

  # Explicit dependency to aws_alb_listener_rules to make sure listeners are created before deploying any ECS services
  # and avoid any race condition.
  #  listener_rule_ids = [
  #    aws_alb_listener_rule.host_based_example.id,
  #    aws_alb_listener_rule.host_based_path_based_example.id,
  #    aws_alb_listener_rule.path_based_example.id
  #  ]

  service_tags         = var.service_tags
  task_definition_tags = var.task_definition_tags
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A SECURITY GROUP FOR THE AWSVPC TASK NETWORK
# Allow all inbound access on the container port and outbound access
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "ecs_task_security_group" {
  name   = var.security_group_name
  vpc_id = var.vpc_id
  tags   = var.security_group_tags
}

resource "aws_security_group_rule" "allow_outbound_all" {
  security_group_id = aws_security_group.ecs_task_security_group.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_inbound_on_container_port" {
  security_group_id = aws_security_group.ecs_task_security_group.id
  type              = "ingress"
  from_port         = var.from_port
  to_port           = var.to_port
  protocol          = "tcp"
  #  cidr_blocks              = ["0.0.0.0/0"]
  source_security_group_id = module.alb.alb_security_group_id
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN ALB TO ROUTE TRAFFIC ACROSS THE ECS TASKS
# Typically, this would be created once for use with many different ECS Services.
# ---------------------------------------------------------------------------------------------------------------------

module "alb" {
  source = "/github/workspace/modules/aws-load-balancer/alb"

  alb_name        = var.alb_name
  is_internal_alb = var.is_internal_alb

  http_listener_ports                    = var.http_listener_ports
  https_listener_ports_and_ssl_certs_num = var.https_listener_ports_and_ssl_certs_num
  https_listener_ports_and_ssl_certs     = var.https_listener_ports_and_ssl_certs
  ssl_policy                             = var.ssl_policy

  vpc_id         = var.vpc_id
  vpc_subnet_ids = var.public_subnet_ids

  enable_alb_access_logs           = var.enable_alb_access_logs
  alb_access_logs_s3_bucket_name   = var.alb_access_logs_s3_bucket_name
  custom_alb_access_logs_s3_prefix = var.custom_alb_access_logs_s3_prefix

  custom_tags = var.alb_tags
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE ALB LISTENER RULES ASSOCIATED WITH THIS ECS SERVICE
# When an HTTP request is received by the ALB, how will the ALB know to route that request to this particular ECS Service?
# The answer is that we define ALB Listener Rules (https://goo.gl/vQv8oQ) that can route a request to a specific "Target
# Group" that contains "Targets". Each Target is actually an ECS Task (which is really just a Docker container). An ECS Service
# is ultimately made up of zero or more ECS Tasks.
#
# For example purposes, we will define one path-based routing rule and one host-based routing rule.
# ---------------------------------------------------------------------------------------------------------------------

# EXAMPLE OF A HOST-BASED LISTENER RULE
# Host-based Listener Rules are used when you wish to have a single ALB handle requests for both foo.acme.com and
# bar.acme.com. Using a host-based routing rule, the ALB can route each inbound request to the desired Target Group.
resource "aws_alb_listener_rule" "path_https" {
  # Get the Listener ARN associated with port 80 on the ALB
  # In other words, this ALB has a Listener that listens for incoming traffic on port 80. That Listener has a unique
  # Amazon Resource Name (ARN), which we must pass to this rule so it knows which ALB Listener to "attach" to. Fortunately,
  # Our ALB module outputs values like http_listener_arns, https_listener_non_acm_cert_arns, and https_listener_acm_cert_arns
  # so that we can easily look up the ARN by the port number.
  count        = var.create_alb_listener_https_rule ? 1 : 0
  listener_arn = module.alb.https_listener_non_acm_cert_arns["443"]

  priority = 95

  action {
    type             = "forward"
    target_group_arn = module.fargate_service.target_group_arns["alb"]
  }

  condition {
    # host_header {
    #   #      values = ["*.${var.route53_hosted_zone_name}"]
    #   values = ["*.example.com"]
    # }
    path_pattern {
      values = ["/*"]
    }
  }
}

# EXAMPLE OF A PATH-BASED LISTENER RULE
# Path-based Listener Rules are used when you wish to route all requests received by the ALB that match a certain
# "path" pattern to a given ECS Service. This is useful if you have one service that should receive all requests sent
# to /api and another service that receives requests sent to /customers.
resource "aws_alb_listener_rule" "path_based_example" {
  # Get the Listener ARN associated with port 5000 on the ALB
  # In other words, this ALB has a Listener that listens for incoming traffic on port 80. That Listener has a unique
  # Amazon Resource Name (ARN), which we must pass to this rule so it knows which ALB Listener to "attach" to. Fortunately,
  # Our ALB module outputs values like http_listener_arns, https_listener_non_acm_cert_arns, and https_listener_acm_cert_arns
  # so that we can easily look up the ARN by the port number.
  count        = var.create_alb_listener_http_rule ? 1 : 0
  listener_arn = module.alb.http_listener_arns["80"]

  priority = 100

  action {
    type             = "forward"
    target_group_arn = module.fargate_service.target_group_arns["alb"]
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

# resource "aws_alb_listener_rule" "path_based_example_81" {
#   # Get the Listener ARN associated with port 5000 on the ALB
#   # In other words, this ALB has a Listener that listens for incoming traffic on port 80. That Listener has a unique
#   # Amazon Resource Name (ARN), which we must pass to this rule so it knows which ALB Listener to "attach" to. Fortunately,
#   # Our ALB module outputs values like http_listener_arns, https_listener_non_acm_cert_arns, and https_listener_acm_cert_arns
#   # so that we can easily look up the ARN by the port number.
#   count        = var.create_alb_listener_http_rule ? 1 : 0
#   listener_arn = module.alb.http_listener_arns["81"]

#   priority = 100

#   action {
#     type             = "forward"
#     target_group_arn = module.fargate_service.target_group_arns["alb"]
#   }

#   condition {
#     path_pattern {
#       values = ["/*"]
#     }
#   }
# }


# resource "aws_alb_listener_rule" "multiple_path_based_example" {
#   # Get the Listener ARN associated with port 5000 on the ALB
#   # In other words, this ALB has a Listener that listens for incoming traffic on port 80. That Listener has a unique
#   # Amazon Resource Name (ARN), which we must pass to this rule so it knows which ALB Listener to "attach" to. Fortunately,
#   # Our ALB module outputs values like http_listener_arns, https_listener_non_acm_cert_arns, and https_listener_acm_cert_arns
#   # so that we can easily look up the ARN by the port number.
#   for_each = var.listeners
#   # create_alb_listener_http_rule = 1
#   listener_arn = module.alb.http_listener_arns["each.value.port"]

#   priority = 100

#   action {
#       type             = "forward"
#       target_group_arn = module.fargate_service.target_group_arns["alb"] # Replace with your target group ARN
#     }
#   condition {
#     path_pattern {
#       values = ["/*"]
#     }
#   }
# }


#
## EXAMPLE OF A LISTENER RULE THAT USES BOTH PATH-BASED AND HOST-BASED ROUTING CONDITIONS
## This Listener Rule will only route when both conditions are met.
#resource "aws_alb_listener_rule" "host_based_path_based_example" {
#  # Get the Listener ARN associated with port 5000 on the ALB
#  # In other words, this ALB has a Listener that listens for incoming traffic on port 80. That Listener has a unique
#  # Amazon Resource Name (ARN), which we must pass to this rule so it knows which ALB Listener to "attach" to. Fortunately,
#  # Our ALB module outputs values like http_listener_arns, https_listener_non_acm_cert_arns, and https_listener_acm_cert_arns
#  # so that we can easily look up the ARN by the port number.
#  listener_arn = module.alb.http_listener_arns["5000"]
#
#  priority = 105
#
#  action {
#    type             = "forward"
#    target_group_arn = module.fargate_service.target_group_arns["alb"]
#  }
#
#  condition {
#    host_header {
#      values = ["*.acme.com"]
#    }
#  }
#
#  condition {
#    path_pattern {
#      values = ["/static/*"]
#    }
#  }
#}
#
# --------------------------------------------------------------------------------------------------------------------
# CREATE AN EXAMPLE CLOUDWATCH LOG GROUP
# --------------------------------------------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "cloudwatch_log_group" {
  name = var.cloudwatch_log_group_name
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE CLOUDWATCH ALARMS TO TRIGGER OUR AUTOSCALING POLICIES BASED ON CPU UTILIZATION
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "high_cpu_usage" {
  alarm_name        = "${var.service_name}-high-cpu-usage"
  alarm_description = "An alarm that triggers auto scaling if the CPU usage for service ${var.service_name} gets too high"
  namespace         = "AWS/ECS"
  metric_name       = "CPUUtilization"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.service_name
  }

  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  period              = "60"
  statistic           = "Average"
  threshold           = "90"
  unit                = "Percent"
  alarm_actions       = [aws_appautoscaling_policy.scale_out.arn]
}

resource "aws_cloudwatch_metric_alarm" "low_cpu_usage" {
  alarm_name        = "${var.service_name}-low-cpu-usage"
  alarm_description = "An alarm that triggers auto scaling if the CPU usage for service ${var.service_name} gets too low"
  namespace         = "AWS/ECS"
  metric_name       = "CPUUtilization"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.service_name
  }

  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  period              = "60"
  statistic           = "Average"
  threshold           = "70"
  unit                = "Percent"
  alarm_actions       = [aws_appautoscaling_policy.scale_in.arn]
}


# ---------------------------------------------------------------------------------------------------------------------
# CREATE AUTO SCALING POLICIES TO SCALE THE NUMBER OF ECS TASKS UP AND DOWN IN RESPONSE TO LOAD
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_appautoscaling_policy" "scale_out" {
  name        = "${var.service_name}-scale-out"
  resource_id = module.fargate_service.service_app_autoscaling_target_resource_id

  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}

resource "aws_appautoscaling_policy" "scale_in" {
  name        = "${var.service_name}-scale-in"
  resource_id = module.fargate_service.service_app_autoscaling_target_resource_id

  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}
