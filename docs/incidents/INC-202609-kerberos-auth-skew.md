---
id: INC-20260921-01
title: Kegagalan Otentikasi Kerberos Akibat Clock Skew Primary Domain Controller
severity: P1 - Critical
status: Resolved
date: 2026-09-21
affected_services:
  - Active Directory Domain Services (corp.local)
  - SMB File Shares (FS01.corp.local)
  - VPN RADIUS Authentication
mttr: 42m
---

# Laporan Insiden: Kegagalan Otentikasi Kerberos (INC-20260921-01)

## Ringkasan Eksekutif
Pada pukul 08:14 UTC, pengguna workstation domain melaporkan kegagalan login massal dan penolakan akses ke mapped network drives dengan kode error `STATUS_TIME_DIFFERENCE_AT_ISSUE` (0xC0000133). 

Investigasi menemukan bahwa Primary Domain Controller (`DC01.corp.local`) mengalami perbedaan waktu (clock drift) sebesar +380 detik terhadap server upstream NTP akibat sinkronisasi waktu hypervisor yang aktif tanpa kontrol setelah pembaruan host.

## Metrik Insiden
- **Pengguna Terdampak:** 450 workstation aktif di kantor pusat.
- **Waktu Mulai Insiden:** 2026-09-21 08:14 UTC.
- **Waktu Deteksi (Triage):** 2026-09-21 08:19 UTC (T+5m).
- **Waktu Remediasi:** 2026-09-21 08:48 UTC (T+34m).
- **Insiden Ditutup:** 2026-09-21 08:56 UTC (T+42m).

---

## Analisis Akar Masalah (5-Whys Method)
1. **Mengapa pengguna tidak bisa mengakses network drive dan login?**  
   Workstation ditolak saat melakukan handshake tiket Kerberos (TGS Request).
2. **Mengapa tiket Kerberos ditolak?**  
   Protokol Kerberos v5 membatasi toleransi selisih waktu maksimal 300 detik untuk mencegah serangan replay (RFC 4120).
3. **Mengapa waktu server dan client berbeda?**  
   Jam internal `DC01` berada pada `08:20:15 UTC`, sedangkan workstation berada pada `08:13:55 UTC` (selisih 380 detik).
4. **Mengapa jam DC01 bergeser?**  
   Layanan integrasi hypervisor (`VMware Tools Time Synchronization Provider`) aktif kembali setelah patching berkala host ESXi, menimpa konfigurasi Windows Time Service (W32Time).
5. **Mengapa jam host ESXi sendiri tidak akurat?**  
   Port keluar UDP 123 (NTP) dari subnet manajemen server terblokir pada firewall perimeter akibat kesalahan modifikasi rule saat change window malam sebelumnya.

---

## Jejak Diagnostik & Bukti Log

### 1. Log Windows Event Viewer
Pencarian log pada Domain Controller:

```text
Log Name:      System
Source:        Microsoft-Windows-Kerberos-Key-Distribution-Center
Event ID:      4
Level:         Error
Computer:      DC01.corp.local
Description:   The Kerberos subsystem encountered a bias error. The time skew 
               between client and server is greater than the allowed limit of 300 seconds.
```

### 2. Pengecekan Sumber Waktu (CLI)

=== "PowerShell"
    ```powershell
    # Memeriksa status dan sumber waktu aktif saat ini
    w32tm /query /status

    # Memeriksa selisih offset terhadap pool NTP otoritatif
    w32tm /stripchart /computer:0.pool.ntp.org /samples:3 /dataonly
    ```

=== "Bash (Monitoring Host)"
    ```bash
    # Cek stratum dan keterjangkauan server NTP dari gateway
    chronyc sources -v
    chronyc tracking
    ```

---

## Prosedur Remediasi

### Tahap 1: Mematikan Time Sync dari Hypervisor
Jalankan pada DC01 melalui PowerShell dengan hak akses Administrator:

```powershell
# Nonaktifkan penyedia sinkronisasi waktu hypervisor di registry Windows
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\VMICTimeProvider" -Name "Enabled" -Value 0
```

### Tahap 2: Konfigurasi Ulang NTP Otoritatif pada PDC Emulator

!!! warning "Perhatian Operasional"
    Menyesuaikan jam Domain Controller mundur secara mendadak dapat membuat sesi tiket Kerberos yang sedang aktif menjadi kadaluarsa seketika. Lakukan forced resync secara terkendali.

```powershell
# Arahkan PDC ke sumber NTP pool eksternal yang valid
w32tm /config /manualpeerlist:"0.id.pool.ntp.org,0x8 1.id.pool.ntp.org,0x8" /syncfromflags:manual /reliable:YES /update

# Muat ulang service Windows Time
Restart-Service w32time

# Paksa pembaruan waktu segera
w32tm /resync /rediscover
```

### Tahap 3: Verifikasi Pasca Remediasi
```powershell
w32tm /query /status | Select-String "Phase Offset", "Source"
```

*Output yang diharapkan:*
```text
Source: 0.id.pool.ntp.org,0x8
Phase Offset: 0.0002194s
```

---

## Tindakan Korektif & Preventif

| No | Tindakan Pencegahan | Penanggung Jawab | Target | Status |
|---|---|---|---|---|
| 1 | Menerapkan Group Policy Object (GPO) untuk mematikan `VMICTimeProvider` secara permanen pada semua VM Domain Controller | Tim SysAdmin | 2026-09-22 | Selesai |
| 2 | Menambahkan trigger alarm Zabbix jika clock drift pada PDC Emulator melebihi 20 detik | Tim Monitoring | 2026-09-23 | Selesai |
| 3 | Memulihkan dan mengunci aturan egress UDP port 123 pada firewall gateway perimeter | Tim Network | 2026-09-21 | Selesai |
