# Panduan Menghubungkan Project ke Server Kerja

Dokumen ini menjelaskan variabel dan konfigurasi apa saja yang perlu Anda ubah ketika ingin melakukan *deployment* atau menyambungkan project lokal Anda ke server yang ada di tempat kerja Anda.

Terdapat dua bagian berdasarkan dua project Anda: **Proxmox Multi-VM (Terraform)** dan **CDC - Kafka (Docker Compose)**.

---

## 1. Project Proxmox Multi-VM (`proxmox-multi-vm`)
Jika Anda ingin agar Terraform melakukan *provisioning* ke server Proxmox di tempat kerja, Anda harus mengubah file **`terraform/terraform.tfvars`** serta mengatur kredensial otentikasinya.

### File yang Diubah: `terraform.tfvars`

Buka file `terraform/terraform.tfvars` dan ubah variabel-variabel berikut agar sesuai dengan *environment* Proxmox di tempat kerja:

```hcl
# 1. Endpoint & Kredensial Proxmox
proxmox_endpoint     = "https://<IP_SERVER_KERJA>:8006/" # Ganti dengan IP/Domain Proxmox tempat kerja

# 2. Konfigurasi Node Proxmox
proxmox_node         = "pve"                             # Ganti dengan nama node Proxmox di tempat kerja
vm_datastore_id      = "local-lvm"                       # Ganti dengan nama storage yang tersedia (misal: "local-zfs" atau "ceph")
network_bridge       = "vmbr0"                           # Ganti dengan interface bridge yang digunakan di server kerja

# 3. Konfigurasi Jaringan & IP Address
vm_gateway           = "192.168.x.x"                     # Ganti dengan IP Gateway jaringan di tempat kerja
vm_cidr              = 24                                # Sesuaikan subnet mask
dns_servers          = ["8.8.8.8", "1.1.1.1"]            # Bisa disesuaikan dengan DNS internal kantor jika ada

# 4. Alokasi IP Address untuk setiap VM
vms = {
  web-01 = {
    vm_id = 101
    vm_ip = "192.168.x.101" # Ganti semua `vm_ip` agar berada di blok IP yang valid di server kerja
    # ...
  }
  # ... Lakukan hal yang sama untuk VM lainnya ...
}
```

### Konfigurasi Otentikasi API
Selain file `terraform.tfvars`, pastikan Anda juga mengekspor API Token atau kredensial dari Proxmox tempat kerja ke *environment variable* komputer Anda sebelum menjalankan `terraform apply`:

```bash
# Untuk Linux/MacOS/GitBash
export PM_API_TOKEN_ID="user@pam!token_id"
export PM_API_TOKEN_SECRET="xxxx-xxxx-xxxx-xxxx"

# Untuk Windows Bash
$env:PM_API_TOKEN_ID="user@pam!token_id"
$env:PM_API_TOKEN_SECRET="xxxx-xxxx-xxxx-xxxx"
```

---

## 2. Project CDC - Kafka (`CDC - Kafka`)
Jika Anda men-deploy Kafka cluster ini di server kerja menggunakan Docker Compose, Anda harus memastikan Kafka dapat diakses oleh layanan di luar server tersebut.

### File yang Diubah: `docker-compose.yml`

Buka `docker-compose.yml` dan cari layanan `kafka`. Ubah pada bagian **`KAFKA_ADVERTISED_LISTENERS`**.

**Sebelumnya (Lokal):**
```yaml
KAFKA_ADVERTISED_LISTENERS: INTERNAL://kafka:9092,EXTERNAL://localhost:29092
```

**Setelah Diubah (Server Kerja):**
```yaml
KAFKA_ADVERTISED_LISTENERS: INTERNAL://kafka:9092,EXTERNAL://<IP_SERVER_KERJA>:29092
```
*Ganti `<IP_SERVER_KERJA>` dengan alamat IP publik atau IP LAN server kerja Anda tempat docker berjalan.* 

Hal ini **sangat penting** agar saat client (atau Anda dari laptop) ingin mempublikasikan/mengonsumsi data dari Kafka dari luar server, Kafka akan merespons dengan IP server yang benar, bukan merespons dengan `localhost`.

### Tambahan: Firewall Server Kerja
Pastikan juga port-port berikut ini **di-allow (dibuka)** pada Firewall server kerja Anda agar bisa diakses dari luar:
- `29092` (Akses Kafka)
- `8080` (Akses Kafka UI)
- `8083` (Akses Kafka Connect REST API)
- `5432` (Akses PostgreSQL jika perlu diremote)
