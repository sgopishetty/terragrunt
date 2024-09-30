terraform {
  source = "../../../modules/waf_web_acl"
}

include "root" {
  path   = find_in_parent_folders()
  expose = true
}

include "envcommon" {
  path   = "${dirname(find_in_parent_folders())}/_envcommon/waf_web_acl/waf.hcl"
  expose = true
}

dependency "dev_s3_state" {
  config = {
    backend = "s3"
    config = {
      bucket = "epi-stg-terra-tf-state"
      key    = "new/resources/us-east-1/dev/ecs-service"
      region = "us-east-1"
    }
  }
}


inputs = {
  name = "dev_uat_waf_acl"
  scope = "REGIONAL"
  alb_arn = [dependency.dev_s3_state.outputs.alb_arn]
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