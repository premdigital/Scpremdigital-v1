# 1. Hapus opsi [14] dari menu utama
sed -i '/\[14\] Hubungkan VPS ke Web Auto-Creator/d' install.sh
sed -i 's/read -p " Pilih Opsi \[0-14\]: " opt/read -p " Pilih Opsi \[0-13\]: " opt/g' install.sh

# 2. Hapus seluruh blok 'case 14)' dari menu utama
sed -i '/14)/,/;;/d' install.sh

# 3. Ubah teks menu '1' di sub-menu (API & Bot)
sed -i 's/\[1\] Ganti Secret Key API Web/\[1\] Hubungkan VPS ke Web Auto-Creator/g' install.sh

# 4. Ganti isi dari 'case 1' di sub-menu (API & Bot)
sed -i '/1)/,/;;/c\
                    1)\
                        clear\
                        echo -e "\\e[36m====================================================\\e[0m"\
                        echo -e "\\e[33m         HUBUNGKAN VPS KE WEB AUTO-CREATOR         \\e[0m"\
                        echo -e "\\e[36m====================================================\\e[0m"\
                        echo -e "Menu ini akan memasang Daemon agar VPS ini dapat"\
                        echo -e "menerima perintah pembuatan akun otomatis dari Web."\
                        echo -e ""\
                        read -p "Masukkan Server ID / Node ID (Contoh: sg-premium-01): " new_nodeid\
                        if [ -z "$new_nodeid" ]; then\
                            echo "Dibatalkan."\
                            sleep 2\
                            continue\
                        fi\
                        read -p "Masukkan API Key Firebase/Web: " new_apikey\
                        if [ -z "$new_apikey" ]; then\
                            echo "Dibatalkan."\
                            sleep 2\
                            continue\
                        fi\
                        echo -e "\\n\\e[33m[INFO] Menyiapkan Auto-Creator Daemon...\\e[0m"\
                        mkdir -p /etc/premdigital\
                        echo "$new_apikey" > /etc/premdigital/web_apikey.txt\
                        echo "$new_nodeid" > /etc/premdigital/web_nodeid.txt\
                        cat > /root/auto_creator.sh << '"'"'SCRIPT_EOF'"'"'\
#!/bin/bash\
NODE_ID="NODE_ID_REPLACE"\
PROJECT_ID="web-premdigitalvpn"\
API_KEY="API_KEY_REPLACE"\
REST_URL="https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents"\
\
fetch_commands() {\
  QUERY_PAYLOAD=$(cat <<EOT\
  {\
    "structuredQuery": {\
      "from": [{"collectionId": "vps_commands"}],\
      "where": {\
        "compositeFilter": {\
          "op": "AND",\
          "filters": [\
            {\
              "fieldFilter": {\
                "field": {"fieldPath": "serverId"},\
                "op": "EQUAL",\
                "value": {"stringValue": "${NODE_ID}"}\
              }\
            },\
            {\
              "fieldFilter": {\
                "field": {"fieldPath": "status"},\
                "op": "EQUAL",\
                "value": {"stringValue": "pending"}\
              }\
            }\
          ]\
        }\
      }\
    }\
  }\
EOT\
  )\
  curl -s -X POST "${REST_URL}:runQuery?key=${API_KEY}" \\\
    -H "Content-Type: application/json" \\\
    -d "$QUERY_PAYLOAD"\
}\
\
update_command_status() {\
  DOC_PATH=$1\
  UPDATE_URL="${REST_URL}/${DOC_PATH}?key=${API_KEY}&updateMask.fieldPaths=status"\
  PAYLOAD=$(cat <<EOT\
  {\
    "fields": {\
      "status": { "stringValue": "success" }\
    }\
  }\
EOT\
  )\
  curl -s -X PATCH "$UPDATE_URL" -H "Content-Type: application/json" -d "$PAYLOAD" > /dev/null\
}\
\
while true; do\
  RESPONSE=$(fetch_commands)\
  if echo "$RESPONSE" | grep -q '"'"'"document":"'"'"'; then\
    echo "$RESPONSE" | jq -c '"'"'.[].document'"'"' | while read -r DOC_DATA; do\
      [ -z "$DOC_DATA" ] || [ "$DOC_DATA" == "null" ] && continue\
      DOC_PATH=$(echo "$DOC_DATA" | jq -r '"'"'.name'"'"' | awk -F'"'"'(default)/documents/'"'"' '"'"'{print $2}'"'"')\
      USERNAME=$(echo "$DOC_DATA" | jq -r '"'"'.fields.username.stringValue'"'"')\
      PASSWORD=$(echo "$DOC_DATA" | jq -r '"'"'.fields.password.stringValue'"'"')\
      PROTOCOL=$(echo "$DOC_DATA" | jq -r '"'"'.fields.protocol.stringValue'"'"')\
      ACTIVEDAYS=$(echo "$DOC_DATA" | jq -r '"'"'.fields.activeDays.integerValue'"'"')\
      \
      if [ "$PROTOCOL" == "ssh" ]; then\
        if id "$USERNAME" &>/dev/null; then\
            userdel -f "$USERNAME" &>/dev/null\
        fi\
        EXP_DATE=$(date -d "+${ACTIVEDAYS} days" +"%Y-%m-%d")\
        useradd -e "$EXP_DATE" -s /bin/false -M "$USERNAME"\
        echo "$USERNAME:$PASSWORD" | chpasswd\
        update_command_status "$DOC_PATH"\
      fi\
    done\
  fi\
  sleep 5\
done\
SCRIPT_EOF\
                        sed -i "s/NODE_ID_REPLACE/$new_nodeid/g" /root/auto_creator.sh\
                        sed -i "s/API_KEY_REPLACE/$new_apikey/g" /root/auto_creator.sh\
                        chmod +x /root/auto_creator.sh\
                        cat > /etc/systemd/system/vps-autocreator.service << '"'"'SVC_EOF'"'"'\
[Unit]\
Description=VPS Auto-Creator Daemon\
After=network.target\
\
[Service]\
Type=simple\
User=root\
ExecStart=/root/auto_creator.sh\
Restart=always\
RestartSec=5\
\
[Install]\
WantedBy=multi-user.target\
SVC_EOF\
                        systemctl daemon-reload\
                        systemctl enable vps-autocreator\
                        systemctl restart vps-autocreator\
                        echo -e "\\e[32m[SUKSES] VPS berhasil dihubungkan! Auto-Creator sudah berjalan.\\e[0m"\
                        echo -e "Silakan cek di web Anda apakah fitur auto create berjalan.\\n"\
                        read -n 1 -s -r -p "Tekan sembarang tombol untuk kembali ke menu..."\
                        continue\
                        ;;' install.sh
