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

}
