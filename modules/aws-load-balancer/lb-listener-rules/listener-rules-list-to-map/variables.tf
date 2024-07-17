variable "rules" {
  type = any

  # Each entry in the map supports the following attributes:

  # OPTIONAL (defaults to value of corresponding module input):
  # - priority          number                    : A value between 1 and 50000. Leaving it unset will automatically set
  #                                                  the rule with the next available priority after currently existing highest
  #                                                   rule. This value must be unique for each listener.
  # - listener_ports    list(string)              : A list of ports to use to lookup the LB listener from
  #                                                 var.default_listener_arns. Conflicts with listener_arns attribute.
  #                                                 Defaults to var.default_listener_ports if omitted.
  # - listener_arns     list(string)              : A list of listener ARNs to use for applying the rule. Conflicts with
  #                                                 listener_ports attribute.
  # - authenticate_oidc map(object)               : OIDC authentication configuration. Only applies, if not null.
  #
  # - authenticate_cognito map(object)               : Cognito authentication configuration. Only applies, if not null.
  #

  # BASED ON RULE TYPE:
  # Forward rules:
  # - stickiness        [map(object[Stickiness])]   : Target group stickiness for the rule. Only applies if more than one
  #                                                  target_group_arn is defined.
  #
  # Redirect rules:
  # - status_code   [string]: The HTTP redirect code. The redirect is either permanent `HTTP_301` or temporary `HTTP_302`.
  #
  # The URI consists of the following components: `protocol://hostname:port/path?query`. You must modify at least one of
  # the following components to avoid a redirect loop: protocol, hostname, port, or path. Any components that you do not
  # modify retain their original values.
  # - host        [string]: The hostname. The hostname can contain #{host}.
  # - path        [string]: The absolute path, starting with the leading "/". The path can contain `host`, `path`, and `port`.
  # - port        [string]: The port. Specify a value from 1 to 65525.
  # - protocol    [string]: The protocol. Valid values are `HTTP` and `HTTPS`. You cannot redirect HTTPS to HTTP.
  # - query       [string]: The query params. Do not include the leading "?".
  #
  # Fixed response rules:
  # - message_body  [string]      : The message body.
  # - status_code   [string]      : The HTTP response code. Valid values are `2XX`, `4XX`, or `5XX`.

  # Wildcard characters:
  # * - matches 0 or more characters
  # ? - matches exactly 1 character
  # To search for a literal '*' or '?' character in a query string, escape the character with a backslash (\).

  # Conditions (need to specify at least one):
  # - path_patterns        [list(string)]     : A list of paths to match (note that "/foo" is different than "/foo/").
  #                                            Comparison is case sensitive. Wildcard characters supported: * and ?.
  #                                            It is compared to the path of the URL, not it's query string. To compare
  #                                            against query string, use the `query_strings` condition.
  # - host_headers         [list(string)]     : A list of host header patterns to match. Comparison is case insensitive.
  #                                            Wildcard characters supported: * and ?.
  # - source_ips           [list(string)]     : A list of IP CIDR notations to match. You can use both IPv4 and IPv6
  #                                            addresses. Wildcards are not supported. Condition is not satisfied by the
  #                                            addresses in the `X-Forwarded-For` header, use `http_headers` condition instead.
  # - query_strings        [list(map(string))]: Query string pairs or values to match. Comparison is case insensitive.
  #                                            Wildcard characters supported: * and ?. Only one pair needs to match for
  #                                            the condition to be satisfied.
  # - http_request_methods [list(string)]     : A list of HTTP request methods or verbs to match. Only allowed characters are
  #                                            A-Z, hyphen (-) and underscore (_). Comparison is case sensitive. Wildcards
  #                                            are not supported. AWS recommends that GET and HEAD requests are routed in the
  #                                            same way because the response to a HEAD request may be cached.

  # Authenticate OIDC Blocks:
  # authenticate_oidc:
  # - authorization_endpoint              string     : (Required) The authorization endpoint of the IdP.
  # - client_id                           string     : (Required) The OAuth 2.0 client identifier.
  # - client_secret                       string     : (Required) The OAuth 2.0 client secret.
  # - issuer                              string     : (Required) The OIDC issuer identifier of the IdP.
  # - token_endpoint                      string     : (Required) The token endpoint of the IdP.
  # - user_info_endpoint                  string     : (Required) The user info endpoint of the IdP.
  # - authentication_request_extra_params map(string): (Optional) The query parameters to include in the redirect request to the authorization endpoint. Max: 10.
  # - on_unauthenticated_request          string     : (Optional) The behavior if the user is not authenticated. Valid values: deny, allow and authenticate
  # - scope                               string     : (Optional) The set of user claims to be requested from the IdP.
  # - session_cookie_name                 string     : (Optional) The name of the cookie used to maintain session information.
  # - session_timeout                     int        : (Optional) The maximum duration of the authentication session, in seconds.

  # Authenticate Cognito Blocks:
  # authenticate_cognito:
  # - user_pool_arn                       string      : (Required) The ARN of the Cognito user pool
  # - user_pool_client_id                 string      : (Required) The ID of the Cognito user pool client.
  # - user_pool_domain                    string      : (Required) The domain prefix or fully-qualified domain name of the Cognito user pool.
  # - authentication_request_extra_params map(string) : (Optional) The query parameters to include in the redirect request to the authorization endpoint. Max: 10.
  # - on_unauthenticated_request          string      : (Optional) The behavior if the user is not authenticated. Valid values: deny, allow and authenticate
  # - scope                               string      : (Optional) The set of user claims to be requested from the IdP.
  # - session_cookie_name                 string      : (Optional) The name of the cookie used to maintain session information.
  # - session_timeout                     int         : (Optional) The maximum duration of the authentication session, in seconds.

  # Example:
  #  {
  #    "foo" = {
  #      priority      = 120
  #      listener_arns = ["some-arn"]
  #
  #      host_headers         = ["www.foo.com", "*.foo.com"]
  #      path_patterns        = ["/foo/*"]
  #      source_ips           = ["127.0.0.1/32"]
  #      http_request_methods = ["GET"]
  #      query_strings = [
  #        {
  #           key   = "foo"  # Key is optional, this can be ommited.
  #          value = "bar"
  #        }, {
  #          value = "hello"
  #        }
  #     ]
  #   },
  #   "bar" = {
  #     priority       = 127
  #     listener_ports = ["443"]
  #
  #     host_headers   = ["example.com", "www.example.com"]
  #     path_patterns  = ["/super_secure_path", "/another_path"]
  #     http_headers   = [
  #       {
  #         http_header_name = "X-Forwarded-For"
  #         values           = ["127.0.0.1"]
  #       }
  #     ]
  #   },
  #   "auth" = {
  #     priority       = 128
  #     listener_ports = ["443"]
  #
  #     host_headers      = ["intern.example.com]
  #     path_patterns     = ["/admin", "/admin/*]
  #     authenticate_oidc = {
  #       authorization_endpoint = "https://myaccount.oktapreview.com/oauth2/v1/authorize"
  #       client_id              = "0123456789aBcDeFgHiJ"
  #       client_secret          = "clientsecret"
  #       issuer                 = "https://myaccount.oktapreview.com"
  #       token_endpoint         = "https://myaccount.oktapreview.com/oauth2/v1/token"
  #       user_info_endpoint     = "https://myaccount.oktapreview.com/oauth2/v1/userinfo"
  #     }
  #   }
  # }
}

variable "default_listener_arns" {
  description = "A map of all the listeners on the load balancer. The keys should be the port numbers and the values should be the ARN of the listener for that port."
  type        = map(string)
}

variable "default_listener_ports" {
  description = "The default port numbers on the load balancer to attach listener rules to. You can override this default on a rule-by-rule basis by setting the listener_ports parameter in each rule. The port numbers specified in this variable and the listener_ports parameter must exist in var.listener_arns."
  type        = list(string)
}