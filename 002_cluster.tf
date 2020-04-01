// Create a new rancher2_bootstrap using bootstrap provider config
resource "rancher2_bootstrap" "admin" {
  provider = rancher2.bootstrap

  password   = var.rancher_admin_password
  telemetry  = true
  depends_on = [null_resource.wait_for_rancher_server]
}

# Provider config for admin
provider "rancher2" {
  alias = "admin"

  api_url   = rancher2_bootstrap.admin.url
  token_key = rancher2_bootstrap.admin.token
  insecure  = true
}

resource "rancher2_cluster" "default" {
  provider    = rancher2.admin
  name        = "default"
  description = "Default rancher cluster"
  rke_config {
    network {
      plugin = "canal"
    }
    services {
      kube_api {
        audit_log {
          enabled = true
          configuration {
            max_age    = 5
            max_backup = 5
            max_size   = 100
            path       = "-"
            format     = "json"
            policy     = file("files/auditlog_policy.yaml")
          }
        }
      }
    }
  }
}
