<#
.SYNOPSIS
    Audit and report stale/inactive Active Directory user accounts.
.DESCRIPTION
    Scans Active Directory domain for user accounts that have not logged in
    for more than $DaysInactive days. Exports audit log to CSV and can optionally
    disable them.
.PARAMETER DaysInactive
    Threshold in days to consider an account inactive. Default is 90 days.
.PARAMETER ExportCsvPath
    Path to export audit results.
.PARAMETER DisableAccounts
    Switch to disable discovered stale accounts. Requires elevated domain privileges.
.EXAMPLE
    .\Get-StaleADAccounts.ps1 -DaysInactive 90 -ExportCsvPath "C:\Reports\StaleUsers.csv"
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [int]$DaysInactive = 90,
    [string]$ExportCsvPath = "$PSScriptRoot\Stale_AD_Accounts_$(Get-Date -Format 'yyyyMMdd').csv",
    [switch]$DisableAccounts
)

Import-Module ActiveDirectory -ErrorAction Stop

$CutoffDate = (Get-Date).AddDays(-$DaysInactive)
Write-Host "[*] Auditing AD accounts with LastLogonDate prior to: $($CutoffDate.ToShortDateString())" -ForegroundColor Cyan

# Query enabled user accounts older than cutoff date
$StaleUsers = Get-ADUser -Filter { Enabled -eq $true -and LastLogonDate -lt $CutoffDate } `
    -Properties SamAccountName, DisplayName, Department, Title, LastLogonDate, mail, DistinguishedName |
    Select-Object SamAccountName, DisplayName, Department, Title, LastLogonDate, mail, DistinguishedName

if (-not $StaleUsers) {
    Write-Host "[+] No stale accounts detected. Domain hygiene intact." -ForegroundColor Green
    return
}

Write-Host "[!] Found $($StaleUsers.Count) inactive accounts." -ForegroundColor Yellow
$StaleUsers | Format-Table SamAccountName, Department, LastLogonDate -AutoSize

# Export to CSV
$StaleUsers | Export-Csv -Path $ExportCsvPath -NoTypeInformation -Encoding UTF8
Write-Host "[+] Audit report exported to: $ExportCsvPath" -ForegroundColor Green

# Optional: Disable accounts if flag is present
if ($DisableAccounts) {
    foreach ($User in $StaleUsers) {
        if ($PSCmdlet.ShouldProcess($User.SamAccountName, "Disable Inactive Account")) {
            try {
                Disable-ADAccount -Identity $User.SamAccountName
                Write-Host "[OK] Disabled: $($User.SamAccountName)" -ForegroundColor Magenta
            } catch {
                Write-Error "Failed to disable $($User.SamAccountName): $_"
            }
        }
    }
}
