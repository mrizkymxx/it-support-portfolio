# SOP: Onboarding Pengguna Active Directory & Entra ID

| Dokumen ID | SOP-IT-001 |
|---|---|
| **Kategori** | Identity & Access Management (IAM) |
| **Versi** | 2.1 |
| **Penanggung Jawab** | L1 / L2 IT Support |
| **Prasyarat** | Tiket persetujuan HRD + Manager Divisi |

---

## 1. Tujuan
Memastikan setiap karyawan baru mendapatkan akun domain, email Microsoft 365, hak akses folder file server, dan lisensi software sesuai prinsip *Least Privilege* (hak akses minimal yang diperlukan untuk bekerja).

---

## 2. Struktur Organizational Unit (OU) & Aturan Penamaan

- **Username Format:** `nama.depan` (contoh: `budi.santoso`)
- **Password Standar:** Auto-generated 14 karakter acak + opsi `User must change password at next logon`.
- **Lokasi OU:**
  - `OU=Users,OU=Finance,DC=corp,DC=local`
  - `OU=Users,OU=Engineering,DC=corp,DC=local`
  - `OU=Users,OU=Operations,DC=corp,DC=local`

---

## 3. Matriks Keanggotaan Security Group

| Divisi | Security Group AD | Akses Sumber Daya |
|---|---|---|
| **Finance** | `SG_Finance_Users`, `SG_SharedFolder_RW` | File Share `\\FS01\Finance`, ERP Client |
| **Engineering**| `SG_Engineering_Users`, `SG_Git_Access` | File Share `\\FS01\Projects`, VPN Dev Subnet |
| **All Staff** | `SG_All_Employees`, `SG_Global_Internet` | Akses Web Gateway, Portal Intranet |

---

## 4. Prosedur Eksekusi

### Opsi A: Eksekusi Otomasi via PowerShell (Direkomendasikan)

Gunakan skrip provisioning baku untuk meminimalisir kesalahan manual:

```powershell
# Parameter pembuatan user baru
$FirstName   = "Budi"
$LastName    = "Santoso"
$Department  = "Finance"
$SamAccount  = "budi.santoso"
$UPN         = "$SamAccount@corp.local"
$OUPath      = "OU=Users,OU=$Department,DC=corp,DC=local"
$TempPassword = ConvertTo-SecureString "P@ssw0rdEnterprise2026!" -AsPlainText -Force

# Buat User di Active Directory
New-ADUser `
    -Name "$FirstName $LastName" `
    -GivenName $FirstName `
    -Surname $LastName `
    -SamAccountName $SamAccount `
    -UserPrincipalName $UPN `
    -Department $Department `
    -Path $OUPath `
    -AccountPassword $TempPassword `
    -Enabled $true `
    -ChangePasswordAtLogon $true

# Tambahkan ke grup keamanan divisi
Add-ADGroupMember -Identity "SG_Finance_Users" -Members $SamAccount
Add-ADGroupMember -Identity "SG_All_Employees" -Members $SamAccount
```

### Opsi B: GUI Active Directory Users and Computers (ADUC)
1. Buka `dsa.msc`.
2. Navigasi ke target OU departemen yang sesuai.
3. Klik kanan > **New** > **User**.
4. Isi Nama Lengkap, User Logon Name.
5. Centang **User must change password at next logon**.
6. Buka tab **Member Of** > Tambahkan grup sesuai matriks.

---

## 5. Checklist Validasi Pasca Provisioning

- [ ] Akun berhasil dibuat dan aktif di OU yang benar.
- [ ] User berhasil login pertama kali di workstation uji coba dan dipaksa ganti password.
- [ ] Mapped network drive (`Z:\`) otomatis terpasang via GPO Logon Script.
- [ ] Akun tersinkronisasi ke Entra ID Connect (Sync cycle: 30 menit atau eksekusi `Start-ADSyncSyncCycle -PolicyType Delta`).
- [ ] Tiket onboarding pada Helpdesk diperbarui dengan username resmi dan ditutup.
