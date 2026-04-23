terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.60.1"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token_schulungen
}

variable "hcloud_token_schulungen" {
  sensitive = true
}

# Anzahl der nodes, kann on OpenTofu über -var k3s_node_count=n gesetzt werden
variable "k3s_node_count" {
  type    = number
  default = 2
}

# Token für die Verbindung zwischen den control-planes
variable "k3s_server_token" {
  type    = string
  default = "secret-master"
}

# Token für die Verbindung zwischen den agents/nodes zu dem master-0 control-plane
variable "k3s_agent_token" {
  type    = string
  default = "secret-agents"
}

# SSH Key für die Verbindung auf die einzelnen control-planes und nodes
data "hcloud_ssh_key" "schulung" {
  name = "schulung"
}

# erster, initialer master, der als control-plane dient, mit diesem master synchronisieren sich die anderen masters und nodes
resource "hcloud_server" "k3s-master-0" {
  name        = "k3s-master-0"
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
      "curl -sfL https://get.k3s.io | K3S_TOKEN=${var.k3s_server_token} K3S_AGENT_TOKEN=${var.k3s_agent_token} sh -s - server --cluster-init"
    ]
    connection {
      type        = "ssh"
      host        = self.ipv4_address
      user        = "root"
      private_key = file("../../${data.hcloud_ssh_key.schulung.name}")
    }
  }
}

# weitere 2 masters, die sich mit dem master-0 initial verbinden
resource "hcloud_server" "k3s-master" {
  for_each    = { for server in range(1, 3) : server => "master-${server}" }
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
      "curl -sfL https://get.k3s.io | K3S_TOKEN=${var.k3s_server_token} sh -s - server --server https://${hcloud_server.k3s-master-0.ipv4_address}:6443"
    ]
    connection {
      type        = "ssh"
      host        = self.ipv4_address
      user        = "root"
      private_key = file("../../${data.hcloud_ssh_key.schulung.name}")
    }
  }
}

# weitere agents/worker nodes, die sich mit master-0 initial verbinden
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
      "curl -sfL https://get.k3s.io | K3S_URL=https://${hcloud_server.k3s-master-0.ipv4_address}:6443 K3S_TOKEN=${var.k3s_agent_token} sh -"
    ]
    connection {
      type        = "ssh"
      host        = self.ipv4_address
      user        = "root"
      private_key = file("../../${data.hcloud_ssh_key.schulung.name}")
    }
  }
}
