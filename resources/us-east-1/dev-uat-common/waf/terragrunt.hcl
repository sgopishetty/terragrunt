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


locals {
  dev_state = jsondecode(run_cmd("./get_state.sh", "-b", "epi-stg-terra-tf-state", "-k", "new/resources/us-east-1/dev/ecs-service/terraform.tfstate"))
  #uat_state = jsondecode(run_cmd("./get_state.sh", "-b", "epi-stg-terra-tf-state", "-k", "new/resources/us-east-1/uat/ecs-service/terraform.tfstate"))
}


inputs = {
  name = "dev_uat_waf_acl"
  scope = "REGIONAL"
  alb_arn = [local.dev_state.alb_arn]
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