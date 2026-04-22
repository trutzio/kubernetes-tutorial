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

resource "hcloud_server" "k3s-single-control-plane" {
  name        = "k3s-single-control-plane"
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
      "curl -sfL https://get.k3s.io | sh -"
    ]
    connection {
      type        = "ssh"
      host        = self.ipv4_address
      user        = "root"
      private_key = file("../../${data.hcloud_ssh_key.schulung.name}")
    }
  }
}

resource "hcloud_server" "k3s-load-balancer" {
  name        = "k3s-load-balancer"
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
