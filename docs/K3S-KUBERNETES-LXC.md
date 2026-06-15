# Panduan K3s Kubernetes di Proxmox LXC (Unprivileged)

Dokumen ini menjelaskan arsitektur, batasan teknis, solusi, serta langkah operasional untuk menjalankan cluster Kubernetes ringan (K3s) di atas Proxmox LXC Container (Unprivileged) dalam lingkungan lab lokal Anda.

---

## 1. Arsitektur Cluster

Cluster Kubernetes K3s ini terdiri dari 3 node yang dikelola secara deklaratif melalui Terraform dan dikonfigurasi menggunakan Ansible:

| Hostname | Alamat IP | Peran (Role) | Tipe Kontainer | Alokasi Resource |
| :--- | :--- | :--- | :--- | :--- |
| **app-01** | `192.168.177.102` | Control Plane (Master) | LXC (Unprivileged) | 1 CPU, 1GB RAM, 12GB Disk |
| **app-02** | `192.168.177.105` | Worker Node (Agent) | LXC (Unprivileged) | 1 CPU, 1GB RAM, 12GB Disk |
| **web-01** | `192.168.177.101` | Worker Node (Agent) | LXC (Unprivileged) | 1 CPU, 1GB RAM, 12GB Disk |

---

## 2. Mengapa Memilih Unprivileged LXC?

Pada awalnya, direncanakan untuk menggunakan Virtual Machine (VM) penuh dengan QEMU. Namun, terdapat batasan pada lingkungan host Anda:
1. **VirtualBox Nested Virtualization Terbatas**: Proxmox berjalan di dalam VirtualBox dengan nested virtualization yang tidak aktif (mode NEM). Hal ini menyebabkan VM QEMU di dalam Proxmox tidak dapat melakukan booting/menyala.
2. **Keamanan API Token Proxmox**: API Token Proxmox (`root@pam!token`) dilarang keras oleh sistem keamanan Proxmox untuk memodifikasi atau membuat kontainer bertipe *Privileged*. 

Oleh karena itu, jalur yang realistis dan aman adalah menggunakan **Unprivileged LXC Container** dengan fitur **Nesting** diaktifkan.

---

## 3. Batasan Teknis & Solusi Workaround

Secara default, Kubernetes membutuhkan akses penuh ke kernel induk untuk memuat modul jaringan dan memodifikasi parameter kernel. Karena Unprivileged LXC meminjam kernel Proxmox host dengan hak akses terbatas, dua modifikasi berikut wajib diterapkan agar K3s dapat berjalan:

### A. Masalah `/dev/kmsg` Hilang
Kubelet membutuhkan `/dev/kmsg` untuk memantau kejadian OOM (Out Of Memory). File ini tidak ada di dalam unprivileged LXC.

* **Solusi**: Membuat aturan `systemd-tmpfiles` yang secara otomatis membuat tautan simbolis (*symlink*) `/dev/kmsg` ke `/dev/console` setiap kali kontainer dinyalakan.
* **Implementasi di Ansible (`k3s.yml`)**:
  ```yaml
  pre_tasks:
    - name: Create systemd-tmpfiles configuration for /dev/kmsg
      ansible.builtin.copy:
        dest: /etc/tmpfiles.d/kmsg.conf
        content: "L /dev/kmsg - - - - /dev/console\n"
  ```

### B. Error Tulis `/proc/sys` (Read-Only)
Kubelet mencoba menulis ke `/proc/sys/vm/overcommit_memory` dan parameter kernel lainnya saat booting. Di unprivileged LXC, direktori ini bersifat *read-only*.

* **Solusi**: Mengaktifkan feature gate `KubeletInUserNamespace` pada Kubelet dan API Server. Feature gate ini memerintahkan Kubelet untuk mengabaikan error tulis pada direktori `/proc/sys` karena menyadari ia sedang berjalan di namespace pengguna yang terisolasi.
* **Implementasi di Ansible (`group_vars/`)**:
  * **Master (`k3s_master.yml`)**:
    ```yaml
    k3s_server:
      kubelet-arg:
        - "feature-gates=KubeletInUserNamespace=true"
      kube-apiserver-arg:
        - "feature-gates=KubeletInUserNamespace=true"
    ```
  * **Worker (`k3s_worker.yml`)**:
    ```yaml
    k3s_agent:
      kubelet-arg:
        - "feature-gates=KubeletInUserNamespace=true"
    ```

---

## 4. Langkah Penyebaran (Deployment Guide)

### Prasyarat
1. Pastikan Proxmox Host menyala (`192.168.177.128`).
2. Pastikan Adapter virtual VMnet milik VMware di Windows dalam keadaan aktif (jaringan `192.168.177.x`).

### Langkah 1: Provisioning Infrastruktur (Terraform)
Masuk ke folder `terraform` di terminal Bash Anda (WSL/Git Bash), lalu jalankan:
```bash
cd D:/Data\ Joni/terraform/proxmox-multi-vm/terraform
terraform apply -lock=false
```
*Pastikan parameter `workload_type = "lxc"` dan `lxc_unprivileged = true` pada file `terraform.tfvars`.*

### Langkah 2: Konfigurasi & Instalasi K3s (Ansible)
Masuk ke folder `ansible` dan jalankan playbook dengan parameter bypass pengecekan Host Key SSH:
```bash
cd ../ansible
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory.ini k3s.yml
```
> [!NOTE]  
> Mengapa menggunakan `ANSIBLE_HOST_KEY_CHECKING=False`?  
> Karena file `ansible.cfg` diabaikan oleh Ansible di folder drive Windows `/mnt/d/` (karena terdeteksi sebagai *world-writable directory*). Penggunaan variable ini memastikan Ansible tidak terhenti meminta konfirmasi interaktif atas kunci SSH kontainer baru.

---

## 5. Verifikasi Cluster

### A. Mengecek Status Node dari Master Node
Hubungkan ke Master Node (`app-01`) menggunakan kunci SSH lab Anda:
```bash
ssh -i ~/.ssh/lab_key root@192.168.177.102 "k3s kubectl get nodes"
```

Output yang benar akan menampilkan semua node dengan status **`Ready`**:
```text
NAME     STATUS   ROLES                  AGE     VERSION
app-01   Ready    control-plane,master   5m      v1.28.4+k3s2
web-01   Ready    <none>                 3m      v1.28.4+k3s2
app-02   Ready    <none>                 3m      v1.28.4+k3s2
```

### B. Mengakses Cluster secara Lokal dari WSL Anda
Agar Anda bisa memanipulasi cluster langsung dari komputer lokal Anda tanpa melakukan SSH, ikuti langkah ini:

1. Buat folder config di WSL Anda:
   ```bash
   mkdir -p ~/.kube
   ```
2. Salin konfigurasi Kubernetes dari Master Node:
   ```bash
   ssh -i ~/.ssh/lab_key root@192.168.177.102 "cat /etc/rancher/k3s/k3s.yaml" > ~/.kube/config
   ```
3. Ubah alamat API server dari local loopback ke IP publik Master Node:
   ```bash
   sed -i 's/127.0.0.1/192.168.177.102/g' ~/.kube/config
   ```
4. Amankan izin akses file konfigurasi tersebut:
   ```bash
   chmod 600 ~/.kube/config
   ```
5. Tes koneksi dari WSL:
   ```bash
   kubectl get nodes
   ```

---

## 6. Troubleshooting Mandiri

* **K3s tidak mau menyala setelah reboot kontainer**: 
  Periksa apakah `/dev/kmsg` telah berhasil disambungkan kembali. Anda bisa melihat log systemd dengan:
  ```bash
  systemctl status systemd-tmpfiles-setup.service
  ```
* **Node Agen tidak terdeteksi**:
  Periksa log agen di node worker (`app-02` atau `web-01`) untuk memastikan koneksi ke Master IP berhasil:
  ```bash
  journalctl -u k3s --no-pager -n 50
  ```
