# ---------------------------------------------------------------------------------------------------------------------
# CONFIGURE ROUTING RULES FOR THIS SERVICE
# Below, we configure the LB to send requests that come in on certain ports (the listener_arn) and certain paths or
# domain names (the condition block) to the Target Group.
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.75.1, < 6.0.0"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE FORWARD RULES
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_lb_listener_rule" "forward" {
  for_each = { for key, val in module.forward_rules_map.rules_map : key => val if var.ignore_changes_to_target_groups == false }

  listener_arn = each.value.listener_arn
  priority     = each.value.priority

  dynamic "action" {
    for_each = each.value.authenticate_oidc != null ? ["once"] : []

    content {
      type = "authenticate-oidc"

      authenticate_oidc {
        authorization_endpoint = each.value.authenticate_oidc.authorization_endpoint
        client_id              = each.value.authenticate_oidc.client_id
        client_secret          = each.value.authenticate_oidc.client_secret
        issuer                 = each.value.authenticate_oidc.issuer
        token_endpoint         = each.value.authenticate_oidc.token_endpoint
        user_info_endpoint     = each.value.authenticate_oidc.user_info_endpoint

        on_unauthenticated_request = try(each.value.authenticate_oidc.on_unauthenticated_request, null)
        scope                      = try(each.value.authenticate_oidc.scope, null)
        session_cookie_name        = try(each.value.authenticate_oidc.session_cookie_name, null)
        session_timeout            = try(each.value.authenticate_oidc.session_timeout, null)

        authentication_request_extra_params = try(each.value.authenticate_oidc.authentication_request_extra_params, null)
      }
    }
  }

  dynamic "action" {
    for_each = each.value.authenticate_cognito != null ? ["once"] : []

    content {
      type = "authenticate-cognito"

      authenticate_cognito {
        user_pool_arn       = each.value.authenticate_cognito.user_pool_arn
        user_pool_client_id = each.value.authenticate_cognito.user_pool_client_id
        user_pool_domain    = each.value.authenticate_cognito.user_pool_domain

        authentication_request_extra_params = try(each.value.authenticate_cognito.on_unauthenticated_request, null)
        on_unauthenticated_request          = try(each.value.authenticate_cognito.on_unauthenticated_request, null)
        scope                               = try(each.value.authenticate_cognito.scope, null)
        session_cookie_name                 = try(each.value.authenticate_cognito.session_cookie_name, null)
        session_timeout                     = try(each.value.authenticate_cognito.session_timeout, null)
      }
    }
  }

  action {
    type = "forward"

    # Use this argument if only one target_group_arn was provided.
    target_group_arn = length(var.default_forward_target_group_arns) == 1 ? var.default_forward_target_group_arns[0].arn : null

    # Use this block if two or more target_group_arns were provided.
    dynamic "forward" {
      for_each = length(var.default_forward_target_group_arns) >= 2 ? ["once"] : []

      content {
        dynamic "target_group" {
          for_each = var.default_forward_target_group_arns

          content {
            arn    = target_group.value.arn
            weight = lookup(target_group.value, "weight", null)
          }
        }

        dynamic "stickiness" {
          for_each = each.value.stickiness == null ? [] : ["once"]
          content {
            enabled  = each.value.stickiness.enabled
            duration = each.value.stickiness.duration
          }
        }
      }
    }
  }

  dynamic "condition" {
    # If any path_patterns are specified, create exactly one condition block
    for_each = length(each.value.path_patterns) > 0 ? ["once"] : []

    content {
      path_pattern {
        values = each.value.path_patterns
      }
    }
  }

  dynamic "condition" {
    # If any host_headers are specified, create exactly one condition block
    for_each = length(each.value.host_headers) > 0 ? ["once"] : []

    content {
      host_header {
        values = each.value.host_headers
      }
    }
  }

  dynamic "condition" {
    # If any source_ips are specified, create exactly one condition block
    for_each = length(each.value.source_ips) > 0 ? ["once"] : []

    content {
      source_ip {
        values = each.value.source_ips
      }
    }
  }

  dynamic "condition" {
    # If any http_request_methods are specified, create exactly one condition block
    for_each = length(each.value.http_request_methods) > 0 ? ["once"] : []

    content {
      http_request_method {
        values = each.value.http_request_methods
      }
    }
  }

  dynamic "condition" {
    # If any query_strings are specified, create exactly one condition block
    for_each = length(each.value.query_strings) > 0 ? ["once"] : []

    content {
      dynamic "query_string" {
        for_each = each.value.query_strings

        content {
          key   = lookup(query_string.value, "key", null)
          value = query_string.value.value
        }
      }
    }
  }

  dynamic "condition" {
    # If any http_headers are specified, create exactly one condition block
    for_each = length(each.value.http_headers) > 0 ? ["once"] : []

    content {
      dynamic "http_header" {
        for_each = each.value.http_headers

        content {
          http_header_name = http_header.value.http_header_name
          values           = http_header.value.values
        }
      }
    }
  }
}

resource "aws_lb_listener_rule" "forward_with_ignore_target_groups" {
  for_each = { for key, val in module.forward_rules_map.rules_map : key => val if var.ignore_changes_to_target_groups == true }

  listener_arn = each.value.listener_arn
  priority     = each.value.priority

  dynamic "action" {
    for_each = each.value.authenticate_oidc != null ? ["once"] : []

    content {
      type = "authenticate-oidc"

      authenticate_oidc {
        authorization_endpoint = each.value.authenticate_oidc.authorization_endpoint
        client_id              = each.value.authenticate_oidc.client_id
        client_secret          = each.value.authenticate_oidc.client_secret
        issuer                 = each.value.authenticate_oidc.issuer
        token_endpoint         = each.value.authenticate_oidc.token_endpoint
        user_info_endpoint     = each.value.authenticate_oidc.user_info_endpoint

        on_unauthenticated_request = try(each.value.authenticate_oidc.on_unauthenticated_request, null)
        scope                      = try(each.value.authenticate_oidc.scope, null)
        session_cookie_name        = try(each.value.authenticate_oidc.session_cookie_name, null)
        session_timeout            = try(each.value.authenticate_oidc.session_timeout, null)

        authentication_request_extra_params = try(each.value.authenticate_oidc.authentication_request_extra_params, null)
      }
    }
  }

  dynamic "action" {
    for_each = each.value.authenticate_cognito != null ? ["once"] : []

    content {
      type = "authenticate-cognito"

      authenticate_cognito {
        user_pool_arn       = each.value.authenticate_cognito.user_pool_arn
        user_pool_client_id = each.value.authenticate_cognito.user_pool_client_id
        user_pool_domain    = each.value.authenticate_cognito.user_pool_domain

        authentication_request_extra_params = try(each.value.authenticate_cognito.on_unauthenticated_request, null)
        on_unauthenticated_request          = try(each.value.authenticate_cognito.on_unauthenticated_request, null)
        scope                               = try(each.value.authenticate_cognito.scope, null)
        session_cookie_name                 = try(each.value.authenticate_cognito.session_cookie_name, null)
        session_timeout                     = try(each.value.authenticate_cognito.session_timeout, null)
      }
    }
  }

  action {
    type = "forward"

    # Use first target group arn as we want to ignore changes after initial Terraform apply
    target_group_arn = var.default_forward_target_group_arns[0].arn
  }

  dynamic "condition" {
    # If any path_patterns are specified, create exactly one condition block
    for_each = length(each.value.path_patterns) > 0 ? ["once"] : []

    content {
      path_pattern {
        values = each.value.path_patterns
      }
    }
  }

  dynamic "condition" {
    # If any host_headers are specified, create exactly one condition block
    for_each = length(each.value.host_headers) > 0 ? ["once"] : []

    content {
      host_header {
        values = each.value.host_headers
      }
    }
  }

  dynamic "condition" {
    # If any source_ips are specified, create exactly one condition block
    for_each = length(each.value.source_ips) > 0 ? ["once"] : []

    content {
      source_ip {
        values = each.value.source_ips
      }
    }
  }

  dynamic "condition" {
    # If any http_request_methods are specified, create exactly one condition block
    for_each = length(each.value.http_request_methods) > 0 ? ["once"] : []

    content {
      http_request_method {
        values = each.value.http_request_methods
      }
    }
  }

  dynamic "condition" {
    # If any query_strings are specified, create exactly one condition block
    for_each = length(each.value.query_strings) > 0 ? ["once"] : []

    content {
      dynamic "query_string" {
        for_each = each.value.query_strings

        content {
          key   = lookup(query_string.value, "key", null)
          value = query_string.value.value
        }
      }
    }
  }

  dynamic "condition" {
    # If any http_headers are specified, create exactly one condition block
    for_each = length(each.value.http_headers) > 0 ? ["once"] : []

    content {
      dynamic "http_header" {
        for_each = each.value.http_headers

        content {
          http_header_name = http_header.value.http_header_name
          values           = http_header.value.values
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [action[0].target_group_arn]
  }
}


# ---------------------------------------------------------------------------------------------------------------------
# CREATE REDIRECT RULES
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_lb_listener_rule" "redirect" {
  for_each = module.redirect_rules_map.rules_map

  listener_arn = each.value.listener_arn
  priority     = each.value.priority

  dynamic "action" {
    for_each = each.value.authenticate_oidc != null ? ["once"] : []

    content {
      type = "authenticate-oidc"

      authenticate_oidc {
        authorization_endpoint = each.value.authenticate_oidc.authorization_endpoint
        client_id              = each.value.authenticate_oidc.client_id
        client_secret          = each.value.authenticate_oidc.client_secret
        issuer                 = each.value.authenticate_oidc.issuer
        token_endpoint         = each.value.authenticate_oidc.token_endpoint
        user_info_endpoint     = each.value.authenticate_oidc.user_info_endpoint

        on_unauthenticated_request = try(each.value.authenticate_oidc.on_unauthenticated_request, null)
        scope                      = try(each.value.authenticate_oidc.scope, null)
        session_cookie_name        = try(each.value.authenticate_oidc.session_cookie_name, null)
        session_timeout            = try(each.value.authenticate_oidc.session_timeout, null)

        authentication_request_extra_params = try(each.value.authenticate_oidc.authentication_request_extra_params, null)
      }
    }
  }

  dynamic "action" {
    for_each = each.value.authenticate_cognito != null ? ["once"] : []

    content {
      type = "authenticate-cognito"

      authenticate_cognito {
        user_pool_arn       = each.value.authenticate_cognito.user_pool.pool
        user_pool_client_id = each.value.authenticate_cognito.user_pool_client.client
        user_pool_domain    = each.value.authenticate_cognito.user_pool_domain

        authentication_request_extra_params = try(each.value.authenticate_cognito.on_unauthenticated_request, null)
        on_unauthenticated_request          = try(each.value.authenticate_cognito.on_unauthenticated_request, null)
        scope                               = try(each.value.authenticate_cognito.scope, null)
        session_cookie_name                 = try(each.value.authenticate_cognito.session_cookie_name, null)
        session_timeout                     = try(each.value.authenticate_cognito.session_timeout, null)
      }
    }
  }

  action {
    type = "redirect"

    redirect {
      port        = each.value.port
      protocol    = each.value.protocol
      status_code = each.value.status_code

      host  = each.value.host
      path  = each.value.path
      query = each.value.query
    }
  }

  dynamic "condition" {
    # If any path_patterns are specified, create exactly one condition block
    for_each = length(each.value.path_patterns) > 0 ? ["once"] : []

    content {
      path_pattern {
        values = each.value.path_patterns
      }
    }
  }

  dynamic "condition" {
    # If any host_headers are specified, create exactly one condition block
    for_each = length(each.value.host_headers) > 0 ? ["once"] : []

    content {
      host_header {
        values = each.value.host_headers
      }
    }
  }

  dynamic "condition" {
    # If any source_ips are specified, create exactly one condition block
    for_each = length(each.value.source_ips) > 0 ? ["once"] : []

    content {
      source_ip {
        values = each.value.source_ips
      }
    }
  }

  dynamic "condition" {
    # If any http_request_methods are specified, create exactly one condition block
    for_each = length(each.value.http_request_methods) > 0 ? ["once"] : []

    content {
      http_request_method {
        values = each.value.http_request_methods
      }
    }
  }

  dynamic "condition" {
    # If any query_strings are specified, create exactly one condition block
    for_each = length(each.value.query_strings) > 0 ? ["once"] : []

    content {
      dynamic "query_string" {
        for_each = each.value.query_strings

        content {
          key   = lookup(query_string.value, "key", null)
          value = query_string.value.value
        }
      }
    }
  }

  dynamic "condition" {
    # If any http_headers are specified, create exactly one condition block
    for_each = length(each.value.http_headers) > 0 ? ["once"] : []

    content {
      dynamic "http_header" {
        for_each = each.value.http_headers

        content {
          http_header_name = http_header.value.http_header_name
          values           = http_header.value.values
        }
      }
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE FIXED RESPONSE RULES
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_lb_listener_rule" "fixed_response" {
  for_each = module.fixed_response_rules_map.rules_map

  listener_arn = each.value.listener_arn
  priority     = each.value.priority

  dynamic "action" {
    for_each = each.value.authenticate_oidc != null ? ["once"] : []

    content {
      type = "authenticate-oidc"

      authenticate_oidc {
        authorization_endpoint = each.value.authenticate_oidc.authorization_endpoint
        client_id              = each.value.authenticate_oidc.client_id
        client_secret          = each.value.authenticate_oidc.client_secret
        issuer                 = each.value.authenticate_oidc.issuer
        token_endpoint         = each.value.authenticate_oidc.token_endpoint
        user_info_endpoint     = each.value.authenticate_oidc.user_info_endpoint

        on_unauthenticated_request = try(each.value.authenticate_oidc.on_unauthenticated_request, null)
        scope                      = try(each.value.authenticate_oidc.scope, null)
        session_cookie_name        = try(each.value.authenticate_oidc.session_cookie_name, null)
        session_timeout            = try(each.value.authenticate_oidc.session_timeout, null)

        authentication_request_extra_params = try(each.value.authenticate_oidc.authentication_request_extra_params, null)
      }
    }
  }

  dynamic "action" {
    for_each = each.value.authenticate_cognito != null ? ["once"] : []

    content {
      type = "authenticate-cognito"

      authenticate_cognito {
        user_pool_arn       = each.value.authenticate_cognito.user_pool.pool
        user_pool_client_id = each.value.authenticate_cognito.user_pool_client.client
        user_pool_domain    = each.value.authenticate_cognito.user_pool_domain

        authentication_request_extra_params = try(each.value.authenticate_cognito.on_unauthenticated_request, null)
        on_unauthenticated_request          = try(each.value.authenticate_cognito.on_unauthenticated_request, null)
        scope                               = try(each.value.authenticate_cognito.scope, null)
        session_cookie_name                 = try(each.value.authenticate_cognito.session_cookie_name, null)
        session_timeout                     = try(each.value.authenticate_cognito.session_timeout, null)
      }
    }
  }

  action {
    type = "fixed-response"

    fixed_response {
      content_type = each.value.content_type
      message_body = each.value.message_body
      status_code  = each.value.status_code
    }
  }

  dynamic "condition" {
    # If any path_patterns are specified, create exactly one condition block
    for_each = length(each.value.path_patterns) > 0 ? ["once"] : []

    content {
      path_pattern {
        values = each.value.path_patterns
      }
    }
  }

  dynamic "condition" {
    # If any host_headers are specified, create exactly one condition block
    for_each = length(each.value.host_headers) > 0 ? ["once"] : []

    content {
      host_header {
        values = each.value.host_headers
      }
    }
  }

  dynamic "condition" {
    # If any source_ips are specified, create exactly one condition block
    for_each = length(each.value.source_ips) > 0 ? ["once"] : []

    content {
      source_ip {
        values = each.value.source_ips
      }
    }
  }

  dynamic "condition" {
    # If any http_request_methods are specified, create exactly one condition block
    for_each = length(each.value.http_request_methods) > 0 ? ["once"] : []

    content {
      http_request_method {
        values = each.value.http_request_methods
      }
    }
  }

  dynamic "condition" {
    # If any query_strings are specified, create exactly one condition block
    for_each = length(each.value.query_strings) > 0 ? ["once"] : []

    content {
      dynamic "query_string" {
        for_each = each.value.query_strings

        content {
          key   = lookup(query_string.value, "key", null)
          value = query_string.value.value
        }
      }
    }
  }

  dynamic "condition" {
    # If any http_headers are specified, create exactly one condition block
    for_each = length(each.value.http_headers) > 0 ? ["once"] : []

    content {
      dynamic "http_header" {
        for_each = each.value.http_headers

        content {
          http_header_name = http_header.value.http_header_name
          values           = http_header.value.values
        }
      }
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# COMPUTE FOR EACH DEFINITIONS FOR EACH RULE
# ---------------------------------------------------------------------------------------------------------------------

module "forward_rules_map" {
  source = "./listener-rules-list-to-map"

  rules                  = var.forward_rules
  default_listener_arns  = var.default_listener_arns
  default_listener_ports = var.default_listener_ports
}

module "redirect_rules_map" {
  source = "./listener-rules-list-to-map"

  rules                  = var.redirect_rules
  default_listener_arns  = var.default_listener_arns
  default_listener_ports = var.default_listener_ports
}

module "fixed_response_rules_map" {
  source = "./listener-rules-list-to-map"

  rules                  = var.fixed_response_rules
  default_listener_arns  = var.default_listener_arns
  default_listener_ports = var.default_listener_ports
}