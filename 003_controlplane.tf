data "template_file" "rancher_agent" {
  template = file("files/cloud-init-agent.yaml")
  vars = {
    docker_version_server = var.rancher_docker_version
  }
}

locals {
  rancher-etcd-to-etcd-host-port = { for v in setproduct(scaleway_instance_ip.rancher_controlplane[*].address, ["2379", "2380", "9099", "10250", "10254"]) : "${v[0]}/${v[1]}" => {
    ip   = v[0]
    port = v[1]
    }
  }
  rancher-worker-to-etcd-host-port = { for v in setproduct(concat(scaleway_instance_ip.rancher_worker_dev_s[*].address, var.rancher_external_worker_nodes), ["6443", "8472", "4789"]) : "${v[0]}/${v[1]}" => {
    ip   = v[0]
    port = v[1]
    }
  }
}

resource "scaleway_instance_placement_group" "rancher-etcd" {
  name        = "${var.prefix}rancher-etcd"
  policy_mode = "enforced"
}

//https://www.reddit.com/r/Terraform/comments/d8em03/terraform_12_nested_for_each/
resource "scaleway_instance_security_group" "rancher-etcd-cp" {
  description             = "Security group rancher etcd-control plane nodes"
  name                    = "${var.prefix}rancher-etcd-cp"
  inbound_default_policy  = "drop"
  outbound_default_policy = "accept"
  external_rules          = true
}

resource scaleway_instance_security_group_rules "rancher-etcd-cp-rules" {
  security_group_id = scaleway_instance_security_group.rancher-etcd-cp.id
  #tcp
  dynamic "inbound_rule" {
    for_each = ["22", "443"]
    content {
      action   = "accept"
      port     = inbound_rule.value
      protocol = "TCP"
    }
  }
  //inter etcd sg
  dynamic "inbound_rule" {
    for_each = local.rancher-etcd-to-etcd-host-port
    //noinspection HILUnresolvedReference
    content {
      action   = "accept"
      ip       = inbound_rule.value.ip
      port     = inbound_rule.value.port
      protocol = "ANY"
    }
  }
}
resource "scaleway_instance_ip" "rancher_controlplane" {
  count = var.rancher_control_plane_count
}

resource "scaleway_instance_server" "rancher_controlplane" {
  depends_on = [rancher2_bootstrap.admin]
  count      = var.rancher_control_plane_count
  image      = data.scaleway_image.ubuntu.id
  name       = format("%srancher-etcd-cp-%03d", var.prefix, count.index + 1)
  ip_id      = scaleway_instance_ip.rancher_controlplane[count.index].id
  user_data {
    key   = "rancher_ip"
    value = scaleway_instance_server.rancherserver.public_ip
  }
  user_data {
    key   = "rancher_node_command"
    value = rancher2_cluster.default.cluster_registration_token[0].node_command
  }
  user_data {
    key   = "rancher_node_role"
    value = "--etcd --controlplane"
  }
  user_data {
    key   = "rancher_node_labels"
    value = ""
  }
  cloud_init         = <<EOF
${data.template_file.common-init.rendered}
${data.template_file.rancher_agent.rendered}
EOF
  type               = "DEV1-M"
  security_group_id  = scaleway_instance_security_group.rancher-etcd-cp.id
  placement_group_id = scaleway_instance_placement_group.rancher-etcd.id
}
