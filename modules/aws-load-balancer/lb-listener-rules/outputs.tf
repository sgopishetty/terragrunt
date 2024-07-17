output "lb_listener_rule_forward_arns" {
  description = "The ARNs of the rules of type forward. The key is the same key of the rule from the `forward_rules` variable."
  value       = { for name, listener_rule in aws_lb_listener_rule.forward : name => listener_rule.arn }
}

output "lb_listener_rule_forward_with_ignore_target_groups_arns" {
  description = "The ARNs of the rules of type forward. The key is the same key of the rule from the `forward_rules` variable."
  value       = { for name, listener_rule in aws_lb_listener_rule.forward_with_ignore_target_groups : name => listener_rule.arn }
}

output "lb_listener_rule_fixed_response_arns" {
  description = "The ARNs of the rules of type fixed-response. The key is the same key of the rule from the `fixed_response_rules` variable."
  value       = { for name, listener_rule in aws_lb_listener_rule.fixed_response : name => listener_rule.arn }
}

output "lb_listener_rule_redirect_arns" {
  description = "The ARNs of the rules of type redirect. The key is the same key of the rule from the `redirect_rules` variable."
  value       = { for name, listener_rule in aws_lb_listener_rule.redirect : name => listener_rule.arn }
}