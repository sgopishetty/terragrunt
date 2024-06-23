terraform {
  source = "../../../../modules/ecs-cluster"
}

include "root" {
  path   = find_in_parent_folders()
  expose = true
}

include "envcommon" {
  path   = "${dirname(find_in_parent_folders())}/_envcommon/ecs-cluster/cluster.hcl"
  expose = true
}

inputs = {
  vpc_id               = "vpc-04706f24c5d6cadc6"
  cluster_min_size     = 2
  cluster_max_size = 5
  cluster_instance_ami = "ami-01622b740380d90fe"
  cluster_instance_type = "t2.nano"
  cluster_instance_keypair_name = "test"
  vpc_subnet_ids = dependency.subnets.private_subnets
  allow_ssh_from_cidr_blocks = ["0.0.0.0/0"]
  
}

dependency "subnets" {
  config_path = "${get_terragrunt_dir()}/../subnets"

  mock_outputs = {
    private_subnets = ["known-after-apply"]
  }
}