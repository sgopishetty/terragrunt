resource "aws_wafv2_web_acl" "this" {
  name  = var.name
  scope = var.scope

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = var.name
    sampled_requests_enabled   = true
  }

  # Loop over predefined WAF rules (like managed rule groups)
  dynamic "rule" {
    for_each = var.rules
    content {
      name     = rule.value.name
      priority = index(var.rules, rule.value)

      override_action {
        none {}  # Set to 'block {}' to block instead of count
      }

      statement {
        managed_rule_group_statement {
          vendor_name = "AWS"
          name        = rule.value.rule_id
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = rule.value.name
        sampled_requests_enabled   = true
      }
    }
  }

  # Loop over custom JSON-based rules, including RuleActionOverrides
  dynamic "rule" {
    for_each = var.custom_rules_json
    content {
      name     = rule.value["Name"]
      priority = rule.value["Priority"]

      statement {
        managed_rule_group_statement {
          vendor_name = rule.value["Statement"]["ManagedRuleGroupStatement"]["VendorName"]
          name        = rule.value["Statement"]["ManagedRuleGroupStatement"]["Name"]

          # RuleActionOverrides handling
          dynamic "rule_action_override" {
            for_each = lookup(rule.value["Statement"]["ManagedRuleGroupStatement"], "RuleActionOverrides", [])
            content {
              name = rule_action_override.value["Name"]

              action_to_use {
                count {} # Assuming 'Count' override as per your input
              }
            }
          }
        }
      }

      override_action {
        none {}  # Can modify this if you want to override to 'block {}'
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = rule.value["VisibilityConfig"]["MetricName"]
        sampled_requests_enabled   = rule.value["VisibilityConfig"]["SampledRequestsEnabled"]
      }
    }
  }

  # Loop over custom regex-based rules
  dynamic "rule" {
    for_each = var.custom_regex_rules_json
    content {
      name     = rule.value["Name"]
      priority = rule.value["Priority"]

      statement {
        not_statement {
          statement {
            regex_match_statement {
              regex_string = rule.value["Statement"]["NotStatement"]["Statement"]["RegexMatchStatement"]["RegexString"]

              field_to_match {
                uri_path {}
              }

              dynamic "text_transformation" {
                for_each = rule.value["Statement"]["NotStatement"]["Statement"]["RegexMatchStatement"]["TextTransformations"]
                content {
                  priority = text_transformation.value["Priority"]
                  type     = text_transformation.value["Type"]
                }
              }
            }
          }
        }
      }

      action {
        block {}
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = rule.value["VisibilityConfig"]["MetricName"]
        sampled_requests_enabled   = rule.value["VisibilityConfig"]["SampledRequestsEnabled"]
      }
    }
  }
  
  # Add Git pipeline rules
  dynamic "rule" {
    for_each = var.git_pipeline_rules_json
    content {
      name     = rule.value.Name
      priority = rule.value.Priority

      statement {
        and_statement {
          statement {
            label_match_statement {
              scope = rule.value.Statement.AndStatement.Statements[0].LabelMatchStatement.Scope
              key   = rule.value.Statement.AndStatement.Statements[0].LabelMatchStatement.Key
            }
          }

          statement {
            not_statement {
              statement {
                regex_match_statement {
                  regex_string = rule.value.Statement.AndStatement.Statements[1].NotStatement.Statement.RegexMatchStatement.RegexString
                  field_to_match {
                    uri_path {}
                  }
                 dynamic "text_transformation" {
                  for_each = rule.value.Statement.AndStatement.Statements[1].NotStatement.Statement.RegexMatchStatement.TextTransformations
                  content {
                    priority = text_transformation.value.Priority
                    type     = text_transformation.value.Type
                  }
                }
                }
              }
            }
          }
        }
      }

      action {
        block {}
      }

      visibility_config {
        cloudwatch_metrics_enabled = rule.value.VisibilityConfig.SampledRequestsEnabled
        metric_name                = rule.value.VisibilityConfig.MetricName
        sampled_requests_enabled    = rule.value.VisibilityConfig.CloudWatchMetricsEnabled
      }
    }
  }


}





# Association between WAF and ALB
resource "aws_wafv2_web_acl_association" "this" {
  for_each    = toset(var.alb_arns) # Iterate over the list of ALB ARNs
  resource_arn = each.value          # ARN of the ALB to associate the Web ACL with
  web_acl_arn  = aws_wafv2_web_acl.this.arn
}