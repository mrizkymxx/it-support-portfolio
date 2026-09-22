# Otomasi PowerShell: Audit Akun Active Directory Inaktif

Skrip otomatis untuk menemukan, mendata, dan menonaktifkan akun pengguna Active Directory yang tidak pernah login lebih dari 90 hari guna menjaga kebersihan domain dan mencegah eksploitasi akun dormant/orphan.

---

## 1. Spesifikasi Skrip

- **File:** `Get-StaleADAccounts.ps1`
- **Modul Dibutuhkan:** `ActiveDirectory` (RSAT)
- **Fitur Utama:**
  - Parameter fleksibel batas hari inaktif (`-DaysInactive`)
  - Ekspor otomatis ke format CSV dengan timestamp
  - Mendukung `-WhatIf` (fitur `SupportsShouldProcess`) agar aman diuji sebelum eksekusi riil
  - Penanganan error (*Try-Catch*) saat menonaktifkan akun

---

## 2. Kode Skrip Lengkap

```powershell
<#
.SYNOPSIS
    Audit dan pelaporan akun pengguna Active Directory inaktif.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [int]$DaysInactive = 90,
    [string]$ExportCsvPath = "$PSScriptRoot\Stale_AD_Accounts_$(Get-Date -Format 'yyyyMMdd').csv",
    [switch]$DisableAccounts
)

Import-Module ActiveDirectory -ErrorAction Stop

$CutoffDate = (Get-Date).AddDays(-$DaysInactive)
Write-Host "[*] Memeriksa akun AD dengan LastLogonDate sebelum: $($CutoffDate.ToShortDateString())" -ForegroundColor Cyan

# Kueri akun aktif yang LastLogonDate-nya lebih lama dari cutoff
$StaleUsers = Get-ADUser -Filter { Enabled -eq $true -and LastLogonDate -lt $CutoffDate } `
    -Properties SamAccountName, DisplayName, Department, Title, LastLogonDate, mail, DistinguishedName |
    Select-Object SamAccountName, DisplayName, Department, Title, LastLogonDate, mail, DistinguishedName

if (-not $StaleUsers) {
    Write-Host "[+] Tidak ditemukan akun inaktif. Kebersihan domain terjaga." -ForegroundColor Green
    return
}

Write-Host "[!] Ditemukan $($StaleUsers.Count) akun inaktif." -ForegroundColor Yellow
$StaleUsers | Format-Table SamAccountName, Department, LastLogonDate -AutoSize

# Ekspor ke file CSV
$StaleUsers | Export-Csv -Path $ExportCsvPath -NoTypeInformation -Encoding UTF8
Write-Host "[+] Laporan audit diekspor ke: $ExportCsvPath" -ForegroundColor Green

# Eksekusi penonaktifan jika parameter -DisableAccounts diberikan
if ($DisableAccounts) {
    foreach ($User in $StaleUsers) {
        if ($PSCmdlet.ShouldProcess($User.SamAccountName, "Nonaktifkan Akun Inaktif")) {
            try {
                Disable-ADAccount -Identity $User.SamAccountName
                Write-Host "[OK] Berhasil dinonaktifkan: $($User.SamAccountName)" -ForegroundColor Magenta
            } catch {
                Write-Error "Gagal menonaktifkan $($User.SamAccountName): $_"
            }
        }
    }
}
```

---

## 3. Contoh Penggunaan Operasional

### A. Hanya Menghasilkan Laporan (Audit Mode)
```powershell
.\Get-StaleADAccounts.ps1 -DaysInactive 60 -ExportCsvPath "C:\IT_Audit\Q3_StaleAccounts.csv"
```

### B. Simulasi Dry-Run dengan -WhatIf
Melihat akun mana saja yang akan dimatikan tanpa benar-benar merubah status:
```powershell
.\Get-StaleADAccounts.ps1 -DaysInactive 90 -DisableAccounts -WhatIf
```

### C. Eksekusi Nonaktifkan Akun Nyata
```powershell
.\Get-StaleADAccounts.ps1 -DaysInactive 90 -DisableAccounts
```
