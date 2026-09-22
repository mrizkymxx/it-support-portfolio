---
id: INC-20260905-03
title: Pemulihan Akses Pengguna Akibat Konflik Kebijakan Conditional Access Microsoft 365
severity: P2 - High
status: Resolved
date: 2026-09-05
affected_services:
  - Microsoft Outlook / Exchange Online
  - Microsoft Teams
  - Entra ID Single Sign-On (SSO)
mttr: 28m
---

# Laporan Insiden: Konflik Kebijakan Conditional Access M365 (INC-20260905-03)

## Ringkasan Eksekutif
Sejumlah staf eksekutif dan manajer cabang tiba-tiba terputus dari Microsoft Outlook dan Teams saat bekerja di luar kantor (WFA / Mobile). Pengguna terjebak dalam loop permintaan MFA berkelanjutan dan menerima pesan error `Sign-in was blocked by Conditional Access: Device must be compliant`.

Investigasi menemukan bahwa integrasi Intune Compliance state tertunda untuk perangkat laptop baru yang belum sinkron dengan Entra Hybrid Join.

## Metrik Insiden
- **Pengguna Terdampak:** 18 pengguna eksekutif dan sales lapangan.
- **Waktu Mulai:** 2026-09-05 09:15 WIB.
- **Deteksi:** 2026-09-05 09:22 WIB.
- **Penyelesaian:** 2026-09-05 09:43 WIB.
- **MTTR:** 28 menit.

---

## Analisis Akar Masalah (5-Whys)
1. **Mengapa pengguna gagal login ke Outlook di luar kantor?**  
   Entra ID menolak token autentikasi OAuth2 dengan kode error `53000`.
2. **Mengapa token ditolak?**  
   Kebijakan Conditional Access bernama `[SEC-04] Require Compliant Device or MFA` menandai perangkat pengguna sebagai *Not Compliant*.
3. **Mengapa perangkat ditandai Not Compliant?**  
   Sertifikat device trust PRT (Primary Refresh Token) pada Windows belum diperbarui setelah rollout update policy BitLocker.
4. **Mengapa sinkronisasi trust tertunda?**  
   Perangkat berada di luar jaringan kantor tanpa jalur koneksi langsung ke Domain Controller lokal untuk menyelesaikan handshake *Hybrid Azure AD Join*.
5. **Akar Masalah Utama:**  
   Kebijakan Conditional Access diaktifkan tanpa mengecualikan perangkat yang status join-nya masih dalam masa grace period (3 hari), dan pengguna tidak mengaktifkan koneksi VPN pra-login.

---

## Bukti Diagnostik & Analisis Log Sign-in

### 1. Log Sign-in Entra ID (Azure Portal)
```text
Failure Reason:  Device is not in compliant state.
Error Code:      53000
User:            user.field@corp.local
Application:     OfficeHome (Microsoft Teams / Exchange Online)
Client App:      Mobile Apps and Desktop clients
Device Trust:    Domain Joined: No, Compliant: No
Conditional Access Policy: [SEC-04] Require Compliant Device
```

### 2. Pengecekan Status Perangkat di Klien (CLI)

```cmd
dsregcmd /status
```

*Cuplikan Output Diagnostik:*
```text
+----------------------------------------------------------------------+
| Device State                                                         |
+----------------------------------------------------------------------+
             AzureAdJoined : YES
          EnterpriseJoined : NO
              DomainJoined : YES
           DeviceCompliant : NO
               IsUserAzureAD : YES
+----------------------------------------------------------------------+
| SSO State                                                            |
+----------------------------------------------------------------------+
                AzureAdPrt : NO
```

---

## Prosedur Remediasi Cepat

### 1. Mitigasi Darurat di Entra ID Admin Center
1. Masuk ke **Entra ID** > **Protection** > **Conditional Access**.
2. Buka kebijakan `[SEC-04] Require Compliant Device`.
3. Dalam menu *Grant*, ubah kriteria dari:  
   `Require device to be marked as compliant` **AND** `Require MFA`  
   menjadi:  
   `Require device to be marked as compliant` **OR** `Require multifactor authentication`.
4. Berikan grace period darurat 24 jam dengan validasi MFA nomor acak (Number Matching).

### 2. Perbaikan Sisi Klien (Workstation Karyawan)
Hubungkan perangkat pengguna melalui VPN perusahaan dan paksa sinkronisasi:

```powershell
# Paksa registrasi ulang device PRT ke Entra ID
dsregcmd /leave
dsregcmd /join

# Sinkronisasi policy Intune langsung dari PowerShell
Get-ScheduledTask -TaskPath "\Microsoft\Windows\EnterpriseMgmt\*" | Start-ScheduledTask
```

### 3. Verifikasi
Jalankan kembali `dsregcmd /status`. Pastikan:
- `AzureAdPrt : YES`
- `DeviceCompliant : YES`
- Klien dapat membuka aplikasi M365 tanpa prompt berulang.

---

## Langkah Pencegahan
- Memisahkan akun Break-Glass / Emergency Access agar tidak pernah terkena kebijakan Conditional Access.
- Menerapkan mode **Report-Only** minimal selama 7 hari sebelum menerapkan kebijakan Conditional Access baru secara enforced.
