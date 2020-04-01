variable "scw_access_key" {}
variable "scw_secret_key" {}
variable "scw_organization_id" {}
variable "scw_zone" {
  default = "fr-par-1"
}

variable cloudflare_api_token {}
variable cloudflare_email {}

variable "prefix" {
  default = ""
}

//rancher configuration
variable "rancher_base_domain" {} //hostname of the dns zone (i.e. example.com)
variable "rancher_subdomain" { default = "rancher" }
variable "rancher_admin_password" {}
variable "rancher_cluster_name" {
  default = "default"
}

//versions
variable "rancher_docker_version" {
  default = "19.03"
}
variable "rancher_server_version" {
  default = "v2.3.5"
}

variable "rancher_control_plane_count" {
  default = 3
}
variable "rancher_worker_dev1_count" {
  default = 2
}
variable "rancher_external_worker_nodes" {
  type    = list(string)
  default = []
}
