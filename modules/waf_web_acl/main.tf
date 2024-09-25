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
}

# Association between WAF and ALB
resource "aws_wafv2_web_acl_association" "this" {
  resource_arn = var.alb_arn  # ARN of the ALB to associate the Web ACL with
  web_acl_arn  = aws_wafv2_web_acl.this.arn
}