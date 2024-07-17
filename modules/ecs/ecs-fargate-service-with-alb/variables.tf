# ---------------------------------------------------------------------------------------------------------------------
# ENVIRONMENT VARIABLES
# Define these secrets as environment variables
# ---------------------------------------------------------------------------------------------------------------------

# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These variables are expected to be passed in by the operator
# ---------------------------------------------------------------------------------------------------------------------

variable "aws_region" {
  description = "The AWS region in which all resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "service_name" {
  description = "The name of the Fargate service to run"
  type        = string
  default     = "fargate-alb"
}

variable "desired_number_of_tasks" {
  description = "How many instances of the container to schedule on the cluster"
  type        = number
  default     = 3
}

variable "container_name" {
  description = "The name of the container in the ECS Task Definition. This is only useful if you have multiple containers defined in the ECS Task Definition. Otherwise, it doesn't matter."
  type        = string
  default     = "webapp"
}

variable "container_port" {
  type    = number
  default = 80
}

variable "from_port" {
  description = "The port on which the host and container listens on for HTTP requests"
  type        = number
  default     = 80
}

variable "to_port" {
  description = "The port on which the host and container listens on for HTTP requests"
  type        = number
  default     = 80
}

variable "enable_ecs_deployment_check" {
  description = "Whether or not to enable ECS deployment check. This requires installation of the check-ecs-service-deployment binary. See the ecs-deploy-check-binaries module README for more information."
  type        = bool
  default     = false
}

variable "deployment_check_timeout_seconds" {
  description = "Number of seconds to wait for the ECS deployment check before giving up as a failure."
  type        = number
  default     = 600
}

variable "container_command" {
  description = "Command to run on the container. Set this to see what happens when a container is set up to exit on boot"
  type        = list(string)
  default     = []
  # Related issue: https://github.com/hashicorp/packer/issues/7578
  # Example:
  # default = ["-c", "/bin/sh", "echo", "Hello"]
}

variable "container_boot_delay_seconds" {
  description = "Delay the boot up sequence of the container by this many seconds. Use this to test various booting scenarios (e.g crash container after a long boot) against the deployment check."
  type        = number
  default     = 0
}

variable "deployment_circuit_breaker_enabled" {
  description = "Set to 'true' to prevent the task from attempting to continuously redeploy after a failed health check."
  type        = bool
  default     = true
}

variable "deployment_circuit_breaker_rollback" {
  description = "Set to 'true' to also automatically roll back to the last successful deployment."
  type        = bool
  default     = true
}

variable "health_check_interval" {
  description = "The approximate amount of time, in seconds, between health checks of an individual Target. Minimum value 5 seconds, Maximum value 300 seconds."
  type        = number
  default     = 60
}

variable "vpc_id" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecs_execution_role" {
  type = string
}

variable "ecs_execution_policy" {
  type = string
}

variable "ecs_cluster_arn" {
  type = string
}

# variable "container_definitions" {
#   type = any
# }

variable "private_subnet_ids" {
  type = any
}

variable "public_subnet_ids" {
  type = any
}

variable "assign_public_ip" {
  type = bool
}

variable "task_cpu" {
  type = string
}

variable "task_memory" {
  type = string
}

variable "security_group_name" {
  type = string
}

variable "cloudwatch_log_group_name" {
  type = string
}

variable "service_tags" {
  description = "A map of tags to apply to the ECS service. Each item in this list should be a map with the parameters key and value."
  type        = map(string)
  default     = {}
  # Example:
  #   {
  #     key1 = "value1"
  #     key2 = "value2"
  #   }
}

variable "task_definition_tags" {
  description = "A map of tags to apply to the task definition. Each item in this list should be a map with the parameters key and value."
  type        = map(string)
  default     = {}
  # Example:
  #   {
  #     key1 = "value1"
  #     key2 = "value2"
  #   }
}

variable "security_group_tags" {
  description = "A map of tags to apply to the ECS security group. Each item in this list should be a map with the parameters key and value."
  type        = map(string)
  default     = {}
  # Example:
  #   {
  #     key1 = "value1"
  #     key2 = "value2"
  #   }
}

variable "alb_tags" {
  description = "A map of tags to apply to the ALB. Each item in this list should be a map with the parameters key and value."
  type        = map(string)
  default     = {}
  # Example:
  #   {
  #     key1 = "value1"
  #     key2 = "value2"
  #   }
}

# Autoscaling configuration

variable "use_auto_scaling" {
  description = "Set this variable to 'true' to tell the ECS service to ignore var.desired_number_of_tasks and instead use auto scaling to determine how many Tasks of this service to run."
  type        = bool
  default     = false
}

variable "min_number_of_tasks" {
  description = "The minimum number of ECS Task instances of the ECS Service to run. Auto scaling will never scale in below this number. Must be set when var.use_auto_scaling is true."
  type        = number
  default     = null
}

variable "max_number_of_tasks" {
  description = "The maximum number of ECS Task instances of the ECS Service to run. Auto scaling will never scale out above this number. Must be set when var.use_auto_scaling is true."
  type        = number
  default     = null
}

variable "deployment_maximum_percent" {
  description = "The upper limit, as a percentage of var.desired_number_of_tasks, of the number of running tasks that can be running in a service during a deployment. Setting this to more than 100 means that during deployment, ECS will deploy new instances of a Task before undeploying the old ones."
  type        = number
  default     = 200
}

variable "deployment_minimum_healthy_percent" {
  description = "The lower limit, as a percentage of var.desired_number_of_tasks, of the number of running tasks that must remain running and healthy in a service during a deployment. Setting this to less than 100 means that during deployment, ECS may undeploy old instances of a Task before deploying new ones."
  type        = number
  default     = 100
}

variable "deployment_controller" {
  description = "Type of deployment controller, possible values: CODE_DEPLOY, ECS, EXTERNAL"
  type        = string
  default     = null
}

# ALB configuration
variable "alb_protocol" {
  type    = string
  default = "HTTP"
}

variable "health_check_protocol" {
  type    = string
  default = "HTTP"
}

variable "alb_name" {
  type = string
}

variable "is_internal_alb" {
  type    = string
  default = false
}

variable "http_listener_ports" {
  type = list(string)
  default = []
}

variable "ssl_policy" {
  type    = string
  default = "ELBSecurityPolicy-TLS-1-1-2017-01"
}

variable "enable_alb_access_logs" {
  description = "Set to true to enable the ALB to log all requests. Ideally, this variable wouldn't be necessary, but because Terraform can't interpolate dynamic variables in counts, we must explicitly include this. Enter true or false."
  type        = bool
  default     = false
}

variable "alb_access_logs_s3_bucket_name" {
  description = "The S3 Bucket name where ALB logs should be stored. If left empty, no ALB logs will be captured. Tip: It's easiest to create the S3 Bucket using the Gruntwork Module https://github.com/gruntwork-io/terraform-aws-monitoring/tree/main/modules/logs/load-balancer-access-logs."
  type        = string
  default     = null
}

variable "custom_alb_access_logs_s3_prefix" {
  description = "Prefix to use for access logs to create a sub-folder in S3 Bucket name where ALB logs should be stored. Only used if var.enable_custom_alb_access_logs_s3_prefix is true."
  type        = string
  default     = null
}

variable "container_definitions_path" {
  type = string
}

variable "health_check_path" {
  description = "The ping path that is the destination on the Targets for health checks. Required when using ALBs."
  type        = string
  default     = "/"
}
variable "https_listener_ports_and_ssl_certs_num" {
  description = "The number of elements in var.https_listener_ports_and_ssl_certs. We should be able to compute this automatically, but due to a Terraform limitation, if there are any dynamic resources in var.https_listener_ports_and_ssl_certs, then we won't be able to: https://github.com/hashicorp/terraform/pull/11482"
  type        = number
  default     = 0
}
variable "https_listener_ports_and_ssl_certs" {
  description = "A list of the ports for which an HTTPS Listener should be created on the ALB. Each item in the list should be a map with the keys 'port', the port number to listen on, and 'tls_arn', the Amazon Resource Name (ARN) of the SSL/TLS certificate to associate with the Listener to be created. If your certificate is issued by the Amazon Certificate Manager (ACM), specify var.https_listener_ports_and_acm_ssl_certs instead. Tip: When you define Listener Rules for these Listeners, be sure that, for each Listener, at least one Listener Rule  uses the '*' path to ensure that every possible request path for that Listener is handled by a Listener Rule. Otherwise some requests won't route to any Target Group."
  type = list(object({
    port    = number
    tls_arn = string
  }))
  default = []

  # Example:
  # default = [
  #   {
  #     port = 443
  #     tls_arn = "arn:aws:iam::123456789012:server-certificate/ProdServerCert"
  #   }
  # ]
}

variable "create_alb_listener_https_rule" {
  description = "Enable ALB listener rule"
  type        = bool
  default     = false
}

variable "create_alb_listener_http_rule" {
  description = "Enable ALB listener rule"
  type        = bool
  default     = false
}

variable "ecs_execution_role_file" {
  type = string
}

variable "ecs_execution_policy_file" {
  type = string
}

variable "ecs_task_role_file" {
  type = string
}

variable "ecs_task_policy_file" {
  type = string
}

variable "ecs_task_role" {
  type = string
}

variable "ecs_task_policy" {
  type = string
}

variable "create_task_role" {
  type    = bool
  default = true
}

variable "listeners" {
  type = map(object({
    port       = string
    # Additional listener configuration fields can be added here
  }))
  default = {
    http = {
      port       = "80"
    }
    https = {
      port       = "81"
    }
    # Add more listener configurations as needed
  }
}


