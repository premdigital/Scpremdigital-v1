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
apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" curl wget wget2 nano python3 python3-pip cron ufw dropbear stunnel4 squid python3-flask python3-requests net-tools psmisc lsof

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
[ -d /etc/ssh/sshd_config.d ] && echo -e "PasswordAuthentication yes\nBanner /etc/issue.net" > /etc/ssh/sshd_config.d/01-permitpassword.conf
systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null

# 5. Setting Banner & Dropbear (Port 109, 143)
echo -e "\e[33m[INFO] Setting Banner & Dropbear...\e[0m"
mkdir -p /etc/dropbear
[ -f /etc/dropbear/dropbear_rsa_host_key ] || dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key -s 2048 2>/dev/null || true
[ -f /etc/dropbear/dropbear_ecdsa_host_key ] || dropbearkey -t ecdsa -f /etc/dropbear/dropbear_ecdsa_host_key 2>/dev/null || true
[ -f /etc/dropbear/dropbear_ed25519_host_key ] || dropbearkey -t ed25519 -f /etc/dropbear/dropbear_ed25519_host_key 2>/dev/null || true

cat > /etc/issue.net << 'END'
<br>
<font color="#00ffcc"><b>========================================</b></font><br>
<font color="#ffb703"><b>      ★ PREMDIGITAL VIP TUNNELING ★     </b></font><br>
<font color="#00ffcc"><b>========================================</b></font><br>
<font color="#ffffff"><b>       [ PERATURAN PENGGUNA SERVER ]    </b></font><br>
<font color="#ff4d4d"><b>  • DILARANG DDOS / HACKING / SCANNING  </b></font><br>
<font color="#ff4d4d"><b>  • DILARANG TORRENT / BITTORENT / P2P  </b></font><br>
<font color="#ff4d4d"><b>  • DILARANG SPAM / CARDING / FRAUD     </b></font><br>
<font color="#ff4d4d"><b>  • DILARANG MULTI-LOGIN (MAX 1 DEVICE) </b></font><br>
<font color="#00ffcc"><b>----------------------------------------</b></font><br>
<font color="#00ff88"><b>  ✓ Server Uptime & High Speed Network  </b></font><br>
<font color="#00ff88"><b>  ✓ Auto-Reboot Server Tiap 05:00 WIB   </b></font><br>
<font color="#e0aaff"><b>  ✓ Support & CS: t.me/premdigital      </b></font><br>
<font color="#00ffcc"><b>========================================</b></font><br>
<font color="#ffd166"><b>  Terima Kasih Atas Kepercayaan Anda!   </b></font><br>
<font color="#00ffcc"><b>========================================</b></font><br>
END

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

def handle_client(client_sock, target_host, target_port, tls_target_port=None):
    target_sock = None
    try:
        client_sock.settimeout(10.0)
        data = client_sock.recv(4096)
        if not data:
            return

        # 1. Deteksi TLS ClientHello (Byte pertama 0x16 = TLS Handshake)
        if (data[0] == 0x16 or data.startswith(b'\x16')) and tls_target_port:
            target_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            target_sock.connect(('127.0.0.1', tls_target_port))
            target_sock.sendall(data)
        # 2. Deteksi Request HTTP / WebSocket Upgrade (HTTP Custom Payload tanpa TLS)
        elif b'HTTP/' in data or b'Upgrade: websocket' in data or b'GET ' in data or b'POST ' in data or b'CONNECT ' in data:
            target_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            target_sock.connect((target_host, target_port))
            response = (
                b"HTTP/1.1 101 Switching Protocols\r\n"
                b"Upgrade: websocket\r\n"
                b"Connection: Upgrade\r\n\r\n"
            )
            client_sock.sendall(response)
        # 3. Direct SSH Protocol biasa (SSH-2.0...)
        else:
            target_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            target_sock.connect((target_host, target_port))
            target_sock.sendall(data)

        client_sock.settimeout(None)
        target_sock.settimeout(None)

        sockets = [client_sock, target_sock]
        while True:
            r, _, x = select.select(sockets, [], sockets, 120)
            if x or not r:
                break
            for s in r:
                other = target_sock if s is client_sock else client_sock
                buf = s.recv(8192)
                if not buf:
                    return
                other.sendall(buf)
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
            server.bind((listen_host, listen_port))
            server.listen(200)
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

# 8. Setting BadVPN UDPGW (Port 7100)
echo -e "\e[33m[INFO] Setting BadVPN UDPGW...\e[0m"
wget -q -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/daybreakersx/premscript/master/badvpn-udpgw64"
chmod +x /usr/bin/badvpn-udpgw

cat > /etc/systemd/system/badvpn-udpgw.service << 'END'
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
systemctl enable badvpn-udpgw 2>/dev/null || true
systemctl restart badvpn-udpgw 2>/dev/null || true

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
                "udpgw": "7100",
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
        if len(parts) == 4:
            user = parts[1]
            pwd = parts[2]
            hari = parts[3]
            os.system(f'useradd -m -s /bin/false -M {user}')
            os.system(f'echo "{user}:{pwd}" | chpasswd')
            
            MSG = f"✅ AKUN SSH SUKSES DIBUAT\n━━━━━━━━━━━━━━━━━━\n👤 Username: {user}\n🔑 Password: {pwd}\n🌍 Host: {DOMAIN}\n⏳  Durasi: {hari} Hari\n━━━━━━━━━━━━━━━━━━\n🔌 Port Info:\n• TLS: 443, 8443\n• HTTP: 80, 8880, 2082\n• Dropbear: 109, 143\n• OpenSSH: 22, 2253\n• UDPGW: 7100\n• Squid: 8080\n━━━━━━━━━━━━━━━━━━\n📥 Payload WS:\nGET / HTTP/1.1[crlf]Host: [host_port][crlf]User-Agent: [ua][crlf]Upgrade: websocket[crlf][crlf]\n━━━━━━━━━━━━━━━━━━"
            requests.post(f"https://api.telegram.org/bot{BOT_TOKEN}/sendMessage", data={"chat_id": chat_id, "text": MSG})
        else:
            requests.get(f"https://api.telegram.org/bot{BOT_TOKEN}/sendMessage?chat_id={chat_id}&text=Format salah. Gunakan: /create user password hari")

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

while true; do
    IP=$(curl -sS -m 2 ipv4.icanhazip.com 2>/dev/null || curl -sS -m 2 ipinfo.io/ip 2>/dev/null || echo "127.0.0.1")
    
    ISP=$(curl -s -m 2 http://ip-api.com/line/?fields=isp 2>/dev/null)
    if [[ -z "$ISP" || "$ISP" =~ "{" || "$ISP" =~ "error" || "$ISP" =~ "429" || "$ISP" =~ "Rate limit" ]]; then
        ISP="PremDigital Cloud"
    fi

    CITY=$(curl -s -m 2 http://ip-api.com/line/?fields=city 2>/dev/null)
    if [[ -z "$CITY" || "$CITY" =~ "{" || "$CITY" =~ "error" || "$CITY" =~ "429" || "$CITY" =~ "Rate limit" ]]; then
        CITY="Singapore"
    fi
    
    if [ -f /etc/vps-domain.txt ]; then
        DOMAIN=$(cat /etc/vps-domain.txt)
    else
        DOMAIN=$IP
    fi

    clear
    echo -e "${C}======================================${NC}"
    echo -e "${Y}     PANEL PREMDIGITAL - VPS MANAGER  ${NC}"
    echo -e "${C}======================================${NC}"
    echo -e " OS      : $(cat /etc/os-release | grep -w PRETTY_NAME | cut -d= -f2 | tr -d '"')"
    echo -e " RAM     : $(free -m | awk 'NR==2{printf "%sMB / %sMB", $3,$2}')"
    echo -e " ISP     : $ISP"
    echo -e " Kota    : $CITY"
    echo -e " Domain  : ${Y}$DOMAIN${NC}"
    echo -e " IP VPS  : ${G}$IP${NC}"
    echo -e "${C}======================================${NC}"
    echo -e " [1] Buat Akun SSH Baru"
    echo -e " [2] Hapus Akun SSH"
    echo -e " [3] List Akun SSH Aktif"
    echo -e " [4] Ganti Domain Server"
    echo -e " [5] Cek Status Port & Service Tunneling"
    echo -e " [6] Restart Semua Service Tunneling"
    echo -e " [7] Pengaturan Banner SSH (/etc/issue.net)"
    echo -e " [8] Jalankan Auto-Delete Expired"
    echo -e " [9] Menu Service API & Bot Telegram"
    echo -e " [0] Keluar"
    echo -e "${C}======================================${NC}"
    read -p " Pilih Opsi [0-9]: " opt
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
            exp=$(date -d "+$masaaktif days" +"%Y-%m-%d")
            useradd -e $exp -s /bin/false -M $user
            echo -e "$user:$pass" | chpasswd
            
            clear
            echo -e "${Y}✅ AKUN SSH SUKSES DIBUAT${NC}"
            echo -e "━━━━━━━━━━━━━━━━━━"
            echo -e "👤 Username: $user"
            echo -e "🔑 Password: $pass"
            echo -e "🌍 Host: $DOMAIN"
            echo -e "⏳  Durasi: $masaaktif Hari ($exp)"
            echo -e "━━━━━━━━━━━━━━━━━━"
            echo -e "🔌 Port Info:"
            echo -e "• WebSocket TLS / SSL  : 443, 8443"
            echo -e "• WebSocket Direct/CDN : 80, 8880, 2082"
            echo -e "• Dropbear SSH         : 109, 143"
            echo -e "• OpenSSH              : 22, 2253"
            echo -e "• BadVPN UDPGW         : 7100"
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
            echo -e "${R}Akun $user berhasil dihapus.${NC}"
            sleep 1.5
            ;;
        3)
            clear
            echo -e "${C}======================================${NC}"
            echo -e "${Y}         LIST AKUN SSH AKTIF          ${NC}"
            echo -e "${C}======================================${NC}"
            awk -F: '($3>=1000)&&($1!="nobody"){print $1}' /etc/passwd | while read line
            do
                exp=$(chage -l $line | grep "Account expires" | awk -F": " '{print $2}')
                echo -e "Username: ${Y}$line${NC} | Exp: ${R}$exp${NC}"
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
        7)
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
<font color="#00ffcc"><b>========================================</b></font><br>
<font color="#ffb703"><b>      ★ PREMDIGITAL VIP TUNNELING ★     </b></font><br>
<font color="#00ffcc"><b>========================================</b></font><br>
<font color="#ffffff"><b>       [ PERATURAN PENGGUNA SERVER ]    </b></font><br>
<font color="#ff4d4d"><b>  • DILARANG DDOS / HACKING / SCANNING  </b></font><br>
<font color="#ff4d4d"><b>  • DILARANG TORRENT / BITTORENT / P2P  </b></font><br>
<font color="#ff4d4d"><b>  • DILARANG SPAM / CARDING / FRAUD     </b></font><br>
<font color="#ff4d4d"><b>  • DILARANG MULTI-LOGIN (MAX 1 DEVICE) </b></font><br>
<font color="#00ffcc"><b>----------------------------------------</b></font><br>
<font color="#00ff88"><b>  ✓ Server Uptime & High Speed Network  </b></font><br>
<font color="#00ff88"><b>  ✓ Auto-Reboot Server Tiap 05:00 WIB   </b></font><br>
<font color="#e0aaff"><b>  ✓ Support & CS: t.me/premdigital      </b></font><br>
<font color="#00ffcc"><b>========================================</b></font><br>
<font color="#ffd166"><b>  Terima Kasih Atas Kepercayaan Anda!   </b></font><br>
<font color="#00ffcc"><b>========================================</b></font><br>
BANNEREOF
                    systemctl restart dropbear 2>/dev/null
                    systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null
                    echo -e "${G}Banner PremDigital VIP berhasil dipasang & service direstart!${NC}"
                    sleep 1.5
                    ;;
                3)
                    nano /etc/issue.net
                    systemctl restart dropbear 2>/dev/null
                    systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null
                    echo -e "${G}Banner diperbarui & service direstart!${NC}"
                    sleep 1.5
                    ;;
                *)
                    ;;
            esac
            ;;
        8)
            clear
            echo -e "Menjalankan penghapusan akun expired..."
            /usr/local/bin/auto-delete
            echo -e "${G}Penghapusan akun expired selesai!${NC}"
            sleep 1.5
            ;;
        9)
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
            API_KEY=$(grep "API_SECRET" /usr/local/bin/vps-api | cut -d '"' -f 2)
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

# 14. Auto Delete Expired Accounts (Cronjob)
echo -e "\e[33m[INFO] Setting Auto Delete Expired...\e[0m"
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
            echo "Akun $line telah dihapus karena expired."
        fi
    fi
done
END
chmod +x /usr/local/bin/auto-delete

# Cronjob jalan tiap jam 00:00 (Tengah Malam)
(crontab -l 2>/dev/null | grep -v "/usr/local/bin/auto-delete"; echo "0 0 * * * /usr/local/bin/auto-delete") | crontab -

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
echo -e " • BadVPN UDPGW (Gaming/Call)  : \e[33m7100\e[0m"
echo -e " • Squid Proxy                 : \e[33m8080\e[0m"
echo -e " • Web API Backend Server      : \e[33m5000\e[0m"
echo -e "\e[36m----------------------------------------------------\e[0m"
echo -e " 📥 PAYLOAD WEBSOCKET (HTTP Custom / Injector):"
echo -e " \e[32mGET / HTTP/1.1[crlf]Host: $DOMAIN[crlf]User-Agent: [ua][crlf]Upgrade: websocket[crlf][crlf]\e[0m"
echo -e "\e[36m----------------------------------------------------\e[0m"
echo -e " 👉 Ketik \e[33mmenu\e[0m di terminal VPS Anda untuk membuka Panel CLI."
echo -e "\e[36m====================================================\e[0m"
