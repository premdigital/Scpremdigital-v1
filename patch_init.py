with open("install.sh", "r") as f:
    content = f.read()

old_input = """    read -p "Masukkan Domain / Host (Kosongkan jika pakai IP): " input_domain
    if [ -n "$input_domain" ]; then
        echo "$input_domain" > /etc/vps-domain.txt
    fi
fi
DOMAIN=$(cat /etc/vps-domain.txt)"""

new_input = """    read -p "Masukkan API Key Web (Kosongkan jika tidak pakai Web): " input_apikey
    if [ -n "$input_apikey" ]; then
        echo "$input_apikey" > /etc/premdigital/web_apikey.txt
        read -p "Masukkan Server ID / Node ID (Contoh: sg-premium-01): " input_nodeid
        if [ -n "$input_nodeid" ]; then
            echo "$input_nodeid" > /etc/premdigital/web_nodeid.txt
        else
            echo "Node-01" > /etc/premdigital/web_nodeid.txt
        fi
    fi
    read -p "Masukkan Domain / Host (Kosongkan jika pakai IP): " input_domain
    if [ -n "$input_domain" ]; then
        echo "$input_domain" > /etc/vps-domain.txt
    fi
fi
DOMAIN=$(cat /etc/vps-domain.txt)"""

content = content.replace(old_input, new_input)

# Append daemon setup to the very end of install.sh (before MENUEOF is not needed, it's just append)
daemon_setup = """
# ==========================================
# AUTO CREATOR DAEMON SETUP
# ==========================================
if [ -f /etc/premdigital/web_apikey.txt ] && [ -f /etc/premdigital/web_nodeid.txt ]; then
    echo -e "\\e[33m[INFO] Menyiapkan Auto-Creator Daemon untuk Web...\\e[0m"
    WEB_APIKEY=$(cat /etc/premdigital/web_apikey.txt)
    WEB_NODEID=$(cat /etc/premdigital/web_nodeid.txt)
    
    cat > /root/auto_creator.sh << 'SCRIPT_EOF'
#!/bin/bash
NODE_ID="NODE_ID_REPLACE"
PROJECT_ID="web-premdigitalvpn"
API_KEY="API_KEY_REPLACE"
REST_URL="https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents"

fetch_commands() {
  QUERY_PAYLOAD=$(cat <<EOT
  {
    "structuredQuery": {
      "from": [{"collectionId": "vps_commands"}],
      "where": {
        "compositeFilter": {
          "op": "AND",
          "filters": [
            {
              "fieldFilter": {
                "field": {"fieldPath": "serverId"},
                "op": "EQUAL",
                "value": {"stringValue": "${NODE_ID}"}
              }
            },
            {
              "fieldFilter": {
                "field": {"fieldPath": "status"},
                "op": "EQUAL",
                "value": {"stringValue": "pending"}
              }
            }
          ]
        }
      }
    }
  }
EOT
  )
  curl -s -X POST "${REST_URL}:runQuery?key=${API_KEY}" \\
    -H "Content-Type: application/json" \\
    -d "$QUERY_PAYLOAD"
}

update_command_status() {
  DOC_PATH=$1
  UPDATE_URL="${REST_URL}/${DOC_PATH}?key=${API_KEY}&updateMask.fieldPaths=status"
  PAYLOAD=$(cat <<EOT
  {
    "fields": {
      "status": { "stringValue": "success" }
    }
  }
EOT
  )
  curl -s -X PATCH "$UPDATE_URL" -H "Content-Type: application/json" -d "$PAYLOAD" > /dev/null
}

while true; do
  RESPONSE=$(fetch_commands)
  if echo "$RESPONSE" | grep -q '"document"'; then
    echo "$RESPONSE" | jq -c '.[].document' | while read -r DOC_DATA; do
      [ -z "$DOC_DATA" ] || [ "$DOC_DATA" == "null" ] && continue
      DOC_PATH=$(echo "$DOC_DATA" | jq -r '.name' | awk -F'(default)/documents/' '{print $2}')
      USERNAME=$(echo "$DOC_DATA" | jq -r '.fields.username.stringValue')
      PASSWORD=$(echo "$DOC_DATA" | jq -r '.fields.password.stringValue')
      PROTOCOL=$(echo "$DOC_DATA" | jq -r '.fields.protocol.stringValue')
      ACTIVEDAYS=$(echo "$DOC_DATA" | jq -r '.fields.activeDays.integerValue')
      
      if [ "$PROTOCOL" == "ssh" ]; then
        if id "$USERNAME" &>/dev/null; then
            userdel -f "$USERNAME" &>/dev/null
        fi
        EXP_DATE=$(date -d "+${ACTIVEDAYS} days" +"%Y-%m-%d")
        useradd -e "$EXP_DATE" -s /bin/false -M "$USERNAME"
        echo "$USERNAME:$PASSWORD" | chpasswd
        update_command_status "$DOC_PATH"
      fi
    done
  fi
  sleep 5
done
SCRIPT_EOF

    sed -i "s/NODE_ID_REPLACE/$WEB_NODEID/g" /root/auto_creator.sh
    sed -i "s/API_KEY_REPLACE/$WEB_APIKEY/g" /root/auto_creator.sh
    chmod +x /root/auto_creator.sh

    cat > /etc/systemd/system/vps-autocreator.service << 'SVC_EOF'
[Unit]
Description=VPS Auto-Creator Daemon
After=network.target

[Service]
Type=simple
User=root
ExecStart=/root/auto_creator.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SVC_EOF

    systemctl daemon-reload
    systemctl enable vps-autocreator
    systemctl restart vps-autocreator
    echo -e "\\e[32m[SUKSES] Auto-Creator Daemon berjalan!\\e[0m"
fi
"""

content += daemon_setup

with open("install.sh", "w") as f:
    f.write(content)
