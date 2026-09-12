#!/bin/bash

# ==========================================
# CEK LISENSI IP (GITHUB)
# ==========================================
MYIP=$(curl -sS ipv4.icanhazip.com || curl -sS ifconfig.me)
IZIN_DATA=$(curl -sS https://raw.githubusercontent.com/premdigital/Scpremdigital-v1/main/ijin.txt | grep "^$MYIP" 2>/dev/null)
if [ -z "$IZIN_DATA" ]; then
    echo -e "\e[31mAkses Ditolak! IP VPS ($MYIP) tidak terdaftar.\e[0m"
    echo -e "\e[33mSilakan hubungi admin untuk mendaftarkan IP Anda.\e[0m"
    exit 1
fi
EXP_DATE=$(echo "$IZIN_DATA" | awk '{print $3}')
d1=$(date -d "$EXP_DATE" +%s 2>/dev/null)
d2=$(date -d "today" +%s 2>/dev/null)
if [ -n "$d1" ] && [ -n "$d2" ]; then
    SISA_HARI=$(( (d1 - d2) / 86400 ))
    if [ "$SISA_HARI" -lt 0 ]; then
        echo -e "\e[31mScript Expired! Lisensi Anda sudah habis masa aktifnya.\e[0m"
        exit 1
    fi
fi

if [[ "$1" == "--update-menu" ]]; then
    echo -e "\e[32mMendownload dan memperbarui menu & modul Xray...\e[0m"
    wget -qO /tmp/temp-install.sh https://raw.githubusercontent.com/premdigital/Scpremdigital-v1/main/install.sh
    awk '/^cat > \/usr\/bin\/menu << '"'END'"'/{flag=1; next} /^END$/{if(flag){flag=0; next}} flag' /tmp/temp-install.sh > /usr/bin/menu
    awk '/^cat > \/usr\/bin\/menu-service << '"'END'"'/{flag=1; next} /^END$/{if(flag){flag=0; next}} flag' /tmp/temp-install.sh > /usr/bin/menu-service
    awk '/^cat > \/usr\/bin\/menu-backup << '"'END'"'/{flag=1; next} /^END$/{if(flag){flag=0; next}} flag' /tmp/temp-install.sh > /usr/bin/menu-backup
    awk '/^cat > \/usr\/local\/bin\/ws-proxy << '"'END'"'/{flag=1; next} /^END$/{if(flag){flag=0; next}} flag' /tmp/temp-install.sh > /usr/local/bin/ws-proxy
    awk '/^cat > \/etc\/systemd\/system\/ws-proxy\.service << '"'END'"'/{flag=1; next} /^END$/{if(flag){flag=0; next}} flag' /tmp/temp-install.sh > /etc/systemd/system/ws-proxy.service
    awk '/^cat > \/usr\/local\/bin\/sync-stats << '"'END'"'/{flag=1; next} /^END$/{if(flag){flag=0; next}} flag' /tmp/temp-install.sh > /usr/local/bin/sync-stats
    chmod +x /usr/bin/menu /usr/bin/menu-service /usr/bin/menu-backup /usr/local/bin/ws-proxy /usr/local/bin/sync-stats 2>/dev/null
    systemctl daemon-reload 2>/dev/null
    systemctl restart ws-proxy 2>/dev/null
    (crontab -l 2>/dev/null | grep -v "/usr/local/bin/sync-stats"; echo "*/5 * * * * /usr/local/bin/sync-stats") | crontab -
    ln -sf /usr/bin/menu-backup /usr/bin/backup-vps 2>/dev/null
    ln -sf /usr/bin/menu-backup /usr/bin/restore-vps 2>/dev/null
    grep -qxF "alias backup='/usr/bin/backup-vps'" ~/.bashrc || echo "alias backup='/usr/bin/backup-vps'" >> ~/.bashrc
    grep -qxF "alias restore='/usr/bin/restore-vps'" ~/.bashrc || echo "alias restore='/usr/bin/restore-vps'" >> ~/.bashrc
    
    # Download modul xray setup, add akun, del akun, & list akun
    wget -qO /usr/local/bin/setup-xray https://raw.githubusercontent.com/premdigital/Scpremdigital-v1/main/setup-xray.sh
    wget -qO /usr/local/bin/add-vmess https://raw.githubusercontent.com/premdigital/Scpremdigital-v1/main/add-vmess.sh
    wget -qO /usr/local/bin/add-vless https://raw.githubusercontent.com/premdigital/Scpremdigital-v1/main/add-vless.sh
    wget -qO /usr/local/bin/add-trojan https://raw.githubusercontent.com/premdigital/Scpremdigital-v1/main/add-trojan.sh
    wget -qO /usr/local/bin/vps-bot https://raw.githubusercontent.com/premdigital/Scpremdigital-v1/main/vps-bot.py
    sed -i "s/-m -s \\/bin\\/false -M/-s \\/bin\\/false -M/g" /usr/local/bin/vps-bot
    chmod +x /usr/local/bin/vps-bot
    systemctl restart vps-bot 2>/dev/null
    wget -qO /usr/local/bin/del-account https://raw.githubusercontent.com/premdigital/Scpremdigital-v1/main/del-account.sh
    wget -qO /usr/local/bin/list-account https://raw.githubusercontent.com/premdigital/Scpremdigital-v1/main/list-account.sh
    chmod +x /usr/local/bin/setup-xray /usr/local/bin/add-vmess /usr/local/bin/add-vless /usr/local/bin/add-trojan /usr/local/bin/del-account /usr/local/bin/list-account
    
    # Update Telegram Bot Script (Preserve Token)
    if [ -f /usr/local/bin/vps-bot ]; then
        existing_token=$(grep -oP 'BOT_TOKEN\s*=\s*"\K[^"]+' /usr/local/bin/vps-bot 2>/dev/null || true)
        wget -qO /tmp/vps-bot.py https://raw.githubusercontent.com/premdigital/Scpremdigital-v1/main/vps-bot.py
        if [ -s /tmp/vps-bot.py ]; then
            sed -i "s/-m -s \\/bin\\/false -M/-s \\/bin\\/false -M/g" /tmp/vps-bot.py
            cp -f /tmp/vps-bot.py /usr/local/bin/vps-bot
            chmod +x /usr/local/bin/vps-bot
            if [ -n "$existing_token" ] && [ "$existing_token" != "ISI_TOKEN_BOT_DISINI" ]; then
                sed -i "s/BOT_TOKEN = \".*\"/BOT_TOKEN = \"$existing_token\"/g" /usr/local/bin/vps-bot
            fi
            systemctl restart vps-bot 2>/dev/null || true
        fi
        rm -f /tmp/vps-bot.py
    else
        wget -qO /usr/local/bin/vps-bot https://raw.githubusercontent.com/premdigital/Scpremdigital-v1/main/vps-bot.py
        sed -i "s/-m -s \/bin\/false -M/-s \/bin\/false -M/g" /usr/local/bin/vps-bot
        chmod +x /usr/local/bin/vps-bot
        systemctl restart vps-bot 2>/dev/null || true
    fi

    # Inisialisasi & Perbaiki Xray jika belum running atau belum ada
    if ! systemctl is-active --quiet xray 2>/dev/null || [ ! -f /usr/local/bin/xray ]; then
        echo -e "\e[33m[INFO] Menyiapkan & Memperbaiki Xray Core Engine di VPS...\e[0m"
        bash /usr/local/bin/setup-xray
    fi

    # Perbaiki jika ada entri dengan tanggal expired kosong di database xray-users.db
    if [ -f /etc/premdigital/xray-users.db ]; then
        default_exp=$(date -d "+30 days" +%Y-%m-%d 2>/dev/null || date +%Y-%m-%d)
        sed -i -E "s/ \|  \| / | ${default_exp} | /g" /etc/premdigital/xray-users.db 2>/dev/null
    fi

    # Update Banner PremDigital Blue Planet di /etc/issue.net
    cat > /etc/issue.net << 'BANNEREOF'
<br>
<center>
<font color="#0080ff">━━━━━━</font><font color="#00e5ff">ஐஇ⚙️இஐ</font><font color="#0080ff">━━━━━━</font><br>
<font color="#ffd700"><b>--- ★ PREMDIGITAL ★ ---</b></font><br>
<font color="#ff3333"><b>! TERM OF SERVICE !</b></font><br>
<font color="#00ffff"><b>NO SPAM</b></font><br>
<font color="#00ffff"><b>NO DDOS</b></font><br>
<font color="#00ffff"><b>NO HACKING AND CARDING</b></font><br>
<font color="#ff4444"><b>NO TORRENT!!</b></font><br>
<font color="#ff4444"><b>NO MULTI LOGIN!!</b></font><br>
<font color="#b388ff"><b>Order Premium :</b></font><br>
<font color="#64b5f6">Tele: https://t.me/PremdigitalTunnel_bot</font><br>
<font color="#58d68d">WA: https://wa.me/6283188458876</font><br>
<font color="#00ffff"><b>Web: https://www.premdigital.web.id</b></font><br>
<font color="#0080ff">━━━━━━</font><font color="#00e5ff">ஐஇ⚙️இஐ</font><font color="#0080ff">━━━━━━</font>
</center>
<br>
BANNEREOF
    cp -f /etc/issue.net /etc/issue 2>/dev/null || true
    systemctl restart dropbear 2>/dev/null || true
    systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null || true

    # Perbaiki & Aktifkan Stunnel SSL Service (Port 8443)
    echo -e "\e[33m[INFO] Memeriksa & Mengaktifkan Stunnel SSL...\e[0m"
    if ! command -v stunnel4 >/dev/null 2>&1 && ! command -v stunnel >/dev/null 2>&1; then
        apt-get update -y >/dev/null 2>&1
        apt-get install -y stunnel4 >/dev/null 2>&1
    fi
    STUNNEL_BIN=$(command -v stunnel4 || command -v stunnel || echo "/usr/bin/stunnel4")
    [ ! -f /usr/bin/stunnel4 ] && [ -f /usr/bin/stunnel ] && ln -sf /usr/bin/stunnel /usr/bin/stunnel4 2>/dev/null || true
    [ ! -f /usr/bin/stunnel ] && [ -f /usr/bin/stunnel4 ] && ln -sf /usr/bin/stunnel4 /usr/bin/stunnel 2>/dev/null || true

    mkdir -p /etc/stunnel
    if [ ! -s /etc/stunnel/stunnel.pem ]; then
        openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -sha256 \
        -subj "/C=ID/ST=DKI Jakarta/L=Jakarta/O=PremDigital/OU=PremDigital/CN=premdigital.com" \
        -out /etc/stunnel/stunnel.pem -keyout /etc/stunnel/stunnel.pem 2>/dev/null
        chmod 600 /etc/stunnel/stunnel.pem 2>/dev/null
        chown root:root /etc/stunnel/stunnel.pem 2>/dev/null
    fi

    cat > /etc/default/stunnel4 << 'END_STUNNEL_DEF'
ENABLED=1
FILES="/etc/stunnel/*.conf"
OPTIONS=""
END_STUNNEL_DEF

    cat > /etc/stunnel/stunnel.conf << 'END_STUNNEL_CONF'
cert = /etc/stunnel/stunnel.pem
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1
foreground = yes

[openssh-tls]
accept = 0.0.0.0:8443
connect = 127.0.0.1:109
END_STUNNEL_CONF

    cat > /etc/systemd/system/stunnel4.service << EOF
[Unit]
Description=SSL/TLS Stunnel Service
After=network.target dropbear.service

[Service]
Type=simple
User=root
ExecStartPre=-/bin/sh -c 'fuser -k 8443/tcp >/dev/null 2>&1 || true'
ExecStart=$STUNNEL_BIN /etc/stunnel/stunnel.conf
Restart=always
RestartSec=3
StartLimitIntervalSec=0
KillMode=mixed

[Install]
WantedBy=multi-user.target
EOF

    ln -sf /etc/systemd/system/stunnel4.service /etc/systemd/system/stunnel.service 2>/dev/null || true
    fuser -k 8443/tcp >/dev/null 2>&1 || true
    pkill -9 stunnel4 2>/dev/null || true
    pkill -9 stunnel 2>/dev/null || true
    systemctl daemon-reload
    systemctl unmask stunnel4 stunnel 2>/dev/null || true
    systemctl enable stunnel4 2>/dev/null || true
    systemctl restart stunnel4 2>/dev/null || systemctl restart stunnel 2>/dev/null || true

    # Pastikan Official Ookla Speedtest CLI terpasang
    if ! command -v speedtest >/dev/null 2>&1; then
        echo -e "\e[33m[INFO] Menyiapkan Official Ookla Speedtest CLI...\e[0m"
        ARCH=$(uname -m)
        case "$ARCH" in
            x86_64|amd64) ST_URL="https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-x86_64.tgz" ;;
            aarch64|arm64) ST_URL="https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-aarch64.tgz" ;;
            armhf|armv7l) ST_URL="https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-armhf.tgz" ;;
            i386|i686) ST_URL="https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-i386.tgz" ;;
            *) ST_URL="" ;;
        esac
        if [ -n "$ST_URL" ]; then
            curl -sLo /tmp/speedtest.tgz "$ST_URL" 2>/dev/null || wget -qO /tmp/speedtest.tgz "$ST_URL" 2>/dev/null
            if [ -s /tmp/speedtest.tgz ]; then
                tar -xzf /tmp/speedtest.tgz -C /usr/local/bin speedtest 2>/dev/null || tar -xzf /tmp/speedtest.tgz -C /usr/bin speedtest 2>/dev/null
                chmod +x /usr/local/bin/speedtest 2>/dev/null || chmod +x /usr/bin/speedtest 2>/dev/null
                rm -f /tmp/speedtest.tgz 2>/dev/null
            fi
        fi
    fi

    # Inisialisasi data Uptime & Masa Aktif VPS jika belum ada
    mkdir -p /etc/premdigital
    if [ ! -f /etc/premdigital/install_date.txt ]; then
        if [ -f /etc/vps-domain.txt ]; then
            stat -c %Y /etc/vps-domain.txt > /etc/premdigital/install_date.txt 2>/dev/null || date +%s > /etc/premdigital/install_date.txt
        elif [ -f /etc/systemd/system/ws-proxy.service ]; then
            stat -c %Y /etc/systemd/system/ws-proxy.service > /etc/premdigital/install_date.txt 2>/dev/null || date +%s > /etc/premdigital/install_date.txt
        else
            date +%s > /etc/premdigital/install_date.txt
        fi
    fi
    [ ! -f /etc/premdigital/vps_duration_days.txt ] && echo "30" > /etc/premdigital/vps_duration_days.txt

    rm -f /tmp/temp-install.sh
    echo -e "\e[32mMenu, Modul Xray, Banner, Stunnel SSL, Ookla Speedtest & Uptime berhasil diperbarui! Silakan ketik perintah: menu\e[0m"
    exit 0
fi

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

# Pasang Official Ookla Speedtest CLI
echo -e "\e[33m[INFO] Memasang Official Ookla Speedtest CLI...\e[0m"
ARCH=$(uname -m)
case "$ARCH" in
    x86_64|amd64) ST_URL="https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-x86_64.tgz" ;;
    aarch64|arm64) ST_URL="https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-aarch64.tgz" ;;
    armhf|armv7l) ST_URL="https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-armhf.tgz" ;;
    i386|i686) ST_URL="https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-i386.tgz" ;;
    *) ST_URL="" ;;
esac
if [ -n "$ST_URL" ]; then
    curl -sLo /tmp/speedtest.tgz "$ST_URL" 2>/dev/null || wget -qO /tmp/speedtest.tgz "$ST_URL" 2>/dev/null
    if [ -s /tmp/speedtest.tgz ]; then
        tar -xzf /tmp/speedtest.tgz -C /usr/local/bin speedtest 2>/dev/null || tar -xzf /tmp/speedtest.tgz -C /usr/bin speedtest 2>/dev/null
        chmod +x /usr/local/bin/speedtest 2>/dev/null || chmod +x /usr/bin/speedtest 2>/dev/null
        rm -f /tmp/speedtest.tgz 2>/dev/null
    fi
fi
if ! command -v speedtest >/dev/null 2>&1; then
    apt-get install -y speedtest-cli >/dev/null 2>&1 || true
fi

# Inisialisasi data Uptime & Masa Aktif VPS
mkdir -p /etc/premdigital
if [ ! -f /etc/premdigital/install_date.txt ]; then
    date +%s > /etc/premdigital/install_date.txt
fi
if [ ! -f /etc/premdigital/vps_duration_days.txt ]; then
    echo "30" > /etc/premdigital/vps_duration_days.txt
fi

# Matikan web server bawaan VPS & bebaskan port tunneling
echo -e "\e[33m[INFO] Membersihkan port dan service yang berbenturan...\e[0m"
systemctl stop apache2 2>/dev/null || true
systemctl disable apache2 2>/dev/null || true
systemctl stop nginx 2>/dev/null || true
systemctl disable nginx 2>/dev/null || true
killall -9 apache2 2>/dev/null || true
killall -9 nginx 2>/dev/null || true

fuser -k 443/tcp >/dev/null 2>&1 || true
fuser -k 80/tcp >/dev/null 2>&1 || true
fuser -k 700/tcp >/dev/null 2>&1 || true
fuser -k 109/tcp >/dev/null 2>&1 || true
fuser -k 143/tcp >/dev/null 2>&1 || true
fuser -k 4430/tcp >/dev/null 2>&1 || true
fuser -k 8443/tcp >/dev/null 2>&1 || true
fuser -k 8880/tcp >/dev/null 2>&1 || true
fuser -k 2082/tcp >/dev/null 2>&1 || true

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
<center>
<font color="#0080ff">━━━━━━</font><font color="#00e5ff">ஐஇ⚙️இஐ</font><font color="#0080ff">━━━━━━</font><br>
<font color="#ffd700"><b>--- ★ PREMDIGITAL ★ ---</b></font><br>
<font color="#ff3333"><b>! TERM OF SERVICE !</b></font><br>
<font color="#00ffff"><b>NO SPAM</b></font><br>
<font color="#00ffff"><b>NO DDOS</b></font><br>
<font color="#00ffff"><b>NO HACKING AND CARDING</b></font><br>
<font color="#ff4444"><b>NO TORRENT!!</b></font><br>
<font color="#ff4444"><b>NO MULTI LOGIN!!</b></font><br>
<font color="#b388ff"><b>Order Premium :</b></font><br>
<font color="#64b5f6">Tele: https://t.me/PremdigitalTunnel_bot</font><br>
<font color="#58d68d">WA: https://wa.me/6283188458876</font><br>
<font color="#00ffff"><b>Web: https://www.premdigital.web.id</b></font><br>
<font color="#0080ff">━━━━━━</font><font color="#00e5ff">ஐஇ⚙️இஐ</font><font color="#0080ff">━━━━━━</font>
</center>
<br>
END
cp -f /etc/issue.net /etc/issue 2>/dev/null || true
cat > /etc/motd << 'END_MOTD'
========================================
        ★ PREMDIGITAL TUNNELING ★        
========================================
Silahkan Ketik { menu }
END_MOTD

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
StartLimitIntervalSec=0

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
        # 2. Deteksi Request HTTP / WebSocket Upgrade (HTTP Custom Payload atau Xray)
        elif b'HTTP/' in data or b'Upgrade: websocket' in data or b'GET ' in data or b'POST ' in data or b'PATCH ' in data or b'HEAD ' in data:
            xray_port = None
            if b'/vmess' in data:
                xray_port = 10001
            elif b'/vless' in data:
                xray_port = 10002
            elif b'/trojan' in data:
                xray_port = 10003
            elif b'/upvmess' in data:
                xray_port = 10007
            elif b'/upvless' in data:
                xray_port = 10008
            elif b'/uptrojan' in data:
                xray_port = 10009

            if xray_port:
                target_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                set_optimized_sock(target_sock)
                target_sock.connect(('127.0.0.1', xray_port))
                target_sock.sendall(data)
                first_client_packet = False
            else:
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
StartLimitIntervalSec=0
KillMode=process

[Install]
WantedBy=multi-user.target
END

systemctl daemon-reload
systemctl enable ws-proxy
systemctl restart ws-proxy

# 7. Setting Stunnel (Port 8443)
echo -e "\e[33m[INFO] Setting Stunnel...\e[0m"
STUNNEL_BIN=$(command -v stunnel4 || command -v stunnel || echo "/usr/bin/stunnel4")
[ ! -f /usr/bin/stunnel4 ] && [ -f /usr/bin/stunnel ] && ln -sf /usr/bin/stunnel /usr/bin/stunnel4 2>/dev/null || true
[ ! -f /usr/bin/stunnel ] && [ -f /usr/bin/stunnel4 ] && ln -sf /usr/bin/stunnel4 /usr/bin/stunnel 2>/dev/null || true

mkdir -p /etc/stunnel
if [ ! -s /etc/stunnel/stunnel.pem ]; then
    openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -sha256 \
    -subj "/C=ID/ST=DKI Jakarta/L=Jakarta/O=PremDigital/OU=PremDigital/CN=premdigital.com" \
    -out /etc/stunnel/stunnel.pem -keyout /etc/stunnel/stunnel.pem 2>/dev/null
    chmod 600 /etc/stunnel/stunnel.pem 2>/dev/null
    chown root:root /etc/stunnel/stunnel.pem 2>/dev/null
fi

cat > /etc/default/stunnel4 << 'END'
ENABLED=1
FILES="/etc/stunnel/*.conf"
OPTIONS=""
END

cat > /etc/stunnel/stunnel.conf << 'END'
cert = /etc/stunnel/stunnel.pem
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1
foreground = yes

[openssh-tls]
accept = 0.0.0.0:8443
connect = 127.0.0.1:109
END

cat > /etc/systemd/system/stunnel4.service << EOF
[Unit]
Description=SSL/TLS Stunnel Service
After=network.target dropbear.service

[Service]
Type=simple
User=root
ExecStartPre=-/bin/sh -c 'fuser -k 8443/tcp >/dev/null 2>&1 || true'
ExecStart=$STUNNEL_BIN /etc/stunnel/stunnel.conf
Restart=always
RestartSec=3
StartLimitIntervalSec=0
KillMode=mixed

[Install]
WantedBy=multi-user.target
EOF

ln -sf /etc/systemd/system/stunnel4.service /etc/systemd/system/stunnel.service 2>/dev/null || true
fuser -k 8443/tcp >/dev/null 2>&1 || true
pkill -9 stunnel4 2>/dev/null || true
pkill -9 stunnel 2>/dev/null || true
systemctl daemon-reload
systemctl unmask stunnel4 stunnel 2>/dev/null || true
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
StartLimitIntervalSec=0

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
StartLimitIntervalSec=0

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
wget -qO /usr/local/bin/vps-bot "https://raw.githubusercontent.com/premdigital/Scpremdigital-v1/main/vps-bot.py"
sed -i "s/-m -s \/bin\/false -M/-s \/bin\/false -M/g" /usr/local/bin/vps-bot
chmod +x /usr/local/bin/vps-bot
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

# ==========================================
# CEK LISENSI IP (GITHUB)
# ==========================================
MYIP=$(curl -sS ipv4.icanhazip.com || curl -sS ifconfig.me)
IZIN_DATA=$(curl -sS https://raw.githubusercontent.com/premdigital/Scpremdigital-v1/main/ijin.txt | grep "^$MYIP" 2>/dev/null)
if [ -z "$IZIN_DATA" ]; then
    echo -e "${R}Akses Ditolak! IP VPS ($MYIP) tidak terdaftar.${NC}"
    exit 1
fi
CLIENT_NAME=$(echo "$IZIN_DATA" | awk '{print $2}')
EXP_DATE=$(echo "$IZIN_DATA" | awk '{print $3}')
d1=$(date -d "$EXP_DATE" +%s 2>/dev/null)
d2=$(date -d "today" +%s 2>/dev/null)
if [ -n "$d1" ] && [ -n "$d2" ]; then
    SISA_HARI=$(( (d1 - d2) / 86400 ))
    if [ "$SISA_HARI" -lt 0 ]; then
        echo -e "${R}Script Expired! Lisensi Anda sudah habis masa aktifnya.${NC}"
        exit 1
    fi
fi

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

check_api() {
    if ! systemctl is-active --quiet vps-api 2>/dev/null && ! pidof vps-api >/dev/null 2>&1; then
        echo -e "${R}STOPPED${NC}"
    elif grep -qE "API_SECRET\s*=\s*['\"]PREMDIGITAL_RAHASIA_123['\"]" /usr/local/bin/vps-api 2>/dev/null; then
        echo -e "${Y}WAITING CONFIG${NC}"
    else
        echo -e "${G}RUNNING${NC}"
    fi
}

check_bot() {
    if ! systemctl is-active --quiet vps-bot 2>/dev/null && ! pidof vps-bot >/dev/null 2>&1; then
        echo -e "${R}STOPPED${NC}"
    elif grep -qE "BOT_TOKEN\s*=\s*['\"]ISI_TOKEN_BOT_DISINI['\"]" /usr/local/bin/vps-bot 2>/dev/null; then
        echo -e "${Y}WAITING TOKEN${NC}"
    else
        echo -e "${G}RUNNING${NC}"
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
    if systemctl is-active --quiet stunnel4 2>/dev/null || systemctl is-active --quiet stunnel 2>/dev/null || pgrep -x stunnel4 >/dev/null 2>&1 || pgrep -x stunnel >/dev/null 2>&1 || pidof stunnel4 >/dev/null 2>&1 || pidof stunnel >/dev/null 2>&1; then
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

get_uptime_info() {
    local install_file="/etc/premdigital/install_date.txt"
    local duration_file="/etc/premdigital/vps_duration_days.txt"
    local now
    now=$(date +%s)

    if [ ! -f "$install_file" ]; then
        mkdir -p /etc/premdigital
        if [ -f /etc/vps-domain.txt ]; then
            stat -c %Y /etc/vps-domain.txt > "$install_file" 2>/dev/null || echo "$now" > "$install_file"
        elif [ -f /etc/systemd/system/ws-proxy.service ]; then
            stat -c %Y /etc/systemd/system/ws-proxy.service > "$install_file" 2>/dev/null || echo "$now" > "$install_file"
        else
            echo "$now" > "$install_file"
        fi
    fi

    local install_ts
    install_ts=$(cat "$install_file" 2>/dev/null | tr -d '\r\n')
    [[ "$install_ts" =~ ^[0-9]+$ ]] || install_ts=$now

    local total_days=30
    if [ -f "$duration_file" ]; then
        local custom_days
        custom_days=$(cat "$duration_file" 2>/dev/null | tr -d '\r\n')
        [[ "$custom_days" =~ ^[0-9]+$ ]] && [ "$custom_days" -gt 0 ] && total_days=$custom_days
    fi

    local elapsed_sec=$((now - install_ts))
    [ $elapsed_sec -lt 0 ] && elapsed_sec=0

    local elapsed_days=$((elapsed_sec / 86400))
    local elapsed_hours=$(((elapsed_sec % 86400) / 3600))
    local elapsed_minutes=$(((elapsed_sec % 3600) / 60))

    local elapsed_str=""
    if [ $elapsed_days -gt 0 ]; then
        elapsed_str="${elapsed_days} Hari, ${elapsed_hours} Jam"
    elif [ $elapsed_hours -gt 0 ]; then
        elapsed_str="${elapsed_hours} Jam, ${elapsed_minutes} Menit"
    else
        elapsed_str="${elapsed_minutes} Menit"
    fi

    echo -e "${elapsed_str}"
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
    SWAP_INFO=$(free -m | awk '/Swap/{if($2>0) printf "%sMB", $2; else print "0MB"}')
    UPTIME_INFO=$(get_uptime_info)

    clear
    echo -e "${C}======================================${NC}"
    echo -e "${C}✧==============${Y}ஐஇ⚙இஐ${C}==============✧${NC}"
    echo -e "          ${Y}PREMDIGITAL TUNNEL${NC}"
    echo -e "${C}✧==============${Y}ஐஇ⚙இஐ${C}==============✧${NC}"
    echo -e " OS         : $(cat /etc/os-release | grep -w PRETTY_NAME | cut -d= -f2 | tr -d '"')"
    echo -e " RAM        : $(free -m | awk 'NR==2{printf "%sMB / %sMB", $3,$2}')"
    echo -e " SWAP       : $SWAP_INFO"
    echo -e " Bandwidth  : $BW_INFO"
    echo -e " ISP        : $ISP"
    echo -e " Kota       : $CITY"
    echo -e " Domain     : ${Y}$DOMAIN${NC}"
    echo -e " IP VPS     : ${G}$IP${NC}"
    echo -e " UPTIME     : $UPTIME_INFO"
    echo -e "${C}======================================${NC}"
    echo -e "${C}┌──────────────────────────────────────┐${NC}"
    printf "${C}│${NC}  Version     : %-22s${C}│${NC}\n" "SPv25.8.31"
    printf "${C}│${NC}  Order By    : %-22s${C}│${NC}\n" "Premdigital"
    printf "${C}│${NC}  Client Name : %-22s${C}│${NC}\n" "$CLIENT_NAME"
    printf "${C}│${NC}  Expiry In   : %-22s${C}│${NC}\n" "$SISA_HARI Days"
    echo -e "${C}└──────────────────────────────────────┘${NC}"
    echo -e "${C}======================================${NC}"
    echo -e " [1] Buat Akun SSH"
    echo -e " [2] Buat Akun VMESS"
    echo -e " [3] Buat Akun VLESS"
    echo -e " [4] Buat Akun TROJAN"
    echo -e " [5] Hapus Akun (SSH / VMESS / VLESS / TROJAN)"
    echo -e " [6] List Akun (SSH / VMESS / VLESS / TROJAN)"
    echo -e " [7] Status Service & Port Tunneling"
    echo -e " [8] Cek Statistik Bandwidth VPS"
    echo -e " [9] Restart Semua Service"
    echo -e " [10] Cek / Kelola Auto-Kill Multi-Login"
    echo -e " [11] Service Menu API & Bot"
    echo -e " [12] Pengaturan Banner SSH"
    echo -e " [13] Backup & Restore Data VPS"
    echo -e " [0] Keluar"
    echo -e "${C}======================================${NC}"
    read -p " Pilih Opsi [0-13]: " opt
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
            while true; do
                read -p "Berapa Hari (Default 30): " masaaktif
                [ -z "$masaaktif" ] && masaaktif=30
                if [[ "$masaaktif" =~ ^[0-9]+$ ]] && [ "$masaaktif" -gt 0 ]; then
                    break
                else
                    echo -e "${R}Input salah! Masa aktif harus berupa angka (contoh: 30).${NC}"
                fi
            done
            
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
            if [ ! -f /usr/local/bin/add-vmess ]; then
                echo -e "\e[33m[INFO] Mengunduh modul Buat Akun VMESS...\e[0m"
                wget -qO /usr/local/bin/add-vmess https://raw.githubusercontent.com/premdigital/Scpremdigital-v1/main/add-vmess.sh
                chmod +x /usr/local/bin/add-vmess
            fi
            /usr/local/bin/add-vmess
            read -r -p "Tekan [Enter] untuk kembali ke menu..." dummy
            ;;
        3)
            clear
            if [ ! -f /usr/local/bin/add-vless ]; then
                echo -e "\e[33m[INFO] Mengunduh modul Buat Akun VLESS...\e[0m"
                wget -qO /usr/local/bin/add-vless https://raw.githubusercontent.com/premdigital/Scpremdigital-v1/main/add-vless.sh
                chmod +x /usr/local/bin/add-vless
            fi
            /usr/local/bin/add-vless
            read -r -p "Tekan [Enter] untuk kembali ke menu..." dummy
            ;;
        4)
            clear
            if [ ! -f /usr/local/bin/add-trojan ]; then
                echo -e "\e[33m[INFO] Mengunduh modul Buat Akun TROJAN...\e[0m"
                wget -qO /usr/local/bin/add-trojan https://raw.githubusercontent.com/premdigital/Scpremdigital-v1/main/add-trojan.sh
    wget -qO /usr/local/bin/vps-bot https://raw.githubusercontent.com/premdigital/Scpremdigital-v1/main/vps-bot.py
    sed -i "s/-m -s \\/bin\\/false -M/-s \\/bin\\/false -M/g" /usr/local/bin/vps-bot
    chmod +x /usr/local/bin/vps-bot
    systemctl restart vps-bot 2>/dev/null
                chmod +x /usr/local/bin/add-trojan
            fi
            /usr/local/bin/add-trojan
            read -r -p "Tekan [Enter] untuk kembali ke menu..." dummy
            ;;
        5)
            clear
            if [ ! -f /usr/local/bin/del-account ]; then
                echo -e "\e[33m[INFO] Mengunduh modul Hapus Akun...\e[0m"
                wget -qO /usr/local/bin/del-account https://raw.githubusercontent.com/premdigital/Scpremdigital-v1/main/del-account.sh
                chmod +x /usr/local/bin/del-account
            fi
            /usr/local/bin/del-account
            ;;
        6)
            clear
            if [ ! -f /usr/local/bin/list-account ]; then
                echo -e "\e[33m[INFO] Mengunduh modul List Akun...\e[0m"
                wget -qO /usr/local/bin/list-account https://raw.githubusercontent.com/premdigital/Scpremdigital-v1/main/list-account.sh
                chmod +x /usr/local/bin/list-account
            fi
            /usr/local/bin/list-account
            ;;
        7)
            clear
            echo -e "${C}======================================${NC}"
            echo -e "${Y}    STATUS SERVICE & PORT TUNNELING   ${NC}"
            echo -e "${C}======================================${NC}"
            echo -e " • WebSocket Proxy    : $(check_wsproxy)"
            echo -e " • Xray Core Engine   : $(check_service xray)"
            echo -e " • Stunnel SSL        : $(check_stunnel)"
            echo -e " • Dropbear SSH       : $(check_dropbear)"
            echo -e " • OpenSSH Server     : $(check_service ssh)"
            echo -e " • BadVPN UDPGW       : $(check_service badvpn-udpgw)"
            echo -e " • Squid Proxy        : $(check_service squid)"
            echo -e " • Web API Server     : $(check_api)"
            echo -e " • Telegram Bot       : $(check_bot)"
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
        8)
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
            echo -e " [3] Speedtest VPS (Ookla)"
            echo -e " [4] Atur Masa Aktif VPS (Default: 30 Hari)"
            echo -e " [0] Kembali ke Menu Utama"
            echo -e "${C}======================================${NC}"
            read -p " Pilih Opsi [0-4]: " opt_bw
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
                3)
                    clear
                    echo -e "${C}======================================${NC}"
                    echo -e "${Y}       SPEEDTEST VPS (OOKLA)          ${NC}"
                    echo -e "${C}======================================${NC}"
                    if ! command -v speedtest >/dev/null 2>&1; then
                        echo -e "${Y}[INFO] Mengunduh official binary Ookla Speedtest...${NC}"
                        ARCH=$(uname -m)
                        case "$ARCH" in
                            x86_64|amd64) ST_URL="https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-x86_64.tgz" ;;
                            aarch64|arm64) ST_URL="https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-aarch64.tgz" ;;
                            armhf|armv7l) ST_URL="https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-armhf.tgz" ;;
                            i386|i686) ST_URL="https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-i386.tgz" ;;
                            *) ST_URL="" ;;
                        esac
                        if [ -n "$ST_URL" ]; then
                            curl -sLo /tmp/speedtest.tgz "$ST_URL" 2>/dev/null || wget -qO /tmp/speedtest.tgz "$ST_URL" 2>/dev/null
                            if [ -s /tmp/speedtest.tgz ]; then
                                tar -xzf /tmp/speedtest.tgz -C /usr/local/bin speedtest 2>/dev/null || tar -xzf /tmp/speedtest.tgz -C /usr/bin speedtest 2>/dev/null
                                chmod +x /usr/local/bin/speedtest 2>/dev/null || chmod +x /usr/bin/speedtest 2>/dev/null
                                rm -f /tmp/speedtest.tgz 2>/dev/null
                            fi
                        fi
                    fi

                    if ! command -v speedtest >/dev/null 2>&1 && ! command -v speedtest-cli >/dev/null 2>&1; then
                        echo -e "${Y}[INFO] Memasang speedtest-cli via apt...${NC}"
                        apt-get update -y >/dev/null 2>&1
                        apt-get install -y speedtest-cli >/dev/null 2>&1
                    fi

                    echo -e "${G}Menjalankan uji kecepatan jaringan VPS via Ookla...${NC}"
                    echo -e "--------------------------------------"
                    if command -v speedtest >/dev/null 2>&1; then
                        speedtest --accept-license --accept-gdpr
                    elif command -v speedtest-cli >/dev/null 2>&1; then
                        speedtest-cli --share
                    else
                        echo -e "${R}Gagal menjalankan speedtest. Pastikan koneksi internet VPS stabil.${NC}"
                    fi
                    echo -e "${C}======================================${NC}"
                    echo ""
                    read -r -p "Tekan [Enter] untuk kembali ke menu..." dummy
                    ;;
                4)
                    clear
                    echo -e "${C}======================================${NC}"
                    echo -e "${Y}       ATUR MASA AKTIF VPS            ${NC}"
                    echo -e "${C}======================================${NC}"
                    cur_dur=30
                    [ -f /etc/premdigital/vps_duration_days.txt ] && cur_dur=$(cat /etc/premdigital/vps_duration_days.txt | tr -d '\r\n')
                    inst_date=""
                    if [ -f /etc/premdigital/install_date.txt ]; then
                        ts=$(cat /etc/premdigital/install_date.txt | tr -d '\r\n')
                        inst_date=$(date -d "@$ts" "+%d-%m-%Y %H:%M" 2>/dev/null || date "+%d-%m-%Y")
                    else
                        inst_date=$(date "+%d-%m-%Y")
                    fi
                    echo -e " Tanggal Install VPS : ${G}$inst_date${NC}"
                    echo -e " Masa Aktif Total    : ${Y}${cur_dur} Hari${NC}"
                    echo -e " Status Uptime Saat  : $(get_uptime_info)"
                    echo -e "--------------------------------------"
                    echo -e " [1] Ubah Total Masa Aktif (misal: 30, 60, 90, 365)"
                    echo -e " [2] Reset Tanggal Install ke Hari Ini"
                    echo -e " [0] Batal"
                    echo -e "${C}======================================${NC}"
                    read -p " Pilih Opsi [0-2]: " opt_dur
                    case $opt_dur in
                        1)
                            read -p " Masukkan Jumlah Hari Masa Aktif VPS: " new_days
                            if [[ "$new_days" =~ ^[0-9]+$ ]] && [ "$new_days" -gt 0 ]; then
                                mkdir -p /etc/premdigital
                                echo "$new_days" > /etc/premdigital/vps_duration_days.txt
                                echo -e "${G}Masa aktif VPS berhasil diubah menjadi $new_days Hari!${NC}"
                            else
                                echo -e "${R}Input tidak valid! Harus berupa angka positif.${NC}"
                            fi
                            sleep 1.5
                            ;;
                        2)
                            mkdir -p /etc/premdigital
                            date +%s > /etc/premdigital/install_date.txt
                            echo -e "${G}Tanggal install VPS berhasil di-reset ke hari ini!${NC}"
                            sleep 1.5
                            ;;
                        *)
                            ;;
                    esac
                    ;;
                *)
                    ;;
            esac
            ;;
        9)
            clear
            echo -e "${Y}Merestart semua service tunneling...${NC}"
            systemctl restart ws-proxy 2>/dev/null
            systemctl restart xray 2>/dev/null
            fuser -k 8443/tcp >/dev/null 2>&1 || true
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
        12)
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
<center>
<font color="#0080ff">━━━━━━</font><font color="#00e5ff">ஐஇ⚙️இஐ</font><font color="#0080ff">━━━━━━</font><br>
<font color="#ffd700"><b>--- ★ PREMDIGITAL ★ ---</b></font><br>
<font color="#ff3333"><b>! TERM OF SERVICE !</b></font><br>
<font color="#00ffff"><b>NO SPAM</b></font><br>
<font color="#00ffff"><b>NO DDOS</b></font><br>
<font color="#00ffff"><b>NO HACKING AND CARDING</b></font><br>
<font color="#ff4444"><b>NO TORRENT!!</b></font><br>
<font color="#ff4444"><b>NO MULTI LOGIN!!</b></font><br>
<font color="#b388ff"><b>Order Premium :</b></font><br>
<font color="#64b5f6">Tele: https://t.me/PremdigitalTunnel_bot</font><br>
<font color="#58d68d">WA: https://wa.me/6283188458876</font><br>
<font color="#00ffff"><b>Web: https://www.premdigital.web.id</b></font><br>
<font color="#0080ff">━━━━━━</font><font color="#00e5ff">ஐஇ⚙️இஐ</font><font color="#0080ff">━━━━━━</font>
</center>
<br>
BANNEREOF
                    cp -f /etc/issue.net /etc/issue 2>/dev/null || true
                    cat > /etc/motd << 'END_MOTD'
========================================
        ★ PREMDIGITAL TUNNELING ★        
========================================
Silahkan Ketik { menu }
END_MOTD
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
        13)
            menu-backup
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
    echo -e " [5] Ganti API Key Firebase Web Stats"
    echo -e " [0] Kembali ke Menu Utama"
    echo -e "${C}======================================${NC}"
    read -p " Pilih Opsi [0-5]: " opt
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
            curl -s -X POST http://127.0.0.1:5000/api/create \
                 -H "Content-Type: application/json" \
                 -d '{"secret": "'"$API_KEY"'", "username": "testapi", "password": "123", "expired": "1"}' | jq .
            echo ""
            echo -e "${G}Jika muncul JSON berformat di atas dengan tulisan 'success', berarti API BEKERJA NORMAL!${NC}"
            userdel -f testapi 2>/dev/null
            echo ""
            read -r -p "Tekan [Enter] untuk kembali ke menu service..." dummy
            ;;
        5)
            clear
            echo -e "${Y}=== Ganti API Key Firebase Web Stats ===${NC}"
            read -p "Masukkan API Key Firebase Baru: " fb_key
            if [ -n "$fb_key" ]; then
                mkdir -p /etc/premdigital
                echo "$fb_key" > /etc/premdigital/firebase_key.txt
                echo -e "\n${G}API Key Firebase berhasil disimpan!${NC}"
                echo -e "Mencoba sinkronisasi sekarang..."
                /usr/local/bin/sync-stats
            else
                echo -e "${R}API Key tidak boleh kosong!${NC}"
            fi
            sleep 2
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

# 13.1 CLI Menu Backup & Restore
cat > /usr/bin/menu-backup << 'END'
#!/bin/bash
Y="\e[33m"
C="\e[36m"
R="\e[31m"
G="\e[32m"
NC="\e[0m"

BACKUP_DIR="/root/backup"
mkdir -p "$BACKUP_DIR"

do_backup() {
    clear
    echo -e "${C}======================================${NC}"
    echo -e "${Y}        PROSES BACKUP DATA VPS        ${NC}"
    echo -e "${C}======================================${NC}"
    echo -e "${Y}Mengumpulkan data konfigurasi, akun & database...${NC}"
    
    local IP
    IP=$(curl -sS -m 3 ipv4.icanhazip.com 2>/dev/null || curl -sS -m 3 ipinfo.io/ip 2>/dev/null || echo "127.0.0.1")
    local IP_CLEAN
    IP_CLEAN=$(echo "$IP" | tr '.' '-')
    local NOW
    NOW=$(date +'%Y-%m-%d-%H%M%S')
    local TEMP="/root/backup/tmp_bck_$$"
    mkdir -p "$TEMP"

    # 1. Konfigurasi Xray & Sertifikat
    if [ -d /etc/xray ]; then
        mkdir -p "$TEMP/xray"
        cp -rf /etc/xray/* "$TEMP/xray/" 2>/dev/null
    fi

    # 2. Domain & Banner
    [ -f /etc/vps-domain.txt ] && cp -f /etc/vps-domain.txt "$TEMP/"
    [ -f /etc/issue.net ] && cp -f /etc/issue.net "$TEMP/"
    [ -f /etc/issue ] && cp -f /etc/issue "$TEMP/"

    # 3. Stunnel & PremDigital Configs
    if [ -d /etc/stunnel ]; then
        mkdir -p "$TEMP/stunnel"
        cp -rf /etc/stunnel/* "$TEMP/stunnel/" 2>/dev/null
    fi
    if [ -d /etc/premdigital ]; then
        mkdir -p "$TEMP/premdigital"
        cp -rf /etc/premdigital/* "$TEMP/premdigital/" 2>/dev/null
    fi

    # 4. User Accounts (SSH & Dropbear)
    awk -F: '($3>=1000)&&($1!="nobody"){print $1}' /etc/passwd > "$TEMP/vpn_users.list"
    awk -F: '($3>=1000)&&($1!="nobody"){print $0}' /etc/passwd > "$TEMP/passwd.bak"
    touch "$TEMP/shadow.bak" "$TEMP/group.bak" "$TEMP/user_exp.txt"
    while IFS= read -r u; do
        [ -z "$u" ] && continue
        grep "^$u:" /etc/shadow >> "$TEMP/shadow.bak" 2>/dev/null
        grep "^$u:" /etc/group >> "$TEMP/group.bak" 2>/dev/null
        exp=$(chage -l "$u" 2>/dev/null | grep "Account expires" | awk -F": " '{print $2}')
        echo "$u:$exp" >> "$TEMP/user_exp.txt"
    done < "$TEMP/vpn_users.list"

    # 5. API Secret & Telegram Bot Token
    [ -f /usr/local/bin/vps-api ] && grep "^API_SECRET =" /usr/local/bin/vps-api > "$TEMP/api_secret.txt" 2>/dev/null
    [ -f /usr/local/bin/vps-bot ] && grep "^BOT_TOKEN =" /usr/local/bin/vps-bot > "$TEMP/bot_token.txt" 2>/dev/null

    # 6. Crontab
    [ -f /var/spool/cron/crontabs/root ] && cp -f /var/spool/cron/crontabs/root "$TEMP/cron_root" 2>/dev/null

    local BFILE="$BACKUP_DIR/backup-${IP_CLEAN}-${NOW}.tar.gz"
    tar -czf "$BFILE" -C "$TEMP" .
    rm -rf "$TEMP"

    if [ ! -f "$BFILE" ]; then
        echo -e "${R}Gagal membuat file backup!${NC}"
        sleep 2
        return
    fi

    local FSIZE
    FSIZE=$(du -h "$BFILE" 2>/dev/null | awk '{print $1}')

    echo ""
    echo -e "${G}======================================${NC}"
    echo -e "${G}         BACKUP BERHASIL DIBUAT       ${NC}"
    echo -e "${G}======================================${NC}"
    echo -e " Lokasi File : ${Y}$BFILE${NC}"
    echo -e " Ukuran File : ${G}$FSIZE${NC}"
    echo -e " Waktu Dibuat: $(date '+%d-%m-%Y %H:%M:%S')"
    echo -e " Domain VPS  : $(cat /etc/vps-domain.txt 2>/dev/null || echo "$IP")"
    echo -e "--------------------------------------"
    
    read -p " Ingin upload & buat link download online? [y/N]: " up_opt
    if [[ "$up_opt" =~ ^[yY]$ ]]; then
        echo -e "${Y}Mengupload ke cloud temporary hosting...${NC}"
        local dlink=""
        dlink=$(curl -s -F "file=@$BFILE" https://file.io 2>/dev/null | grep -oP '"link":\s*"\K[^"]+' || true)
        if [ -z "$dlink" ]; then
            dlink=$(curl -s -F "file=@$BFILE" https://0x0.st 2>/dev/null || true)
        fi
        if [ -n "$dlink" ]; then
            echo ""
            echo -e "${G}Link Download Backup Online:${NC}"
            echo -e "${Y}$dlink${NC}"
            echo -e "${C}Simpan link ini untuk restore di VPS lain.${NC}"
        else
            echo -e "${R}Gagal upload online. File tetap tersimpan di $BFILE${NC}"
        fi
    fi
    echo -e "${C}======================================${NC}"
    echo ""
    read -r -p "Tekan [Enter] untuk kembali ke menu..." dummy
}

do_restore_core() {
    local target_archive="$1"
    if [ ! -f "$target_archive" ]; then
        echo -e "${R}File arsip backup tidak ditemukan!${NC}"
        sleep 2
        return 1
    fi

    if ! tar -tzf "$target_archive" >/dev/null 2>&1; then
        echo -e "${R}File arsip backup rusak atau format tidak valid (.tar.gz)!${NC}"
        sleep 2
        return 1
    fi

    local RTMP="/root/backup/tmp_restore_$$"
    mkdir -p "$RTMP"
    tar -xzf "$target_archive" -C "$RTMP" 2>/dev/null

    echo -e "${Y}[1/5] Memulihkan konfigurasi Xray & Sertifikat...${NC}"
    if [ -d "$RTMP/xray" ]; then
        mkdir -p /etc/xray
        cp -rf "$RTMP/xray"/* /etc/xray/ 2>/dev/null
    fi

    echo -e "${Y}[2/5] Memulihkan data Domain, Banner & Database...${NC}"
    [ -f "$RTMP/vps-domain.txt" ] && cp -f "$RTMP/vps-domain.txt" /etc/vps-domain.txt
    if [ -f "$RTMP/issue.net" ]; then
        cp -f "$RTMP/issue.net" /etc/issue.net
        cp -f "$RTMP/issue.net" /etc/issue 2>/dev/null
    fi
    [ -d "$RTMP/stunnel" ] && cp -rf "$RTMP/stunnel"/* /etc/stunnel/ 2>/dev/null
    [ -d "$RTMP/premdigital" ] && cp -rf "$RTMP/premdigital"/* /etc/premdigital/ 2>/dev/null

    echo -e "${Y}[3/5] Memulihkan akun SSH, Dropbear & masa aktif...${NC}"
    local count_ssh=0
    if [ -f "$RTMP/vpn_users.list" ] && [ -f "$RTMP/passwd.bak" ]; then
        while IFS= read -r u; do
            [ -z "$u" ] && continue
            count_ssh=$((count_ssh + 1))
            if id "$u" &>/dev/null; then
                sh_line=$(grep "^$u:" "$RTMP/shadow.bak" 2>/dev/null)
                [ -n "$sh_line" ] && sed -i "s|^$u:.*|$sh_line|" /etc/shadow 2>/dev/null
            else
                grep "^$u:" "$RTMP/passwd.bak" >> /etc/passwd 2>/dev/null
                grep "^$u:" "$RTMP/shadow.bak" >> /etc/shadow 2>/dev/null
                grep "^$u:" "$RTMP/group.bak" >> /etc/group 2>/dev/null
                mkdir -p "/home/$u" 2>/dev/null
                chown -R "$u:$u" "/home/$u" 2>/dev/null
            fi
            if [ -f "$RTMP/user_exp.txt" ]; then
                uexp=$(grep "^$u:" "$RTMP/user_exp.txt" | cut -d: -f2)
                if [ -n "$uexp" ] && [ "$uexp" != "never" ]; then
                    chage -E "$uexp" "$u" 2>/dev/null
                fi
            fi
        done < "$RTMP/vpn_users.list"
    fi

    echo -e "${Y}[4/5] Memulihkan kredensial API & Bot Telegram...${NC}"
    if [ -f "$RTMP/api_secret.txt" ] && [ -f /usr/local/bin/vps-api ]; then
        sec=$(grep -oP 'API_SECRET = "\K[^"]+' "$RTMP/api_secret.txt")
        [ -n "$sec" ] && sed -i "s/API_SECRET = \".*\"/API_SECRET = \"$sec\"/g" /usr/local/bin/vps-api
    fi
    if [ -f "$RTMP/bot_token.txt" ] && [ -f /usr/local/bin/vps-bot ]; then
        tok=$(grep -oP 'BOT_TOKEN = "\K[^"]+' "$RTMP/bot_token.txt")
        [ -n "$tok" ] && sed -i "s/BOT_TOKEN = \".*\"/BOT_TOKEN = \"$tok\"/g" /usr/local/bin/vps-bot
    fi
    [ -f "$RTMP/cron_root" ] && crontab "$RTMP/cron_root" 2>/dev/null

    rm -rf "$RTMP"

    echo -e "${Y}[5/5] Merestart seluruh service tunneling...${NC}"
    systemctl restart ws-proxy 2>/dev/null
    systemctl restart xray 2>/dev/null
    fuser -k 8443/tcp >/dev/null 2>&1 || true
    systemctl restart stunnel4 2>/dev/null || systemctl restart stunnel 2>/dev/null
    systemctl restart dropbear 2>/dev/null
    systemctl restart badvpn-udpgw 2>/dev/null
    systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null
    systemctl restart squid 2>/dev/null
    systemctl restart vps-api 2>/dev/null
    systemctl restart vps-bot 2>/dev/null

    echo ""
    echo -e "${G}======================================${NC}"
    echo -e "${G}       RESTORE DATA BERHASIL!         ${NC}"
    echo -e "${G}======================================${NC}"
    echo -e " Akun SSH Dipulihkan : ${Y}$count_ssh Akun${NC}"
    echo -e " Status Service Xray : ${G}$(systemctl is-active xray 2>/dev/null || echo 'OK')${NC}"
    echo -e " Domain VPS          : ${Y}$(cat /etc/vps-domain.txt 2>/dev/null || echo '-')${NC}"
    echo -e "${G}======================================${NC}"
    echo ""
    read -r -p "Tekan [Enter] untuk kembali ke menu..." dummy
}

do_restore_local() {
    clear
    echo -e "${C}======================================${NC}"
    echo -e "${Y}     RESTORE DARI FILE LOKAL VPS      ${NC}"
    echo -e "${C}======================================${NC}"
    
    local files=($(ls -1t "$BACKUP_DIR"/backup-*.tar.gz 2>/dev/null))
    if [ ${#files[@]} -eq 0 ]; then
        echo -e "${R}Tidak ada file backup ditemukan di $BACKUP_DIR${NC}"
        echo ""
        read -r -p "Tekan [Enter] untuk kembali..." dummy
        return
    fi

    echo -e "Pilih file backup yang ingin dipulihkan:"
    local i=1
    for f in "${files[@]}"; do
        local fname
        fname=$(basename "$f")
        local fsz
        fsz=$(du -h "$f" 2>/dev/null | awk '{print $1}')
        local fdate
        fdate=$(date -r "$f" '+%d-%m-%Y %H:%M' 2>/dev/null)
        echo -e " [$i] $fname (${G}$fsz${NC} - $fdate)"
        i=$((i + 1))
    done
    echo -e " [0] Batal"
    echo -e "${C}======================================${NC}"
    read -p " Pilih Nomor File [0-$((i - 1))]: " sel
    if [[ "$sel" =~ ^[0-9]+$ ]] && [ "$sel" -ge 1 ] && [ "$sel" -lt "$i" ]; then
        local chosen="${files[$((sel - 1))]}"
        echo -e "\n${Y}Memulihkan dari file: $(basename "$chosen")...${NC}"
        do_restore_core "$chosen"
    else
        echo -e "${Y}Dibatalkan.${NC}"
        sleep 1
    fi
}

do_restore_url() {
    clear
    echo -e "${C}======================================${NC}"
    echo -e "${Y}      RESTORE DARI LINK / URL ONLINE  ${NC}"
    echo -e "${C}======================================${NC}"
    echo -e "Masukkan link unduh file backup (.tar.gz):"
    echo -e "(Contoh: https://file.io/xyz atau direct raw link)"
    echo -e "--------------------------------------"
    read -p " Link URL: " r_url
    if [ -z "$r_url" ]; then
        echo -e "${R}Link tidak boleh kosong!${NC}"
        sleep 1.5
        return
    fi

    echo -e "${Y}Mengunduh arsip backup dari URL...${NC}"
    local dest="$BACKUP_DIR/downloaded_restore_$$.tar.gz"
    curl -sL "$r_url" -o "$dest" 2>/dev/null || wget -qO "$dest" "$r_url" 2>/dev/null

    if [ ! -s "$dest" ]; then
        echo -e "${R}Gagal mengunduh file dari link tersebut atau file kosong!${NC}"
        rm -f "$dest" 2>/dev/null
        sleep 2
        return
    fi

    do_restore_core "$dest"
    rm -f "$dest" 2>/dev/null
}

do_send_telegram() {
    clear
    echo -e "${C}======================================${NC}"
    echo -e "${Y}     KIRIM FILE BACKUP KE TELEGRAM    ${NC}"
    echo -e "${C}======================================${NC}"

    local bot_token=""
    if [ -f /usr/local/bin/vps-bot ]; then
        bot_token=$(grep "^BOT_TOKEN =" /usr/local/bin/vps-bot | cut -d '"' -f 2)
    fi
    if [ -z "$bot_token" ] || [ "$bot_token" == "ISI_TOKEN_BOT_DISINI" ]; then
        read -p " Masukkan Bot Token Telegram: " bot_token
    fi

    if [ -z "$bot_token" ] || [ "$bot_token" == "ISI_TOKEN_BOT_DISINI" ]; then
        echo -e "${R}Bot token tidak valid!${NC}"
        sleep 1.5
        return
    fi

    local chat_id=""
    [ -f /etc/premdigital/telegram_chat_id.txt ] && chat_id=$(cat /etc/premdigital/telegram_chat_id.txt | tr -d '\r\n')
    if [ -z "$chat_id" ]; then
        read -p " Masukkan Telegram Chat ID Anda: " chat_id
        if [ -n "$chat_id" ]; then
            mkdir -p /etc/premdigital
            echo "$chat_id" > /etc/premdigital/telegram_chat_id.txt
        fi
    else
        echo -e " Chat ID tersimpan: ${G}$chat_id${NC}"
        read -p " Gunakan Chat ID ini? [Y/n]: " use_cid
        if [[ "$use_cid" =~ ^[nN]$ ]]; then
            read -p " Masukkan Chat ID Baru: " chat_id
            echo "$chat_id" > /etc/premdigital/telegram_chat_id.txt
        fi
    fi

    if [ -z "$chat_id" ]; then
        echo -e "${R}Chat ID tidak boleh kosong!${NC}"
        sleep 1.5
        return
    fi

    local latest_file
    latest_file=$(ls -1t "$BACKUP_DIR"/backup-*.tar.gz 2>/dev/null | head -n 1)
    if [ -z "$latest_file" ] || [ ! -f "$latest_file" ]; then
        echo -e "${Y}Belum ada file backup, membuat backup baru sekarang...${NC}"
        local IP
        IP=$(curl -sS -m 3 ipv4.icanhazip.com 2>/dev/null || echo "127.0.0.1")
        local IP_CLEAN
        IP_CLEAN=$(echo "$IP" | tr '.' '-')
        local NOW
        NOW=$(date +'%Y-%m-%d-%H%M%S')
        local TEMP="/root/backup/tmp_bck_$$"
        mkdir -p "$TEMP"
        [ -d /etc/xray ] && cp -rf /etc/xray "$TEMP/" 2>/dev/null
        [ -f /etc/vps-domain.txt ] && cp -f /etc/vps-domain.txt "$TEMP/"
        [ -f /etc/issue.net ] && cp -f /etc/issue.net "$TEMP/"
        [ -d /etc/stunnel ] && cp -rf /etc/stunnel "$TEMP/" 2>/dev/null
        [ -d /etc/premdigital ] && cp -rf /etc/premdigital "$TEMP/" 2>/dev/null
        awk -F: '($3>=1000)&&($1!="nobody"){print $1}' /etc/passwd > "$TEMP/vpn_users.list"
        awk -F: '($3>=1000)&&($1!="nobody"){print $0}' /etc/passwd > "$TEMP/passwd.bak"
        while IFS= read -r u; do
            [ -n "$u" ] && grep "^$u:" /etc/shadow >> "$TEMP/shadow.bak" 2>/dev/null
            [ -n "$u" ] && grep "^$u:" /etc/group >> "$TEMP/group.bak" 2>/dev/null
        done < "$TEMP/vpn_users.list"
        latest_file="$BACKUP_DIR/backup-${IP_CLEAN}-${NOW}.tar.gz"
        tar -czf "$latest_file" -C "$TEMP" .
        rm -rf "$TEMP"
    fi

    echo -e "${Y}Mengirim $(basename "$latest_file") ke Telegram...${NC}"
    local caption="Backup VPS $(cat /etc/vps-domain.txt 2>/dev/null || echo 'PremDigital') - $(date '+%d-%m-%Y %H:%M:%S')"
    local res
    res=$(curl -s -F chat_id="$chat_id" -F document=@"$latest_file" -F caption="$caption" "https://api.telegram.org/bot${bot_token}/sendDocument")

    if echo "$res" | grep -q '"ok":true'; then
        echo -e "${G}SUKSES! File backup berhasil terkirim langsung ke Telegram Anda!${NC}"
    else
        echo -e "${R}Gagal mengirim file ke Telegram!${NC}"
        echo -e "Detail response: $res"
    fi
    echo ""
    read -r -p "Tekan [Enter] untuk kembali..." dummy
}

do_manage_backups() {
    clear
    echo -e "${C}======================================${NC}"
    echo -e "${Y}     DAFTAR FILE BACKUP DI VPS        ${NC}"
    echo -e "${C}======================================${NC}"
    local files=($(ls -1t "$BACKUP_DIR"/backup-*.tar.gz 2>/dev/null))
    if [ ${#files[@]} -eq 0 ]; then
        echo -e "Tidak ada file backup tersimpan di $BACKUP_DIR"
        echo ""
        read -r -p "Tekan [Enter] untuk kembali..." dummy
        return
    fi

    local i=1
    for f in "${files[@]}"; do
        local fname
        fname=$(basename "$f")
        local fsz
        fsz=$(du -h "$f" 2>/dev/null | awk '{print $1}')
        local fdate
        fdate=$(date -r "$f" '+%d-%m-%Y %H:%M:%S' 2>/dev/null)
        echo -e " [$i] $fname (${G}$fsz${NC} | $fdate)"
        i=$((i + 1))
    done
    echo -e "--------------------------------------"
    echo -e " [D] Hapus Satu File Tertentu"
    echo -e " [C] Bersihkan / Hapus SEMUA Backup Lama"
    echo -e " [0] Kembali"
    echo -e "${C}======================================${NC}"
    read -p " Pilihan: " m_opt
    case "$m_opt" in
        [dD])
            read -p " Masukkan nomor file yang ingin dihapus [1-$((i - 1))]: " del_num
            if [[ "$del_num" =~ ^[0-9]+$ ]] && [ "$del_num" -ge 1 ] && [ "$del_num" -lt "$i" ]; then
                rm -f "${files[$((del_num - 1))]}"
                echo -e "${G}File backup berhasil dihapus!${NC}"
                sleep 1.5
            fi
            ;;
        [cC])
            read -p " Yakin ingin menghapus SEMUA file backup lokal? [y/N]: " cf
            if [[ "$cf" =~ ^[yY]$ ]]; then
                rm -f "$BACKUP_DIR"/backup-*.tar.gz 2>/dev/null
                echo -e "${G}Semua file backup telah dihapus!${NC}"
                sleep 1.5
            fi
            ;;
        *)
            ;;
    esac
}

do_auto_backup_cron() {
    clear
    echo -e "${C}======================================${NC}"
    echo -e "${Y}      AUTO-BACKUP OTOMATIS (CRON)     ${NC}"
    echo -e "${C}======================================${NC}"
    local is_active="NONAKTIF"
    crontab -l 2>/dev/null | grep -q "menu-backup --cron" && is_active="${G}AKTIF (Setiap 00:00 Tengah Malam)${NC}"

    echo -e "Status Auto-Backup  : $is_active"
    echo -e "Jadwal Eksekusi     : Setiap Hari Pukul 00:00 WIB/UTC"
    echo -e "Pembersihan Otomatis: Menyimpan 7 hari terakhir (rotasi)"
    echo -e "--------------------------------------"
    echo -e " [1] Aktifkan Auto-Backup Harian"
    echo -e " [2] Nonaktifkan Auto-Backup Harian"
    echo -e " [0] Kembali"
    echo -e "${C}======================================${NC}"
    read -p " Pilih Opsi [0-2]: " a_opt
    case $a_opt in
        1)
            (crontab -l 2>/dev/null | grep -v "menu-backup --cron"; echo "0 0 * * * /usr/bin/menu-backup --cron >/dev/null 2>&1") | crontab -
            echo -e "${G}Auto-Backup harian berhasil diaktifkan!${NC}"
            sleep 1.5
            ;;
        2)
            (crontab -l 2>/dev/null | grep -v "menu-backup --cron") | crontab -
            echo -e "${G}Auto-Backup harian berhasil dinonaktifkan!${NC}"
            sleep 1.5
            ;;
        *)
            ;;
    esac
}

# Standalone execution checks
if [[ "$(basename "$0")" == "backup-vps" ]] || [[ "$1" == "--backup" ]]; then
    do_backup
    exit 0
fi

if [[ "$(basename "$0")" == "restore-vps" ]] || [[ "$1" == "--restore" ]]; then
    do_restore_local
    exit 0
fi

if [[ "$1" == "--cron" ]]; then
    IP=$(curl -sS -m 3 ipv4.icanhazip.com 2>/dev/null || echo "127.0.0.1")
    IP_CLEAN=$(echo "$IP" | tr '.' '-')
    NOW=$(date +'%Y-%m-%d-%H%M%S')
    TEMP="/root/backup/tmp_bck_cron_$$"
    mkdir -p "$TEMP"
    [ -d /etc/xray ] && cp -rf /etc/xray "$TEMP/" 2>/dev/null
    [ -f /etc/vps-domain.txt ] && cp -f /etc/vps-domain.txt "$TEMP/"
    [ -f /etc/issue.net ] && cp -f /etc/issue.net "$TEMP/"
    [ -d /etc/stunnel ] && cp -rf /etc/stunnel "$TEMP/" 2>/dev/null
    [ -d /etc/premdigital ] && cp -rf /etc/premdigital "$TEMP/" 2>/dev/null
    awk -F: '($3>=1000)&&($1!="nobody"){print $1}' /etc/passwd > "$TEMP/vpn_users.list"
    awk -F: '($3>=1000)&&($1!="nobody"){print $0}' /etc/passwd > "$TEMP/passwd.bak"
    while IFS= read -r u; do
        [ -n "$u" ] && grep "^$u:" /etc/shadow >> "$TEMP/shadow.bak" 2>/dev/null
        [ -n "$u" ] && grep "^$u:" /etc/group >> "$TEMP/group.bak" 2>/dev/null
    done < "$TEMP/vpn_users.list"
    BFILE="$BACKUP_DIR/backup-${IP_CLEAN}-${NOW}.tar.gz"
    tar -czf "$BFILE" -C "$TEMP" .
    rm -rf "$TEMP"

    if [ -f /etc/premdigital/telegram_chat_id.txt ] && [ -f /usr/local/bin/vps-bot ]; then
        cid=$(cat /etc/premdigital/telegram_chat_id.txt | tr -d '\r\n')
        tok=$(grep "^BOT_TOKEN =" /usr/local/bin/vps-bot | cut -d '"' -f 2)
        if [ -n "$cid" ] && [ -n "$tok" ] && [ "$tok" != "ISI_TOKEN_BOT_DISINI" ]; then
            curl -s -F chat_id="$cid" -F document=@"$BFILE" -F caption="Auto-Backup VPS $(cat /etc/vps-domain.txt 2>/dev/null || echo $IP) - $(date '+%d-%m-%Y %H:%M')" "https://api.telegram.org/bot${tok}/sendDocument" >/dev/null 2>&1
        fi
    fi

    find "$BACKUP_DIR" -name "backup-*.tar.gz" -mtime +7 -delete 2>/dev/null
    exit 0
fi

while true; do
    clear
    echo -e "${C}======================================${NC}"
    echo -e "${Y}      BACKUP & RESTORE DATA VPS       ${NC}"
    echo -e "${C}======================================${NC}"
    echo -e " [1] Backup Data VPS Sekarang"
    echo -e " [2] Restore Data dari File Lokal VPS"
    echo -e " [3] Restore Data dari Link / URL Online"
    echo -e " [4] Kirim File Backup ke Bot Telegram"
    echo -e " [5] Lihat / Hapus File Backup Lokal"
    echo -e " [6] Set Auto-Backup Otomatis (Cron Harian)"
    echo -e " [0] Kembali ke Menu Utama"
    echo -e "${C}======================================${NC}"
    read -p " Pilih Opsi [0-6]: " opt_bck
    case $opt_bck in
        1) do_backup ;;
        2) do_restore_local ;;
        3) do_restore_url ;;
        4) do_send_telegram ;;
        5) do_manage_backups ;;
        6) do_auto_backup_cron ;;
        0) break ;;
        *) ;;
    esac
done
END
chmod +x /usr/bin/menu-backup
ln -sf /usr/bin/menu-backup /usr/bin/backup-vps
ln -sf /usr/bin/menu-backup /usr/bin/restore-vps

# Helper Scripts: VMESS, VLESS, TROJAN, Hapus Akun, List Akun & Xray Setup
wget -qO /usr/local/bin/setup-xray https://raw.githubusercontent.com/premdigital/Scpremdigital-v1/main/setup-xray.sh
wget -qO /usr/local/bin/add-vmess https://raw.githubusercontent.com/premdigital/Scpremdigital-v1/main/add-vmess.sh
wget -qO /usr/local/bin/add-vless https://raw.githubusercontent.com/premdigital/Scpremdigital-v1/main/add-vless.sh
wget -qO /usr/local/bin/add-trojan https://raw.githubusercontent.com/premdigital/Scpremdigital-v1/main/add-trojan.sh
    wget -qO /usr/local/bin/vps-bot https://raw.githubusercontent.com/premdigital/Scpremdigital-v1/main/vps-bot.py
    sed -i "s/-m -s \\/bin\\/false -M/-s \\/bin\\/false -M/g" /usr/local/bin/vps-bot
    chmod +x /usr/local/bin/vps-bot
    systemctl restart vps-bot 2>/dev/null
wget -qO /usr/local/bin/del-account https://raw.githubusercontent.com/premdigital/Scpremdigital-v1/main/del-account.sh
wget -qO /usr/local/bin/list-account https://raw.githubusercontent.com/premdigital/Scpremdigital-v1/main/list-account.sh
chmod +x /usr/local/bin/setup-xray /usr/local/bin/add-vmess /usr/local/bin/add-vless /usr/local/bin/add-trojan /usr/local/bin/del-account /usr/local/bin/list-account
bash /usr/local/bin/setup-xray

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

# Auto-delete Expired Xray Users
if [ -f /etc/premdigital/xray-users.db ] && [ -f /etc/xray/config.json ]; then
    while IFS=" | " read -r xuser xuuid xexp xproto; do
        if [[ -n "$xuser" && -n "$xexp" && "$xexp" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ && "$xexp" < "$hariini" ]]; then
            python3 - <<EOF
import json
try:
    with open("/etc/xray/config.json", "r") as f:
        data = json.load(f)
    for ib in data.get("inbounds", []):
        clients = ib.get("settings", {}).get("clients", [])
        ib["settings"]["clients"] = [c for c in clients if c.get("email") != "$xuser"]
    with open("/etc/xray/config.json", "w") as f:
        json.dump(data, f, indent=2)
except:
    pass
EOF
            sed -i "/^$xuser |/d" /etc/premdigital/xray-users.db 2>/dev/null
            systemctl restart xray >/dev/null 2>&1
            echo "Akun Xray $xuser telah dihapus karena expired."
        fi
    done < /etc/premdigital/xray-users.db
fi
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

# 14.5. Sinkronisasi Data Firebase (Firebase Web Stats Sync)
echo -e "\e[33m[INFO] Setting Firebase Web Stats Sync...\e[0m"
cat > /usr/local/bin/sync-stats << 'END'
#!/bin/bash
FB_KEY=$(cat /etc/premdigital/firebase_key.txt 2>/dev/null)
if [ -z "$FB_KEY" ]; then
    FB_KEY="AIzaSyAymTIeAbbtdD5JdbzkpwMZZHPi05YIlGU"
fi
API_URL="https://firestore.googleapis.com/v1/projects/integrated-wharf-pf6jr/databases/ai-studio-premdigitaltunne-563571df-29ee-44be-a591-c6690b4a41c4/documents/platform/stats?key=${FB_KEY}"

total_ssh=$(awk -F: '($3>=1000)&&($1!="nobody"){print $1}' /etc/passwd | wc -l)
total_vmess=$(grep -i "vmess" /etc/premdigital/xray-users.db 2>/dev/null | wc -l)
total_vless=$(grep -i "vless" /etc/premdigital/xray-users.db 2>/dev/null | wc -l)
total_trojan=$(grep -i "trojan" /etc/premdigital/xray-users.db 2>/dev/null | wc -l)
total_accounts=$((total_ssh + total_vmess + total_vless + total_trojan))

online_users=$(netstat -anp 2>/dev/null | grep ESTABLISHED | grep -E "dropbear|sshd|xray|ws-proxy" | grep -v "127.0.0.1" | wc -l)

curl -s -X PATCH "$API_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "fields": {
      "activeServers": { "integerValue": "1" },
      "onlineUsers": { "integerValue": "'"$online_users"'" },
      "totalAccounts": { "integerValue": "'"$total_accounts"'" },
      "servicesToday": { "integerValue": "12" },
      "breakdown": {
        "mapValue": {
          "fields": {
            "ssh": { "integerValue": "'"$total_ssh"'" },
            "vmess": { "integerValue": "'"$total_vmess"'" },
            "vless": { "integerValue": "'"$total_vless"'" },
            "trojan": { "integerValue": "'"$total_trojan"'" }
          }
        }
      }
    }
  }' >/dev/null 2>&1
END
chmod +x /usr/local/bin/sync-stats

# Cronjob jalan tiap tengah malam (auto-delete), 2 menit (auto-kill multi-login), dan 5 menit (sinkronisasi firebase)
(crontab -l 2>/dev/null | grep -v "/usr/local/bin/auto-delete" | grep -v "/usr/local/bin/auto-kill-multilogin" | grep -v "/usr/local/bin/sync-stats"; \
 echo "0 0 * * * /usr/local/bin/auto-delete"; \
 echo "*/2 * * * * /usr/local/bin/auto-kill-multilogin"; \
 echo "*/5 * * * * /usr/local/bin/sync-stats") | crontab -

# Alias menu, backup, restore
grep -qxF "alias menu='/usr/bin/menu'" ~/.bashrc || echo "alias menu='/usr/bin/menu'" >> ~/.bashrc
grep -qxF "alias backup='/usr/bin/backup-vps'" ~/.bashrc || echo "alias backup='/usr/bin/backup-vps'" >> ~/.bashrc
grep -qxF "alias restore='/usr/bin/restore-vps'" ~/.bashrc || echo "alias restore='/usr/bin/restore-vps'" >> ~/.bashrc

# 15. Ringkasan Instalasi Tunneling
clear
echo -e "\e[36m====================================================\e[0m"
echo -e "\e[33m   INSTALASI TUNNELING PREMDIGITAL V1 SUKSES!       \e[0m"
echo -e "\e[36m====================================================\e[0m"
echo -e " 🌍 Host / Domain : \e[32m$DOMAIN\e[0m"
echo -e " 🌐 IP VPS        : \e[32m$MYIP\e[0m"
echo -e "\e[36m----------------------------------------------------\e[0m"
echo -e " 🔌 INFORMASI PORT TUNNELING:\e[0m"
echo -e " • Xray VMESS / VLESS / TROJAN : \e[33m443 (TLS), 80 (NTLS)\e[0m"
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
echo -e " 👉 Perintah Cepat: \e[33mbackup\e[0m (Backup Data) | \e[33mrestore\e[0m (Pulihkan Data)"
echo -e "\e[36m====================================================\e[0m"
