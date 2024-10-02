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
  alb_arns = [dependency.dev_service_arn.outputs.alb_arn]
  rules = [
    {
      name        = "AWSManagedRulesAmazonIpReputationList"
      rule_id     = "AWSManagedRulesAmazonIpReputationList"
      priority    = 2
    },
    {
      name        = "AWSManagedRulesAnonymousIpList"
      rule_id     = "AWSManagedRulesAnonymousIpList"
      priority    = 3
      override_action = "count"
      excluded_rules  = ["HostingProviderIpList"]
    },
    {
      name        = "AWSManagedRulesCommonRuleSet"
      rule_id     = "AWSManagedRulesCommonRuleSet"
      priority    = 4
    },
    {
      name        = "AWSManagedRulesKnownBadInputsRuleSet"
      rule_id     = "AWSManagedRulesKnownBadInputsRuleSet"
      priority    = 5
    },
    {
      name        = "AWSManagedRulesLinuxRuleSet"
      rule_id     = "AWSManagedRulesLinuxRuleSet"
      priority    = 6
    },
    {
      name        = "AWSManagedRulesSQLiRuleSet"
      rule_id     = "AWSManagedRulesSQLiRuleSet"
      priority    = 7
    },
    {
      name        = "Allow-Application-traffic"
      priority    = 0
      metric_name = "Allow-Application-traffic"
      regex_match_statement = [{
        regex_string = "\\/v1\\/events\\/ready-for-coding|\\/v1\\/healthcheck|\\/docs|\\/v1\\/docs\\/|\\/v1|\\/openapi.json"
        text_transformations = [{
          priority = 0
          type     = "NONE"
        }]
      }]
    },
    {
      name        = "Allow-git-pipeline"
      priority    = 1
      metric_name = "Allow-git-pipeline"
      and_statement = [{
        label_match_statement_scope = "LABEL"
        label_match_statement_key   = "awswaf:managed:aws:anonymous-ip-list:HostingProviderIPList"
        not_statement = {
          regex_string = "\\/v1\\/events\\/ready-for-coding|\\/v1\\/healthcheck"
          text_transformations = [{
            priority = 0
            type     = "NONE"
          }]
        }
      }]
    }
  ]
}


dependency "dev_service_arn" {
  config_path = "${get_terragrunt_dir()}/../../dev/ecs-service"

  mock_outputs = {
    alb_arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/my-app-loadbalancer/50dc6c495c0c9188"
  }
}