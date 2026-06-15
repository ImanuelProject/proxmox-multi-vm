# Proxmox Host-Only Management

Dokumen ini menjelaskan pola jaringan yang lebih stabil untuk lab lokal:

- `NIC 1`: bridged atau NAT untuk akses internet guest
- `NIC 2`: host-only untuk akses management yang stabil dari host Windows

Target management IP yang direkomendasikan:

- Host Windows host-only: `192.168.56.1/24`
- Proxmox management: `192.168.56.20/24`

## Kenapa Pola Ini Dipakai

Jika Proxmox management memakai bridged Wi-Fi, IP guest akan bergantung pada jaringan Wi-Fi aktif. Saat pindah hotspot atau Wi‑Fi kantor/rumah, endpoint API bisa berubah atau tidak reachable.

Host-only network menghindari masalah itu karena:

- IP host-only Windows tetap
- IP management Proxmox bisa dibuat tetap
- Terraform tidak perlu berganti `proxmox_endpoint` saat Anda pindah Wi‑Fi

## Yang Sudah Disiapkan Dari Sisi Host

VM `Proxmox-Lab` sekarang memakai:

- `NIC 1`: bridged ke adaptor Wi‑Fi host
- `NIC 2`: host-only `VirtualBox Host-Only Ethernet Adapter`

Script bantu:

```bash
./scripts/configure-hostonly-management.sh
```

## Langkah Di Guest Proxmox

Lakukan dari console Proxmox guest.

### 1. Identifikasi nama interface

```bash
ip a
```

Biasanya akan ada dua interface ethernet. Cari interface yang terhubung ke NIC host-only.

### 2. Edit network config

Periksa file:

```bash
cat /etc/network/interfaces
```

Contoh target sederhana:

```bash
auto lo
iface lo inet loopback

iface eno1 inet manual
iface eno2 inet manual

auto vmbr0
iface vmbr0 inet static
    address 192.168.56.20/24
    bridge-ports eno2
    bridge-stp off
    bridge-fd 0
```

Catatan:

- `eno2` hanya contoh, sesuaikan dengan nama interface host-only Anda
- jika Anda masih ingin internet dari bridged/NAT, jangan pindahkan semuanya ke interface yang salah
- untuk konfigurasi yang lebih kompleks, Anda bisa tetap mempertahankan bridge lain untuk uplink internet

### 3. Reload network

Lakukan dengan hati-hati dari console:

```bash
ifreload -a
```

atau reboot guest:

```bash
reboot
```

### 4. Uji dari host Windows

Setelah guest naik lagi:

```bash
ping 192.168.56.20
```

Lalu buka:

```text
https://192.168.56.20:8006/
```

## Setelah Guest Sudah Stabil

Baru ubah file lokal `terraform/terraform.tfvars`:

```hcl
proxmox_endpoint = "https://192.168.56.20:8006/"
```

Jika Anda juga ingin VM hasil Terraform dapat diakses stabil dari host, desain subnet VM dan bridge Proxmox perlu dirapikan lagi secara terpisah.
