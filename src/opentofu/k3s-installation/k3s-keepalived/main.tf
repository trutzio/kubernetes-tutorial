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

# 2 keepalived server
resource "hcloud_server" "lb" {
  for_each    = { for server in range(0, 2) : server => "keepalived-lb-${server}" }
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
      "apt update",
      "apt install -y keepalived tcpdump",
    ]
    connection {
      type        = "ssh"
      host        = self.ipv4_address
      user        = "root"
      private_key = file("../../${data.hcloud_ssh_key.schulung.name}")
    }
  }
}
