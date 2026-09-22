# Otomasi Bash: Watchdog & Self-Healing Service Linux

Skrip pemantau daemon Linux otomatis untuk mendeteksi matinya layanan kritis (misal: `nginx`, `postgresql`, `sshd`) dan melakukan pemulihan otomatis (*self-healing restart*) dengan pencatatan log insiden.

---

## 1. Spesifikasi Skrip

- **File:** `service-watchdog.sh`
- **Lingkungan Target:** Ubuntu / Debian / RHEL dengan Systemd
- **Fitur Utama:**
  - Pengecekan status non-intrusif via `systemctl is-active`
  - Penanganan error ketat (`set -euo pipefail`)
  - Log audit otomatis di `/var/log/service-watchdog.log`
  - Deteksi status *zombie/crashed* pasca restart

---

## 2. Kode Skrip Lengkap

```bash
#!/usr/bin/env bash
#
# service-watchdog.sh - Autonomous daemon watchdog and self-healing restarter
#

set -euo pipefail

SERVICE_NAME="${1:-nginx}"
LOG_FILE="/var/log/service-watchdog.log"
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"

log_msg() {
    echo "[$TIMESTAMP] $1" | tee -a "$LOG_FILE"
}

# Periksa apakah layanan sedang aktif
if systemctl is-active --quiet "$SERVICE_NAME"; then
    # Layanan sehat, keluar tanpa error
    exit 0
else
    log_msg "PERINGATAN: Layanan '$SERVICE_NAME' MATI! Mencoba pemulihan otomatis..."

    # Coba restart layanan
    if systemctl restart "$SERVICE_NAME"; then
        sleep 2
        if systemctl is-active --quiet "$SERVICE_NAME"; then
            log_msg "PEMULIHAN: Layanan '$SERVICE_NAME' berhasil dihidupkan kembali."
        else
            log_msg "KRITIKAL: Restart '$SERVICE_NAME' selesai, tetapi proses masih mati."
            exit 2
        fi
    else
        log_msg "KRITIKAL: Gagal mengeksekusi restart pada layanan '$SERVICE_NAME'."
        exit 1
    fi
fi
```

---

## 3. Implementasi Cron Terjadwal

Pasang pada Crontab root agar berjalan setiap 2 menit:

```bash
# Buka crontab
sudo crontab -e

# Tambahkan baris pemantauan
*/2 * * * * /usr/local/bin/service-watchdog.sh nginx > /dev/null 2>&1
*/5 * * * * /usr/local/bin/service-watchdog.sh postgresql > /dev/null 2>&1
```
