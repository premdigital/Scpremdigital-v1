#!/bin/bash
# ==========================================
# PremDigital - Xray Core & Multiplexer Setup
# ==========================================

if [ "${EUID}" -ne 0 ]; then
    echo "Mohon jalankan sebagai root"
    exit 1
fi

echo -e "\e[33m[INFO] Menyiapkan Direktori & Sertifikat Xray...\e[0m"
mkdir -p /etc/xray /var/log/xray /etc/premdigital/xray

# Deteksi Domain VPS
if [ -f /etc/vps-domain.txt ]; then
    domain=$(cat /etc/vps-domain.txt | tr -d '\r\n')
else
    domain=$(curl -sS -m 3 ipv4.icanhazip.com 2>/dev/null || curl -sS -m 3 ipinfo.io/ip 2>/dev/null || echo "127.0.0.1")
    echo "$domain" > /etc/vps-domain.txt
fi

# Buat Sertifikat SSL untuk Xray jika belum ada
if [ ! -f /etc/xray/xray.crt ] || [ ! -f /etc/xray/xray.key ]; then
    if [ -f /etc/stunnel/stunnel.pem ]; then
        cp -f /etc/stunnel/stunnel.pem /etc/xray/xray.crt
        cp -f /etc/stunnel/stunnel.pem /etc/xray/xray.key
    else
        openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -sha256 \
        -subj "/C=ID/ST=DKI Jakarta/L=Jakarta/O=PremDigital/OU=PremDigital/CN=$domain" \
        -out /etc/xray/xray.crt -keyout /etc/xray/xray.key 2>/dev/null
    fi
    chmod 644 /etc/xray/xray.crt 2>/dev/null
    chmod 600 /etc/xray/xray.key 2>/dev/null
fi

# Download Xray Core jika belum ada
if [ ! -f /usr/local/bin/xray ]; then
    echo -e "\e[33m[INFO] Mengunduh Xray Core Official...\e[0m"
    arch=$(uname -m)
    xray_arch="64"
    if [ "$arch" == "aarch64" ] || [ "$arch" == "arm64" ]; then
        xray_arch="arm64-v8a"
    fi
    
    apt-get install -y unzip curl wget python3 >/dev/null 2>&1
    wget -qO /tmp/xray.zip "https://github.com/XTLS/Xray-core/releases/download/v1.8.24/Xray-linux-${xray_arch}.zip"
    if [ -f /tmp/xray.zip ]; then
        unzip -o /tmp/xray.zip -d /usr/local/bin/ xray >/dev/null 2>&1
        chmod +x /usr/local/bin/xray
        rm -f /tmp/xray.zip
    fi
fi

# Buat Base Config Xray jika belum ada atau kosong
if [ ! -s /etc/xray/config.json ]; then
    echo -e "\e[33m[INFO] Mengonfigurasi /etc/xray/config.json...\e[0m"
    cat > /etc/xray/config.json << 'EOF'
{
  "log": {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": 10001,
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/vmess"
        }
      }
    },
    {
      "port": 10002,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": {
        "clients": [],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/vless"
        }
      }
    },
    {
      "port": 10003,
      "listen": "127.0.0.1",
      "protocol": "trojan",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/trojan"
        }
      }
    },
    {
      "port": 10004,
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "grpc",
        "grpcSettings": {
          "serviceName": "vmess"
        }
      }
    },
    {
      "port": 10005,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": {
        "clients": [],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "grpc",
        "grpcSettings": {
          "serviceName": "vless"
        }
      }
    },
    {
      "port": 10006,
      "listen": "127.0.0.1",
      "protocol": "trojan",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "grpc",
        "grpcSettings": {
          "serviceName": "trojan"
        }
      }
    },
    {
      "port": 10007,
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "httpupgrade",
        "httpupgradeSettings": {
          "path": "/upvmess"
        }
      }
    },
    {
      "port": 10008,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": {
        "clients": [],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "httpupgrade",
        "httpupgradeSettings": {
          "path": "/upvless"
        }
      }
    },
    {
      "port": 10009,
      "listen": "127.0.0.1",
      "protocol": "trojan",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "httpupgrade",
        "httpupgradeSettings": {
          "path": "/uptrojan"
        }
      }
    },
    {
      "port": 4430,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": {
        "clients": [],
        "decryption": "none",
        "fallbacks": [
          { "path": "/vmess", "dest": 10001 },
          { "path": "/vless", "dest": 10002 },
          { "path": "/trojan", "dest": 10003 },
          { "path": "/upvmess", "dest": 10007 },
          { "path": "/upvless", "dest": 10008 },
          { "path": "/uptrojan", "dest": 10009 },
          { "serviceName": "vmess", "dest": 10004 },
          { "serviceName": "vless", "dest": 10005 },
          { "serviceName": "trojan", "dest": 10006 },
          { "dest": 109 }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "tls",
        "tlsSettings": {
          "certificates": [
            {
              "certificateFile": "/etc/xray/xray.crt",
              "keyFile": "/etc/xray/xray.key"
            }
          ]
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct"
    }
  ]
}
EOF
fi

# Buat Service Systemd untuk Xray
cat > /etc/systemd/system/xray.service << 'EOF'
[Unit]
Description=Xray Service PremDigital
Documentation=https://github.com/xtls
After=network.target

[Service]
User=root
ExecStart=/usr/local/bin/xray run -config /etc/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable xray >/dev/null 2>&1
systemctl restart xray >/dev/null 2>&1

echo -e "\e[32m[INFO] Xray Core & Service berhasil disiapkan!\e[0m"
