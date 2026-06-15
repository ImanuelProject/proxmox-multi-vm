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

- `terraform/main.tf`: root Terraform config, provider, module call, dan inventory Ansible
- `terraform/modules/proxmox-workloads/`: module reusable untuk VM/LXC Proxmox
- `terraform/variables.tf`: definisi variabel Terraform
- `terraform/terraform.tfvars.example`: contoh konfigurasi lokal
- `terraform/environments/*.tfvars.example`: contoh konfigurasi per environment
- `ansible/playbook.yml`: bootstrap dasar VM Ubuntu
- `ansible/requirements.yml`: daftar collection Ansible untuk lint dan bootstrap
- `scripts/apply-and-configure.sh`: flow `terraform -> inventory -> ansible`
- `scripts/destroy-lab.sh`: flow `terraform destroy`
- `scripts/start-proxmox-lab.sh`: start VM host Proxmox di VirtualBox
- `scripts/stop-proxmox-lab.sh`: stop VM host Proxmox di VirtualBox
- `scripts/check-prereqs.sh`: cek dependency lokal
- `scripts/set-proxmox-token.sh`: set token Proxmox untuk sesi terminal Bash aktif
- `scripts/configure-hostonly-management.sh`: pasang NIC host-only untuk management Proxmox
- `PROXMOX-HOSTONLY-NETWORK.md`: panduan memindahkan IP management Proxmox ke host-only network
- `ENVIRONMENT-ARCHITECTURE.md`: arsitektur logical per environment
- `RUNBOOK.md`: panduan operasional harian
- `.github/workflows/iac-validate.yml`: validasi Terraform, lint Ansible, dan artifact `terraform plan`
- `observability/`: starter stack Prometheus, Loki, Grafana, dan Alertmanager

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

```bash
source ./scripts/set-proxmox-token.sh
./scripts/start-proxmox-lab.sh
./scripts/check-prereqs.sh -RequireAnsible
./scripts/apply-and-configure.sh
```

Jika hanya ingin provisioning Terraform:

```bash
./scripts/apply-and-configure.sh -SkipAnsible
```

Jika ingin destroy semua resource Terraform:

```bash
./scripts/destroy-lab.sh
```

## Tutorial Menjalankan Lab

Urutan paling aman untuk menjalankan lab ini dari nol:

1. Buka terminal Bash di folder repo:

```bash
cd "d:/Data Joni/terraform/proxmox-multi-vm"
```

2. Nyalakan VM host Proxmox:

```bash
./scripts/start-proxmox-lab.sh
```

3. Set token Proxmox untuk sesi terminal aktif:

```bash
source ./scripts/set-proxmox-token.sh
```

4. Cek prerequisite lokal:

```bash
./scripts/check-prereqs.sh
```

5. Pastikan `terraform/terraform.tfvars` sudah sesuai kebutuhan.

Untuk mode stabil di laptop ini:

```hcl
workload_type = "vm"
vm_started    = false
```

6. Jalankan provisioning Terraform:

```bash
./scripts/apply-and-configure.sh -SkipAnsible
```

7. Lihat output Terraform dan inventory hasil generate:

```bash
cat ./ansible/inventory.ini
```

8. Jika ingin menghapus semua resource Terraform:

```bash
./scripts/destroy-lab.sh
```

9. Jika selesai menggunakan lab, matikan VM host Proxmox:

```bash
./scripts/stop-proxmox-lab.sh
```

Catatan:

- untuk mode `vm` dengan `vm_started = false`, inventory bisa kosong dan output SSH akan menampilkan `not available while vm_started = false`
- itu perilaku yang benar untuk mode `API-only`

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

## Skala Multi-VM

Struktur `vms` sekarang mendukung:

- default global lewat `vm_defaults`
- `role` per instance
- `tags` per instance
- override CPU, memory, dan disk hanya untuk host tertentu

Pola yang direkomendasikan:

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
    vm_id     = 102
    vm_ip     = "192.168.10.102"
    role      = "app"
    tags      = ["backend"]
    cpu_cores = 2
    memory    = 2048
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

Hasilnya:

- setiap entri tetap dibuat otomatis lewat `for_each`
- host tanpa override akan memakai nilai dari `vm_defaults`
- inventory Ansible akan punya grup per role seperti `role_web`, `role_app`, dan `role_db`

Contoh skenario `5 VM`:

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

  monitoring-01 = {
    vm_id     = 104
    vm_ip     = "192.168.10.104"
    role      = "monitoring"
    tags      = ["ops"]
    disk_size = 20
  }

  app-02 = {
    vm_id     = 105
    vm_ip     = "192.168.10.105"
    role      = "app"
    tags      = ["backend"]
    cpu_cores = 2
    memory    = 2048
  }
}
```

Grup inventory Ansible yang akan terbentuk:

- `role_web`
- `role_app`
- `role_db`
- `role_monitoring`

Contoh isi `ansible/inventory.ini` untuk topologi itu:

```ini
[proxmox_vms]
web-01 ansible_host=192.168.10.101 ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_ed25519
app-01 ansible_host=192.168.10.102 ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_ed25519
db-01 ansible_host=192.168.10.103 ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_ed25519
monitoring-01 ansible_host=192.168.10.104 ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_ed25519
app-02 ansible_host=192.168.10.105 ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_ed25519

[role_web]
web-01

[role_app]
app-01
app-02

[role_db]
db-01

[role_monitoring]
monitoring-01
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

```bash
./scripts/configure-hostonly-management.sh
```

Panduan guest-side:

- buka [PROXMOX-HOSTONLY-NETWORK.md](/abs/D:\Data Joni\terraform\proxmox-multi-vm\PROXMOX-HOSTONLY-NETWORK.md:1)

Catatan:

- contoh `terraform.tfvars.example` sudah memakai endpoint host-only `192.168.56.20`
- sesuaikan lagi bila guest Proxmox Anda memakai IP management yang berbeda

## Script Helper

| Kebutuhan | Command |
| --- | --- |
| Start VM Proxmox via GUI | `./scripts/start-proxmox-lab.sh` |
| Start VM Proxmox headless | `./scripts/start-proxmox-lab.sh -Type headless` |
| Stop VM Proxmox graceful | `./scripts/stop-proxmox-lab.sh` |
| Stop VM Proxmox paksa | `./scripts/stop-proxmox-lab.sh -Mode poweroff` |
| Set token Proxmox per sesi | `source ./scripts/set-proxmox-token.sh` |
| Cek dependency dasar | `./scripts/check-prereqs.sh` |
| Cek dependency termasuk Ansible | `./scripts/check-prereqs.sh -RequireAnsible` |
| Provision Terraform saja | `./scripts/apply-and-configure.sh -SkipAnsible` |
| Provision environment tertentu | `./scripts/apply-and-configure.sh -SkipAnsible -EnvironmentName dev` |
| Provision + bootstrap | `./scripts/apply-and-configure.sh` |
| Provision tanpa prompt approval | `./scripts/apply-and-configure.sh -AutoApprove` |
| Destroy resource | `./scripts/destroy-lab.sh` |
| Destroy environment tertentu | `./scripts/destroy-lab.sh -EnvironmentName dev` |
| Destroy tanpa prompt approval | `./scripts/destroy-lab.sh -AutoApprove` |

<details>
<summary>Contoh command lengkap</summary>

```bash
./scripts/start-proxmox-lab.sh
./scripts/start-proxmox-lab.sh -Type headless
./scripts/stop-proxmox-lab.sh
./scripts/stop-proxmox-lab.sh -Mode poweroff
source ./scripts/set-proxmox-token.sh
./scripts/check-prereqs.sh
./scripts/check-prereqs.sh -RequireAnsible
./scripts/apply-and-configure.sh
./scripts/apply-and-configure.sh -SkipAnsible
./scripts/apply-and-configure.sh -AutoApprove
./scripts/destroy-lab.sh
./scripts/destroy-lab.sh -AutoApprove
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

## Terraform Module Layout

Terraform sekarang dipisah menjadi root config dan module reusable:

- root `terraform/main.tf` menangani provider, wiring variable, dan inventory
- module `terraform/modules/proxmox-workloads/` menangani resource VM/LXC dan normalisasi workload

Tujuannya:

- root config tetap tipis
- logika provisioning lebih mudah dipakai ulang
- struktur lebih siap untuk berkembang ke environment atau stack tambahan

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
- `vm_defaults`: default CPU, memory, disk, dan role untuk semua instance
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

Set token Proxmox untuk sesi terminal Bash aktif:

```bash
source ./scripts/set-proxmox-token.sh
```

Atau jika ingin langsung memberi nilainya:

```bash
source ./scripts/set-proxmox-token.sh -TokenValue "root@pam!terraform=your-token"
```

Lalu jalankan flow normal:

```bash
./scripts/check-prereqs.sh
./scripts/apply-and-configure.sh -SkipAnsible
```

## CI-CD Dan Environment-Aware

Repo ini sekarang punya workflow validasi GitHub Actions di:

- `.github/workflows/iac-validate.yml`

Workflow itu menjalankan:

- `terraform fmt -check`
- `terraform init -backend=false`
- `terraform validate`
- `terraform plan -refresh=false -lock=false`
- `ansible-lint`
- `yamllint`

Artifact yang dihasilkan:

- `terraform-plan-report`
- berisi file binary `tfplan`
- berisi report teks `tfplan.txt`

Repo ini juga mendukung struktur environment-aware melalui:

- `terraform/environments/dev.tfvars.example`
- `terraform/environments/staging.tfvars.example`
- `terraform/environments/prod.tfvars.example`
- `ENVIRONMENT-ARCHITECTURE.md`

Untuk menjalankan environment tertentu, salin dulu file example ke file lokal lalu gunakan:

```bash
cp terraform/environments/dev.tfvars.example terraform/environments/dev.tfvars
./scripts/apply-and-configure.sh -SkipAnsible -EnvironmentName dev
```

## Observability Dasar

Repo ini sekarang menyediakan starter observability di folder `observability/`.

Isinya:

- Prometheus config
- Loki config
- Grafana datasource provisioning
- Grafana dashboard provisioning
- Alertmanager config
- `docker-compose.yml.example`
- alert rules dasar dan baseline host alert

Untuk host yang benar-benar menyala, playbook Ansible juga sekarang menambahkan baseline berikut:

- `prometheus-node-exporter`
- `rsyslog`
- `prometheus` khusus role `monitoring`

Cara cepat menjalankan stack observability lokal:

```bash
docker compose -f ./observability/docker-compose.yml.example up -d
```

Service yang aktif:

- Grafana: `http://localhost:3000`
- Prometheus: `http://localhost:9090`
- Loki: `http://localhost:3100`
- Alertmanager: `http://localhost:9093`

Dashboard dan alerting yang sudah disiapkan:

- dashboard Grafana `Platform Overview`
- alert `InstanceDown`
- alert `HostHighCpuUsage`
- alert `HostHighMemoryUsage`
- alert `HostDiskAlmostFull`
