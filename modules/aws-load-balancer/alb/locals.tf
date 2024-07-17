# ---------------------------------------------------------------------------------------------------------------------
# LOCAL VALUES USED THROUGHOUT THE MODULE
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Remap the additional_ssl_certs_for_ports variable to a convenient list for use with for_each on the
  # aws_acm_certificate data source so we can get the arn from the provided domain. Note that since we can
  # potentially have multiple different domains per port, we will use KEY-DOMAIN as the for_each key.
  additional_acm_certs_to_lookup_list = flatten([
    for key, certs in var.additional_ssl_certs_for_ports :
    [
      for cert in certs :
      {
        key    = "${key}-${cert.tls_domain_name}"
        domain = cert.tls_domain_name
      }
      if cert.tls_domain_name != null
    ]
  ])
  additional_acm_certs_to_lookup = {
    for cert in local.additional_acm_certs_to_lookup_list :
    cert.key => cert.domain
  }

  # Remap the additional_ssl_certs_for_ports variable to a convenient list for use with for_each on the
  # aws_lb_listener_certificate resource. Since we can have multiple different domains and arns on a port, we will use
  # KEY-DOMAIN or KEY-HASH(ARN) as the for_each key.
  additional_certs_to_associate_list = flatten([
    for key, certs in var.additional_ssl_certs_for_ports :
    [
      for cert in certs :
      {
        key = (
          cert.tls_domain_name != null
          ? "${key}-${cert.tls_domain_name}"
          : "${key}-${md5(cert.tls_arn)}"
        )
        port            = key
        tls_domain_name = cert.tls_domain_name
        tls_arn         = cert.tls_arn
      }
    ]
  ])
  additional_certs_to_associate = {
    for cert in local.additional_certs_to_associate_list :
    cert.key => cert
  }

  # Compute the prefix to use for ALB access logs based on the flag. The purpose of the feature flag is to support
  # setting the prefix to be explicitly `null`.
  alb_access_logs_s3_prefix = (
    var.enable_custom_alb_access_logs_s3_prefix
    ? var.custom_alb_access_logs_s3_prefix
    : var.alb_name
  )

  # Intermediate computations that make it easier to generate the output values.
  http_listener_port_arns = {
    for listener in aws_alb_listener.http :
    listener.port => listener.arn
  }
  https_listener_non_acm_port_arns = {
    for listener in aws_alb_listener.https_non_acm_certs :
    listener.port => listener.arn
  }
  https_listener_acm_port_arns = {
    for listener in aws_alb_listener.https_acm_certs :
    listener.port => listener.arn
  }

}
