#!/bin/bash
# ==========================================
# Script Create VLESS (5 Network Protocol)
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
echo -e "\e[1;33m       MEMBUAT AKUN VLESS (5 JALUR)\e[0m"
echo -e "\e[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"

# Validasi Username
until [[ $user =~ ^[a-zA-Z0-9_]+$ && ${CLIENT_EXISTS} == '0' ]]; do
    read -rp "Username : " -e user
    CLIENT_EXISTS=$(grep -w $user $CONFIG_XRAY | wc -l)
    if [[ ${CLIENT_EXISTS} == '1' ]]; then
        echo -e "\e[1;31mUsername '${user}' sudah ada!\e[0m"
        exit 1
    fi
done

read -p "Masa Aktif (Hari) : " masaaktif

# Generate UUID & Tanggal
uuid=$(cat /proc/sys/kernel/random/uuid)
exp=$(date -d "$masaaktif days" +"%Y-%m-%d")

# Inject ke Config Xray (VLESS tidak pakai alterId)
jq "( .inbounds[] | select(.protocol == \"vless\") | .settings.clients ) += [{\"id\": \"${uuid}\", \"email\": \"${user}\"}]" $CONFIG_XRAY > /tmp/xray_tmp.json
mv /tmp/xray_tmp.json $CONFIG_XRAY
systemctl restart xray > /dev/null 2>&1

# ==========================================
# Generate 5 Link VLESS (Format URI)
# ==========================================

# 1. WS TLS
link_ws_tls="vless://${uuid}@${domain}:443?path=/vless&security=tls&encryption=none&host=${domain}&type=ws&sni=${domain}#${user}"

# 2. WS Non-TLS
link_ws_ntls="vless://${uuid}@${domain}:80?path=/vless&security=none&encryption=none&host=${domain}&type=ws#${user}"

# 3. gRPC
link_grpc="vless://${uuid}@${domain}:443?mode=multi&security=tls&encryption=none&type=grpc&serviceName=vless&sni=${domain}#${user}"

# 4. HTTP Upgrade TLS
link_up_tls="vless://${uuid}@${domain}:443?path=/upvless&security=tls&encryption=none&host=${domain}&type=httpupgrade&sni=${domain}#${user}"

# 5. HTTP Upgrade Non-TLS
link_up_ntls="vless://${uuid}@${domain}:80?path=/upvless&security=none&encryption=none&host=${domain}&type=httpupgrade#${user}"

# ==========================================
# Output Hasil di Terminal
# ==========================================
clear
echo -e "✅ \e[1;32mSUKSES CREATE VLESS\e[0m"
echo -e "━━━━━━━━━━━━━━━━━━"
echo -e "👤 Username: \e[1;33m${user}\e[0m"
echo -e "🆔 UUID: \e[1;37m${uuid}\e[0m"
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
