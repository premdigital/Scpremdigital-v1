#!/usr/bin/python3
import requests, time, os, subprocess, json
from datetime import datetime, timedelta

BOT_TOKEN = "ISI_TOKEN_BOT_DISINI"
LAST_UPDATE_ID = 0

try:
    with open('/etc/vps-domain.txt', 'r') as f:
        DOMAIN = f.read().strip()
except:
    DOMAIN = "IP_VPS"

# Set konfigurasi tambahan sesuai gambar
ADMIN_CONTACT = "t.me/T0M15"
WEB_URL = "https://www.premdigital.web.id"
VERSION = "v1.0 (PremDigital)"

def send_message_with_keyboard(chat_id, text, reply_markup=None):
    url = f"https://api.telegram.org/bot{BOT_TOKEN}/sendMessage"
    payload = {
        "chat_id": chat_id,
        "text": text,
        "parse_mode": "HTML",
        "disable_web_page_preview": True
    }
    if reply_markup:
        payload["reply_markup"] = reply_markup
        
    try:
        requests.post(url, json=payload)
    except Exception as e:
        pass

def process_callback(callback_query):
    chat_id = callback_query["message"]["chat"]["id"]
    data = callback_query["data"]
    
    # Menjawab callback agar loading di tombol hilang
    requests.post(f"https://api.telegram.org/bot{BOT_TOKEN}/answerCallbackQuery", json={"callback_query_id": callback_query["id"]})

    if data == "menu_ssh":
        msg = (
            f"<b>🔑 BUAT AKUN SSH/OVPN/UDP</b>\n"
            f"━━━━━━━━━━━━━━━━━━\n"
            f"Untuk saat ini, pembuatan akun dilakukan dengan perintah manual.\n\n"
            f"Ketik format berikut:\n"
            f"<code>/create [username] [password] [hari] [limit_ip]</code>\n\n"
            f"<b>Contoh:</b> <code>/create tester 123 30 2</code>"
        )
        send_message_with_keyboard(chat_id, msg)
    elif data == "menu_coming_soon":
        send_message_with_keyboard(chat_id, "<i>⚠️ Fitur ini sedang dalam tahap pengembangan.</i>")
    elif data == "menu_status":
        uptime = subprocess.getoutput("uptime -p").replace("up ", "")
        try:
            mem = subprocess.getoutput("free -m | awk 'NR==2{printf \"%.2f%%\", $3*100/$2 }'")
        except:
            mem = "Unknown"
        msg = (
            f"<b>📊 STATUS SERVER</b>\n"
            f"┌─────────────────┐\n"
            f"├ 🌐 <b>Domain:</b> <code>{DOMAIN}</code>\n"
            f"├ ⏱ <b>Uptime:</b> {uptime}\n"
            f"├ 💾 <b>RAM Use:</b> {mem}\n"
            f"└─────────────────┘"
        )
        send_message_with_keyboard(chat_id, msg)

def process_message(text, chat_id, first_name, user_id):
    text = text.strip()
    
    if text.startswith("/start") or text.startswith("/help") or text.lower() == "menu":
        msg = (
            f"📦━━━━━━━[ <b>PREMDIGITAL</b> ]━━━━━━━📦\n\n"
            f"👋 Selamat datang di <b>VPN AUTO ORDER</b> 💎\n"
            f"Solusi kelola akun VPN cepat, aman, & otomatis 🚀\n\n"
            f"🧭 <b>Informasi Akun (Bot)</b>\n"
            f"┌───────────────────────┐\n"
            f"├ 👤 <b>Nama :</b> {first_name}\n"
            f"├ 🆔 <b>ID   :</b> <code>{user_id}</code>\n"
            f"├ 👑 <b>Role :</b> ADMIN / OWNER\n"
            f"└───────────────────────┘\n\n"
            f"⚡ <b>Sistem</b>\n"
            f"• Otomatis 24 Jam\n"
            f"• Cepat & Stabil\n"
            f"• Support Banyak Protocol\n\n"
            f"☎️ <b>Admin</b>\n"
            f"📧 {ADMIN_CONTACT}\n"
            f"🌐 {WEB_URL}\n\n"
            f"<i>Version {VERSION}</i>"
        )
        
        # Susunan Tombol sesuai gambar
        keyboard = {
            "inline_keyboard": [
                [
                    {"text": "🔑 Buat Ssh/Ovpn/Udp", "callback_data": "menu_ssh"}
                ],
                [
                    {"text": "⚡ Buat Vmess", "callback_data": "menu_coming_soon"},
                    {"text": "🛡️ Buat Vless", "callback_data": "menu_coming_soon"}
                ],
                [
                    {"text": "🚀 Buat Trojan", "callback_data": "menu_coming_soon"},
                    {"text": "📊 Status Server", "callback_data": "menu_status"}
                ],
                [
                    {"text": "👨‍💻 Hubungi Admin ↗️", "url": f"https://{ADMIN_CONTACT}"}
                ]
            ]
        }
        
        send_message_with_keyboard(chat_id, msg, reply_markup=keyboard)

    # === MENU CREATE AKUN MANUAL (Tetap dipertahankan) ===
    elif text.startswith("/create"):
        parts = text.split()
        if len(parts) >= 4:
            user = parts[1]
            pwd = parts[2]
            hari = parts[3]
            
            ip_limit = parts[4] if len(parts) > 4 else "2"
            
            if ip_limit == "1": kuota_gb = "50"
            elif ip_limit == "2": kuota_gb = "70"
            elif ip_limit == "3": kuota_gb = "100"
            elif ip_limit == "5": kuota_gb = "150"
            else: kuota_gb = "70" 
            
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
            
            MSG = (
                f"<b>✅ AKUN SSH BERHASIL DIBUAT</b>\n"
                f"━━━━━━━━━━━━━━━━━━━━━━\n"
                f"👤 <b>Username :</b> <code>{user}</code>\n"
                f"🔑 <b>Password :</b> <code>{pwd}</code>\n"
                f"🌐 <b>Host/IP  :</b> <code>{DOMAIN}</code>\n"
                f"⏳ <b>Durasi   :</b> {hari} Hari\n"
                f"📅 <b>Expired  :</b> {exp_date}\n"
                f"📱 <b>Limit IP :</b> {ip_limit} Device\n"
                f"📦 <b>Kuota    :</b> {kuota_label}\n"
                f"━━━━━━━━━━━━━━━━━━━━━━\n"
                f"<b>🔌 PORT LAYANAN:</b>\n"
                f"▪️ TLS/SSL  : 443, 8443\n"
                f"▪️ HTTP/WS  : 80, 8880, 2082\n"
                f"▪️ OpenSSH  : 22, 2253\n"
                f"▪️ Dropbear : 109, 143\n"
                f"▪️ UDPGW    : 7100\n"
                f"━━━━━━━━━━━━━━━━━━━━━━\n"
                f"<b>📥 PAYLOAD WEBSOCKET:</b>\n"
                f"<code>GET / HTTP/1.1[crlf]Host: [host_port][crlf]User-Agent: [ua][crlf]Upgrade: websocket[crlf][crlf]</code>\n"
                f"━━━━━━━━━━━━━━━━━━━━━━"
            )
            send_message_with_keyboard(chat_id, MSG)

# === SETUP TOMBOL MENU UTAMA (Tombol biru "Menu" di kiri bawah Telegram) ===
def setup_bot_menu():
    url = f"https://api.telegram.org/bot{BOT_TOKEN}/setMyCommands"
    commands = {
        "commands": [
            {"command": "start", "description": "Tampilkan Main Menu"},
            {"command": "status", "description": "Cek Status Server VPS"}
        ]
    }
    try: requests.post(url, json=commands)
    except: pass

setup_bot_menu() # Jalankan sekali saat bot hidup

while True:
    try:
        req = requests.get(f"https://api.telegram.org/bot{BOT_TOKEN}/getUpdates?offset={LAST_UPDATE_ID}", timeout=5)
        data = req.json()
        for result in data.get("result", []):
            LAST_UPDATE_ID = result["update_id"] + 1
            
            # Jika user menekan tombol (Callback Query)
            if "callback_query" in result:
                process_callback(result["callback_query"])
            
            # Jika user mengetik pesan biasa
            elif "message" in result:
                chat_id = result["message"]["chat"]["id"]
                text = result["message"].get("text", "")
                first_name = result["message"]["chat"].get("first_name", "User")
                user_id = result["message"]["from"]["id"]
                
                if text:
                    process_message(text, chat_id, first_name, user_id)
    except:
        pass
    time.sleep(2)
