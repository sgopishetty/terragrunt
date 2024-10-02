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

  dynamic "rule" {
    for_each = var.rules
    content {
      name     = rule.value.name
      priority = rule.value.priority

      statement {
        # Handle managed rule group statements
        dynamic "managed_rule_group_statement" {
          for_each = lookup(rule.value, "rule_id", null) != null ? [rule.value] : []
          content {
            vendor_name = "AWS"
            name        = managed_rule_group_statement.value.rule_id

            # Logic to exclude specific sub-rules
            dynamic "excluded_rule" {
              for_each = lookup(managed_rule_group_statement.value, "excluded_rules", [])
              content {
                name = excluded_rule.value  # Name of the sub-rule to exclude
              }
            }
          }
        }

        # Handle custom regex match statements
        dynamic "regex_match_statement" {
          for_each = lookup(rule.value, "regex_match_statement", [])
          content {
            regex_string = regex_match_statement.value.regex_string

            field_to_match {
              uri_path {}
            }

            # Dynamically handle the required text_transformation block
            dynamic "text_transformation" {
              for_each = regex_match_statement.value.text_transformations
              content {
                priority = text_transformation.value.priority
                type     = text_transformation.value.type
              }
            }
          }
        }

         # Handle custom AndStatement
        dynamic "and_statement" {
          for_each = lookup(rule.value, "and_statement", [])
          content {
            statement {
              label_match_statement {
                scope = and_statement.value.label_match_statement_scope
                key   = and_statement.value.label_match_statement_key
              }

              not_statement {
                statement {
                  regex_match_statement {
                    regex_string = and_statement.value.not_statement.regex_string

                    field_to_match {
                      uri_path {}
                    }

                    # Dynamically handle the required text_transformation block
                    dynamic "text_transformation" {
                      for_each = and_statement.value.not_statement.text_transformations
                      content {
                        priority = text_transformation.value.priority
                        type     = text_transformation.value.type
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }

      # Override action block
      dynamic "override_action" {
        for_each = rule.value.override_action != null ? [rule.value.override_action] : []
        content {
          count {}  # Override action to count
        }
      }

      action {
        block {}  # Default action is block
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = rule.value.metric_name
        sampled_requests_enabled   = true
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