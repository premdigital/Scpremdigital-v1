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
    if text.startswith("/start") or text.startswith("/help"):
        MSG = f"👋 Selamat datang di Bot PremDigital Tunnel!\n\nBot VPS Anda aktif dan berjalan normal. 🚀\n\nUntuk membuat akun SSH, gunakan format:\n`/create <user> <pass> <hari> [ip_limit]`\n\nContoh:\n`/create tester 123 30 2`"
        requests.post(f"https://api.telegram.org/bot{BOT_TOKEN}/sendMessage", data={"chat_id": chat_id, "text": MSG, "parse_mode": "Markdown"})
    elif text.startswith("/create"):
        parts = text.split()
        if len(parts) >= 4:
            user = parts[1]
            pwd = parts[2]
            hari = parts[3]
            
            ip_limit = parts[4] if len(parts) > 4 else "2"
            
            if ip_limit == "1":
                kuota_gb = "50"
            elif ip_limit == "2":
                kuota_gb = "70"
            elif ip_limit == "3":
                kuota_gb = "100"
            elif ip_limit == "5":
                kuota_gb = "150"
            else:
                kuota_gb = "70" 
            
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
            
            os.system('mkdir -p /etc/premdigital/multilogin /etc/premdigital/user_quota')
            os.system(f'echo "{ip_limit}" > /etc/premdigital/multilogin/{user}')
            os.system(f'echo "{kuota_gb}" > /etc/premdigital/user_quota/{user}')
            
            kuota_label = f"{kuota_gb} GB" if str(kuota_gb) != "0" else "Unlimited"
            
            MSG = f"✅ AKUN SSH SUKSES DIBUAT\n━━━━━━━━━━━━━━━━━━\n👤 Username: {user}\n🔑 Password: {pwd}\n🌍 Host: {DOMAIN}\n⏳ Durasi: {hari} Hari\n📱 Max Login: {ip_limit} IP\n📦 Kuota Data: {kuota_label}\n━━━━━━━━━━━━━━━━━━\n🔌 Port Info:\n• TLS: 443, 8443\n• HTTP: 80, 8880, 2082\n• Dropbear: 109, 143\n• OpenSSH: 22, 2253\n• UDPGW: 7100\n• Squid: 8080\n━━━━━━━━━━━━━━━━━━\n📥 Payload WS:\nGET / HTTP/1.1[crlf]Host: [host_port][crlf]User-Agent: [ua][crlf]Upgrade: websocket[crlf][crlf]\n━━━━━━━━━━━━━━━━━━"
            requests.post(f"https://api.telegram.org/bot{BOT_TOKEN}/sendMessage", data={"chat_id": chat_id, "text": MSG})
        else:
            requests.post(f"https://api.telegram.org/bot{BOT_TOKEN}/sendMessage", data={"chat_id": chat_id, "text": "Format salah.\n\nGunakan: /create <user> <pass> <hari> [ip_limit]\nContoh: /create tester 123 30 2"})

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
