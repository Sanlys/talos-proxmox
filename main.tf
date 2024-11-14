terraform {
  required_version = ">= 0.12"
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.1-rc4"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.7.0-alpha.0"
    }
  }
}

provider "proxmox" {
  pm_api_url      = "https://pve1.s1.lan:8006/api2/json"
  pm_tls_insecure = true
}

provider "talos" {

}

variable "control_plane_count" {
  default = 1
}

variable "talos_iso" {
  default = "ceph-iso:iso/talos-nocloud-qemuguest-amd64.iso"
}

variable "proxmox_node" {
  default = "pve1"
}

locals {
  vm_cores   = 2
  vm_memory  = 2048
  vm_storage = "local-lvm"
}

resource "proxmox_vm_qemu" "control_plane" {
  count                  = var.control_plane_count
  name                   = "talos-control-plane-${count.index + 1}"
  target_node            = var.proxmox_node
  cores                  = local.vm_cores
  memory                 = local.vm_memory
  scsihw                 = "virtio-scsi-pci"
  define_connection_info = true

  boot  = "order=sata0;"
  agent = 1

  disk {
    size    = "20G"
    storage = local.vm_storage
    type    = "disk"
    slot    = "scsi0"
  }
  disk {
    iso  = var.talos_iso
    slot = "sata0"
    type = "cdrom"
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }
  ipconfig0 = "ip=dhcp"
}

locals {
  control_plane_ips = [for vm in proxmox_vm_qemu.control_plane : vm.ssh_host]
}

output "control_plane_ips" {
  value       = local.control_plane_ips
  description = "List of control plane IP addresses"
}
