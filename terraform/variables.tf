variable "proxmox_endpoint" {
  type        = string
  description = "URL API Proxmox"
}

variable "proxmox_api_token" {
  type        = string
  sensitive   = true
  description = "API token Proxmox lengkap"
}

variable "proxmox_tls_insecure" {
  type        = bool
  description = "Lewati verifikasi TLS certificate Proxmox API"
  default     = true
}

variable "proxmox_node" {
  type        = string
  description = "Nama node Proxmox"
}

variable "workload_type" {
  type        = string
  description = "Jenis workload yang dikelola Terraform: vm atau lxc"
  default     = "vm"

  validation {
    condition     = contains(["vm", "lxc"], var.workload_type)
    error_message = "workload_type harus bernilai \"vm\" atau \"lxc\"."
  }
}

variable "vm_datastore_id" {
  type        = string
  description = "Storage untuk disk VM"
}

variable "default_tags" {
  type        = list(string)
  description = "Tag default yang akan diterapkan ke semua workload"
  default     = ["terraform", "ansible", "ubuntu"]
}

variable "network_bridge" {
  type        = string
  description = "Bridge network Proxmox"
}

variable "vm_gateway" {
  type        = string
  description = "Gateway VM"
}

variable "vm_cidr" {
  type        = number
  description = "CIDR network VM"
}

variable "dns_servers" {
  type        = list(string)
  description = "DNS server untuk VM"
}

variable "vm_user" {
  type        = string
  description = "User default di VM"
}

variable "ansible_user" {
  type        = string
  description = "Override user SSH Ansible. Jika null, vm memakai vm_user dan lxc memakai root."
  default     = null
  nullable    = true
}

variable "ssh_public_key_path" {
  type        = string
  description = "Path SSH public key"
}

variable "ssh_public_key" {
  type        = string
  description = "Isi SSH public key secara inline. Jika diisi, Terraform tidak akan membaca file dari ssh_public_key_path."
  default     = null
  nullable    = true
}

variable "ssh_private_key_path" {
  type        = string
  description = "Path SSH private key untuk Ansible"
}

variable "vm_started" {
  type        = bool
  description = "Nyalakan VM setelah dibuat oleh Terraform"
  default     = true
}

variable "cloud_image_file_id" {
  type        = string
  description = "File ID cloud image yang sudah tersedia di datastore Proxmox, misalnya local:import/noble-server-cloudimg-amd64.qcow2"
  default     = null
  nullable    = true
}

variable "container_template_file_id" {
  type        = string
  description = "File ID template LXC yang sudah tersedia di datastore Proxmox, misalnya local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
  default     = null
  nullable    = true
}

variable "container_operating_system_type" {
  type        = string
  description = "Tipe OS untuk LXC sesuai provider Proxmox"
  default     = "ubuntu"
}

variable "lxc_unprivileged" {
  type        = bool
  description = "Jalankan LXC sebagai unprivileged container"
  default     = true
}

variable "lxc_nesting" {
  type        = bool
  description = "Aktifkan fitur nesting pada LXC"
  default     = true
}

variable "lxc_swap" {
  type        = number
  description = "Ukuran swap LXC dalam MB"
  default     = 0
}

variable "lxc_network_interface_name" {
  type        = string
  description = "Nama interface jaringan di dalam LXC"
  default     = "eth0"
}

variable "vm_defaults" {
  type = object({
    role      = optional(string)
    cpu_cores = number
    memory    = number
    disk_size = number
  })

  description = "Nilai default untuk VM/LXC yang akan dipakai jika field per-instance tidak diisi"
  default = {
    role      = "app"
    cpu_cores = 1
    memory    = 1024
    disk_size = 12
  }
}

variable "vms" {
  type = map(object({
    vm_id     = number
    vm_ip     = string
    role      = optional(string)
    tags      = optional(list(string), [])
    cpu_cores = optional(number)
    memory    = optional(number)
    disk_size = optional(number)
  }))

  description = "Daftar VM/LXC yang akan dibuat. vm_id dan vm_ip wajib, field lain bisa mengambil nilai dari vm_defaults."
}
