# Environment Architecture

Dokumen ini merangkum arsitektur logical per environment untuk repo `proxmox-multi-vm`.

## Tujuan

Environment dipisahkan agar:

- konfigurasi `dev`, `staging`, dan `prod` lebih mudah dipahami
- naming, tagging, subnet, dan sizing dapat dibedakan
- workflow Terraform lebih reusable

## Struktur Environment

Contoh file environment ada di:

- `terraform/environments/dev.tfvars.example`
- `terraform/environments/staging.tfvars.example`
- `terraform/environments/prod.tfvars.example`

File `.example` aman di-commit.
File kerja nyata seperti `dev.tfvars` tidak di-commit.

## Arsitektur Dev

Karakteristik:

- sizing kecil
- cocok untuk validasi perubahan
- fokus pada kecepatan iterasi

Contoh:

- tag default: `dev`
- resource default: 1 vCPU, 1024 MB RAM, 12 GB disk
- workload minimal: `web-01`, `app-01`

## Arsitektur Staging

Karakteristik:

- lebih mendekati production
- dipakai untuk integration test dan validasi deployment
- baseline resource lebih besar dari dev

Contoh:

- tag default: `staging`
- resource default: 2 vCPU, 2048 MB RAM, 20 GB disk
- workload: `web-01`, `app-01`, `db-01`

## Arsitektur Prod

Karakteristik:

- sizing paling besar
- memisahkan tier aplikasi dan observability
- menambahkan monitoring node

Contoh:

- tag default: `prod`
- resource default: 2 vCPU, 4096 MB RAM, 30 GB disk
- workload: `web-01`, `app-01`, `db-01`, `monitoring-01`

## Pola Layer Platform

Lapisan logical yang direkomendasikan:

1. Infrastructure layer
   - Proxmox node
   - datastore
   - bridge network

2. Workload layer
   - VM atau LXC per role
   - role: `web`, `app`, `db`, `monitoring`

3. Automation layer
   - Terraform untuk provisioning
   - Ansible untuk bootstrap

4. Observability layer
   - Prometheus
   - Grafana
   - Loki
   - Alertmanager

5. Delivery layer
   - GitHub Actions validation
   - Terraform plan artifact

## Command Pattern

Contoh menjalankan environment tertentu:

```bash
cp terraform/environments\staging.tfvars.example terraform/environments\staging.tfvars
./scripts/apply-and-configure.sh -SkipAnsible -EnvironmentName staging
```

## Catatan Praktis

- untuk laptop ini, mode yang paling stabil tetap `API-only`
- artinya environment architecture tetap bisa divalidasi walau nested KVM tidak tersedia
- jika nanti dipindah ke host yang mendukung nested virtualization penuh, struktur environment ini tetap bisa dipakai kembali
