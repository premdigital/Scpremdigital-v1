#!/bin/bash
# ==========================================
# PREMDIGITAL - SSH & VPN AUTO INSTALLER V1
# ==========================================
# OS Support: Ubuntu 20.04 / 22.04 / 24.04 / Debian 10+
# ==========================================

if [ "${EUID}" -ne 0 ]; then
    echo -e "\e[31mMohon jalankan script ini sebagai root (sudo su)\e[0m"
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo -e "\e[32m[INFO] Memperbaiki package manager & lock jika ada...\e[0m"
dpkg --configure -a
apt-get -f install -y

echo -e "\e[32m[INFO] Memulai Instalasi Script PremDigital...\e[0m"
sleep 1

# 1. Update & Install Dependencies
echo -e "\e[33m[INFO] Update & Install Packages (Non-interactive)...\e[0m"
apt-get update -y
apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" curl wget wget2 nano python3 python3-pip cron ufw dropbear stunnel4 squid python3-flask python3-requests net-tools psmisc lsof vnstat bc

# Matikan web server bawaan VPS & bebaskan port tunneling
echo -e "\e[33m[INFO] Membersihkan port dan service yang berbenturan...\e[0m"
systemctl stop apache2 2>/dev/null || true
systemctl disable apache2 2>/dev/null || true
systemctl stop nginx 2>/dev/null || true
systemctl disable nginx 2>/dev/null || true
killall -9 apache2 2>/dev/null || true
killall -9 nginx 2>/dev/null || true

fuser -k 443/tcp 2>/dev/null || true
fuser -k 80/tcp 2>/dev/null || true
fuser -k 700/tcp 2>/dev/null || true
fuser -k 109/tcp 2>/dev/null || true
fuser -k 143/tcp 2>/dev/null || true
fuser -k 4430/tcp 2>/dev/null || true
fuser -k 8443/tcp 2>/dev/null || true
fuser -k 8880/tcp 2>/dev/null || true
fuser -k 2082/tcp 2>/dev/null || true

# Pastikan firewall tidak memblokir port
ufw disable 2>/dev/null || true
iptables -P INPUT ACCEPT 2>/dev/null || true
iptables -P FORWARD ACCEPT 2>/dev/null || true
iptables -P OUTPUT ACCEPT 2>/dev/null || true

# Optimasi Kernel TCP BBR & Buffer Anti Speedtest Jump
echo -e "\e[33m[INFO] Setting Optimasi Kernel TCP BBR & Buffer...\e[0m"
modprobe tcp_bbr 2>/dev/null || true
cat >> /etc/sysctl.conf << 'EOF_SYSCTL'
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.ipv4.ip_forward=1
net.core.rmem_max=67108864
net.core.wmem_max=67108864
net.ipv4.tcp_rmem=4096 87380 33554432
net.ipv4.tcp_wmem=4096 65536 33554432
net.ipv4.tcp_mtu_probing=1
EOF_SYSCTL
sysctl -p 2>/dev/null || true

# 2. Setting Waktu & Timezone (WIB)
echo -e "\e[33m[INFO] Setting Timezone (WIB)...\e[0m"
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime
dpkg-reconfigure --frontend noninteractive tzdata

# 3. Setup Direktori & Setup Domain
echo -e "\e[33m[INFO] Setup Direktori & Domain...\e[0m"
mkdir -p /etc/premdigital/
mkdir -p /usr/local/bin/
touch /etc/premdigital/users.db

MYIP=$(curl -sS ipv4.icanhazip.com 2>/dev/null || curl -sS ipinfo.io/ip 2>/dev/null || echo "127.0.0.1")
if [ ! -f /etc/vps-domain.txt ]; then
    echo "$MYIP" > /etc/vps-domain.txt
fi

if [ -t 0 ]; then
    clear
    echo -e "\e[36m====================================================\e[0m"
    echo -e "\e[33m         SETUP DOMAIN SERVER PREMDIGITAL           \e[0m"
    echo -e "\e[36m====================================================\e[0m"
    echo -e "IP VPS Anda terdeteksi: \e[32m$MYIP\e[0m"
    read -p "Masukkan Domain / Host (Kosongkan jika pakai IP): " input_domain
    if [ -n "$input_domain" ]; then
        echo "$input_domain" > /etc/vps-domain.txt
    fi
fi
DOMAIN=$(cat /etc/vps-domain.txt)

# 4. Setting SSH OpenSSH (Port 22 & 2253)
echo -e "\e[33m[INFO] Setting OpenSSH...\e[0m"
grep -qxF '/bin/false' /etc/shells || echo '/bin/false' >> /etc/shells
grep -qxF '/usr/sbin/nologin' /etc/shells || echo '/usr/sbin/nologin' >> /etc/shells
sed -i 's/#Port 22/Port 22/g' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 2253' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/g' /etc/ssh/sshd_config
echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
sed -i 's|#Banner none|Banner /etc/issue.net|g' /etc/ssh/sshd_config
sed -i 's|Banner none|Banner /etc/issue.net|g' /etc/ssh/sshd_config
grep -qxF 'Banner /etc/issue.net' /etc/ssh/sshd_config || echo 'Banner /etc/issue.net' >> /etc/ssh/sshd_config
sed -i 's/#PrintMotd yes/PrintMotd no/g' /etc/ssh/sshd_config
sed -i 's/PrintMotd yes/PrintMotd no/g' /etc/ssh/sshd_config
grep -qxF 'PrintMotd no' /etc/ssh/sshd_config || echo 'PrintMotd no' >> /etc/ssh/sshd_config
sed -i 's/#PrintLastLog yes/PrintLastLog no/g' /etc/ssh/sshd_config
sed -i 's/PrintLastLog yes/PrintLastLog no/g' /etc/ssh/sshd_config
grep -qxF 'PrintLastLog no' /etc/ssh/sshd_config || echo 'PrintLastLog no' >> /etc/ssh/sshd_config
sed -i 's/#DebianBanner yes/DebianBanner no/g' /etc/ssh/sshd_config
sed -i 's/DebianBanner yes/DebianBanner no/g' /etc/ssh/sshd_config
grep -qxF 'DebianBanner no' /etc/ssh/sshd_config || echo 'DebianBanner no' >> /etc/ssh/sshd_config
[ -d /etc/ssh/sshd_config.d ] && echo -e "PasswordAuthentication yes\nBanner /etc/issue.net\nPrintMotd no\nPrintLastLog no\nDebianBanner no" > /etc/ssh/sshd_config.d/01-permitpassword.conf

# Sembunyikan pesan sistem Ubuntu / MOTD bawaan
echo "" > /etc/motd 2>/dev/null || true
echo "" > /var/run/motd.dynamic 2>/dev/null || true
echo "" > /run/motd.dynamic 2>/dev/null || true
chmod -x /etc/update-motd.d/* 2>/dev/null || true
sed -i 's/ENABLED=1/ENABLED=0/g' /etc/default/motd-news 2>/dev/null || true
sed -i 's/.*pam_motd.so/#&/g' /etc/pam.d/sshd 2>/dev/null || true
sed -i 's/.*pam_motd.so/#&/g' /etc/pam.d/login 2>/dev/null || true
sed -i 's/.*pam_motd.so/#&/g' /etc/pam.d/dropbear 2>/dev/null || true

systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null

# 5. Setting Banner & Dropbear (Port 109, 143)
echo -e "\e[33m[INFO] Setting Banner & Dropbear...\e[0m"
mkdir -p /etc/dropbear
[ -f /etc/dropbear/dropbear_rsa_host_key ] || dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key -s 2048 2>/dev/null || true
[ -f /etc/dropbear/dropbear_ecdsa_host_key ] || dropbearkey -t ecdsa -f /etc/dropbear/dropbear_ecdsa_host_key 2>/dev/null || true
[ -f /etc/dropbear/dropbear_ed25519_host_key ] || dropbearkey -t ed25519 -f /etc/dropbear/dropbear_ed25519_host_key 2>/dev/null || true

cat > /etc/issue.net << 'END'
<br>
<font color="#00ffff">========================================</font><br>
<font color="#ffd700"><b>       ★ PREMDIGITAL TUNNELING ★        </b></font><br>
<font color="#00ffff">========================================</font><br>
<font color="#ffffff"><b>      [ PERATURAN PENGGUNA SERVER ]    </b></font><br>
<font color="#ff4d4d">  • DILARANG DDOS / HACKING / SCANNING  </font><br>
<font color="#ff4d4d">  • DILARANG TORRENT / BITTORENT / P2P  </font><br>
<font color="#ff4d4d">  • DILARANG SPAM / CARDING / FRAUD     </font><br>
<font color="#ff4d4d">  • DILARANG MULTI-LOGIN (MAX 1 DEVICE) </font><br>
<font color="#00ffff">----------------------------------------</font><br>
<font color="#00ff7f">  ✓ Server Uptime & High Speed Network  </font><br>
<font color="#00ff7f">  ✓ Auto-Reboot Server Tiap 05:00 WIB   </font><br>
<font color="#e0aaff">  ✓ Support & CS: https://wa.me/6283188458876 </font><br>
<font color="#00ffff">  ✓ Website: https://www.premdigital.web.id </font><br>
<font color="#00ffff">========================================</font><br>
<font color="#ffd700">  Terima Kasih Atas Kepercayaan Anda!   </font><br>
<font color="#00ffff">========================================</font><br>
<br>
END
cp -f /etc/issue.net /etc/issue 2>/dev/null || true
cp -f /etc/issue.net /etc/motd 2>/dev/null || true

cat > /etc/default/dropbear << 'END'
NO_START=0
DROPBEAR_PORT=109
DROPBEAR_EXTRA_ARGS="-p 143"
DROPBEAR_BANNER="/etc/issue.net"
DROPBEAR_RECEIVE_WINDOW=65536
END

cat > /etc/systemd/system/dropbear.service << 'END'
[Unit]
Description=Dropbear SSH Server (Port 109, 143)
After=network.target

[Service]
Type=simple
ExecStart=/usr/sbin/dropbear -F -E -p 109 -p 143 -b /etc/issue.net
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
END

systemctl daemon-reload
systemctl enable dropbear
systemctl restart dropbear

# 6. Setting WebSocket SSH Proxy (Smart Multiplexer Port 443, 80, 8880, 2082)
echo -e "\e[33m[INFO] Setting WebSocket SSH Proxy...\e[0m"
cat > /usr/local/bin/ws-proxy << 'END'
#!/usr/bin/python3
import socket, threading, select, sys, time

BUFFER_SIZE = 65536
RESPONSE_101 = b"HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n"

def set_optimized_sock(s):
    try:
        s.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        s.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 262144)
        s.setsockopt(socket.SOL_SOCKET, socket.SO_SNDBUF, 262144)
    except Exception:
        pass

def handle_client(client_sock, target_host, target_port, tls_target_port=None):
    target_sock = None
    try:
        set_optimized_sock(client_sock)
        client_sock.settimeout(12.0)
        data = client_sock.recv(4096)
        if not data:
            return

        # 1. Deteksi TLS ClientHello (Byte pertama 0x16 = TLS Handshake)
        if (data[0] == 0x16 or data.startswith(b'\x16')) and tls_target_port:
            target_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            set_optimized_sock(target_sock)
            target_sock.connect(('127.0.0.1', tls_target_port))
            target_sock.sendall(data)
            first_client_packet = False
        # 2. Deteksi Request HTTP / WebSocket Upgrade (HTTP Custom Payload)
        elif b'HTTP/' in data or b'Upgrade: websocket' in data or b'GET ' in data or b'POST ' in data or b'PATCH ' in data or b'HEAD ' in data:
            target_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            set_optimized_sock(target_sock)
            target_sock.connect((target_host, target_port))
            
            # Ambil banner awal Dropbear langsung dari port SSH
            target_sock.settimeout(6.0)
            ssh_banner = target_sock.recv(1024)
            if not ssh_banner:
                return
            
            # Kirim respons 101 disusul banner SSH Dropbear ke HTTP Custom
            client_sock.sendall(RESPONSE_101)
            client_sock.sendall(ssh_banner)
            first_client_packet = True
        # 3. Direct SSH Protocol biasa (SSH-2.0...)
        else:
            target_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            set_optimized_sock(target_sock)
            target_sock.connect((target_host, target_port))
            target_sock.sendall(data)
            first_client_packet = False

        client_sock.settimeout(None)
        target_sock.settimeout(None)

        sockets = [client_sock, target_sock]
        while True:
            r, _, x = select.select(sockets, [], sockets, 300)
            if x or not r:
                break
            for s in r:
                if s is client_sock:
                    buf = client_sock.recv(BUFFER_SIZE)
                    if not buf:
                        return
                    # Filter dan bersihkan paket sisa injeksi [split]HTTP/ 200
                    if first_client_packet:
                        if buf.startswith(b"HTTP/") or b"HTTP/1." in buf:
                            idx = buf.find(b"SSH-2.0")
                            if idx != -1:
                                buf = buf[idx:]
                                target_sock.sendall(buf)
                                first_client_packet = False
                            continue
                        first_client_packet = False
                    target_sock.sendall(buf)
                else:
                    buf = target_sock.recv(BUFFER_SIZE)
                    if not buf:
                        return
                    client_sock.sendall(buf)
    except Exception:
        pass
    finally:
        try: client_sock.close()
        except: pass
        if target_sock:
            try: target_sock.close()
            except: pass

def start_listener(listen_host, listen_port, target_host, target_port, tls_target_port=None):
    server = None
    while True:
        try:
            server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            set_optimized_sock(server)
            server.bind((listen_host, listen_port))
            server.listen(1000)
            break
        except Exception:
            if server:
                try: server.close()
                except: pass
            time.sleep(2)

    while True:
        try:
            client_sock, _ = server.accept()
            t = threading.Thread(
                target=handle_client,
                args=(client_sock, target_host, target_port, tls_target_port),
                daemon=True
            )
            t.start()
        except Exception:
            time.sleep(0.05)

if __name__ == '__main__':
    ports = [
        ('0.0.0.0', 443, '127.0.0.1', 109, 4430),
        ('0.0.0.0', 80, '127.0.0.1', 109, None),
        ('127.0.0.1', 700, '127.0.0.1', 109, None),
        ('0.0.0.0', 8880, '127.0.0.1', 109, None),
        ('0.0.0.0', 2082, '127.0.0.1', 109, None),
    ]
    for host, port, thost, tport, tls_port in ports:
        t = threading.Thread(
            target=start_listener,
            args=(host, port, thost, tport, tls_port),
            daemon=True
        )
        t.start()

    while True:
        time.sleep(3600)
END
chmod +x /usr/local/bin/ws-proxy

cat > /etc/systemd/system/ws-proxy.service << 'END'
[Unit]
Description=WebSocket SSH Proxy Smart Multiplexer
After=network.target dropbear.service

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 /usr/local/bin/ws-proxy
Restart=always
RestartSec=3
KillMode=process

[Install]
WantedBy=multi-user.target
END

systemctl daemon-reload
systemctl enable ws-proxy
systemctl restart ws-proxy

# 7. Setting Stunnel (Port 4430 Internal & 8443)
echo -e "\e[33m[INFO] Setting Stunnel...\e[0m"
STUNNEL_BIN=$(command -v stunnel4 || command -v stunnel || echo "/usr/bin/stunnel4")

mkdir -p /etc/stunnel
cat > /etc/stunnel/stunnel.conf << 'END'
pid = /run/stunnel4.pid
cert = /etc/stunnel/stunnel.pem
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[ws-tls]
accept = 127.0.0.1:4430
connect = 127.0.0.1:700

[openssh-tls]
accept = 0.0.0.0:8443
connect = 127.0.0.1:700
END

openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -sha256 \
-subj "/C=ID/ST=DKI Jakarta/L=Jakarta/O=PremDigital/OU=PremDigital/CN=premdigital.com" \
-out /etc/stunnel/stunnel.pem -keyout /etc/stunnel/stunnel.pem

chmod 600 /etc/stunnel/stunnel.pem
chown root:root /etc/stunnel/stunnel.pem

cat > /etc/default/stunnel4 << 'END'
ENABLED=1
FILES="/etc/stunnel/*.conf"
OPTIONS=""
END

cat > /etc/systemd/system/stunnel4.service << EOF
[Unit]
Description=SSL/TLS Stunnel Service
After=network.target

[Service]
Type=forking
ExecStart=$STUNNEL_BIN /etc/stunnel/stunnel.conf
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable stunnel4 2>/dev/null || true
systemctl restart stunnel4 2>/dev/null || systemctl restart stunnel 2>/dev/null || true

# 8. Setting BadVPN UDPGW (Port 7100, 7200, 7300)
echo -e "\e[33m[INFO] Setting BadVPN UDPGW...\e[0m"
wget -q -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/daybreakersx/premscript/master/badvpn-udpgw64" 2>/dev/null || \
wget -q -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/SSH-Server/autoscript/main/files/badvpn-udpgw64" 2>/dev/null
chmod +x /usr/bin/badvpn-udpgw

# Service port 7300 (Default HTTP Custom)
cat > /etc/systemd/system/badvpn-7300.service << 'END'
[Unit]
Description=BadVPN UDPGW Service (Port 7300)
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 500 --max-connections-for-client 20
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
END

# Service port 7100 (Alternatif)
cat > /etc/systemd/system/badvpn-7100.service << 'END'
[Unit]
Description=BadVPN UDPGW Service (Port 7100)
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/badvpn-udpgw --listen-addr 127.0.0.1:7100 --max-clients 500 --max-connections-for-client 20
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
END

systemctl daemon-reload
systemctl enable badvpn-7300 badvpn-7100 2>/dev/null || true
systemctl restart badvpn-7300 badvpn-7100 2>/dev/null || true

# 9. Setting Squid Proxy (Port 8080)
echo -e "\e[33m[INFO] Setting Squid...\e[0m"
cat > /etc/squid/squid.conf <<-END
acl localhost src 127.0.0.1/32
acl localnet src 10.0.0.0/8
acl localnet src 172.16.0.0/12
acl localnet src 192.168.0.0/16
acl all src all
http_access allow localhost
http_access allow localnet
http_access allow all
http_port 8080
END
systemctl restart squid

# 10. Web API (Python Flask) - Port 5000
echo -e "\e[33m[INFO] Install Web API Backend...\e[0m"
cat > /usr/local/bin/vps-api <<-END
#!/usr/bin/python3
from flask import Flask, request, jsonify
import os, subprocess, datetime

app = Flask(__name__)
API_SECRET = "PREMDIGITAL_RAHASIA_123"

@app.route('/api/create', methods=['POST'])
def create_ssh():
    data = request.json
    if data.get('secret') != API_SECRET:
        return jsonify({"status": "error", "message": "Unauthorized"}), 401
    
    username = data.get('username')
    password = data.get('password')
    expired_days = data.get('expired')
    
    if not username or not password or not expired_days:
        return jsonify({"status": "error", "message": "Data tidak lengkap"}), 400
        
    exp_date = (datetime.datetime.now() + datetime.timedelta(days=int(expired_days))).strftime('%Y-%m-%d')
    
    # Jalankan perintah useradd di linux
    os.system(f'useradd -e {exp_date} -s /bin/false -M {username}')
    os.system(f'echo "{username}:{password}" | chpasswd')
    
    # Baca Domain
    try:
        with open('/etc/vps-domain.txt', 'r') as f:
            domain = f.read().strip()
    except:
        domain = "IP_VPS"
        
    return jsonify({
        "status": "success",
        "data": {
            "username": username,
            "password": password,
            "host": domain,
            "durasi": f"{expired_days} Hari",
            "port_info": {
                "tls": "443, 8443",
                "http": "80, 8880, 2082",
                "dropbear": "109, 143",
                "openssh": "22, 2253",
                "udpgw": "7300, 7100",
                "squid": "8080"
            },
            "payload_ws": "GET / HTTP/1.1[crlf]Host: [host_port][crlf]User-Agent: [ua][crlf]Upgrade: websocket[crlf][crlf]"
        }
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
END
chmod +x /usr/local/bin/vps-api

cat > /etc/systemd/system/vps-api.service <<-END
[Unit]
Description=PremDigital VPS API
After=network.target

[Service]
ExecStart=/usr/local/bin/vps-api
Restart=always

[Install]
WantedBy=multi-user.target
END
systemctl enable vps-api
systemctl restart vps-api

# 11. Bot Telegram Server-Side
echo -e "\e[33m[INFO] Setting Telegram Bot Base...\e[0m"
cat > /usr/local/bin/vps-bot <<-END
#!/usr/bin/python3
import requests, time, os, subprocess
from datetime import datetime, timedelta

BOT_TOKEN = "ISI_TOKEN_BOT_DISINI"
LAST_UPDATE_ID = 0

try:
    with open('/etc/vps-domain.txt', 'r') as f:
        DOMAIN = f.read().strip()
except:
    DOMAIN = "IP_VPS"

def process_message(text, chat_id):
    if text.startswith("/create"):
        parts = text.split()
        if len(parts) >= 4:
            user = parts[1]
            pwd = parts[2]
            hari = parts[3]
            
            # Deteksi argumen tambahan (IP Limit)
            ip_limit = parts[4] if len(parts) > 4 else "2"
            
            # Setup Kuota otomatis berdasarkan IP Limit
            if ip_limit == "1":
                kuota_gb = "50"
            elif ip_limit == "2":
                kuota_gb = "70"
            elif ip_limit == "3":
                kuota_gb = "100"
            elif ip_limit == "5":
                kuota_gb = "150"
            else:
                kuota_gb = "70" # Default fallback
            
            # Cek otomatis jika VPS Unlimited, maka bypass input kuota user menjadi 0
            try:
                vps_quota = subprocess.check_output("if [ -f /etc/premdigital/bandwidth_quota.txt ]; then cat /etc/premdigital/bandwidth_quota.txt; else echo 'Unknown'; fi", shell=True).decode('utf-8').strip()
                if vps_quota == 'Unknown':
                    isp = subprocess.check_output("curl -s -m 3 http://ip-api.com/line/?fields=isp 2>/dev/null || echo 'Unknown'", shell=True).decode('utf-8').strip()
                    if any(x in isp for x in ['DigitalOcean', 'DO', 'Linode', 'Akamai', 'Vultr', 'Hetzner', 'Contabo', 'Oracle', 'Amazon', 'AWS', 'Google', 'GCP']):
                        vps_quota = 'Limited'
                    else:
                        vps_quota = 'Unlimited'
                if 'Unlimited' in vps_quota:
                    kuota_gb = "0"
            except:
                pass

            try:
                exp_date = (datetime.now() + timedelta(days=int(hari))).strftime('%Y-%m-%d')
            except:
                exp_date = (datetime.now() + timedelta(days=30)).strftime('%Y-%m-%d')

            os.system(f'useradd -e {exp_date} -m -s /bin/false -M {user}')
            os.system(f'echo "{user}:{pwd}" | chpasswd')
            
            # Setup IP Limit & Quota
            os.system('mkdir -p /etc/premdigital/multilogin /etc/premdigital/user_quota')
            os.system(f'echo "{ip_limit}" > /etc/premdigital/multilogin/{user}')
            os.system(f'echo "{kuota_gb}" > /etc/premdigital/user_quota/{user}')
            
            kuota_label = f"{kuota_gb} GB" if str(kuota_gb) != "0" else "Unlimited"
            
            MSG = f"✅ AKUN SSH SUKSES DIBUAT\n━━━━━━━━━━━━━━━━━━\n👤 Username: {user}\n🔑 Password: {pwd}\n🌍 Host: {DOMAIN}\n⏳ Durasi: {hari} Hari\n📱 Max Login: {ip_limit} IP\n📦 Kuota Data: {kuota_label}\n━━━━━━━━━━━━━━━━━━\n🔌 Port Info:\n• TLS: 443, 8443\n• HTTP: 80, 8880, 2082\n• Dropbear: 109, 143\n• OpenSSH: 22, 2253\n• UDPGW: 7100\n• Squid: 8080\n━━━━━━━━━━━━━━━━━━\n📥 Payload WS:\nGET / HTTP/1.1[crlf]Host: [host_port][crlf]User-Agent: [ua][crlf]Upgrade: websocket[crlf][crlf]\n━━━━━━━━━━━━━━━━━━"
            requests.post(f"https://api.telegram.org/bot{BOT_TOKEN}/sendMessage", data={"chat_id": chat_id, "text": MSG})
        else:
            requests.post(f"https://api.telegram.org/bot{BOT_TOKEN}/sendMessage", data={"chat_id": chat_id, "text": "Format salah.\n\nGunakan: /create <user> <pass> <hari> [ip_limit]\nContoh 1: /create tester 123 30\nContoh 2: /create vvip 123 30 1\n(Ket: 1 IP = 50GB, 2 IP = 70GB, 3 IP = 100GB, 5 IP = 150GB)"})

while True:
    try:
        req = requests.get(f"https://api.telegram.org/bot{BOT_TOKEN}/getUpdates?offset={LAST_UPDATE_ID}")
        data = req.json()
        for result in data.get("result", []):
            LAST_UPDATE_ID = result["update_id"] + 1
            chat_id = result["message"]["chat"]["id"]
            text = result["message"].get("text", "")
            process_message(text, chat_id)
    except:
        pass
    time.sleep(3)
END
chmod +x /usr/local/bin/vps-bot

cat > /etc/systemd/system/vps-bot.service <<-END
[Unit]
Description=PremDigital Telegram Bot
After=network.target

[Service]
ExecStart=/usr/local/bin/vps-bot
Restart=always

[Install]
WantedBy=multi-user.target
END
systemctl enable vps-bot
systemctl restart vps-bot 2>/dev/null || true

# 12. CLI Menu & Commands
echo -e "\e[33m[INFO] Setting up CLI Menu...\e[0m"
cat > /usr/bin/menu << 'END'
#!/bin/bash
Y="\e[33m"
C="\e[36m"
R="\e[31m"
G="\e[32m"
NC="\e[0m"

check_port() {
    local port=$1
    if ss -tuln 2>/dev/null | grep -qE "[:.]${port}[[:space:]]" || netstat -tuln 2>/dev/null | grep -qE "[:.]${port}[[:space:]]" || lsof -iTCP:${port} -sTCP:LISTEN 2>/dev/null | grep -q LISTEN; then
        echo -e "${G}ONLINE${NC}"
    else
        echo -e "${R}OFFLINE${NC}"
    fi
}

check_service() {
    local sname=$1
    if systemctl is-active --quiet "$sname" 2>/dev/null; then
        echo -e "${G}RUNNING${NC}"
    elif pidof "$sname" >/dev/null 2>&1; then
        echo -e "${G}RUNNING${NC}"
    else
        echo -e "${R}STOPPED${NC}"
    fi
}

check_wsproxy() {
    if systemctl is-active --quiet ws-proxy 2>/dev/null || pgrep -f "ws-proxy" >/dev/null 2>&1; then
        echo -e "${G}RUNNING${NC}"
    else
        echo -e "${R}STOPPED${NC}"
    fi
}

check_stunnel() {
    if systemctl is-active --quiet stunnel4 2>/dev/null || systemctl is-active --quiet stunnel 2>/dev/null || pidof stunnel4 >/dev/null 2>&1 || pidof stunnel >/dev/null 2>&1; then
        echo -e "${G}RUNNING${NC}"
    else
        echo -e "${R}STOPPED${NC}"
    fi
}

check_dropbear() {
    if systemctl is-active --quiet dropbear 2>/dev/null || pidof dropbear >/dev/null 2>&1; then
        echo -e "${G}RUNNING${NC}"
    else
        echo -e "${R}STOPPED${NC}"
    fi
}

get_bandwidth() {
    local iface
    iface=$(ip route show default 2>/dev/null | awk '/default/ {print $5}')
    [ -z "$iface" ] && iface=$(ls /sys/class/net | grep -vE 'lo|docker|tun|tap' | head -n1)
    
    local used_str="0 MB"
    local total_bytes=0
    if [ -n "$iface" ] && [ -f "/sys/class/net/$iface/statistics/rx_bytes" ]; then
        local rx tx
        rx=$(cat "/sys/class/net/$iface/statistics/rx_bytes" 2>/dev/null || echo 0)
        tx=$(cat "/sys/class/net/$iface/statistics/tx_bytes" 2>/dev/null || echo 0)
        total_bytes=$((rx + tx))
        
        # Konversi byte ke MB / GB
        if [ "$total_bytes" -gt 1073741824 ]; then
            used_str="$(awk "BEGIN {printf \"%.2f GB\", $total_bytes/1073741824}")"
        elif [ "$total_bytes" -gt 1048576 ]; then
            used_str="$(awk "BEGIN {printf \"%.1f MB\", $total_bytes/1048576}")"
        else
            used_str="$(awk "BEGIN {printf \"%.0f KB\", $total_bytes/1024}")"
        fi
    fi

    # Cek kuota limit: manual setting atau auto-detect provider
    local limit_cfg="/etc/premdigital/bandwidth_quota.txt"
    local quota_type="Unlimited"

    if [ -f "$limit_cfg" ]; then
        quota_type=$(cat "$limit_cfg" | tr -d '\r\n')
    else
        # Auto-detect berdasarkan provider/ISP VPS
        local isp_check="$1"
        case "$isp_check" in
            *DigitalOcean*|*DO*) quota_type="1000 GB (DO Plan)" ;;
            *Linode*|*Akamai*) quota_type="1000 GB (Linode Plan)" ;;
            *Vultr*) quota_type="1000 GB (Vultr Plan)" ;;
            *Hetzner*) quota_type="20 TB (Hetzner Plan)" ;;
            *OVH*) quota_type="Unlimited (OVH Unmetered)" ;;
            *Contabo*) quota_type="32 TB (Contabo Plan)" ;;
            *Oracle*) quota_type="10 TB (Oracle Cloud)" ;;
            *Amazon*|*AWS*) quota_type="100 GB (AWS Free Tier/Metered)" ;;
            *Google*|*GCP*) quota_type="Metered (GCP Pay-as-you-go)" ;;
            *Biznet*|*Telkom*|*IDNIC*|*IDCloudHost*|*CBN*|*Indonet*) quota_type="Unlimited (Unmetered ID)" ;;
            *) quota_type="Unlimited" ;;
        esac
    fi

    if [[ "$quota_type" == *"Unlimited"* ]]; then
        echo -e "${used_str} / ${G}${quota_type}${NC}"
    else
        echo -e "${used_str} / ${Y}${quota_type}${NC}"
    fi
}

while true; do
    IP=$(curl -sS -m 3 ipv4.icanhazip.com 2>/dev/null || curl -sS -m 3 ipinfo.io/ip 2>/dev/null || echo "127.0.0.1")
    
    # Deteksi ISP Akurat (ipinfo.io -> ip-api -> ifconfig.co)
    ISP=$(curl -s -m 3 "https://ipinfo.io/${IP}/org" 2>/dev/null | sed -e 's/^AS[0-9]* //' | tr -d '"')
    if [[ -z "$ISP" || "$ISP" =~ "{" || "$ISP" =~ "error" || "$ISP" =~ "Rate limit" ]]; then
        ISP=$(curl -s -m 3 "http://ip-api.com/line/${IP}?fields=isp" 2>/dev/null)
    fi
    if [[ -z "$ISP" || "$ISP" =~ "{" || "$ISP" =~ "error" || "$ISP" =~ "429" || "$ISP" =~ "Rate limit" ]]; then
        ISP="PremDigital Cloud"
    fi

    # Deteksi Kota Akurat
    CITY=$(curl -s -m 3 "https://ipinfo.io/${IP}/city" 2>/dev/null | tr -d '"')
    if [[ -z "$CITY" || "$CITY" =~ "{" || "$CITY" =~ "error" || "$CITY" =~ "Rate limit" ]]; then
        CITY=$(curl -s -m 3 "http://ip-api.com/line/${IP}?fields=city" 2>/dev/null)
    fi
    if [[ -z "$CITY" || "$CITY" =~ "{" || "$CITY" =~ "error" || "$CITY" =~ "429" || "$CITY" =~ "Rate limit" ]]; then
        CITY="Singapore"
    fi
    
    if [ -f /etc/vps-domain.txt ]; then
        DOMAIN=$(cat /etc/vps-domain.txt)
    else
        DOMAIN=$IP
    fi

    BW_INFO=$(get_bandwidth "$ISP")

    clear
    echo -e "${C}======================================${NC}"
    echo -e "${Y}          PREMDIGITAL TUNNEL          ${NC}"
    echo -e "${C}======================================${NC}"
    echo -e " OS         : $(cat /etc/os-release | grep -w PRETTY_NAME | cut -d= -f2 | tr -d '"')"
    echo -e " RAM        : $(free -m | awk 'NR==2{printf "%sMB / %sMB", $3,$2}')"
    echo -e " Bandwidth  : $BW_INFO"
    echo -e " ISP        : $ISP"
    echo -e " Kota       : $CITY"
    echo -e " Domain     : ${Y}$DOMAIN${NC}"
    echo -e " IP VPS     : ${G}$IP${NC}"
    echo -e "${C}======================================${NC}"
    echo -e " [1] Buat Akun SSH Baru"
    echo -e " [2] Hapus Akun SSH"
    echo -e " [3] List Akun SSH Aktif"
    echo -e " [4] Ganti Domain Server"
    echo -e " [5] Cek Status Port & Service Tunneling"
    echo -e " [6] Cek Statistik Bandwidth VPS (vnStat)"
    echo -e " [7] Restart Semua Service Tunneling"
    echo -e " [8] Pengaturan Banner SSH (/etc/issue.net)"
    echo -e " [9] Jalankan Auto-Delete Expired"
    echo -e " [10] Cek & Atur Auto-Kill Multi-Login (Per-Akun)"
    echo -e " [11] Menu Service API & Bot Telegram"
    echo -e " [0] Keluar"
    echo -e "${C}======================================${NC}"
    read -p " Pilih Opsi [0-11]: " opt
    case $opt in
        1)
            clear
            read -p "Username: " user
            if id "$user" &>/dev/null; then
                echo -e "${R}Error: Username $user sudah ada di sistem!${NC}"
                sleep 2
                continue
            fi
            read -p "Password: " pass
            read -p "Berapa Hari: " masaaktif
            
            echo -e "\nPilih Batas Multi-Login (Max IP):"
            echo -e " [1] 1 IP (Max 1 Device)"
            echo -e " [2] 2 IP (Max 2 Device)"
            echo -e " [3] 3 IP (Max 3 Device)"
            echo -e " [4] 5 IP (Max 5 Device)"
            read -p "Pilihan [1-4] (Default 2 IP): " max_ip_opt
            case $max_ip_opt in
                1) max_ip=1 ;;
                2) max_ip=2 ;;
                3) max_ip=3 ;;
                4) max_ip=5 ;;
                *) max_ip=2 ;;
            esac

            # Cek VPS Quota
            vps_quota_type="Unlimited"
            if [ -f "/etc/premdigital/bandwidth_quota.txt" ]; then
                vps_quota_type=$(cat "/etc/premdigital/bandwidth_quota.txt" | tr -d '\r\n')
            else
                case "$ISP" in
                    *DigitalOcean*|*DO*) vps_quota_type="1000 GB" ;;
                    *Linode*|*Akamai*) vps_quota_type="1000 GB" ;;
                    *Vultr*) vps_quota_type="1000 GB" ;;
                    *Hetzner*) vps_quota_type="20 TB" ;;
                    *Contabo*) vps_quota_type="32 TB" ;;
                    *Oracle*) vps_quota_type="10 TB" ;;
                    *Amazon*|*AWS*) vps_quota_type="100 GB" ;;
                    *Google*|*GCP*) vps_quota_type="Metered" ;;
                    *) vps_quota_type="Unlimited" ;;
                esac
            fi

            if [[ "$vps_quota_type" == *"Unlimited"* ]]; then
                quota_gb=0
                quota_label="Unlimited (VPS Unmetered)"
            else
                echo -e "\nPilih Kuota Bandwidth Akun:"
                echo -e " [1] Unlimited (Tanpa Batas Kuota)"
                echo -e " [2] 10 GB"
                echo -e " [3] 25 GB"
                echo -e " [4] 50 GB"
                echo -e " [5] 100 GB"
                echo -e " [6] Custom (Ketik sendiri GB, misal: 15)"
                read -p "Pilihan [1-6] (Default Unlimited): " quota_opt
                case $quota_opt in
                    1) quota_gb=0; quota_label="Unlimited" ;;
                    2) quota_gb=10; quota_label="10 GB" ;;
                    3) quota_gb=25; quota_label="25 GB" ;;
                    4) quota_gb=50; quota_label="50 GB" ;;
                    5) quota_gb=100; quota_label="100 GB" ;;
                    6)
                        read -p "Masukkan kuota (dalam GB angka saja): " custom_gb
                        custom_gb=$(echo "$custom_gb" | tr -dc '0-9')
                        [ -z "$custom_gb" ] && custom_gb=0
                        quota_gb=$custom_gb
                        if [ "$quota_gb" -gt 0 ]; then
                            quota_label="${quota_gb} GB"
                        else
                            quota_label="Unlimited"
                        fi
                        ;;
                    *) quota_gb=0; quota_label="Unlimited" ;;
                esac
            fi
            
            mkdir -p /etc/premdigital/multilogin
            mkdir -p /etc/premdigital/user_quota
            echo "$max_ip" > "/etc/premdigital/multilogin/$user"
            echo "$quota_gb" > "/etc/premdigital/user_quota/$user"

            exp=$(date -d "+$masaaktif days" +"%Y-%m-%d")
            useradd -e $exp -s /bin/false -M $user
            echo -e "$user:$pass" | chpasswd
            
            clear
            echo -e "${Y}✅ AKUN SSH SUKSES DIBUAT${NC}"
            echo -e "━━━━━━━━━━━━━━━━━━"
            echo -e "👤 Username   : $user"
            echo -e "🔑 Password   : $pass"
            echo -e "🌍 Host       : $DOMAIN"
            echo -e "⏳ Durasi     : $masaaktif Hari ($exp)"
            echo -e "📱 Max Login  : $max_ip IP / Device"
            echo -e "📦 Kuota Data : $quota_label"
            echo -e "━━━━━━━━━━━━━━━━━━"
            echo -e "🔌 Port Info:"
            echo -e "• WebSocket TLS / SSL  : 443, 8443"
            echo -e "• WebSocket Direct/CDN : 80, 8880, 2082"
            echo -e "• Dropbear SSH         : 109, 143"
            echo -e "• OpenSSH              : 22, 2253"
            echo -e "• BadVPN UDPGW         : 7300, 7100"
            echo -e "• Squid Proxy          : 8080"
            echo -e "━━━━━━━━━━━━━━━━━━"
            echo -e "📥 Payload WS (Bisa tanpa TLS / pakai TLS):"
            echo -e "GET / HTTP/1.1[crlf]Host: $DOMAIN[crlf]User-Agent: [ua][crlf]Upgrade: websocket[crlf][crlf]"
            echo -e "━━━━━━━━━━━━━━━━━━"
            echo ""
            read -r -p "Tekan [Enter] untuk kembali ke menu..." dummy
            ;;
        2)
            clear
            read -p "Masukkan Username yang mau dihapus: " user
            userdel -f $user 2>/dev/null
            rm -f "/etc/premdigital/multilogin/$user" 2>/dev/null
            echo -e "${R}Akun $user berhasil dihapus.${NC}"
            sleep 1.5
            ;;
        3)
            clear
            echo -e "${C}======================================${NC}"
            echo -e "${Y}         LIST AKUN SSH AKTIF          ${NC}"
            echo -e "${C}======================================${NC}"
            printf "%-14s %-12s %-10s\n" "USERNAME" "EXPIRED" "MAX IP"
            echo -e "--------------------------------------"
            awk -F: '($3>=1000)&&($1!="nobody"){print $1}' /etc/passwd | while read line
            do
                exp=$(chage -l $line | grep "Account expires" | awk -F": " '{print $2}')
                limit="2 IP"
                if [ -f "/etc/premdigital/multilogin/$line" ]; then
                    limit="$(cat "/etc/premdigital/multilogin/$line") IP"
                fi
                printf "%-14s %-12s %-10s\n" "$line" "$exp" "$limit"
            done
            echo -e "${C}======================================${NC}"
            echo ""
            read -r -p "Tekan [Enter] untuk kembali ke menu..." dummy
            ;;
        4)
            clear
            echo -e "${C}=== GANTI DOMAIN SERVER ===${NC}"
            echo -e "Domain Saat Ini: ${Y}$DOMAIN${NC}"
            read -p "Masukkan Domain Baru: " newdomain
            echo "$newdomain" > /etc/vps-domain.txt
            echo -e "${Y}Domain berhasil diubah menjadi: $newdomain${NC}"
            sleep 1.5
            ;;
        5)
            clear
            echo -e "${C}======================================${NC}"
            echo -e "${Y}    STATUS SERVICE & PORT TUNNELING   ${NC}"
            echo -e "${C}======================================${NC}"
            echo -e " • WebSocket Proxy    : $(check_wsproxy)"
            echo -e " • Stunnel SSL        : $(check_stunnel)"
            echo -e " • Dropbear SSH       : $(check_dropbear)"
            echo -e " • OpenSSH Server     : $(check_service ssh)"
            echo -e " • BadVPN UDPGW       : $(check_service badvpn-udpgw)"
            echo -e " • Squid Proxy        : $(check_service squid)"
            echo -e " • Web API Server     : $(check_service vps-api)"
            echo -e " • Telegram Bot       : $(check_service vps-bot)"
            echo -e "${C}--------------------------------------${NC}"
            echo -e " • Port 443 (WS Multiplexer) : $(check_port 443)"
            echo -e " • Port 80 (HTTP WebSocket)  : $(check_port 80)"
            echo -e " • Port 109 (Dropbear)       : $(check_port 109)"
            echo -e " • Port 22 (OpenSSH)         : $(check_port 22)"
            echo -e " • Port 7100 (BadVPN UDPGW)  : $(check_port 7100)"
            echo -e " • Port 8080 (Squid Proxy)   : $(check_port 8080)"
            echo -e "${C}======================================${NC}"
            echo ""
            read -r -p "Tekan [Enter] untuk kembali ke menu..." dummy
            ;;
        6)
            clear
            echo -e "${C}======================================${NC}"
            echo -e "${Y}       STATISTIK & KUOTA BANDWIDTH    ${NC}"
            echo -e "${C}======================================${NC}"
            echo -e "Status Saat Ini: $BW_INFO"
            echo -e "--------------------------------------"
            if command -v vnstat >/dev/null 2>&1; then
                echo -e "${Y}[ Ringkasan Pemakaian Harian ]${NC}"
                vnstat -d 2>/dev/null | tail -n 8
                echo ""
                echo -e "${Y}[ Pemakaian Bulanan ]${NC}"
                vnstat -m 2>/dev/null | tail -n 6
            else
                echo -e "Detail Interface Jaringan:"
                ip -s link
            fi
            echo -e "${C}======================================${NC}"
            echo -e " [1] Set Kuota Bandwidth (Unlimited / Custom TB/GB)"
            echo -e " [2] Reset ke Auto-Detect Provider VPS"
            echo -e " [0] Kembali ke Menu Utama"
            echo -e "${C}======================================${NC}"
            read -p " Pilih Opsi [0-2]: " opt_bw
            case $opt_bw in
                1)
                    mkdir -p /etc/premdigital
                    echo -e "\nPilih Jenis Kuota VPS:"
                    echo -e " [1] Unlimited (Unmetered Bandwidth)"
                    echo -e " [2] 1000 GB (1 TB)"
                    echo -e " [3] 2000 GB (2 TB)"
                    echo -e " [4] 5000 GB (5 TB)"
                    echo -e " [5] Custom (Ketik Sendiri, contoh: 500 GB)"
                    read -p "Pilihan [1-5]: " b_opt
                    case $b_opt in
                        1) echo "Unlimited" > /etc/premdigital/bandwidth_quota.txt ;;
                        2) echo "1000 GB" > /etc/premdigital/bandwidth_quota.txt ;;
                        3) echo "2000 GB" > /etc/premdigital/bandwidth_quota.txt ;;
                        4) echo "5000 GB" > /etc/premdigital/bandwidth_quota.txt ;;
                        5) 
                           read -p "Masukkan batas kuota (misal: 750 GB): " cust_q
                           echo "$cust_q" > /etc/premdigital/bandwidth_quota.txt
                           ;;
                    esac
                    echo -e "${G}Kuota bandwidth berhasil diatur!${NC}"
                    sleep 1.5
                    ;;
                2)
                    rm -f /etc/premdigital/bandwidth_quota.txt 2>/dev/null
                    echo -e "${G}Kembali ke mode Auto-Detect provider VPS!${NC}"
                    sleep 1.5
                    ;;
                *)
                    ;;
            esac
            ;;
        7)
            clear
            echo -e "${Y}Merestart semua service tunneling...${NC}"
            systemctl restart ws-proxy 2>/dev/null
            systemctl restart stunnel4 2>/dev/null || systemctl restart stunnel 2>/dev/null
            systemctl restart dropbear 2>/dev/null
            systemctl restart badvpn-udpgw 2>/dev/null
            systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null
            systemctl restart squid 2>/dev/null
            systemctl restart vps-api 2>/dev/null
            systemctl restart vps-bot 2>/dev/null
            echo -e "${G}Semua service tunneling berhasil direstart!${NC}"
            sleep 1.5
            ;;
        8)
            clear
            echo -e "${C}======================================${NC}"
            echo -e "${Y}       PENGATURAN BANNER SSH          ${NC}"
            echo -e "${C}======================================${NC}"
            echo -e " [1] Lihat Banner Saat Ini"
            echo -e " [2] Pasang / Reset Banner PremDigital VIP"
            echo -e " [3] Edit Banner Manual (via nano)"
            echo -e " [0] Kembali ke Menu Utama"
            echo -e "${C}======================================${NC}"
            read -p " Pilih Opsi [0-3]: " opt_banner
            case $opt_banner in
                1)
                    clear
                    echo -e "${Y}=== ISI BANNER SAAT INI (/etc/issue.net) ===${NC}"
                    echo ""
                    cat /etc/issue.net 2>/dev/null || echo -e "${R}Banner belum ada / kosong.${NC}"
                    echo ""
                    echo -e "${C}======================================${NC}"
                    read -r -p "Tekan [Enter] untuk kembali..." dummy
                    ;;
                2)
                    cat > /etc/issue.net << 'BANNEREOF'
<br>
<font color="#00ffff">========================================</font><br>
<font color="#ffd700"><b>       ★ PREMDIGITAL TUNNELING ★        </b></font><br>
<font color="#00ffff">========================================</font><br>
<font color="#ffffff"><b>      [ PERATURAN PENGGUNA SERVER ]    </b></font><br>
<font color="#ff4d4d">  • DILARANG DDOS / HACKING / SCANNING  </font><br>
<font color="#ff4d4d">  • DILARANG TORRENT / BITTORENT / P2P  </font><br>
<font color="#ff4d4d">  • DILARANG SPAM / CARDING / FRAUD     </font><br>
<font color="#ff4d4d">  • DILARANG MULTI-LOGIN (MAX 1 DEVICE) </font><br>
<font color="#00ffff">----------------------------------------</font><br>
<font color="#00ff7f">  ✓ Server Uptime & High Speed Network  </font><br>
<font color="#00ff7f">  ✓ Auto-Reboot Server Tiap 05:00 WIB   </font><br>
<font color="#e0aaff">  ✓ Support & CS: https://wa.me/6283188458876 </font><br>
<font color="#00ffff">  ✓ Website: https://www.premdigital.web.id </font><br>
<font color="#00ffff">========================================</font><br>
<font color="#ffd700">  Terima Kasih Atas Kepercayaan Anda!   </font><br>
<font color="#00ffff">========================================</font><br>
<br>
BANNEREOF
                    cp -f /etc/issue.net /etc/issue 2>/dev/null || true
                    cp -f /etc/issue.net /etc/motd 2>/dev/null || true
                    systemctl restart dropbear 2>/dev/null
                    systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null
                    echo -e "${G}Banner PremDigital berhasil dipasang & service direstart!${NC}"
                    sleep 1.5
                    ;;
                3)
                    nano /etc/issue.net
                    cp -f /etc/issue.net /etc/issue 2>/dev/null || true
                    systemctl restart dropbear 2>/dev/null
                    systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null
                    echo -e "${G}Banner diperbarui & service direstart!${NC}"
                    sleep 1.5
                    ;;
                *)
                    ;;
            esac
            ;;
        9)
            clear
            echo -e "Menjalankan penghapusan akun expired..."
            /usr/local/bin/auto-delete
            echo -e "${G}Penghapusan akun expired selesai!${NC}"
            sleep 1.5
            ;;
        10)
            clear
            echo -e "${C}======================================${NC}"
            echo -e "${Y}   FITUR AUTO-KILL MULTI-LOGIN        ${NC}"
            echo -e "${C}======================================${NC}"
            echo -e "Status: ${G}AKTIF (Multi-Device Sesuai Akun)${NC}"
            echo -e "Pilihan IP: 1 IP, 2 IP, 3 IP, atau 5 IP"
            echo -e "Script : /usr/local/bin/auto-kill-multilogin"
            echo -e "Cronjob: Berjalan otomatis setiap 2 Menit"
            echo -e "--------------------------------------"
            echo -e " [1] Cek Log Pelanggaran Multi-Login"
            echo -e " [2] Jalankan Deteksi & Kill Sekarang"
            echo -e " [0] Kembali ke Menu Utama"
            echo -e "${C}======================================${NC}"
            read -p " Pilih Opsi [0-2]: " opt_multi
            case $opt_multi in
                1)
                    clear
                    echo -e "${Y}=== LOG PELANGGARAN MULTI-LOGIN ===${NC}"
                    if [ -f /var/log/multilogin.log ]; then
                        tail -n 30 /var/log/multilogin.log
                    else
                        echo -e "Belum ada log pelanggaran multi-login."
                    fi
                    echo ""
                    read -r -p "Tekan [Enter] untuk kembali..." dummy
                    ;;
                2)
                    clear
                    echo -e "${Y}Memindai seluruh sesi koneksi pengguna...${NC}"
                    /usr/local/bin/auto-kill-multilogin
                    echo -e "${G}Selesai memeriksa sesi & menertibkan limit login!${NC}"
                    sleep 1.5
                    ;;
                *)
                    ;;
            esac
            ;;
        11)
            menu-service
            ;;
        0)
            clear
            exit 0
            ;;
        *)
            echo -e "Pilihan salah!"
            sleep 1
            ;;
    esac
done
END
chmod +x /usr/bin/menu

# 13. CLI Menu Service (API & Bot)
cat > /usr/bin/menu-service << 'END'
#!/bin/bash
Y="\e[33m"
C="\e[36m"
R="\e[31m"
G="\e[32m"
NC="\e[0m"

while true; do
    clear
    echo -e "${C}======================================${NC}"
    echo -e "${Y}       MENU SERVICE (API & BOT)       ${NC}"
    echo -e "${C}======================================${NC}"
    echo -e " [1] Ganti Secret Key API Web"
    echo -e " [2] Ganti Token Bot Telegram"
    echo -e " [3] Restart Service (API & Bot)"
    echo -e " [4] Cek Status Koneksi API (Test Ping)"
    echo -e " [0] Kembali ke Menu Utama"
    echo -e "${C}======================================${NC}"
    read -p " Pilih Opsi [0-4]: " opt
    case $opt in
        1)
            clear
            read -p "Masukkan Secret Key Baru: " newkey
            sed -i "s/API_SECRET = \".*\"/API_SECRET = \"$newkey\"/g" /usr/local/bin/vps-api
            systemctl restart vps-api
            echo -e "\n${G}Secret Key berhasil diganti!${NC}"
            sleep 1.5
            ;;
        2)
            clear
            read -p "Masukkan Token Bot Telegram: " newtoken
            sed -i "s/BOT_TOKEN = \".*\"/BOT_TOKEN = \"$newtoken\"/g" /usr/local/bin/vps-bot
            systemctl restart vps-bot
            echo -e "\n${G}Token Bot berhasil diganti!${NC}"
            sleep 1.5
            ;;
        3)
            clear
            echo -e "Merestart Service..."
            systemctl restart ws-proxy
            systemctl restart stunnel4 2>/dev/null || systemctl restart stunnel 2>/dev/null
            systemctl restart dropbear
            systemctl restart badvpn-udpgw 2>/dev/null
            systemctl restart vps-api
            systemctl restart vps-bot
            echo -e "\n${G}Service API & Bot berhasil direstart!${NC}"
            sleep 1.5
            ;;
        4)
            clear
            echo -e "${Y}Mencoba menembak API di localhost (Port 5000)...${NC}"
            API_KEY=$(grep "^API_SECRET =" /usr/local/bin/vps-api | cut -d '"' -f 2)
            curl -X POST http://127.0.0.1:5000/api/create \
                 -H "Content-Type: application/json" \
                 -d '{"secret": "'"$API_KEY"'", "username": "testapi", "password": "123", "expired": "1"}'
            echo ""
            echo -e "Jika muncul JSON success, berarti API BEKERJA NORMAL!"
            userdel -f testapi 2>/dev/null
            echo ""
            read -r -p "Tekan [Enter] untuk kembali ke menu service..." dummy
            ;;
        0)
            break
            ;;
        *)
            echo -e "Pilihan salah!"
            sleep 1
            ;;
    esac
done
END
chmod +x /usr/bin/menu-service

# 14. Auto Delete Expired Accounts & Multi-Login Auto Kill (Max 2 IP)
echo -e "\e[33m[INFO] Setting Auto Delete Expired & Multi-Login Auto Kill...\e[0m"
cat > /usr/local/bin/auto-delete << 'END'
#!/bin/bash
hariini=$(date +%Y-%m-%d)
awk -F: '($3>=1000)&&($1!="nobody"){print $1}' /etc/passwd | while read line
do
    exp=$(chage -l $line | grep "Account expires" | awk -F": " '{print $2}')
    if [[ $exp != "never" ]]; then
        tgl_exp=$(date -d"$exp" +%Y-%m-%d)
        if [[ "$tgl_exp" < "$hariini" ]]; then
            userdel -f $line
            rm -f "/etc/premdigital/multilogin/$line" 2>/dev/null
            echo "Akun $line telah dihapus karena expired."
        fi
    fi
done
END
chmod +x /usr/local/bin/auto-delete

# Script Auto-Kill Multi Login Dinamis (Per Akun: 1, 2, 3, atau 5 IP)
cat > /usr/local/bin/auto-kill-multilogin << 'END'
#!/bin/bash
LOG_FILE="/var/log/multilogin.log"
LIMIT_DIR="/etc/premdigital/multilogin"

mkdir -p "$LIMIT_DIR"
touch $LOG_FILE

# Ambil semua user SSH non-system (UID >= 1000)
awk -F: '($3>=1000)&&($1!="nobody"){print $1}' /etc/passwd | while read -r user; do
    # Tentukan batas multi login untuk akun ini (Default 2 IP jika belum tersetting)
    max_limit=2
    if [ -f "$LIMIT_DIR/$user" ]; then
        user_val=$(cat "$LIMIT_DIR/$user" | tr -dc '0-9')
        if [ -n "$user_val" ]; then
            max_limit=$user_val
        fi
    fi

    # Hitung proses unik SSH & Dropbear untuk user ini
    pids=$(pgrep -u "$user" -f "dropbear|sshd: $user" 2>/dev/null)
    total_sess=$(echo "$pids" | grep -v '^$' | wc -l)
    
    if [ "$total_sess" -gt "$max_limit" ]; then
        timestamp=$(date "+%Y-%m-%d %H:%M:%S")
        echo "[$timestamp] User '$user' melanggar multi-login! Total sesi: $total_sess (Max Limit: $max_limit IP). Mematikan sesi..." >> $LOG_FILE
        # Matikan semua sesi user yang melanggar agar adil
        kill -9 $pids 2>/dev/null
    fi
done
END
chmod +x /usr/local/bin/auto-kill-multilogin

# Cronjob jalan tiap tengah malam (auto-delete) dan tiap 2 menit (auto-kill multi-login)
(crontab -l 2>/dev/null | grep -v "/usr/local/bin/auto-delete" | grep -v "/usr/local/bin/auto-kill-multilogin"; \
 echo "0 0 * * * /usr/local/bin/auto-delete"; \
 echo "*/2 * * * * /usr/local/bin/auto-kill-multilogin") | crontab -

# Alias menu
grep -qxF "alias menu='/usr/bin/menu'" ~/.bashrc || echo "alias menu='/usr/bin/menu'" >> ~/.bashrc

# 15. Ringkasan Instalasi Tunneling
clear
echo -e "\e[36m====================================================\e[0m"
echo -e "\e[33m   INSTALASI TUNNELING PREMDIGITAL V1 SUKSES!       \e[0m"
echo -e "\e[36m====================================================\e[0m"
echo -e " 🌍 Host / Domain : \e[32m$DOMAIN\e[0m"
echo -e " 🌐 IP VPS        : \e[32m$MYIP\e[0m"
echo -e "\e[36m----------------------------------------------------\e[0m"
echo -e " 🔌 INFORMASI PORT TUNNELING:\e[0m"
echo -e " • WebSocket Direct / CDN HTTP : \e[33m80, 8880, 2082\e[0m"
echo -e " • WebSocket SSL / TLS (Multi) : \e[33m443, 8443\e[0m (Bisa tanpa TLS / pakai TLS)"
echo -e " • Dropbear SSH                : \e[33m109, 143\e[0m"
echo -e " • OpenSSH                     : \e[33m22, 2253\e[0m"
echo -e " • BadVPN UDPGW (Gaming/Call)  : \e[33m7300, 7100\e[0m"
echo -e " • Squid Proxy                 : \e[33m8080\e[0m"
echo -e " • Web API Backend Server      : \e[33m5000\e[0m"
echo -e "\e[36m----------------------------------------------------\e[0m"
echo -e " 📥 PAYLOAD WEBSOCKET (HTTP Custom / Injector):"
echo -e " \e[32mGET / HTTP/1.1[crlf]Host: $DOMAIN[crlf]User-Agent: [ua][crlf]Upgrade: websocket[crlf][crlf]\e[0m"
echo -e "\e[36m----------------------------------------------------\e[0m"
echo -e " 👉 Ketik \e[33mmenu\e[0m di terminal VPS Anda untuk membuka Panel CLI."
echo -e "\e[36m====================================================\e[0m"
