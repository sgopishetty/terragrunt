# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED MODULE PARAMETERS
# These variables must be passed in by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "alb_name" {
  description = "The name of the ALB. Do not include the environment name since this module will automatically append it to the value of this variable."
  type        = string
  # AWS imposes a 32 character limit on the names of ALBs, so here we catch any overages client-side
  validation {
    condition     = length(var.alb_name) <= 32
    error_message = "Your alb_name must be 32 characters or less in length."
  }
}

variable "is_internal_alb" {
  description = "If the ALB should only accept traffic from within the VPC, set this to true. If it should accept traffic from the public Internet, set it to false."
  type        = bool
}

variable "ssl_policy" {
  description = "The AWS predefined TLS/SSL policy for the ALB. A List of policies can be found here: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies. AWS recommends ELBSecurityPolicy-2016-08 policy for general use but this policy includes TLSv1.0 which is rapidly being phased out. ELBSecurityPolicy-TLS-1-1-2017-01 is the next policy up that doesn't include TLSv1.0."
  type        = string
}

variable "vpc_subnet_ids" {
  description = "A list of the subnets into which the ALB will place its underlying nodes. Include one subnet per Availabability Zone. If the ALB is public-facing, these should be public subnets. Otherwise, they should be private subnets."
  type        = list(string)
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL MODULE PARAMETERS
# These variables have defaults, but may be overridden by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "additional_security_group_ids" {
  description = "Add additional security groups to the ALB"
  type        = list(string)
  default     = []
}

variable "http_listener_ports" {
  description = "A list of ports for which an HTTP Listener should be created on the ALB. Tip: When you define Listener Rules for these Listeners, be sure that, for each Listener, at least one Listener Rule uses the '*' path to ensure that every possible request path for that Listener is handled by a Listener Rule. Otherwise some requests won't route to any Target Group."
  type        = list(string)
  default     = []
}

variable "https_listener_ports_and_ssl_certs" {
  description = "A list of the ports for which an HTTPS Listener should be created on the ALB. Each item in the list should be a map with the keys 'port', the port number to listen on, and 'tls_arn', the Amazon Resource Name (ARN) of the SSL/TLS certificate to associate with the Listener to be created. If your certificate is issued by the Amazon Certificate Manager (ACM), specify var.https_listener_ports_and_acm_ssl_certs instead. Tip: When you define Listener Rules for these Listeners, be sure that, for each Listener, at least one Listener Rule  uses the '*' path to ensure that every possible request path for that Listener is handled by a Listener Rule. Otherwise some requests won't route to any Target Group."
  type = list(object({
    port    = number
    tls_arn = string
  }))
  default = []

  # Example:
  # default = [
  #   {
  #     port = 443
  #     tls_arn = "arn:aws:iam::123456789012:server-certificate/ProdServerCert"
  #   }
  # ]
}

variable "https_listener_ports_and_ssl_certs_num" {
  description = "The number of elements in var.https_listener_ports_and_ssl_certs. We should be able to compute this automatically, but due to a Terraform limitation, if there are any dynamic resources in var.https_listener_ports_and_ssl_certs, then we won't be able to: https://github.com/hashicorp/terraform/pull/11482"
  type        = number
  default     = 0
}

variable "https_listener_ports_and_acm_ssl_certs" {
  description = "A list of the ports for which an HTTPS Listener should be created on the ALB. Each item in the list should be a map with the keys 'port', the port number to listen on, and 'tls_domain_name', the domain name of an SSL/TLS certificate issued by the Amazon Certificate Manager (ACM) to associate with the Listener to be created. If your certificate isn't issued by ACM, specify var.https_listener_ports_and_ssl_certs instead. Tip: When you define Listener Rules for these Listeners, be sure that, for each Listener, at least one Listener Rule  uses the '*' path to ensure that every possible request path for that Listener is handled by a Listener Rule. Otherwise some requests won't route to any Target Group."
  type = list(object({
    port            = number
    tls_domain_name = string
  }))
  default = []

  # Example:
  # default = [
  #   {
  #     port = 443
  #     tls_domain_name = "foo.your-company.com"
  #   }
  # ]
}

variable "https_listener_ports_and_acm_ssl_certs_num" {
  description = "The number of elements in var.https_listener_ports_and_acm_ssl_certs. We should be able to compute this automatically, but due to a Terraform limitation, if there are any dynamic resources in var.https_listener_ports_and_acm_ssl_certs, then we won't be able to: https://github.com/hashicorp/terraform/pull/11482"
  type        = number
  default     = 0
}

variable "additional_ssl_certs_for_ports" {
  description = "List of additional SSL certs (non-ACM and ACM) to bind to the given listener port. Note that this must not overlap with the certificates defined in var.https_listener_ports_and_ssl_certs and var.https_listener_ports_and_acm_ssl_certs. The keys are the listener ports."
  type = map(list(object({
    # Exactly one of the following must be set, with the other set to null.
    # The domain name to use when looking up the ACM cert to associate.
    tls_domain_name = string
    # The ARN of the TLS cert to associate with the listener.
    tls_arn = string
  })))
  default = {}
}

variable "allow_all_outbound" {
  description = "Set to true to enable all outbound traffic on this ALB. If set to false, the ALB will allow no outbound traffic by default. This will make the ALB unusuable, so some other code must then update the ALB Security Group to enable outbound access!"
  type        = bool
  default     = true
}

variable "enable_alb_access_logs" {
  description = "Set to true to enable the ALB to log all requests. Ideally, this variable wouldn't be necessary, but because Terraform can't interpolate dynamic variables in counts, we must explicitly include this. Enter true or false."
  type        = bool
  default     = false
}

variable "alb_access_logs_s3_bucket_name" {
  description = "The S3 Bucket name where ALB logs should be stored. If left empty, no ALB logs will be captured. Tip: It's easiest to create the S3 Bucket using the Gruntwork Module https://github.com/gruntwork-io/terraform-aws-monitoring/tree/main/modules/logs/load-balancer-access-logs."
  type        = string
  default     = null
}

variable "custom_alb_access_logs_s3_prefix" {
  description = "Prefix to use for access logs to create a sub-folder in S3 Bucket name where ALB logs should be stored. Only used if var.enable_custom_alb_access_logs_s3_prefix is true."
  type        = string
  default     = null
}

variable "enable_custom_alb_access_logs_s3_prefix" {
  description = "Set to true to use the value of alb_access_logs_s3_prefix for access logs prefix. If false, the alb_name will be used. This is useful if you wish to disable the S3 prefix. Only used if var.enable_alb_access_logs is true."
  type        = bool
  default     = false
}

variable "allow_inbound_from_cidr_blocks" {
  description = "The CIDR-formatted IP Address ranges from which this ALB will allow incoming requests. If var.is_internal_alb is false, use the default value. If var.is_internal_alb is true, consider setting this to the VPC's CIDR Block, or something even more restrictive."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allow_inbound_from_security_group_ids" {
  description = "The IDs of security groups from which this ALB will allow incoming requests. . If you update this variable, make sure to update var.allow_inbound_from_security_group_ids_num too!"
  type        = list(string)
  default     = []
}

variable "allow_inbound_from_security_group_ids_num" {
  description = "The number of elements in var.allow_inbound_from_security_group_ids. We should be able to compute this automatically, but due to a Terraform limitation, if there are any dynamic resources in var.allow_inbound_from_security_group_ids, then we won't be able to: https://github.com/hashicorp/terraform/pull/11482"
  type        = number
  default     = 0
}

variable "idle_timeout" {
  description = "The time in seconds that the client TCP connection to the ALB is allowed to be idle before the ALB closes the TCP connection.  "
  type        = number
  default     = 60
}

variable "enable_deletion_protection" {
  description = "If true, deletion of the ALB will be disabled via the AWS API. This will prevent Terraform from deleting the load balancer."
  type        = bool
  default     = false
}

variable "drop_invalid_header_fields" {
  description = "If true, the ALB will drop invalid headers. Elastic Load Balancing requires that message header names contain only alphanumeric characters and hyphens."
  type        = bool
  default     = false
}

variable "custom_tags" {
  description = "A map of custom tags to apply to the ALB and its Security Group. The key is the tag name and the value is the tag value."
  type        = map(string)
  default     = {}
}

variable "default_action" {
  description = "Define the default action if a request to the load balancer does not match any of your listener rules. Currently only 'fixed-response' and 'redirect' are supported. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener#default_action"
  type        = map(any)
  default = {
    fixed-response = {
      content_type = "text/plain"
      message_body = null
      status_code  = 404
    }
  }
}

variable "acm_cert_statuses" {
  description = "When looking up the ACM certs passed in via https_listener_ports_and_acm_ssl_certs, only match certs with the given statuses. Valid values are PENDING_VALIDATION, ISSUED, INACTIVE, EXPIRED, VALIDATION_TIMED_OUT, REVOKED and FAILED."
  type        = list(string)
  default     = ["ISSUED"]
}

variable "acm_cert_types" {
  description = "When looking up the ACM certs passed in via https_listener_ports_and_acm_ssl_certs, only match certs of the given types. Valid values are AMAZON_ISSUED and IMPORTED."
  type        = list(string)
  default     = ["AMAZON_ISSUED", "IMPORTED"]
}

variable "enable_http2" {
  description = "Indicates whether HTTP/2 is enabled in application load balancers. Defaults to true."
  type        = bool
  default     = true
}

variable "enable_xff_client_port" {
  description = "Indicates whether the X-Forwarded-For header should preserve the source port that the client used to connect to the load balancer in application load balancers. Defaults to true."
  type        = bool
  default     = true
}

variable "xff_header_processing_mode" {
  description = " (Optional) Determines how the load balancer modifies the X-Forwarded-For header in the HTTP request before sending the request to the target. The possible values are append, preserve, and remove. Only valid for Load Balancers of type application. The default is append."
  type        = string
  default     = "append"
}

variable "enable_waf_fail_open" {
  description = "Indicates whether to allow a WAF-enabled load balancer to route requests to targets if it is unable to forward the request to AWS WAF."
  type        = bool
  default     = false
}

variable "ip_address_type" {
  description = "The type of IP addresses used by the subnets for your load balancer. The possible values are ipv4 and dualstack."
  type        = string
  default     = null
}

variable "desync_mitigation_mode" {
  description = "Determines how the load balancer handles requests that might pose a security risk to an application due to HTTP desync. Valid values are monitor, defensive (default), strictest."
  type        = string
  default     = "defensive"
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE DEPENDENCIES
# Workaround Terraform limitation where there is no module depends_on.
# See https://github.com/hashicorp/terraform/issues/1178 for more details.
# This can be used to make sure the module resources are created after other bootstrapping resources have been created.
# For example, in AWS, when provisioning a wildcard ACM certificate for a public zone, you need to create several
# verification DNS records - but they must be created in the public zone itself. In this use case, you can pass the public
# zones as a dependency into this module:
# dependencies = flatten([values(aws_route53_zone.public_zones).*.name_servers])
# ---------------------------------------------------------------------------------------------------------------------

variable "dependencies" {
  description = "Create a dependency between the resources in this module to the interpolated values in this list (and thus the source resources). In other words, the resources in this module will now depend on the resources backing the values in this list such that those resources need to be created before the resources in this module, and the resources in this module need to be destroyed before the resources in the list."
  type        = list(string)
  default     = []
}

# ----------------------------------------------------------------------------------------------------------------------
# DEPRECATED PARAMETERS
# ----------------------------------------------------------------------------------------------------------------------

variable "vpc_id" {
  description = "DEPRECATED. The VPC ID in which this ALB will be placed."
  type        = string
  default     = ""
}
