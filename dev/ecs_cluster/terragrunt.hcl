include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "git@github.com:terraform-aws-modules/terraform-aws-ecs.git"
}

inputs = {
    cluster_name = "demo"
    # Capacity provider - autoscaling groups
    default_capacity_provider_use_fargate = false
    create_task_exec_iam_role = false
    autoscaling_capacity_providers = {
    # On-demand instances
       ex_1 = {
         auto_scaling_group_arn         = dependency.asg.outputs.autoscaling_group_arn
         managed_termination_protection = "ENABLED"
   
         managed_scaling = {
           maximum_scaling_step_size = 5
           minimum_scaling_step_size = 1
           status                    = "ENABLED"
           target_capacity           = 60
         }
   
         default_capacity_provider_strategy = {
           weight = 60
           base   = 20
         }
       }
    }
}

dependency "asg" {
  config_path = "../ecs_asg"
  mock_outputs = {
    autoscaling_group_arn = "arn:aws:autoscaling:us-west-2:123456789012:autoScalingGroup:abc12345-6789-abcd-1234-56789abcdef:autoScalingGroupName/my-auto-scaling-group"
  }
}