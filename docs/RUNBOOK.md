# Runbook Operasional

Runbook ini dipakai untuk mode `API-only` pada laptop host yang menjalankan Windows 11 + WSL2. Nested KVM di dalam Proxmox guest tidak menjadi target operasional harian.

## Navigasi Cepat

- [Checklist sebelum mulai](#checklist-sebelum-mulai)
- [Flow harian standar](#flow-harian-standar)
- [Mode host-only management](#mode-host-only-management)
- [Skenario umum](#skenario-umum)
- [Verifikasi hasil](#verifikasi-hasil)
- [Troubleshooting ringkas](#troubleshooting-ringkas)
- [Kembali ke repo](#kembali-ke-repo)

## Checklist Sebelum Mulai

Centang item yang relevan sebelum bekerja:

- [ ] VM `Proxmox-Lab` di VirtualBox tersedia
- [ ] Web UI dan API Proxmox dapat diakses
- [ ] File `terraform/terraform.tfvars` sudah ada
- [ ] `TF_VAR_proxmox_api_token` sudah diset di shell aktif
- [ ] SSH key yang dirujuk di `terraform.tfvars` tersedia
- [ ] `workload_type` di `terraform.tfvars` sesuai target yang ingin dijalankan
- [ ] jika `workload_type = "vm"`, `cloud_image_file_id` sesuai dengan image yang benar-benar ada di datastore Proxmox
- [ ] jika `workload_type = "lxc"`, `container_template_file_id` sesuai dengan template yang benar-benar ada di datastore Proxmox
- [ ] Terraform tersedia di `D:\aplikasi\terraform\terraform.exe` atau di `PATH`
- [ ] VirtualBox tersedia di `C:\Program Files\Oracle\VirtualBox\VBoxManage.exe` atau di `PATH`
- [ ] `ansible-playbook` tersedia di distro `WSL2`

Command bantu:

```bash
source ./scripts/set-proxmox-token.sh
./scripts/check-prereqs.sh
./scripts/check-prereqs.sh -RequireAnsible
```

## Flow Harian Standar

### 1. Start lab Proxmox

Mode GUI:

```bash
./scripts/start-proxmox-lab.sh
```

Mode headless:

```bash
./scripts/start-proxmox-lab.sh -Type headless
```

### 2. Cek prerequisite lokal

Jika hanya ingin validasi dasar:

```bash
./scripts/check-prereqs.sh
```

Jika juga ingin memastikan Ansible tersedia:

```bash
./scripts/check-prereqs.sh -RequireAnsible
```

Jika token belum diset di sesi terminal Bash aktif:

```bash
source ./scripts/set-proxmox-token.sh
```

### Mode Host-Only Management

Jika endpoint Proxmox bridged tidak stabil atau berubah saat pindah Wi-Fi:

1. matikan VM `Proxmox-Lab`
2. jalankan:

```bash
./scripts/configure-hostonly-management.sh
```

3. ikuti panduan di [PROXMOX-HOSTONLY-NETWORK.md](/abs/D:\Data Joni\terraform\proxmox-multi-vm\PROXMOX-HOSTONLY-NETWORK.md:1)
4. setelah guest memakai IP `192.168.56.20`, ubah `terraform/terraform.tfvars`

Target hasil akhirnya:

- host Windows: `192.168.56.1`
- Proxmox API: `https://192.168.56.20:8006/`

Script ini akan:

- mencari `terraform.exe` secara otomatis
- mencari `VBoxManage.exe` secara otomatis saat dibutuhkan
- mengecek `ansible-playbook` langsung di `WSL2`

### 3. Provision resource

Pilih mode di `terraform/terraform.tfvars` lebih dulu:

- `workload_type = "vm"` untuk mode API-only berbasis VM
- `workload_type = "lxc"` untuk container yang benar-benar bisa dijalankan di laptop ini

Provision Terraform saja:

```bash
./scripts/apply-and-configure.sh -SkipAnsible
```

Provision + bootstrap:

```bash
./scripts/apply-and-configure.sh
```

Provision + bootstrap tanpa prompt approval:

```bash
./scripts/apply-and-configure.sh -AutoApprove
```

### 4. Verifikasi hasil

Setelah `apply`, periksa:

- [ ] resource VM muncul di Proxmox
- [ ] VM target menyala bila `vm_started = true`
- [ ] `ansible/inventory.ini` sudah tergenerate
- [ ] SSH ke VM target berhasil
- [ ] halaman Nginx hasil bootstrap dapat diakses

Command cepat:

```bash
cat ./ansible/inventory.ini
```

### 5. Destroy resource Terraform

Mode biasa:

```bash
./scripts/destroy-lab.sh
```

Tanpa prompt approval:

```bash
./scripts/destroy-lab.sh -AutoApprove
```

### 6. Stop lab Proxmox

Shutdown halus:

```bash
./scripts/stop-proxmox-lab.sh
```

Shutdown paksa:

```bash
./scripts/stop-proxmox-lab.sh -Mode poweroff
```

## Skenario Umum

### Terraform tersedia, Ansible belum tersedia

Pakai:

```bash
./scripts/apply-and-configure.sh -SkipAnsible
```

### Token Proxmox belum diset di terminal baru

Pakai:

```bash
source ./scripts/set-proxmox-token.sh
./scripts/check-prereqs.sh
```

### Ingin menjalankan workload nyata tanpa nested KVM

Pakai mode:

```hcl
workload_type              = "lxc"
vm_started                 = true
container_template_file_id = "local:vztmpl/NAMA_TEMPLATE_ANDA.tar.zst"
```

Lalu jalankan:

```bash
./scripts/apply-and-configure.sh
```

### Ingin mengulang apply tanpa `terraform init`

Pakai:

```bash
./scripts/apply-and-configure.sh -SkipTerraformInit
```

### Ingin mengulang destroy tanpa `terraform init`

Pakai:

```bash
./scripts/destroy-lab.sh -SkipTerraformInit
```

### Hanya ingin menyalakan atau mematikan VM host Proxmox

Pakai:

```bash
./scripts/start-proxmox-lab.sh
./scripts/stop-proxmox-lab.sh
```

## Verifikasi Hasil

Jika flow penuh selesai, hasil minimal yang diharapkan:

- Proxmox API tetap responsif
- VM target dibuat sesuai `terraform.tfvars`
- inventory Ansible tergenerate otomatis
- paket dasar terpasang
- Nginx aktif di VM target

<details>
<summary>Checklist verifikasi manual</summary>

- buka Proxmox web UI dan cek daftar VM
- lihat isi `ansible/inventory.ini`
- SSH ke salah satu VM target
- akses IP VM target via browser atau `curl`

</details>

## Troubleshooting Ringkas

### `terraform` tidak ditemukan

Binary Terraform belum ada di `PATH` shell Windows yang dipakai script.

### `ansible-playbook` tidak ditemukan

Gunakan `-SkipAnsible` atau siapkan Ansible lebih dulu.

### Inventory Ansible tidak muncul

Periksa apakah `terraform apply` sukses dan resource `local_file` berjalan normal.

### VM gagal diakses via SSH

Periksa:

- status VM di Proxmox
- IP statis di `terraform.tfvars`
- bridge network Proxmox
- SSH key yang dipakai
- reachability jaringan dari host ke VM target

### LXC gagal dibuat

Periksa:

- `workload_type` benar-benar bernilai `lxc`
- `container_template_file_id` benar dan file template memang ada di datastore Proxmox
- bridge `vmbr0` dan IP statis yang dipakai container sesuai dengan jaringan Anda

### Installer Proxmox mengeluhkan KVM acceleration

Itu expected pada laptop ini selama `WSL2/Hyper-V/VBS` tetap aktif. Untuk repo ini, hal itu tidak menghalangi mode `API-only`.

## Kembali Ke Repo

- `README.md`
- `scripts/check-prereqs.sh`
- `scripts/set-proxmox-token.sh`
- `scripts/apply-and-configure.sh`
- `scripts/destroy-lab.sh`
- `scripts/start-proxmox-lab.sh`
- `scripts/stop-proxmox-lab.sh`
