terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.60.1"
    }
  }
}

variable "vm_count" {
  type        = number
  description = "Number of VMs to create"
  default     = 1
}

data "hcloud_ssh_key" "schulung" {
  name = "schulung"
}

resource "hcloud_server" "student" {
  for_each    = { for vm in range(0, var.vm_count) : vm => "student-${vm}" }
  name        = each.value
  image       = "debian-13"
  server_type = "cpx32"
  location    = "fsn1"
  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }
  ssh_keys = [data.hcloud_ssh_key.schulung.name]
  provisioner "remote-exec" {
    inline = [
      "apt update",
      "apt upgrade -y",
      "apt install -y git",
    ]
    connection {
      type        = "ssh"
      host        = self.ipv4_address
      user        = "root"
      private_key = file("../${data.hcloud_ssh_key.schulung.name}")
    }
  }
}

