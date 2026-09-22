# SOP: Rotasi & Pembaruan Sertifikat SSL Nginx (Certbot)

| Dokumen ID | SOP-IT-002 |
|---|---|
| **Kategori** | Linux Systems & Web Infrastructure |
| **Versi** | 1.4 |
| **Penanggung Jawab** | L2 Support / Sysadmin |
| **Pemicu** | Notifikasi masa aktif SSL < 30 hari atau kegagalan pembaruan otomatis |

---

## 1. Tujuan
Memastikan seluruh portal web internal dan reverse proxy terlindungi enkripsi TLS 1.3 terkini tanpa gangguan downtime (zero-downtime reload).

---

## 2. Pemeriksaan Masa Berlaku Sertifikat

Sebelum melakukan intervensi, periksa status kedaluwarsa sertifikat:

```bash
# Periksa semua sertifikat yang dikelola Certbot
sudo certbot certificates

# Uji tanggal kadaluarsa endpoint HTTPS secara langsung via OpenSSL
echo | openssl s_client -servername portal.corp.local -connect portal.corp.local:443 2>/dev/null | openssl x509 -noout -dates
```

---

## 3. Langkah Pembaruan (Renewal)

### Tahap 1: Pengujian Kering (Dry Run)
Pastikan port 80/443 tidak terhalang firewall sebelum eksekusi riil:

```bash
sudo certbot renew --dry-run
```

*Jika dry-run berhasil tanpa error, lanjutkan ke langkah pembaruan riil.*

### Tahap 2: Eksekusi Pembaruan & Hook Nginx
Jalankan perintah renew dengan *post-hook* agar konfigurasi Nginx otomatis di-reload hanya jika pembaruan berhasil:

```bash
sudo certbot renew --deploy-hook "systemctl reload nginx"
```

### Tahap 3: Uji Sintaks Nginx
Pastikan tidak ada sintaks konfigurasi yang rusak:

```bash
sudo nginx -t
# Output yang diharapkan:
# nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
# nginx: configuration file /etc/nginx/nginx.conf test is successful
```

---

## 4. Konfigurasi Otomasi Terjadwal (Cron & Systemd Timer)

Pastikan service timer pembaruan otomatis aktif pada server Linux:

```bash
# Cek status timer certbot
systemctl status certbot.timer

# Verifikasi jadwal eksekusi timer
systemctl list-timers | grep certbot
```

Jika menggunakan Cron standar (`/etc/cron.d/certbot`), pastikan entri berikut aktif:
```text
0 3 * * * root certbot renew --quiet --deploy-hook "systemctl reload nginx"
```

---

## 5. Troubleshooting Masalah Umum

### Port 80 Digunakan Proses Lain
Jika ACME challenge standalone gagal karena port 80 terkunci:
```bash
# Cari PID proses yang mengunci port 80
sudo ss -tulpn | grep :80

# Jika Nginx berjalan, gunakan plugin --nginx alih-alih --standalone
sudo certbot --nginx -d portal.corp.local
```
