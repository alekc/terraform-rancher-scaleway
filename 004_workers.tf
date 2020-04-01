resource scaleway_instance_security_group "rancher_workers" {
  #tcp
  dynamic "inbound_rule" {
    for_each = ["22", "443"]
    content {
      action   = "accept"
      port     = inbound_rule.value
      protocol = "TCP"
    }
  }
}

resource "scaleway_instance_placement_group" "rancher_workers" {
  name        = "${var.prefix}rancher-workers"
  policy_mode = "enforced"
}

resource "scaleway_instance_ip" "rancher_worker_dev_s" {
  count = var.rancher_worker_dev1_count
}
resource "scaleway_instance_server" "rancher_workers_dev_s" {
  depends_on        = [rancher2_bootstrap.admin]
  count             = var.rancher_worker_dev1_count
  image             = data.scaleway_image.ubuntu.id
  name              = format("%srancher-worker-devs-%03d", var.prefix, count.index + 1)
  enable_dynamic_ip = false
  ip_id             = scaleway_instance_ip.rancher_worker_dev_s[count.index].id
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
    value = "--worker"
  }
  user_data {
    key   = "rancher_node_labels"
    value = "--label foo=bar --label xyz=1"
  }
  cloud_init         = <<EOF
${data.template_file.common-init.rendered}
${data.template_file.rancher_agent.rendered}
EOF
  type               = "DEV1-S"
  security_group_id  = scaleway_instance_security_group.rancher_workers.id
  placement_group_id = scaleway_instance_placement_group.rancher_workers.id
}
