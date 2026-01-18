locals {
  monorepo_pattern = "/[a-zA-Z]"
  is_monorepo      = var.application_root != "" && regex(local.monorepo_pattern, var.application_root) != null

  build_spec  = var.enable_backend ? "${path.module}/templates/build_spec_with_backend.tftpl" : "${path.module}/templates/build_spec_frontend_only.tftpl"
  domain_name = var.sub_domain == "" ? var.dns_zone : "${var.sub_domain}.${var.dns_zone}"

  custom_redirect_rules = var.enable_redirect_to_root ? concat(
    [
      {
        source = "https://www.${local.domain_name}"
        status = "301"
        target = "https://${local.domain_name}"
      }
    ],
    var.custom_redirect_rules
  ) : var.custom_redirect_rules

  custom_headers = length(var.custom_headers) > 0 ? local.is_monorepo ? jsonencode({
    applications = [
      {
        appRoot       = var.application_root
        customHeaders = var.custom_headers
      }
    ]
    }) : jsonencode({
    customHeaders = var.custom_headers
  }) : null
}
