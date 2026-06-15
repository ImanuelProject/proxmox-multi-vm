# Environment-Aware Structure

Repo ini sekarang mendukung pola environment-aware agar workflow local homelab bisa berkembang ke pola yang lebih mendekati praktik platform engineering.

## Struktur yang Direkomendasikan

```text
terraform/
  terraform.tfvars
  terraform.tfvars.example
  environments/
    dev.tfvars.example
    staging.tfvars.example
    prod.tfvars.example
```

`terraform/terraform.tfvars` tetap dipakai sebagai default local working file.

Folder `terraform/environments/` dipakai untuk:

- menyimpan contoh konfigurasi per environment
- memisahkan subnet, tag, dan ukuran resource
- menyiapkan transisi ke workflow yang lebih formal

## Cara Memakai Environment Tertentu

1. Salin example environment ke file kerja lokal:

```bash
cp terraform/environments\dev.tfvars.example terraform/environments\dev.tfvars
```

2. Edit file hasil salin sesuai kebutuhan.

3. Jalankan script dengan environment name:

```bash
./scripts/apply-and-configure.sh -SkipAnsible -EnvironmentName dev
```

Atau langsung dengan var-file eksplisit:

```bash
./scripts/apply-and-configure.sh -SkipAnsible -VarFile "terraform/environments\dev.tfvars"
```

Destroy juga mendukung pola yang sama:

```bash
./scripts/destroy-lab.sh -EnvironmentName dev
```

## Kapan Memakai Masing-Masing Pola

- `terraform.tfvars`: untuk kerja lokal cepat di satu environment
- `terraform/environments/*.tfvars`: untuk pemisahan dev/staging/prod yang lebih jelas

## Catatan

- file `*.tfvars` di-ignore dari Git
- file `*.tfvars.example` aman untuk di-commit
- script helper sekarang membaca `terraform.tfvars` secara default, tetapi bisa diarahkan ke environment tertentu lewat `-EnvironmentName` atau `-VarFile`
