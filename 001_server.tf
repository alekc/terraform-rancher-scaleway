//launch server
data "template_file" "common-init" {
  template = file("files/cloud-init-common.yaml")
  vars = {

  }
}

data "template_file" "rancher-server-init" {
  template = file("files/cloud-init-server.yaml")
  vars = {
    rancher_version       = var.rancher_server_version
    docker_version_server = var.rancher_docker_version
  }
}
//create security group for rancher
resource "scaleway_instance_security_group" "rancher_server" {
  description             = "Security group for rancher server"
  name                    = "${var.prefix}-rancher-server"
  inbound_default_policy  = "drop"
  outbound_default_policy = "accept"
  #tcp
  dynamic "inbound_rule" {
    for_each = ["22", "443", "80"]
    content {
      action   = "accept"
      port     = inbound_rule.value
      protocol = "TCP"
    }
  }
}

//create rancher server
resource "scaleway_instance_server" "rancherserver" {
  image             = data.scaleway_image.ubuntu.id
  name              = "${var.prefix}rancherserver"
  enable_dynamic_ip = true
  cloud_init        = <<EOF
${data.template_file.common-init.rendered}
${data.template_file.rancher-server-init.rendered}
EOF
  type              = "DEV1-M"
  security_group_id = scaleway_instance_security_group.rancher_server.id
}

//dns record for our web interface
resource "cloudflare_record" "rancher-server" {
  name    = var.rancher_subdomain
  type    = "A"
  zone_id = data.cloudflare_zones.zone.zones[0].id
  value   = scaleway_instance_server.rancherserver.public_ip
  proxied = true
}

output "rancher-server-url" {
  value = "https://${cloudflare_record.rancher-server.hostname}"
}

// wait for a server to come up
resource "null_resource" "wait_for_rancher_server" {
  # this is merely a trick to wait that remote host has ssh open and ready to accept connection,
  # otherwise the next local-exec with rsync might fail.
  depends_on = [scaleway_instance_server.rancherserver]
  provisioner "local-exec" {
    command = <<EOF
    echo "Waiting for rancher server to come up"
    while true; do
      curl -iLk https://${scaleway_instance_server.rancherserver.public_ip}/ping && break
      sleep 30
    done
    echo "rancher server is up"
EOF
  }
}
//follow to cluster and agents
