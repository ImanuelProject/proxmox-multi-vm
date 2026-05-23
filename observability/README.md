# Basic Observability Starter

Folder ini berisi baseline observability sederhana untuk menunjukkan arah platform engineering:

- Prometheus untuk metrics
- Grafana untuk dashboard
- Loki untuk logs
- Alertmanager untuk alert routing dasar

Konfigurasi ini belum diikat langsung ke Terraform/Proxmox karena tujuan utamanya adalah:

- memberi starter stack yang mudah dijelaskan saat interview
- menjadi next step setelah provisioning automation selesai
- menunjukkan bagaimana observability menjadi layer lintas infrastruktur dan aplikasi

## Isi Folder

```text
observability/
  docker-compose.yml.example
  alertmanager/
    alertmanager.yml
  prometheus/
    prometheus.yml
    alert.rules.yml
  loki/
    local-config.yml
  grafana/
    provisioning/
      datasources/
        datasources.yml
      dashboards/
        dashboards.yml
        json/
          platform-overview.json
```

## Cara Pakai Cepat

1. Copy file compose:

```powershell
Copy-Item observability\docker-compose.yml.example observability\docker-compose.yml
```

2. Sesuaikan target scrape Prometheus jika perlu.

3. Jalankan dari folder `observability` dengan Docker Compose.

## Catatan

- untuk role `monitoring`, playbook Ansible sekarang menyiapkan `prometheus` dan `prometheus-node-exporter`
- untuk host lain, playbook juga memasang `prometheus-node-exporter`
- stack ini adalah baseline, bukan observability production-grade
