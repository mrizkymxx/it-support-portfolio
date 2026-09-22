---
id: INC-20260914-02
title: Gangguan Resolusi DNS Internal Akibat Forwarder Loop dan Cache Stale
severity: P2 - High
status: Resolved
date: 2026-09-14
affected_services:
  - Internal Web Portals (portal.corp.local)
  - Intranet ERP Application
  - Workstation Name Resolution
mttr: 35m
---

# Laporan Insiden: Gangguan Resolusi DNS Internal (INC-20260914-02)

## Ringkasan Eksekutif
Workstation divisi Finance dan Operations gagal membuka intranet ERP dan portal perusahaan lokal (`https://portal.corp.local`). Browser menampilkan error `DNS_PROBE_FINISHED_NXDOMAIN`. Sementara itu, koneksi internet ke situs publik luar (Google, Microsoft) tetap berjalan normal.

Investigasi menemukan rekursi DNS terputus karena entri DNS Forwarder pada server DNS internal mengarah kembali ke IP loopback gateway lokal yang mengalami timeout port UDP 53.

## Metrik Insiden
- **Pengguna Terdampak:** Seluruh workstation di VLAN 20 (Divisi Finance & Operasional).
- **Waktu Mulai:** 2026-09-14 13:20 WIB.
- **Deteksi Tiket:** 2026-09-14 13:26 WIB.
- **Penyelesaian:** 2026-09-14 13:55 WIB.
- **MTTR:** 35 menit.

---

## Analisis Akar Masalah (5-Whys)
1. **Mengapa aplikasi intranet tidak bisa diakses?**  
   Nama host `portal.corp.local` gagal diterjemahkan menjadi alamat IP internal (`10.10.30.50`).
2. **Mengapa domain internal gagal di-resolve?**  
   Klien workstation mendapatkan jawaban status `Server Failure (SERVFAIL)` dari server DNS primer (`10.10.10.10`).
3. **Mengapa server DNS internal memberikan jawaban SERVFAIL?**  
   Layanan DNS Server mengalami exhaustion thread antrean kueri akibat DNS Forwarder mengulang kueri secara sirkular.
4. **Mengapa forwarder DNS salah konfigurasi?**  
   Adanya entri forwarder lama yang menunjuk ke interface firewall pfSense yang port DNS forwarding-nya telah dialihkan.
5. **Mengapa cache lokal klien tetap gagal setelah perbaikan ringan?**  
   Windows DNS Client Cache menyimpan status *negative cache entry* (NXDOMAIN/SERVFAIL) selama durasi MaxNegativeCacheTTL (900 detik).

---

## Bukti Diagnostik & Perintah Triage

### 1. Uji Resolusi dari Workstation

=== "PowerShell"
    ```powershell
    # Uji query DNS ke server spesifik
    Resolve-DnsName -Name portal.corp.local -Server 10.10.10.10 -Type A

    # Cek entri cache DNS lokal yang tersimpan
    Get-DnsClientCache | Where-Object { $_.Entry -like "*portal.corp*" }
    ```

=== "CMD Tradisional"
    ```cmd
    nslookup portal.corp.local 10.10.10.10
    ```

### 2. Log DNS Server (Event Viewer)
```text
Log Name:      DNS Server
Event ID:      5504
Level:         Warning
Description:   The DNS server encountered an invalid domain name in a packet from 10.10.10.1. 
               The packet will be dropped.
```

---

## Langkah Remediasi

### 1. Koreksi Konfigurasi Forwarder pada Windows DNS Server
Buka PowerShell dengan hak admin pada Domain Controller:

```powershell
# Hapus forwarder DNS yang bermasalah
Remove-DnsServerForwarder -IPAddress 10.10.10.1 -Force

# Tambahkan upstream forwarder otoritatif yang stabil (Cloudflare & Google)
Add-DnsServerForwarder -IPAddress 1.1.1.1, 8.8.8.8

# Bersihkan cache pada DNS Server
Clear-DnsServerCache -Force
```

### 2. Pembersihan Cache Massal di Sisi Klien
Eksekusi pembersihan cache pada workstation pengguna yang terdampak:

```powershell
# Bersihkan DNS cache lokal di Windows
Clear-DnsClientCache

# Registrasi ulang nama NetBIOS dan DNS adapter
Register-DnsClient
```

### 3. Verifikasi Akhir
```powershell
Resolve-DnsName -Name portal.corp.local -Server 10.10.10.10
```

*Output:*
```text
Name                                           Type   TTL   Section    IPAddress
----                                           ----   ---   -------    ---------
portal.corp.local                              A      3600  Answer     10.10.30.50
```

---

## Rencana Perbaikan Permanen
1. Memisahkan Authoritative DNS internal (`corp.local`) agar tidak pernah mem-forward zona lokal ke gateway luar.
2. Menyusun SOP pengetesan DNS sebelum dan sesudah perubahan topologi router/firewall.
