# Secrets And Operations

Dokumen ini merangkum baseline secret handling dan operasional untuk repo homelab ini.

## Secret Handling

### Prinsip

- jangan simpan token Proxmox di `terraform.tfvars`
- jangan commit file `*.tfvars`
- gunakan environment variable per sesi Bash

### Format Token

Format token yang benar:

```text
USER@REALM!TOKENID=SECRET
```

Contoh:

```text
root@pam!terraform=12345678-1234-1234-1234-123456789abc
```

### Cara Set Token

Interaktif:

```bash
source ./scripts/set-proxmox-token.sh
```

Langsung dengan nilai:

```bash
source ./scripts/set-proxmox-token.sh -TokenValue "root@pam!terraform=SECRET"
```

### Verifikasi

```bash
./scripts/check-prereqs.sh
```

Atau langsung ke API:

```bash
curl.exe -k -i -H "Authorization: PVEAPIToken=$env:TF_VAR_proxmox_api_token" "https://192.168.56.20:8006/api2/json/version"
```

## Operational Baseline

### Flow Harian API-Only

```bash
./scripts/start-proxmox-lab.sh -Type headless
source ./scripts/set-proxmox-token.sh
./scripts/check-prereqs.sh
./scripts/apply-and-configure.sh -SkipAnsible
```

### Flow Environment-Aware

```bash
source ./scripts/set-proxmox-token.sh
./scripts/check-prereqs.sh -EnvironmentName dev
./scripts/apply-and-configure.sh -SkipAnsible -EnvironmentName dev
```

### Flow Destroy

```bash
./scripts/destroy-lab.sh -EnvironmentName dev
```

## Checklist Operasional

- Proxmox host-only endpoint bisa diakses
- token Proxmox valid
- `terraform validate` lolos
- inventory yang dihasilkan sesuai mode workload
- gunakan `-SkipAnsible` jika `workload_type = "vm"` dan `vm_started = false`

## Rotasi Token

Jika token tidak valid:

1. buat token baru di Proxmox UI
2. set ulang ke sesi Bash
3. jangan ubah repo untuk menyimpan token itu

## Yang Aman Di-commit

- `terraform.tfvars.example`
- `terraform/environments/*.tfvars.example`
- workflow CI/CD
- playbook Ansible
- docs dan scripts

## Yang Tidak Boleh Di-commit

- `terraform.tfvars`
- `terraform/environments/*.tfvars`
- `terraform.tfstate*`
- `ansible/inventory.ini`
- token asli
