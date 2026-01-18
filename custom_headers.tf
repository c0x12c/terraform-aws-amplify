# Custom headers functionality for AWS Amplify
# Handles both normal repositories and monorepos

locals {
  monorepo_pattern = "/[a-zA-Z]"
  is_monorepo      = var.application_root != "" && regex(local.monorepo_pattern, var.application_root) != null
}

locals {
  template_file = local.is_monorepo ? "${path.module}/templates/customHttp-monorepo.tftpl" : "${path.module}/templates/customHttp-normal.tftpl"

  template_vars = {
    custom_headers   = var.custom_headers
    application_root = var.application_root
  }
}

resource "local_file" "custom_http_config" {
  count = length(var.custom_headers) > 0 ? 1 : 0

  filename = "${path.root}/.terraform/tmp/customHttp-${aws_amplify_app.this.id}.yml"
  content  = templatefile(local.template_file, local.template_vars)

  provisioner "local-exec" {
    command = "mkdir -p ${dirname(self.filename)}"
  }
}

resource "null_resource" "update_custom_headers" {
  count = length(var.custom_headers) > 0 ? 1 : 0

  triggers = {
    always_run   = timestamp()
    app_id       = aws_amplify_app.this.id
    headers_hash = local_file.custom_http_config[0].content_md5
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Update Amplify app with custom headers using temp file
      aws amplify update-app \
        --app-id "${self.triggers.app_id}" \
        --custom-headers "file://${local_file.custom_http_config[0].filename}" \
        --region "${data.aws_region.current.name}"
    EOT

    environment = {
      AWS_DEFAULT_REGION = data.aws_region.current.name
    }

    on_failure = continue
  }

  depends_on = [
    aws_amplify_app.this,
    aws_amplify_branch.this,
    local_file.custom_http_config
  ]
}
