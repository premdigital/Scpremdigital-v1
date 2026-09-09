#!/bin/bash
# ==========================================
# Script Create TROJAN (5 Network Protocol)
# ==========================================

# Cek & Install jq jika belum ada
if ! command -v jq &> /dev/null; then
    apt-get update && apt-get install jq -y > /dev/null 2>&1
fi

CONFIG_XRAY="/etc/xray/config.json"

# Ambil Domain dari file, jika tidak ada pakai IP
domain=$(cat /etc/vps-domain.txt 2>/dev/null)
if [[ -z "$domain" ]]; then
    domain=$(curl -sS ifconfig.me)
fi

clear
echo -e "\e[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
echo -e "\e[1;33m       MEMBUAT AKUN TROJAN (5 JALUR)\e[0m"
echo -e "\e[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"

# Validasi Username (Trojan menggunakan password, kita samakan dengan username agar mudah)
until [[ $user =~ ^[a-zA-Z0-9_]+$ && ${CLIENT_EXISTS} == '0' ]]; do
    read -rp "Username (Password Trojan) : " -e user
    CLIENT_EXISTS=$(grep -w $user $CONFIG_XRAY | wc -l)
    if [[ ${CLIENT_EXISTS} == '1' ]]; then
        echo -e "\e[1;31mUsername '${user}' sudah ada!\e[0m"
        exit 1
    fi
done

read -p "Masa Aktif (Hari) : " masaaktif

# Generate Tanggal
exp=$(date -d "$masaaktif days" +"%Y-%m-%d")

# Inject ke Config Xray (Trojan menggunakan 'password' bukan 'id'/'uuid')
jq "( .inbounds[] | select(.protocol == \"trojan\") | .settings.clients ) += [{\"password\": \"${user}\", \"email\": \"${user}\"}]" $CONFIG_XRAY > /tmp/xray_tmp.json
mv /tmp/xray_tmp.json $CONFIG_XRAY
systemctl restart xray > /dev/null 2>&1

# ==========================================
# Generate 5 Link TROJAN (Format URI)
# ==========================================

# 1. WS TLS
link_ws_tls="trojan://${user}@${domain}:443?path=/trojan&security=tls&host=${domain}&type=ws&sni=${domain}#${user}"

# 2. WS Non-TLS (Catatan: Trojan secara native selalu TLS, tapi Xray mendukung fallback)
link_ws_ntls="trojan://${user}@${domain}:80?path=/trojan&security=none&host=${domain}&type=ws#${user}"

# 3. gRPC
link_grpc="trojan://${user}@${domain}:443?mode=multi&security=tls&type=grpc&serviceName=trojan&sni=${domain}#${user}"

# 4. HTTP Upgrade TLS
link_up_tls="trojan://${user}@${domain}:443?path=/uptrojan&security=tls&host=${domain}&type=httpupgrade&sni=${domain}#${user}"

# 5. HTTP Upgrade Non-TLS
link_up_ntls="trojan://${user}@${domain}:80?path=/uptrojan&security=none&host=${domain}&type=httpupgrade#${user}"

# ==========================================
# Output Hasil di Terminal
# ==========================================
clear
echo -e "✅ \e[1;32mSUKSES CREATE TROJAN\e[0m"
echo -e "━━━━━━━━━━━━━━━━━━"
echo -e "👤 User/Pass: \e[1;33m${user}\e[0m"
echo -e "🌍 Host: \e[1;37m${domain}\e[0m"
echo -e "⏳ Durasi: \e[1;37m${masaaktif} Hari\e[0m"
echo -e "📅 Expired: \e[1;31m${exp}\e[0m"
echo -e ""
echo -e "🔒 \e[1;32mTLS Link (Websocket):\e[0m"
echo -e "\e[1;37m${link_ws_tls}\e[0m"
echo -e ""
echo -e "🔓 \e[1;32mNon-TLS Link (Websocket):\e[0m"
echo -e "\e[1;37m${link_ws_ntls}\e[0m"
echo -e ""
echo -e "🚀 \e[1;32mGRPC Link:\e[0m"
echo -e "\e[1;37m${link_grpc}\e[0m"
echo -e ""
echo -e "⚡ \e[1;32mUpgrade TLS Link:\e[0m"
echo -e "\e[1;37m${link_up_tls}\e[0m"
echo -e ""
echo -e "⚡ \e[1;32mUpgrade Non-TLS Link:\e[0m"
echo -e "\e[1;37m${link_up_ntls}\e[0m"
echo -e "━━━━━━━━━━━━━━━━━━"
