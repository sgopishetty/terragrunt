
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
  vpc_id               = "vpc-06a51eb1b61b77c3f"
  public_subnet_cidrs  = ["172.31.96.0/22", "172.31.100.0/22"]
  private_subnet_cidrs = ["172.31.104.0/22", "172.31.108.0/22"]
  #nat_gateway_id       = "nat-0896997651e64248d"
  internet_gateway_id  = "igw-046c5e60addebbee2"
}