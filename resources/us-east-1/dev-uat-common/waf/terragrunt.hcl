terraform {
  source = "../../../../modules/waf_web_acl"
}

include "root" {
  path   = find_in_parent_folders()
  expose = true
}

include "envcommon" {
  path   = "${dirname(find_in_parent_folders())}/_envcommon/waf_web_acl/waf.hcl"
  expose = true
}


#locals {
#  dev_state = jsondecode(run_cmd("bash", "${get_terragrunt_dir()}/get_state.sh", "-b", "epi-stg-terra-tf-state", "-k", "new/resources/us-east-1/dev/ecs-service/terraform.tfstate"))
#  #uat_state = jsondecode(run_cmd("./get_state.sh", "-b", "epi-stg-terra-tf-state", "-k", "new/resources/us-east-1/uat/ecs-service/terraform.tfstate"))
#}


inputs = {
  scope = "REGIONAL"
  alb_arns = [dependency.dev_service_arn.alb_arn]
  rules = [
    {
      name   = "AWSManagedRulesAmazonIpReputationList"
      rule_id = "AWSManagedRulesAmazonIpReputationList"
    },
    {
      name   = "AWSManagedRulesAnonymousIpList"
      rule_id = "AWSManagedRulesAnonymousIpList"
    },
    {
      name   = "AWSManagedRulesCommonRuleSet"
      rule_id = "AWSManagedRulesCommonRuleSet"
    },
    {
      name   = "AWSManagedRulesKnownBadInputsRuleSet"
      rule_id = "AWSManagedRulesKnownBadInputsRuleSet"
    },
    {
      name   = "AWSManagedRulesLinuxRuleSet"
      rule_id = "AWSManagedRulesLinuxRuleSet"
    },
    {
      name   = "AWSManagedRulesSQLiRuleSet"
      rule_id = "AWSManagedRulesSQLiRuleSet"
    }
  ]
}

dependency "dev_service_arn" {
  config_path = "${get_terragrunt_dir()}/../../dev/ecs-service"

  mock_outputs = {
    alb_arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/my-app-loadbalancer/50dc6c495c0c9188"
  }
}