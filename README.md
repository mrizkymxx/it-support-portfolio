# Muhammad Rizky - IT Operations & Systems Support Runbook

[![Live Documentation](https://img.shields.io/badge/Live_Site-GitHub_Pages-2ea44f?style=for-the-badge&logo=githubpages&logoColor=white)](https://mrizkymxx.github.io/it-support-portfolio/)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-mrizkymxx-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/mrizkymxx)
[![SQL Certified](https://img.shields.io/badge/SQL_Certified-Dicoding_MRZMEG99NPYQ-0052CC?style=for-the-badge&logo=postgresql&logoColor=white)](https://dicoding.com/certificates/MRZMEG99NPYQ)

Repositori dokumentasi operasional IT Support, pemecahan masalah insiden berskala enterprise (ITIL Incident Post-mortems), Standard Operating Procedures (SOP), arsitektur jaringan VLAN/Firewall, dan skrip otomasi sistem.

---

## Ringkasan Proyek

- **Dokumentasi Lengkap:** [https://mrizkymxx.github.io/it-support-portfolio/](https://mrizkymxx.github.io/it-support-portfolio/)
- **Target Peran:** IT Support Specialist, L2 Systems Support Engineer, Junior SysAdmin.
- **Engine Dokumentasi:** MkDocs Material dengan pencarian instan klien, tab multi-OS, dan diagram Mermaid native.

---

## Daftar Isi Dokumentasi

1. **[Kredensial & Sertifikasi](docs/certifications.md)**: Sertifikasi resmi industri (Dicoding, AWS Cloud, SQL, Data Science) yang dipetakan ke fungsi operasional helpdesk dan server ops.
2. **[Studi Kasus Insiden (ITIL Postmortems)](docs/incidents/)**:
   - `INC-01`: Kegagalan Otentikasi Kerberos Akibat Clock Skew Domain Controller (+380s drift, diagnosa w32time, mitigasi hypervisor).
   - `INC-02`: Gangguan Resolusi DNS Internal Akibat Forwarder Loop & Cache Stale.
   - `INC-03`: Pemulihan Akses Pengguna Akibat Konflik Kebijakan Conditional Access Microsoft 365 (Entra ID).
3. **[SOP Operasional Baku](docs/sops/)**:
   - `SOP-IT-001`: Onboarding Pengguna Active Directory & Entra ID (Least Privilege, Group Assignment, Skrip Provisioning).
   - `SOP-IT-002`: Rotasi & Pembaruan Sertifikat SSL Nginx (Certbot hook & zero-downtime).
4. **[Arsitektur Jaringan & Keamanan](docs/networking/)**:
   - Matriks Segmentasi VLAN 10/20/30/40/99 dengan diagram alur isolasi.
   - Kebijakan Firewall Edge (Default Deny, Access Control Lists, Netfilter/iptables).
5. **[Skrip Otomasi](docs/scripts/)**:
   - `Get-StaleADAccounts.ps1`: Skrip audit akun dormant Active Directory (>90 hari) dengan ekspor CSV & penonaktifan aman.
   - `service-watchdog.sh`: Skrip watchdog self-healing untuk restart otomatis daemon Linux yang mati.

---

## Cara Menjalankan Secara Lokal

```bash
# 1. Clone repositori
git clone https://github.com/mrizkymxx/it-support-portfolio.git
cd it-support-portfolio

# 2. Buat virtual environment & install dependensi
python -m venv .venv
# Windows:
.venv\Scripts\activate
# Linux/macOS:
source .venv/bin/activate

pip install -r requirements.txt

# 3. Jalankan development server
mkdocs serve
```
Akses di browser pada `http://127.0.0.1:8000/`.

---

## Lisensi & Atribusi
Dibuat dan dipelihara oleh **Muhammad Rizky** ([@mrizkymxx](https://www.linkedin.com/in/mrizkymxx)).
