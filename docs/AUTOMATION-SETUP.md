# Setup Automasi Provisioning

Dokumen ini fokus pada tata cara menyiapkan automasi provisioning di repo ini dari nol sampai siap dijalankan.

Target akhirnya:

- Proxmox host lab bisa diakses dari Windows host
- token API Proxmox siap dipakai Terraform
- konfigurasi `terraform.tfvars` siap
- script helper bisa dijalankan berulang dengan cepat

Dokumen ini diasumsikan untuk workflow yang direkomendasikan di laptop ini:

- `workload_type = "vm"`
- `vm_started = false`
- mode `API-only`

## Gambaran Alur

Urutan besar setup:

1. siapkan Proxmox host lab di VirtualBox
2. pastikan endpoint Proxmox stabil
3. buat token API Proxmox
4. siapkan file konfigurasi Terraform
5. siapkan token untuk sesi Bash
6. cek prerequisite lokal
7. jalankan provisioning otomatis

## 1. Siapkan Proxmox Host Lab

Pastikan Anda sudah punya:

- VM `Proxmox-Lab` di VirtualBox
- Proxmox sudah terpasang
- VM bisa dinyalakan dari Windows host

Untuk menyalakan VM host Proxmox:

```bash
./scripts/start-proxmox-lab.sh
```

Atau mode headless:

```bash
./scripts/start-proxmox-lab.sh -Type headless
```

## 2. Pastikan Endpoint Proxmox Stabil

Di repo ini, endpoint yang direkomendasikan adalah host-only management:

```text
https://192.168.56.20:8006
```

Sebelum lanjut, pastikan:

- Proxmox bisa diping dari Windows host
- Web UI Proxmox bisa dibuka di browser

Tes sederhana:

```bash
ping 192.168.56.20
```

Jika endpoint belum stabil, ikuti:

- [PROXMOX-HOSTONLY-NETWORK.md](/abs/D:\infra-lab\proxmox-multi-vm\PROXMOX-HOSTONLY-NETWORK.md:1)

## 3. Buat Token API Proxmox

Token ini dipakai Terraform untuk autentikasi ke API Proxmox.

### Langkah di Proxmox UI

1. Buka web UI Proxmox  
   Contoh:
   `https://192.168.56.20:8006`

2. Login sebagai user admin  
   Contoh:
   `root@pam`

3. Buka:
   `Datacenter`

4. Masuk ke:
   `Permissions`

5. Buka tab:
   `API Tokens`

6. Klik:
   `Add`

7. Isi:

- `User`: `root@pam`
- `Token ID`: `terraform`

8. Untuk homelab sederhana, paling praktis:

- nonaktifkan `Privilege Separation`
- pastikan token tidak `disabled`

9. Klik `Add`

10. Simpan secret token yang ditampilkan

### Format Token yang Dipakai di Repo Ini

Format wajib:

```text
USER@REALM!TOKENID=SECRET
```

Contoh:

```text
root@pam!terraform=12345678-1234-1234-1234-123456789abc
```

Catatan:

- secret token biasanya hanya ditampilkan sekali
- jika hilang, buat token baru
- jangan simpan token asli di `terraform.tfvars`

## 4. Siapkan File Terraform

Repo ini menyediakan contoh file:

- [terraform/terraform.tfvars.example](/abs/D:\infra-lab\proxmox-multi-vm\terraform\terraform.tfvars.example:1)

Salin menjadi file lokal Anda:

```bash
cp ./terraform/terraform.tfvars.example ./terraform/terraform.tfvars
```

Lalu sesuaikan bila perlu.

### Konfigurasi yang Direkomendasikan untuk Laptop Ini

Pastikan file lokal Anda setidaknya seperti ini:

```hcl
proxmox_endpoint      = "https://192.168.56.20:8006/"
proxmox_tls_insecure  = true
workload_type         = "vm"
vm_started            = false
proxmox_node          = "pve-lab"
vm_datastore_id       = "local-lvm"
network_bridge        = "vmbr0"
vm_gateway            = "192.168.10.1"
vm_cidr               = 24
dns_servers           = ["8.8.8.8", "1.1.1.1"]
vm_user               = "ubuntu"
ssh_public_key_path   = "~/.ssh/id_ed25519.pub"
ssh_private_key_path  = "~/.ssh/id_ed25519"
cloud_image_file_id   = "local:import/noble-server-cloudimg-amd64.qcow2"
```

### Contoh Topologi Multi-VM

Repo ini mendukung banyak host otomatis lewat `vms`.

Contoh:

```hcl
vm_defaults = {
  role      = "app"
  cpu_cores = 1
  memory    = 1024
  disk_size = 12
}

vms = {
  web-01 = {
    vm_id = 101
    vm_ip = "192.168.10.101"
    role  = "web"
    tags  = ["frontend"]
  }

  app-01 = {
    vm_id = 102
    vm_ip = "192.168.10.102"
    role  = "app"
    tags  = ["backend"]
  }

  db-01 = {
    vm_id     = 103
    vm_ip     = "192.168.10.103"
    role      = "db"
    tags      = ["backend"]
    cpu_cores = 2
    memory    = 2048
  }
}
```

## 5. Siapkan Token untuk Sesi Bash

Repo ini menyediakan helper:

- [scripts/set-proxmox-token.sh](/abs/D:\infra-lab\proxmox-multi-vm\scripts/set-proxmox-token.sh:1)

Cara paling mudah:

```bash
source ./scripts/set-proxmox-token.sh
```

Lalu paste token Anda dalam format:

```text
root@pam!terraform=SECRET
```

Atau langsung:

```bash
source ./scripts/set-proxmox-token.sh -TokenValue "root@pam!terraform=SECRET"
```

## 6. Cek Prerequisite Lokal

Setelah token diset, jalankan:

```bash
./scripts/check-prereqs.sh
```

Kalau nanti ingin melibatkan Ansible juga:

```bash
./scripts/check-prereqs.sh -RequireAnsible
```

Yang dicek script ini:

- folder Terraform dan Ansible
- file `terraform.tfvars`
- playbook Ansible
- `terraform.exe`
- `ansible-playbook` di WSL, jika diminta
- environment variable `TF_VAR_proxmox_api_token`

## 7. Jalankan Automasi Provisioning

### Mode yang Direkomendasikan Saat Ini

Untuk laptop ini, mode yang paling stabil:

```bash
./scripts/apply-and-configure.sh -SkipAnsible
```

Kenapa:

- `vm_started = false`
- nested KVM tidak tersedia stabil
- jadi target utamanya adalah provisioning objek VM di Proxmox via API

### Jika Sudah Pernah `terraform init`

Untuk mempercepat:

```bash
./scripts/apply-and-configure.sh -SkipTerraformInit -SkipAnsible
```

### Jika Ingin Menjalankan Flow Penuh

Flow penuh baru masuk akal jika target workload memang bisa dijalankan, misalnya:

- `workload_type = "lxc"`
- `vm_started = true`

Saat itu perintahnya:

```bash
./scripts/apply-and-configure.sh
```

## 8. Verifikasi Hasil

Sesudah provisioning, cek:

```bash
cat ./ansible/inventory.ini
```

Untuk mode `API-only`:

- inventory bisa kosong
- output Terraform akan menulis `not available while vm_started = false`

Itu perilaku yang benar.

## 9. Hapus Resource Jika Diperlukan

Untuk destroy:

```bash
./scripts/destroy-lab.sh
```

Atau tanpa prompt:

```bash
./scripts/destroy-lab.sh -AutoApprove
```

## 10. Matikan VM Host Proxmox

Jika sudah selesai:

```bash
./scripts/stop-proxmox-lab.sh
```

Atau paksa:

```bash
./scripts/stop-proxmox-lab.sh -Mode poweroff
```

## Cheat Sheet Harian

Urutan cepat harian:

```bash
cd "D:\infra-lab\proxmox-multi-vm"
./scripts/start-proxmox-lab.sh -Type headless
source ./scripts/set-proxmox-token.sh
./scripts/check-prereqs.sh
./scripts/apply-and-configure.sh -SkipTerraformInit -SkipAnsible
```

## Troubleshooting Cepat

### `401 Authentication failed`

Penyebab paling umum:

- token salah
- token disabled
- token dibuat untuk user yang berbeda

Solusi:

- buat token baru di Proxmox UI
- set ulang lewat `set-proxmox-token.sh`

### `terraform apply` sukses tapi host tidak bisa di-SSH

Kalau `vm_started = false`, itu normal. Repo ini sedang bekerja di mode `API-only`.

### `ansible-playbook` tidak ditemukan

Gunakan:

```bash
./scripts/apply-and-configure.sh -SkipAnsible
```

atau siapkan Ansible di WSL.

### Web UI Proxmox tidak bisa dibuka

Periksa:

- VM `Proxmox-Lab` menyala
- endpoint host-only `192.168.56.20`
- network Proxmox guest

## File Terkait

- [README.md](/abs/D:\infra-lab\proxmox-multi-vm\README.md:1)
- [RUNBOOK.md](/abs/D:\infra-lab\proxmox-multi-vm\RUNBOOK.md:1)
- [terraform/terraform.tfvars.example](/abs/D:\infra-lab\proxmox-multi-vm\terraform\terraform.tfvars.example:1)
- [scripts/set-proxmox-token.sh](/abs/D:\infra-lab\proxmox-multi-vm\scripts/set-proxmox-token.sh:1)
- [scripts/check-prereqs.sh](/abs/D:\infra-lab\proxmox-multi-vm\scripts/check-prereqs.sh:1)
- [scripts/apply-and-configure.sh](/abs/D:\infra-lab\proxmox-multi-vm\scripts/apply-and-configure.sh:1)
- [scripts/destroy-lab.sh](/abs/D:\infra-lab\proxmox-multi-vm\scripts/destroy-lab.sh:1)
