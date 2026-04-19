terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.60.1"
    }
  }
}

variable "k3s_agent_token" {
  type    = string
  default = "secret"
}

variable "k3s_node_count" {
  type    = number
  default = 2
}

data "hcloud_ssh_key" "schulung" {
  name = "schulung"
}

resource "hcloud_server" "k3s_control_plane" {
  name        = "k3s-control-plane"
  image       = "debian-13"
  server_type = "cx23"
  location    = "nbg1"
  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }
  ssh_keys = [data.hcloud_ssh_key.schulung.name]
  provisioner "remote-exec" {
    inline = [
      "curl -sfL https://get.k3s.io | K3S_AGENT_TOKEN=${var.k3s_agent_token} sh -"
    ]
    connection {
      type        = "ssh"
      host        = self.ipv4_address
      user        = "root"
      private_key = file("../../${data.hcloud_ssh_key.schulung.name}")
    }
  }
}

resource "hcloud_server" "k3s_node" {
  for_each    = { for node in range(1, var.k3s_node_count + 1) : node => "node-${node}" }
  name        = "k3s-${each.value}"
  image       = "debian-13"
  server_type = "cx23"
  location    = "nbg1"
  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }
  ssh_keys = [data.hcloud_ssh_key.schulung.name]
  provisioner "remote-exec" {
    inline = [
      "curl -sfL https://get.k3s.io | K3S_URL=https://${hcloud_server.k3s_control_plane.ipv4_address}:6443 K3S_TOKEN=${var.k3s_agent_token} sh -"
    ]
    connection {
      type        = "ssh"
      host        = self.ipv4_address
      user        = "root"
      private_key = file("../../${data.hcloud_ssh_key.schulung.name}")
    }
  }
}
