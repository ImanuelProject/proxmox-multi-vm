# Secrets And Operations

Dokumen ini merangkum baseline secret handling dan operasional untuk repo homelab ini.

## Secret Handling

### Prinsip

- jangan simpan token Proxmox di `terraform.tfvars`
- jangan commit file `*.tfvars`
- gunakan environment variable per sesi PowerShell

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

```powershell
.\scripts\set-proxmox-token.ps1
```

Langsung dengan nilai:

```powershell
.\scripts\set-proxmox-token.ps1 -TokenValue "root@pam!terraform=SECRET"
```

### Verifikasi

```powershell
.\scripts\check-prereqs.ps1
```

Atau langsung ke API:

```powershell
curl.exe -k -i -H "Authorization: PVEAPIToken=$env:TF_VAR_proxmox_api_token" "https://192.168.56.20:8006/api2/json/version"
```

## Operational Baseline

### Flow Harian API-Only

```powershell
.\scripts\start-proxmox-lab.ps1 -Type headless
.\scripts\set-proxmox-token.ps1
.\scripts\check-prereqs.ps1
.\scripts\apply-and-configure.ps1 -SkipAnsible
```

### Flow Environment-Aware

```powershell
.\scripts\set-proxmox-token.ps1
.\scripts\check-prereqs.ps1 -EnvironmentName dev
.\scripts\apply-and-configure.ps1 -SkipAnsible -EnvironmentName dev
```

### Flow Destroy

```powershell
.\scripts\destroy-lab.ps1 -EnvironmentName dev
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
2. set ulang ke sesi PowerShell
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
