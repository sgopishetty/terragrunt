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
      name   = "AWSManagedRulesAmazonIpReputationList"
      rule_id = "AWSManagedRulesAmazonIpReputationList"
      priority = 1
    },
    {
      name   = "AWSManagedRulesCommonRuleSet"
      rule_id = "AWSManagedRulesCommonRuleSet"
      priority = 2
    },
    {
      name   = "AWSManagedRulesKnownBadInputsRuleSet"
      rule_id = "AWSManagedRulesKnownBadInputsRuleSet"
      priority = 5
    },
    {
      name   = "AWSManagedRulesLinuxRuleSet"
      rule_id = "AWSManagedRulesLinuxRuleSet"
      priority = 6
    },
    {
      name   = "AWSManagedRulesSQLiRuleSet"
      rule_id = "AWSManagedRulesSQLiRuleSet"
      priority = 7
    }
  ]
  # Custom rule as JSON
  custom_rules_json = [
    {
      "Name"     : "AWS-AWSManagedRulesAnonymousIpList",
      "Priority" : 3,
      "Statement" : {
        "ManagedRuleGroupStatement" : {
          "VendorName" : "AWS",
          "Name"       : "AWSManagedRulesAnonymousIpList",
          "RuleActionOverrides" : [
            {
              "Name" : "HostingProviderIPList",
              "ActionToUse" : {
                "Count" : {}
              }
            }
          ]
        }
      },
      "OverrideAction" : {
        "None" : {}
      },
      "VisibilityConfig" : {
        "SampledRequestsEnabled"   : true,
        "CloudWatchMetricsEnabled" : true,
        "MetricName"               : "AWS-AWSManagedRulesAnonymousIpList"
      }
    }
  ]
   # Regex rules
  custom_regex_rules_json = [
    {
      Name     = "Allow-Application-traffic"
      Priority = 0
      Statement = {
        NotStatement = {
          Statement = {
            RegexMatchStatement = {
              RegexString = "\\/v1\\/events\\/ready-for-coding|\\/v1\\/healthcheck|\\/docs|\\/v1\\/docs\\/|\\/v1|\\/openapi.json"
              FieldToMatch = {
                UriPath = {}
              }
              TextTransformations = [
                {
                  Priority = 0
                  Type     = "NONE"
                }
              ]
            }
          }
        }
      }
      Action = {
        Block = {}
      }
      VisibilityConfig = {
        SampledRequestsEnabled   = true
        CloudWatchMetricsEnabled = true
        MetricName               = "Allow-Application-traffic"
      }
    }
  ]

  git_waf_rules = [
    {
      Name        = "Allow-git-pipeline"
      Priority    = 4
      Statements  = [
        {
          LabelScope  = "LABEL"
          LabelKey    = "awswaf:managed:aws:anonymous-ip-list:HostingProviderIPList"
          RegexString = ""
        },
        {
          LabelScope  = ""
          LabelKey    = ""
          RegexString = "\\/v1\\/events\\/ready-for-coding|\\/v1\\/healthcheck"
        }
      ]
      MetricName  = "Allow-git-pipeline"
    }
  ]
   
  waf_bot_control_rules = [
  {
  "Name": "AWS-AWSManagedRulesBotControlRuleSet",
  "Priority": 9,
  "Statement": {
    "ManagedRuleGroupStatement": {
      "VendorName": "AWS",
      "Name": "AWSManagedRulesBotControlRuleSet",
      "ManagedRuleGroupConfigs": [
        {
          "AWSManagedRulesBotControlRuleSet": {
            "InspectionLevel": "COMMON"
          }
        }
      ],
      "RuleActionOverrides": [
        {
          "Name": "CategoryAdvertising",
          "ActionToUse": {
            "Count": {}
          }
        },
        {
          "Name": "CategoryArchiver",
          "ActionToUse": {
            "Count": {}
          }
        },
        {
          "Name": "CategoryContentFetcher",
          "ActionToUse": {
            "Count": {}
          }
        },
        {
          "Name": "CategoryEmailClient",
          "ActionToUse": {
            "Count": {}
          }
        },
        {
          "Name": "CategoryHttpLibrary",
          "ActionToUse": {
            "Count": {}
          }
        },
        {
          "Name": "CategoryLinkChecker",
          "ActionToUse": {
            "Count": {}
          }
        },
        {
          "Name": "CategoryMiscellaneous",
          "ActionToUse": {
            "Count": {}
          }
        },
        {
          "Name": "CategoryMonitoring",
          "ActionToUse": {
            "Count": {}
          }
        },
        {
          "Name": "CategoryScrapingFramework",
          "ActionToUse": {
            "Count": {}
          }
        },
        {
          "Name": "CategorySearchEngine",
          "ActionToUse": {
            "Count": {}
          }
        },
        {
          "Name": "CategorySecurity",
          "ActionToUse": {
            "Count": {}
          }
        },
        {
          "Name": "CategorySeo",
          "ActionToUse": {
            "Count": {}
          }
        },
        {
          "Name": "CategorySocialMedia",
          "ActionToUse": {
            "Count": {}
          }
        },
        {
          "Name": "CategoryAI",
          "ActionToUse": {
            "Count": {}
          }
        },
        {
          "Name": "SignalAutomatedBrowser",
          "ActionToUse": {
            "Count": {}
          }
        },
        {
          "Name": "SignalKnownBotDataCenter",
          "ActionToUse": {
            "Count": {}
          }
        },
        {
          "Name": "SignalNonBrowserUserAgent",
          "ActionToUse": {
            "Count": {}
          }
        }
      ]
      }
    },
     "OverrideAction": {
    "None": {}
  },
  "VisibilityConfig": {
    "SampledRequestsEnabled": true,
    "CloudWatchMetricsEnabled": true,
    "MetricName": "AWS-AWSManagedRulesBotControlRuleSet"
  }
  }

]
  

}


dependency "dev_service_arn" {
  config_path = "${get_terragrunt_dir()}/../../dev/ecs-service"

  mock_outputs = {
    alb_arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/my-app-loadbalancer/50dc6c495c0c9188"
  }
}