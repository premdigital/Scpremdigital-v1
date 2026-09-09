#!/bin/bash
# ==========================================
# Script Create VMESS (5 Network Protocol)
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
echo -e "\e[1;33m       MEMBUAT AKUN VMESS (5 JALUR)\e[0m"
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

# Inject ke Config Xray
jq "( .inbounds[] | select(.protocol == \"vmess\") | .settings.clients ) += [{\"id\": \"${uuid}\", \"alterId\": 0, \"email\": \"${user}\"}]" $CONFIG_XRAY > /tmp/xray_tmp.json
mv /tmp/xray_tmp.json $CONFIG_XRAY
systemctl restart xray > /dev/null 2>&1

# ==========================================
# Generate 5 Link JSON & Encode ke Base64
# ==========================================

# 1. WS TLS
json_ws_tls=$(cat <<EOF
{
  "v": "2", "ps": "${user}", "add": "${domain}", "port": "443", "id": "${uuid}", "aid": "0", "net": "ws", "path": "/vmess", "type": "none", "host": "${domain}", "sni": "${domain}", "tls": "tls"
}
EOF
)
link_ws_tls="vmess://$(echo -n "$json_ws_tls" | base64 -w 0)"

# 2. WS Non-TLS
json_ws_ntls=$(cat <<EOF
{
  "v": "2", "ps": "${user}", "add": "${domain}", "port": "80", "id": "${uuid}", "aid": "0", "net": "ws", "path": "/vmess", "type": "none", "host": "${domain}", "sni": "${domain}", "tls": "none"
}
EOF
)
link_ws_ntls="vmess://$(echo -n "$json_ws_ntls" | base64 -w 0)"

# 3. gRPC
json_grpc=$(cat <<EOF
{
  "v": "2", "ps": "${user}", "add": "${domain}", "port": "443", "id": "${uuid}", "aid": "0", "net": "grpc", "path": "vmess", "type": "none", "host": "${domain}", "sni": "${domain}", "tls": "tls"
}
EOF
)
link_grpc="vmess://$(echo -n "$json_grpc" | base64 -w 0)"

# 4. HTTP Upgrade TLS
json_up_tls=$(cat <<EOF
{
  "v": "2", "ps": "${user}", "add": "${domain}", "port": "443", "id": "${uuid}", "aid": "0", "net": "httpupgrade", "path": "/upvmess", "type": "none", "host": "${domain}", "sni": "${domain}", "tls": "tls"
}
EOF
)
link_up_tls="vmess://$(echo -n "$json_up_tls" | base64 -w 0)"

# 5. HTTP Upgrade Non-TLS
json_up_ntls=$(cat <<EOF
{
  "v": "2", "ps": "${user}", "add": "${domain}", "port": "80", "id": "${uuid}", "aid": "0", "net": "httpupgrade", "path": "/upvmess", "type": "none", "host": "${domain}", "sni": "${domain}", "tls": "none"
}
EOF
)
link_up_ntls="vmess://$(echo -n "$json_up_ntls" | base64 -w 0)"

# ==========================================
# Output Hasil di Terminal (Sesuai Template)
# ==========================================
clear
echo -e "✅ \e[1;32mSUKSES CREATE VMESS\e[0m"
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
