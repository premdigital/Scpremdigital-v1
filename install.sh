#!/bin/bash
# ==========================================
# PREMDIGITAL - SSH & VPN AUTO INSTALLER V1
# ==========================================
# OS Support: Ubuntu 20.04 / Debian 10+
# ==========================================

if [ "${EUID}" -ne 0 ]; then
    echo -e "Mohon jalankan script ini sebagai root (sudo su)"
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo -e "\e[32m[INFO] Memperbaiki package manager & lock jika ada...\e[0m"
dpkg --configure -a
apt-get -f install -y

echo -e "\e[32m[INFO] Memulai Instalasi Script PremDigital...\e[0m"
sleep 2

# 1. Update & Install Dependencies
echo -e "[INFO] Update & Install Packages (Non-interactive)..."
apt-get update -y
apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" curl wget wget2 nano python3 python3-pip cron ufw dropbear stunnel4 squid python3-flask python3-requests

# 2. Setting Waktu & Timezone (WIB)
echo -e "[INFO] Setting Timezone (WIB)..."
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime
dpkg-reconfigure --frontend noninteractive tzdata

# 3. Setup Direktori
mkdir -p /etc/premdigital/
mkdir -p /usr/local/bin/
touch /etc/premdigital/users.db

# 4. Setting SSH OpenSSH (Port 22 & 2253)
echo -e "[INFO] Setting OpenSSH..."
sed -i 's/#Port 22/Port 22/g' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 2253' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/g' /etc/ssh/sshd_config
echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
[ -d /etc/ssh/sshd_config.d ] && echo "PasswordAuthentication yes" > /etc/ssh/sshd_config.d/01-permitpassword.conf
systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null

# 5. Setting Dropbear (Port 109, 143)
echo -e "[INFO] Setting Dropbear..."
grep -qxF '/bin/false' /etc/shells || echo '/bin/false' >> /etc/shells
grep -qxF '/usr/sbin/nologin' /etc/shells || echo '/usr/sbin/nologin' >> /etc/shells
sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=109/g' /etc/default/dropbear
sed -i 's/DROPBEAR_EXTRA_ARGS=.*/DROPBEAR_EXTRA_ARGS="-p 109 -p 143"/g' /etc/default/dropbear
systemctl restart dropbear

# 6. Setting WebSocket SSH Proxy (Smart Multiplexer Port 443, 80, 8880, 2082)
echo -e "[INFO] Setting WebSocket SSH Proxy..."
cat > /usr/local/bin/ws-proxy << 'END'
#!/usr/bin/python3
import socket, threading, select, sys

def handle_client(client_sock, target_host, target_port, tls_target_port=None):
    target_sock = None
    try:
        client_sock.settimeout(10.0)
        data = client_sock.recv(4096)
        if not data:
            return

        # 1. Deteksi TLS ClientHello (Byte pertama 0x16 = TLS Handshake)
        if data[0] == 0x16 and tls_target_port:
            target_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            target_sock.connect(('127.0.0.1', tls_target_port))
            target_sock.sendall(data)
        # 2. Deteksi Request HTTP / WebSocket Upgrade (HTTP Custom Payload tanpa TLS)
        elif b'HTTP/' in data or b'Upgrade: websocket' in data or b'GET ' in data or b'POST ' in data or b'CONNECT ' in data:
            target_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            target_sock.connect((target_host, target_port))
            response = (
                b"HTTP/1.1 101 Switching Protocols
"
                b"Upgrade: websocket
"
                b"Connection: Upgrade

"
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
    try:
        server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        server.bind((listen_host, listen_port))
        server.listen(200)
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
                pass
    except Exception as e:
        print(f"Error binding {listen_host}:{listen_port} -> {e}", file=sys.stderr)

if __name__ == '__main__':
    # Port 443: Smart Multiplexer (Konek HTTP WebSocket langsung tanpa TLS, atau auto-forward TLS ke Stunnel)
    t_443 = threading.Thread(target=start_listener, args=('0.0.0.0', 443, '127.0.0.1', 109, 4430), daemon=True)
    t_443.start()

    # Port 80: HTTP WebSocket Direct / CDN
    t_80 = threading.Thread(target=start_listener, args=('0.0.0.0', 80, '127.0.0.1', 109), daemon=True)
    t_80.start()

    # Port 700: Backend Decrypted TLS dari Stunnel
    t_700 = threading.Thread(target=start_listener, args=('127.0.0.1', 700, '127.0.0.1', 109), daemon=True)
    t_700.start()

    # Port 8880 & 2082: Alternatif HTTP WS
    t_8880 = threading.Thread(target=start_listener, args=('0.0.0.0', 8880, '127.0.0.1', 109), daemon=True)
    t_8880.start()
    t_2082 = threading.Thread(target=start_listener, args=('0.0.0.0', 2082, '127.0.0.1', 109), daemon=True)
    t_2082.start()

    t_443.join()
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

[Install]
WantedBy=multi-user.target
END

systemctl daemon-reload
systemctl enable ws-proxy
systemctl restart ws-proxy

# 7. Setting Stunnel (Port 4430 Internal & 8443)
echo -e "[INFO] Setting Stunnel..."
cat > /etc/stunnel/stunnel.conf << 'END'
cert = /etc/stunnel/stunnel.pem
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[ws-tls]
accept = 127.0.0.1:4430
connect = 127.0.0.1:700

[openssh-tls]
accept = 8443
connect = 127.0.0.1:700
END

openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -sha256 -subj "/C=ID/ST=DKI Jakarta/L=Jakarta/O=PremDigital/OU=PremDigital/CN=premdigital.com" -out /etc/stunnel/stunnel.pem -keyout /etc/stunnel/stunnel.pem

sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4 2>/dev/null || true
echo "ENABLED=1" >> /etc/default/stunnel4

systemctl enable stunnel4 2>/dev/null || true
systemctl restart stunnel4 2>/dev/null || systemctl restart stunnel 2>/dev/null || true

# 8. Setting BadVPN UDPGW (Port 7100)
echo -e "[INFO] Setting BadVPN UDPGW..."
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

# 7. Setting Squid Proxy (Port 8080)
echo -e "[INFO] Setting Squid..."
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

# 8. Web API (Python Flask) - Port 5000
echo -e "[INFO] Install Web API Backend..."
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
                "http": "80, 8080",
                "slowdns": "53, 5300",
                "ssh_ohp": "9080",
                "udp_custom": "1-65535",
                "udpgw": "7100-7600"
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
systemctl start vps-api

# 9. Bot Telegram Server-Side
echo -e "[INFO] Setting Telegram Bot Base..."
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
            MSG = f"✅ AKUN SSH SUKSES DIBUAT\n━━━━━━━━━━━━━━━━━━\n👤 Username: {user}\n🔑 Password: {pwd}\n🌍 Host: {DOMAIN}\n⏳  Durasi: {hari} Hari\n━━━━━━━━━━━━━━━━━━\n🔌 Port Info:\n• TLS: 443, 8443\n• HTTP: 80, 8080\n• SlowDNS: 53, 5300\n• SSH OHP: 9080\n• UDP Custom: 1-65535\n• UDPGW: 7100-7600\n━━━━━━━━━━━━━━━━━━\n📥 Payload WS:\nGET / HTTP/1.1[crlf]Host: [host_port][crlf]User-Agent: [ua][crlf]Upgrade: websocket[crlf][crlf]\n━━━━━━━━━━━━━━━━━━"
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

# 10. CLI Menu & Commands
echo -e "[INFO] Setting up CLI Menu..."
cat > /usr/bin/menu << 'END'
#!/bin/bash
Y="\e[33m"
C="\e[36m"
R="\e[31m"
G="\e[32m"
NC="\e[0m"

while true; do
    # Ambil Info Jaringan (IP, ISP, Kota)
    IP=$(curl -sS ipv4.icanhazip.com 2>/dev/null)
    [ -z "$IP" ] && IP=$(curl -sS ipinfo.io/ip 2>/dev/null)

    ISP=$(curl -s http://ip-api.com/line/?fields=isp 2>/dev/null)
    [ -z "$ISP" ] && ISP=$(curl -s ipinfo.io/org 2>/dev/null | cut -d " " -f 2-10)
    [ -z "$ISP" ] && ISP="Unknown ISP"

    CITY=$(curl -s http://ip-api.com/line/?fields=city 2>/dev/null)
    [ -z "$CITY" ] && CITY=$(curl -s ipinfo.io/city 2>/dev/null)

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
    echo -e " Domain  : $DOMAIN"
    echo -e " IP VPS  : $IP"
    echo -e "${C}======================================${NC}"
    echo -e " [1] Buat Akun SSH Baru"
    echo -e " [2] Hapus Akun SSH"
    echo -e " [3] List Akun SSH Aktif"
    echo -e " [4] Ganti Domain Server"
    echo -e " [5] Jalankan Auto-Delete Expired"
    echo -e " [6] Menu Service API & Bot Telegram"
    echo -e " [0] Keluar"
    echo -e "${C}======================================${NC}"
    read -p " Pilih Opsi [0-6]: " opt

    case $opt in
        1)
            clear
            read -p "Username: " user
            read -p "Password: " pass
            read -p "Berapa Hari: " masaaktif
            exp=$(date -d "+$masaaktif days" +"%Y-%m-%d")
            useradd -e $exp -s /bin/false -M $user
            echo -e "$user:$pass" | chpasswd
            echo -e "
${Y}✅ AKUN SSH SUKSES DIBUAT${NC}"
            echo -e "━━━━━━━━━━━━━━━━━━"
            echo -e "👤 Username: $user"
            echo -e "🔑 Password: $pass"
            echo -e "🌍 Host: $DOMAIN"
            echo -e "⏳  Durasi: $masaaktif Hari"
            echo -e "━━━━━━━━━━━━━━━━━━"
            echo -e "🔌 Port Info:"
            echo -e "• TLS: 443, 8443"
            echo -e "• HTTP: 80, 8080"
            echo -e "• SlowDNS: 53, 5300"
            echo -e "• SSH OHP: 9080"
            echo -e "• UDP Custom: 1-65535"
            echo -e "• UDPGW: 7100-7600"
            echo -e "━━━━━━━━━━━━━━━━━━"
            echo -e "📥 Payload WS:"
            echo -e "GET / HTTP/1.1[crlf]Host: [host_port][crlf]User-Agent: [ua][crlf]Upgrade: websocket[crlf][crlf]"
            echo -e "━━━━━━━━━━━━━━━━━━"
            echo ""
            read -r -p "Tekan [Enter] untuk kembali ke menu..." dummy
            ;;
        2)
            clear
            read -p "Masukkan Username yang mau dihapus: " user
            userdel -f $user
            echo -e "
${R}Akun $user berhasil dihapus.${NC}"
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
            echo -e "
${Y}Domain berhasil diubah menjadi: $newdomain${NC}"
            sleep 1.5
            ;;
        5)
            clear
            echo -e "Menjalankan penghapusan akun expired..."
            /usr/local/bin/auto-delete
            echo -e "
${G}Penghapusan akun expired selesai!${NC}"
            sleep 1.5
            ;;
        6)
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

# 11. CLI Menu Service (API & Bot)
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
            sed -i "s/API_SECRET = ".*"/API_SECRET = "$newkey"/g" /usr/local/bin/vps-api
            systemctl restart vps-api
            echo -e "
${G}Secret Key berhasil diganti!${NC}"
            sleep 1.5
            ;;
        2)
            clear
            read -p "Masukkan Token Bot Telegram: " newtoken
            sed -i "s/BOT_TOKEN = ".*"/BOT_TOKEN = "$newtoken"/g" /usr/local/bin/vps-bot
            systemctl restart vps-bot
            echo -e "
${G}Token Bot berhasil diganti!${NC}"
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
            echo -e "
${G}Service API & Bot berhasil direstart!${NC}"
            sleep 1.5
            ;;
        4)
            clear
            echo -e "${Y}Mencoba menembak API di localhost (Port 5000)...${NC}
"
            API_KEY=$(grep "API_SECRET" /usr/local/bin/vps-api | cut -d '"' -f 2)
            curl -X POST http://127.0.0.1:5000/api/create                  -H "Content-Type: application/json"                  -d '{"secret": "'"$API_KEY"'", "username": "testapi", "password": "123", "expired": "1"}'
            echo ""
            echo -e "
Jika muncul JSON success, berarti API BEKERJA NORMAL!"
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

# 12. Auto Delete Expired Accounts (Cronjob)
echo -e "[INFO] Setting Auto Delete Expired..."
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
(crontab -l 2>/dev/null; echo "0 0 * * * /usr/local/bin/auto-delete") | crontab -


