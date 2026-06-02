# Kubernetes Roadmap for Platform Engineer

Dokumen ini berisi roadmap belajar Kubernetes dari sudut pandang Platform Engineer.

Fokusnya bukan menghafal semua command atau semua object Kubernetes, tetapi memahami Kubernetes sebagai platform runtime yang akan menjadi kelanjutan alami setelah automation provisioning selesai.

## Tujuan Utama

Sebagai Platform Engineer, target memahami Kubernetes adalah:

- memahami bagaimana aplikasi berjalan di atas cluster
- memahami bagaimana developer melakukan deploy dengan aman dan konsisten
- memahami bagaimana platform menyediakan networking, security, observability, dan delivery workflow
- memahami hubungan antara infrastructure provisioning, cluster runtime, dan developer self-service

## Cara Belajar Yang Disarankan

Jangan mulai dari YAML yang terlalu detail.

Urutan terbaik:

1. pahami masalah yang ingin diselesaikan Kubernetes
2. pahami arsitektur cluster
3. pahami object dasar untuk menjalankan aplikasi
4. pahami add-on platform
5. pahami delivery workflow ke cluster
6. pahami observability dan security baseline

## Tahap 1: Pahami Kenapa Kubernetes Dipakai

Sebelum masuk ke teknis, pahami dulu alasan kenapa Kubernetes digunakan.

Pertanyaan yang harus bisa dijawab:

- kenapa tidak cukup pakai VM manual?
- kenapa butuh scheduler?
- kenapa desired state penting?
- kenapa service discovery dibutuhkan?
- kenapa self-healing dan autoscaling menjadi nilai utama?

Kalau Anda bisa menjelaskan ini, Anda sudah punya fondasi berpikir yang benar.

## Tahap 2: Pahami Arsitektur Dasar Cluster

### Control Plane

Komponen utama:

- API Server
- Scheduler
- Controller Manager
- etcd

Yang perlu dipahami:

- API server adalah pintu masuk semua perubahan state
- scheduler menentukan pod ditempatkan ke node mana
- controller manager menjaga desired state
- etcd menyimpan state cluster

### Worker Node

Komponen utama:

- kubelet
- container runtime
- kube-proxy

Yang perlu dipahami:

- kubelet menjalankan instruksi dari control plane ke node
- container runtime mengeksekusi container
- kube-proxy membantu routing jaringan service

### Hasil Belajar Tahap Ini

Anda harus bisa menjelaskan:

- perbedaan control plane dan worker node
- bagaimana request deploy masuk ke API server lalu berakhir menjadi pod yang berjalan

## Tahap 3: Pahami Object Dasar Kubernetes

Object yang wajib dipahami dulu:

- Pod
- Deployment
- ReplicaSet
- Service
- Namespace
- ConfigMap
- Secret
- Ingress

Yang perlu dikuasai:

- kapan object digunakan
- hubungan antar object
- masalah apa yang diselesaikan tiap object

### Fokus Praktis

- `Pod`: unit terkecil tempat container berjalan
- `Deployment`: menjaga replika aplikasi tetap sesuai desired state
- `Service`: memberi endpoint stabil untuk akses internal
- `Ingress`: mengatur akses HTTP/HTTPS ke aplikasi
- `ConfigMap` dan `Secret`: menyimpan konfigurasi dan data sensitif

## Tahap 4: Pahami Alur Deploy Aplikasi End-to-End

Ini bagian yang sangat penting untuk Platform Engineer.

Contoh alur:

1. developer push code
2. CI build image
3. image di-push ke registry
4. manifest atau Helm release di-update
5. Deployment dibuat atau diperbarui
6. pod dijadwalkan ke worker node
7. Service expose aplikasi di dalam cluster
8. Ingress expose aplikasi ke luar
9. metrics dan logs dikumpulkan

Kalau alur ini jelas, Anda sudah memahami cluster sebagai platform delivery.

## Tahap 5: Pahami Add-On Yang Biasanya Dikelola Platform Engineer

Kubernetes cluster yang nyata hampir selalu butuh add-on.

Yang wajib dipahami:

- Ingress Controller
- cert-manager
- metrics-server
- Horizontal Pod Autoscaler
- RBAC
- NetworkPolicy
- PersistentVolume / StorageClass

### Penjelasan Singkat

- `Ingress Controller`: pintu masuk traffic HTTP/HTTPS
- `cert-manager`: automasi sertifikat TLS
- `metrics-server`: sumber data untuk autoscaling dasar
- `HPA`: scaling pod otomatis
- `RBAC`: kontrol akses pengguna dan service account
- `NetworkPolicy`: kontrol traffic antar workload
- `StorageClass`: standardisasi penyimpanan persisten

## Tahap 6: Pahami Template Deployment

Platform Engineer jarang deploy aplikasi murni dari YAML mentah.

Yang perlu dipahami:

- Helm Chart
- Kustomize
- reusable deployment template

Kenapa ini penting:

- developer butuh pola deploy yang konsisten
- platform engineer perlu menyediakan golden path

Target minimum:

- satu template service web
- satu template API service
- satu template worker/background job

## Tahap 7: Pahami Observability Di Kubernetes

Observability adalah bagian wajib dari platform.

Yang perlu dipahami:

- metrics
- logging
- tracing
- alerting

Tool umum:

- Prometheus
- Grafana
- Loki
- Alertmanager
- OpenTelemetry
- Jaeger atau Tempo

Yang perlu dipahami bukan hanya tool-nya, tetapi:

- data apa yang dikumpulkan
- dari mana datanya datang
- alert mana yang relevan untuk platform

## Tahap 8: Pahami Security Baseline

Kubernetes tanpa security baseline akan cepat berisiko.

Topik penting:

- RBAC
- Secret management
- image scanning
- pod security
- network segmentation
- admission policy

Contoh tool atau konsep yang relevan:

- External Secrets
- Vault / SSM
- OPA / Gatekeeper
- Kyverno
- image scanning di pipeline

## Tahap 9: Hubungkan Dengan Terraform, CI/CD, dan Platform Workflow

Karena Anda sudah punya dasar provisioning, Anda tidak belajar Kubernetes dalam ruang kosong.

Peta hubungannya:

- Terraform: provision cluster dan resource pendukung
- CI/CD: build, test, deploy aplikasi
- Helm/Kustomize: template deployment
- Observability: monitor cluster dan workload
- Secret handling: injeksi konfigurasi aman
- Self-service: developer cukup isi template dan jalankan pipeline

Di titik ini Anda mulai berpikir sebagai Platform Engineer, bukan hanya operator infra.

## Prioritas Belajar Untuk Interview

Kalau waktu terbatas, prioritaskan ini:

### Prioritas 1

- Pod
- Deployment
- Service
- Ingress

### Prioritas 2

- control plane vs worker node
- scheduler
- kubelet
- etcd

### Prioritas 3

- ingress controller
- cert-manager
- HPA
- RBAC

### Prioritas 4

- Helm chart
- CI/CD deploy workflow
- observability stack dasar

## Jawaban Singkat Yang Perlu Bisa Dijelaskan

Contoh hal yang sebaiknya bisa Anda jelaskan saat interview:

- Kubernetes adalah platform runtime untuk menjalankan aplikasi secara declarative.
- Platform Engineer tidak hanya membuat cluster, tetapi membuat jalur deploy yang aman dan reusable di atas cluster itu.
- Setelah provisioning infrastructure selesai, langkah platform berikutnya adalah standardisasi deployment, observability, security, dan self-service workflow.
- Helm, ingress, cert-manager, metrics, dan RBAC adalah layer penting yang biasanya dikelola oleh Platform Engineer.

## Langkah Praktis Setelah Dokumen Ini

Urutan belajar yang disarankan:

1. pahami arsitektur cluster
2. pahami object inti
3. pahami alur deploy aplikasi
4. pahami add-on platform
5. pahami observability dan security baseline
6. pahami self-service / golden path

## Ringkasan Singkat

Kalau ingin berpindah dari automation provisioning ke Kubernetes, fokusnya adalah:

- dari VM atau infra provisioning
- ke runtime platform
- lalu ke deployment standardization
- lalu ke observability, security, dan self-service

Jadi tujuan belajar Kubernetes untuk Platform Engineer bukan hanya bisa menjalankan `kubectl`, tetapi memahami bagaimana membangun platform yang bisa dipakai developer dengan aman, konsisten, dan scalable.
