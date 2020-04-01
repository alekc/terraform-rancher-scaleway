provider "scaleway" {
  access_key      = var.scw_access_key
  secret_key      = var.scw_secret_key
  organization_id = var.scw_organization_id
  zone            = var.scw_zone
  region          = "fr-par"
  version         = "~> 1.14"
}
provider "cloudflare" {
  version   = "~> 2.0"
  api_token = var.cloudflare_api_token
  email     = var.cloudflare_email
}
//bootstrap the cluster.
provider "rancher2" {
  alias = "bootstrap"
  //  api_url   = "https://${scaleway_instance_server.rancherserver.public_ip}"
  api_url   = "https://${cloudflare_record.rancher-server.hostname}"
  bootstrap = true
  insecure  = true
}
data cloudflare_zones "zone" {
  filter {
    name = var.rancher_base_domain
  }
}
data scaleway_image ubuntu {
  name         = "Ubuntu Bionic"
  architecture = "x86_64"
}
