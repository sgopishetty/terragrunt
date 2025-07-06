
terraform {
  source = "../../../../modules/subnets"
}

include "root" {
  path   = find_in_parent_folders()
  expose = true
}

include "envcommon" {
  path   = "${dirname(find_in_parent_folders())}/_envcommon/subnets/subnet.hcl"
  expose = true
}

inputs = {
  vpc_id               = "vpc-05702d6dd207b8cb4"
  public_subnet_cidrs  = ["172.31.96.0/22", "172.31.100.0/22"]
  private_subnet_cidrs = ["172.31.104.0/22", "172.31.108.0/22"]
  #nat_gateway_id       = "nat-0896997651e64248d"
  internet_gateway_id  = "igw-015b6298688fd0f01"
}