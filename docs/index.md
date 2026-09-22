# Muhammad Rizky | IT Operations & Systems Support Runbook

[![LinkedIn Profile](https://img.shields.io/badge/LinkedIn-mrizkymxx-0A66C2?style=flat-square&logo=linkedin)](https://www.linkedin.com/in/mrizkymxx)
[![GitHub Repository](https://img.shields.io/badge/GitHub-it--support--portfolio-181717?style=flat-square&logo=github)](https://github.com/mrizkymxx/it-support-portfolio)
[![Status](https://img.shields.io/badge/Operational_Status-Active-2ea44f?style=flat-square)]()

Dokumentasi teknis, prosedur standar operasional (SOP), investigasi akar masalah insiden (Root Cause Analysis / ITIL Postmortems), dan arsitektur homelab untuk peran **IT Support Specialist**, **L2 Systems Support**, dan **Junior Systems Administrator**.

---

## Ringkasan Profil Teknis

Praktisi Sistem Informasi (S1 Sistem Informasi - UNISNU Jepara) dengan keahlian operasional infrastruktur IT, manajemen direktori (Active Directory / Entra ID), administrasi jaringan (VLAN / Firewall), database troubleshooting (SQL), dan otomasi administrasi sistem (PowerShell / Bash).

| Domain | Teknologi Utama |
|---|---|
| **Sistem Operasi & Server** | Windows Server 2019/2022, Windows 10/11 Pro, Ubuntu Server, Debian |
| **Direktori & Identitas** | Active Directory Domain Services (AD DS), Azure AD / Entra ID, Group Policy (GPO), DNS/DHCP |
| **Jaringan & Keamanan** | pfSense/OPNsense, Cisco Switch (VLAN 802.1Q), OpenVPN/WireGuard, Wireshark, UFW, Iptables |
| **Virtualisasi & Cloud** | Proxmox VE, Hyper-V, AWS (EC2, S3, VPC, IAM), Docker |
| **Database & Kueri** | SQL (PostgreSQL, MySQL, SQL Server) — analisa data korup & error log |
| **Bahasa Skrip** | PowerShell 7, Bash Shell, Python |
| **ITSM & Monitoring** | Standar ITIL v4 (Incident, Problem, Change), Zabbix, Windows Event Viewer |

---

## Topologi Homelab & Lingkungan Uji Coba

Seluruh studi kasus, pengujian insiden, dan skrip pada repositori ini diuji pada lingkungan virtualisasi terisolasi:

```mermaid
graph TD
    WAN[Internet / ISP] --> FW[pfSense Virtual Firewall / Router]
    
    subgraph LAN_10 [VLAN 10: Management & Core Services - 10.10.10.0/24]
        FW --> SW[Managed Virtual Switch]
        SW --> DC01[DC01: Windows Server 2022 - AD DS / DNS / DHCP]
        SW --> MON01[MON01: Linux Zabbix Server & Syslog]
    end

    subgraph LAN_20 [VLAN 20: Corporate Workstations - 10.10.20.0/24]
        SW --> PC01[PC01: Win 11 Pro - Domain Joined]
        SW --> PC02[PC02: Win 10 Pro - Domain Joined]
    end

    subgraph LAN_30 [VLAN 30: Lab DMZ & Web Servers - 10.10.30.0/24]
        SW --> SRV01[SRV01: Nginx Reverse Proxy / SSL]
        SW --> DB01[DB01: PostgreSQL Database Server]
    end
```

---

## Struktur Dokumentasi

1. **[Kredensial & Sertifikasi](certifications.md)**  
   Verifikasi sertifikasi resmi (Dicoding, AWS Cloud, SQL, Data Science) yang dipetakan langsung ke fungsi dukungan teknis.
2. **[Studi Kasus Insiden (ITIL)](incidents/INC-202609-kerberos-auth-skew.md)**  
   Laporan post-mortem investigasi kegagalan sistem nyata: diagnosa CLI, analisis 5-Whys, mitigasi, dan tindakan pencegahan.
3. **[SOP Operasional](sops/active-directory/user-onboarding.md)**  
   Panduan teknis langkah-demi-langkah onboarding Active Directory dan pemeliharaan server Linux.
4. **[Arsitektur Jaringan](networking/vlan-segmentation-matrix.md)**  
   Dokumentasi matriks segmentasi VLAN, alokasi subnet, dan konfigurasi firewall edge.
5. **[Otomasi & Skrip](scripts/powershell/audit-stale-ad-accounts.md)**  
   Skrip PowerShell dan Bash siap pakai untuk audit sistem berkala dan self-healing service.
