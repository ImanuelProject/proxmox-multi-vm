# Proxmox Multi-VM Lab

Lab ini dipakai untuk:

- menjalankan Proxmox VE di dalam VirtualBox
- mengakses Proxmox lewat API untuk provisioning Terraform
- membuat VM Ubuntu dengan cloud-init atau LXC Ubuntu dari template
- menjalankan bootstrap pasca-provisioning lewat Ansible

> Status yang direkomendasikan di laptop ini: `API-only lab`

## Mulai Cepat

Pilih aksi yang ingin Anda lakukan:

- [Lihat mode yang direkomendasikan](#mode-yang-direkomendasikan-di-laptop-ini)
- [Jalankan flow API-only](#flow-api-only)
- [Lihat script helper](#script-helper)
- [Lihat parameter penting](#parameter-yang-penting)
- [Lihat opsi host-only management](#host-only-management)
- [Buka runbook harian](#runbook-harian)
- [Lihat batasan dan risiko](#batasan-saat-ini)

## Struktur

- `terraform/main.tf`: provisioning provider Proxmox, cloud image, VM, dan inventory Ansible
- `terraform/variables.tf`: definisi variabel Terraform
- `terraform/terraform.tfvars.example`: contoh konfigurasi lokal
- `ansible/playbook.yml`: bootstrap dasar VM Ubuntu
- `scripts/apply-and-configure.ps1`: flow `terraform -> inventory -> ansible`
- `scripts/destroy-lab.ps1`: flow `terraform destroy`
- `scripts/start-proxmox-lab.ps1`: start VM host Proxmox di VirtualBox
- `scripts/stop-proxmox-lab.ps1`: stop VM host Proxmox di VirtualBox
- `scripts/check-prereqs.ps1`: cek dependency lokal
- `scripts/set-proxmox-token.ps1`: set token Proxmox untuk sesi PowerShell aktif
- `scripts/configure-hostonly-management.ps1`: pasang NIC host-only untuk management Proxmox
- `PROXMOX-HOSTONLY-NETWORK.md`: panduan memindahkan IP management Proxmox ke host-only network
- `RUNBOOK.md`: panduan operasional harian

## Mode Yang Direkomendasikan Di Laptop Ini

Laptop host ini menjalankan Windows 11 + `WSL2`, dan hypervisor Windows aktif. Karena itu VirtualBox tidak mendapat akses langsung ke AMD-V/SVM dan jatuh ke mode kompatibilitas Hyper-V (`NEM`).

Konsekuensinya:

- Proxmox guest tetap bisa hidup
- Proxmox API tetap bisa dipakai
- Terraform dan Ansible tetap bisa dipakai
- nested KVM di dalam Proxmox guest tidak tersedia

Bukti teknis:

- `Proxmox-Lab/Logs/VBox.log` memuat `Attempting fall back to NEM: AMD-V is not available`
- `Proxmox-Lab/Logs/VBox.log` juga memuat `In nested-guest hwvirt mode = false`

Mode paling realistis untuk repo ini:

- gunakan Proxmox sebagai `API-only lab`
- jangan mengandalkan nested virtualization di dalam Proxmox guest

## Flow API-Only

Checklist singkat:

- [ ] VM `Proxmox-Lab` menyala
- [ ] Web UI / API Proxmox bisa diakses
- [ ] File lokal `terraform/terraform.tfvars` sudah ada
- [ ] Environment variable `TF_VAR_proxmox_api_token` sudah diset
- [ ] `vm_started = true` bila Anda ingin VM target langsung menyala
- [ ] Terraform tersedia di `D:\aplikasi\terraform\terraform.exe` atau di `PATH`
- [ ] VirtualBox tersedia di `C:\Program Files\Oracle\VirtualBox\VBoxManage.exe` atau di `PATH`
- [ ] `ansible-playbook` tersedia di distro `WSL2`

Command yang paling umum:

```powershell
.\scripts\set-proxmox-token.ps1
.\scripts\start-proxmox-lab.ps1
.\scripts\check-prereqs.ps1 -RequireAnsible
.\scripts\apply-and-configure.ps1
```

Jika hanya ingin provisioning Terraform:

```powershell
.\scripts\apply-and-configure.ps1 -SkipAnsible
```

Jika ingin destroy semua resource Terraform:

```powershell
.\scripts\destroy-lab.ps1
```

## Mode Workload

Repo ini sekarang mendukung dua mode workload:

- `workload_type = "vm"` untuk QEMU VM berbasis cloud image
- `workload_type = "lxc"` untuk LXC berbasis template container

Catatan penting:

- mode `vm` tetap cocok untuk belajar API Proxmox, tetapi guest tidak bisa benar-benar start di laptop ini selama nested KVM tidak tersedia
- mode `lxc` adalah jalur yang lebih realistis jika Anda ingin workload benar-benar hidup di dalam Proxmox guest

Contoh mode VM:

```hcl
workload_type      = "vm"
vm_started         = false
cloud_image_file_id = "local:import/noble-server-cloudimg-amd64.qcow2"
```

Contoh mode LXC:

```hcl
workload_type              = "lxc"
vm_started                 = true
container_template_file_id = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
```

Untuk mode `lxc`, inventory Ansible otomatis memakai user `root` kecuali Anda override `ansible_user`.

## Host-Only Management

Jika Anda ingin endpoint Proxmox stabil walau pindah Wi-Fi, gunakan host-only management.

Pola yang direkomendasikan:

- `NIC 1`: bridged/NAT untuk internet guest
- `NIC 2`: host-only untuk management
- target IP management Proxmox: `192.168.56.20`

Script host-side:

```powershell
.\scripts\configure-hostonly-management.ps1
```

Panduan guest-side:

- buka [PROXMOX-HOSTONLY-NETWORK.md](/abs/D:\Data Joni\terraform\proxmox-multi-vm\PROXMOX-HOSTONLY-NETWORK.md:1)

Catatan:

- contoh `terraform.tfvars.example` sudah memakai endpoint host-only `192.168.56.20`
- sesuaikan lagi bila guest Proxmox Anda memakai IP management yang berbeda

## Script Helper

| Kebutuhan | Command |
| --- | --- |
| Start VM Proxmox via GUI | `.\scripts\start-proxmox-lab.ps1` |
| Start VM Proxmox headless | `.\scripts\start-proxmox-lab.ps1 -Type headless` |
| Stop VM Proxmox graceful | `.\scripts\stop-proxmox-lab.ps1` |
| Stop VM Proxmox paksa | `.\scripts\stop-proxmox-lab.ps1 -Mode poweroff` |
| Set token Proxmox per sesi | `.\scripts\set-proxmox-token.ps1` |
| Cek dependency dasar | `.\scripts\check-prereqs.ps1` |
| Cek dependency termasuk Ansible | `.\scripts\check-prereqs.ps1 -RequireAnsible` |
| Provision Terraform saja | `.\scripts\apply-and-configure.ps1 -SkipAnsible` |
| Provision + bootstrap | `.\scripts\apply-and-configure.ps1` |
| Provision tanpa prompt approval | `.\scripts\apply-and-configure.ps1 -AutoApprove` |
| Destroy resource | `.\scripts\destroy-lab.ps1` |
| Destroy tanpa prompt approval | `.\scripts\destroy-lab.ps1 -AutoApprove` |

<details>
<summary>Contoh command lengkap</summary>

```powershell
.\scripts\start-proxmox-lab.ps1
.\scripts\start-proxmox-lab.ps1 -Type headless
.\scripts\stop-proxmox-lab.ps1
.\scripts\stop-proxmox-lab.ps1 -Mode poweroff
.\\scripts\\set-proxmox-token.ps1
.\scripts\check-prereqs.ps1
.\scripts\check-prereqs.ps1 -RequireAnsible
.\scripts\apply-and-configure.ps1
.\scripts\apply-and-configure.ps1 -SkipAnsible
.\scripts\apply-and-configure.ps1 -AutoApprove
.\scripts\destroy-lab.ps1
.\scripts\destroy-lab.ps1 -AutoApprove
```

</details>

## Runbook Harian

Untuk operasi langkah demi langkah, buka `RUNBOOK.md`.

Runbook itu berisi:

- checklist sebelum mulai
- urutan kerja start -> check -> apply -> verify -> destroy -> stop
- skenario umum
- troubleshooting ringkas

Catatan runtime:

- script tidak lagi bergantung penuh pada `PATH` untuk `terraform.exe` dan `VBoxManage.exe`
- Ansible dijalankan lewat `WSL2` menggunakan `wsl.exe`
- token Proxmox dibaca dari environment variable `TF_VAR_proxmox_api_token`

## Jika Ingin Mencoba Nested KVM

Nested KVM baru mungkin berjalan jika hypervisor Windows tidak mengambil alih virtualisasi hardware.

Checklist yang biasanya diperlukan:

1. Matikan `WSL2`.
2. Matikan `Virtual Machine Platform`.
3. Matikan `Windows Hypervisor Platform`.
4. Matikan `Hyper-V` jika ada.
5. Matikan `Memory Integrity / Core Isolation`.
6. Pastikan BIOS/UEFI mengaktifkan `SVM` atau `AMD-V`.
7. Set boot hypervisor ke off.
8. Reboot host Windows.
9. Jalankan ulang VirtualBox dan verifikasi nested virtualization benar-benar aktif.

Catatan:

- selama `WSL2` dipakai aktif, nested KVM di dalam VirtualBox sebaiknya dianggap tidak tersedia
- `NestedHWVirt` aktif di VirtualBox saja tidak cukup jika hypervisor Windows masih memegang AMD-V

## Batasan Saat Ini

- state Terraform masih lokal
- default contoh masih memakai `proxmox_tls_insecure = true`
- certificate self-signed cocok untuk homelab, tetapi bukan baseline ideal untuk environment produksi
- konfigurasi sekarang mengasumsikan cloud image sudah tersedia di datastore Proxmox melalui `cloud_image_file_id`
- konfigurasi LXC mengasumsikan template container sudah tersedia di datastore Proxmox melalui `container_template_file_id`

## Hygiene Repo

File `.gitignore` mengabaikan:

- state dan cache Terraform
- file `*.tfvars`
- inventory Ansible hasil generate
- log VirtualBox
- image dan disk lokal berukuran besar

Tujuannya agar repo hanya menyimpan source configuration, bukan secret dan artefak runtime.

## Parameter Yang Penting

- `workload_type`: pilih `vm` atau `lxc`
- `proxmox_tls_insecure`: pakai `true` jika endpoint Proxmox memakai certificate self-signed
- `vm_started`: pakai `true` untuk flow `Terraform -> Ansible`
- `vm_started`: pakai `false` jika Anda hanya ingin mendefinisikan VM tanpa langsung menyalakannya
- `cloud_image_file_id`: file ID image yang sudah ada di datastore, misalnya `local:import/noble-server-cloudimg-amd64.qcow2`
- `container_template_file_id`: file ID template LXC yang sudah ada di datastore, misalnya `local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst`
- `ansible_user`: override user SSH untuk inventory jika Anda tidak ingin default `vm_user` atau `root`

## Rekomendasi

Prioritas yang paling pragmatis:

1. pertahankan lab ini sebagai `API-only`
2. simpan token Proxmox di `TF_VAR_proxmox_api_token`, bukan di `terraform.tfvars`
3. jika ingin workload yang benar-benar hidup di laptop ini, prioritaskan `workload_type = "lxc"`
4. jika benar-benar perlu nested KVM, siapkan mode boot Windows terpisah tanpa `WSL2/Hyper-V/VBS`

## Secret Handling

Set token Proxmox untuk sesi PowerShell aktif:

```powershell
.\scripts\set-proxmox-token.ps1
```

Atau jika ingin langsung memberi nilainya:

```powershell
.\scripts\set-proxmox-token.ps1 -TokenValue "root@pam!terraform=your-token"
```

Lalu jalankan flow normal:

```powershell
.\scripts\check-prereqs.ps1
.\scripts\apply-and-configure.ps1 -SkipAnsible
```
