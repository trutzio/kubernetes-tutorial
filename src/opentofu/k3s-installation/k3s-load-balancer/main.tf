terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.60.1"
    }
  }
}

data "hcloud_ssh_key" "schulung" {
  name = "schulung"
}

# Token für die Verbindung zwischen den control-planes
variable "k3s_server_token" {
  type    = string
  default = "secret-master"
}

# erster, initialer master, der als control-plane dient, mit diesem master synchronisieren sich die anderen masters und nodes
resource "hcloud_server" "master-0" {
  name        = "master-0"
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
      "curl -sfL https://get.k3s.io | K3S_TOKEN=${var.k3s_server_token} sh -s - server --cluster-init --tls-san ${hcloud_server.load-balancer.ipv4_address}"
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
resource "hcloud_server" "master" {
  for_each    = { for server in range(1, 3) : server => "master-${server}" }
  name        = "${each.value}"
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
      "curl -sfL https://get.k3s.io | K3S_TOKEN=${var.k3s_server_token} sh -s - server --server https://${hcloud_server.master-0.ipv4_address}:6443 --tls-san ${hcloud_server.load-balancer.ipv4_address}"
    ]
    connection {
      type        = "ssh"
      host        = self.ipv4_address
      user        = "root"
      private_key = file("../../${data.hcloud_ssh_key.schulung.name}")
    }
  }
}

resource "hcloud_server" "load-balancer" {
  name        = "load-balancer"
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
      "apt update",
      "apt-get install haproxy -y"
    ] 
    connection {
      type        = "ssh"
      host        = self.ipv4_address
      user        = "root"
      private_key = file("../../${data.hcloud_ssh_key.schulung.name}")
    }  
  }
}
