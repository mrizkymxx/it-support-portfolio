# Kebijakan & Aturan Firewall Edge (pfSense / Netfilter)

Dokumentasi rancangan kebijakan kendali lalu lintas jaringan (Access Control Lists / Firewall Rules) pada perimeter gateway.

---

## 1. Prinsip Utama (Default Deny)

Seluruh antarmuka jaringan menerapkan prinsip **Implicit Deny All**: semua paket data masuk atau lintas segmen diblokir secara default kecuali ada aturan izin (Pass Rule) eksplisit di atasnya.

---

## 2. Matriks Aturan Inter-VLAN (Rule Table)

| ID Aturan | Antarmuka Sumber | Protokol | Port Sumber | Destinasi | Port Tujuan | Aksi | Deskripsi |
|---|---|---|---|---|---|---|---|
| **FW-01** | `VLAN20_CORP` | TCP/UDP | Any | `10.10.10.10` (DC01) | 53 (DNS) | **PASS** | Izinkan query DNS internal |
| **FW-02** | `VLAN20_CORP` | TCP/UDP | Any | `10.10.10.10` (DC01) | 88 (Kerberos) | **PASS** | Izinkan tiket login domain |
| **FW-03** | `VLAN20_CORP` | TCP | Any | `10.10.10.10` (DC01) | 389, 636 (LDAP/S)| **PASS** | Autentikasi direktori |
| **FW-04** | `VLAN20_CORP` | TCP | Any | `10.10.10.10` (DC01) | 445 (SMB) | **BLOCK** | Cegah akses langsung share file DC |
| **FW-05** | `VLAN20_CORP` | TCP | Any | `10.10.30.0/24` (DMZ) | 80, 443 | **PASS** | Akses aplikasi web & portal |
| **FW-06** | `VLAN20_CORP` | IP | Any | `RFC1918_Nets` | Any | **BLOCK** | Blokir sisa lalu lintas antar subnet |
| **FW-07** | `VLAN20_CORP` | IP | Any | `WAN_NET` | 80, 443 | **PASS** | Izinkan browsing keluar (Internet) |
| **FW-08** | `VLAN99_GUEST`| IP | Any | `RFC1918_Nets` | Any | **BLOCK** | Blokir tamu ke seluruh jaringan lokal |
| **FW-09** | `VLAN99_GUEST`| IP | Any | `WAN_NET` | Any | **PASS** | Tamu hanya akses internet publik |

---

## 3. Contoh Konfigurasi Netfilter / iptables (Linux Gateway)

Implementasi ekuivalen pada gateway Linux:

```bash
#!/bin/bash
# Reset ruleset
iptables -F
iptables -X
iptables -t nat -F

# Set default policy DROP
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Izinkan loopback & koneksi yang sudah terbentuk (stateful)
iptables -A INPUT -i lo -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# 1. Izinkan DNS & Kerberos dari VLAN 20 ke DC01
iptables -A FORWARD -i eth0.20 -d 10.10.10.10 -p udp --dport 53 -j ACCEPT
iptables -A FORWARD -i eth0.20 -d 10.10.10.10 -p tcp --dport 53 -j ACCEPT
iptables -A FORWARD -i eth0.20 -d 10.10.10.10 -p tcp --dport 88 -j ACCEPT

# 2. Izinkan Web DMZ dari VLAN 20
iptables -A FORWARD -i eth0.20 -d 10.10.30.0/24 -p tcp -m multiport --dports 80,443 -j ACCEPT

# 3. Blokir semua akses dari VLAN 20 & Guest ke subnet privat internal lainnya
iptables -A FORWARD -i eth0.20 -d 10.0.0.0/8 -j REJECT --reject-with icmp-net-prohibited
iptables -A FORWARD -i eth0.99 -d 10.0.0.0/8 -j DROP

# 4. Izinkan keluar ke internet (NAT Masquerade)
iptables -A FORWARD -i eth0.20 -o eth1 -j ACCEPT
iptables -A FORWARD -i eth0.99 -o eth1 -j ACCEPT
iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE
```

---

## 4. Prosedur Audit & Monitoring Log Firewall
Log pelanggaran paket dicatat dan diteruskan ke server Syslog pusat untuk mendeteksi potensi lateral movement:
```text
Sep 23 06:15:02 fw-edge filterlog[212]: 9,,,1000000104,eth0.20,match,block,in,4,0x0,,128,1542,0,none,6,tcp,52,10.10.20.104,10.10.10.10,51822,3389,0,S,412954812,,64240,,mss;nop;wscale;nop;nop;sackOK
```
*Analisis log:* Workstation `10.10.20.104` mencoba melakukan koneksi RDP port 3389 ke Domain Controller dan otomatis diblokir oleh Rule `FW-06`.
