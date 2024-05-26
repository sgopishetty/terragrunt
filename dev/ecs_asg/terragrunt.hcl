include "root" {
  path = find_in_parent_folders()
}

terraform {
  source  = "git@github.com:terraform-aws-modules/terraform-aws-autoscaling.git"
}

locals {
  base64_user_data = "IyEvYmluL2Jhc2gKY2F0IDw8RU9GID4+IC9ldGMvZWNzL2Vjcy5jb25maWcKRUNTX0NMVVNURVI9ZGVtbwpFQ1NfTE9HTEVWRUw9ZGVidWcKRUNTX0VOQUJMRV9UQVNLX0lBTV9ST0xFPXRydWUKRU9G"
}

inputs = {
  name                 = "asg-ex-1"
  min_size             = 1
  max_size             = 3
  desired_capacity     = 2
  vpc_zone_identifier  = ["subnet-062c00f91809492f9", "subnet-00df360198eb45c76"]
  image_id             = "ami-01622b740380d90fe"
  instance_type        = "t2.nano"
  security_groups      = ["sg-0f26b1f964899aa0d"]
  create_iam_instance_profile = "false"
  iam_instance_profile_arn    = "arn:aws:iam::590184036010:instance-profile/Asg_Role"
  user_data                   = local.base64_user_data
  service_role                = "arn:aws:iam::590184036010:role/aws-service-role/ecs.amazonaws.com/AWSServiceRoleForECS"
  protect_from_scale_in = true
  key_name              = "test"
}