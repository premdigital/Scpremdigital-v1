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
    except:
        pass

def edit_message_with_keyboard(chat_id, message_id, text, reply_markup=None):
    url = f"https://api.telegram.org/bot{BOT_TOKEN}/editMessageText"
    payload = {
        "chat_id": chat_id,
        "message_id": message_id,
        "text": text,
        "parse_mode": "HTML",
        "disable_web_page_preview": True
    }
    if reply_markup:
        payload["reply_markup"] = reply_markup
    try:
        requests.post(url, json=payload)
    except:
        pass

def get_main_menu_text(first_name, user_id):
    return (
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

def get_main_menu_keyboard():
    return {
        "inline_keyboard": [
            [
                {"text": "🛒 Order Akun", "callback_data": "menu_order_akun"},
                {"text": "🆓 Trial Akun", "callback_data": "menu_trial_akun"}
            ],
            [
                {"text": "🔄 Perpanjang", "callback_data": "menu_perpanjang"},
                {"text": "💳 Isi Saldo", "callback_data": "menu_isi_saldo"}
            ],
            [
                {"text": "📋 Daftar Akun Saya", "callback_data": "menu_daftar_akun"}
            ],
            [
                {"text": "🚀 Upgrade Reseller", "callback_data": "menu_upgrade_reseller"}
            ],
            [
                {"text": "👨‍💻 Hubungi Admin ↗️", "url": f"https://{ADMIN_CONTACT}"}
            ]
        ]
    }

def process_callback(callback_query):
    chat_id = callback_query["message"]["chat"]["id"]
    message_id = callback_query["message"]["message_id"]
    first_name = callback_query["message"]["chat"].get("first_name", "User")
    user_id = callback_query["from"]["id"]
    data = callback_query["data"]
    
    requests.post(f"https://api.telegram.org/bot{BOT_TOKEN}/answerCallbackQuery", json={"callback_query_id": callback_query["id"]})

    if data == "back_to_main":
        msg = get_main_menu_text(first_name, user_id)
        keyboard = get_main_menu_keyboard()
        edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)

    elif data in ["menu_order_akun", "menu_trial_akun"]:
        tipe = "ORDER" if data == "menu_order_akun" else "TRIAL"
        msg = (
            f"⚙️ <b>PILIH PROTOKOL/LAYANAN {tipe}</b>\n"
            f"━━━━━━━━━━━━━━━━━━━━━━\n"
            f"Silakan pilih jenis layanan VPN yang ingin Anda buat:"
        )
        keyboard = {
            "inline_keyboard": [
                [
                    {"text": "SSH", "callback_data": f"select_{tipe.lower()}_ssh"},
                    {"text": "VMESS", "callback_data": f"select_{tipe.lower()}_vmess"}
                ],
                [
                    {"text": "VLESS", "callback_data": f"select_{tipe.lower()}_vless"},
                    {"text": "TROJAN", "callback_data": f"select_{tipe.lower()}_trojan"}
                ],
                [
                    {"text": "UDP ZIVPN", "callback_data": f"select_{tipe.lower()}_udp"}
                ],
                [
                    {"text": "🔙 Kembali", "callback_data": "back_to_main"}
                ]
            ]
        }
        edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)

    elif data.startswith("select_"):
        parts = data.split("_")
        action = parts[1] # order atau trial
        protocol = parts[2].upper()
        
        msg = (
            f"📖 <b>DAFTAR SERVER {protocol}</b>\n"
            f"━━━━━━━━━━━━━━━━━━━━━━\n"
            f"📁 <b>Server 1 :</b> 🇸🇬 SINGAPORE\n"
            f"⚡ <b>Ping :</b> 30 ms 🟢\n"
            f"🏢 <b>ISP :</b> DigitalOcean, LLC\n"
            f"💵 <b>Harga per hari:</b> Rp200\n"
            f"🗓 <b>Harga per 30 hari:</b> Rp6.000\n"
            f"📊 <b>Kuota:</b> Unlimited\n"
            f"📱 <b>Limit IP:</b> 1 Device\n"
            f"━━━━━━━━━━━━━━━━━━━━━━\n"
            f"📁 <b>Server 2 :</b> 🇮🇩 INDONESIA\n"
            f"⚡ <b>Ping :</b> 34 ms 🟢\n"
            f"🏢 <b>ISP :</b> PT Biznet Gio Nusantara\n"
            f"💵 <b>Harga per hari:</b> Rp333\n"
            f"🗓 <b>Harga per 30 hari:</b> Rp9.990\n"
            f"📊 <b>Kuota:</b> Unlimited\n"
            f"📱 <b>Limit IP:</b> 2 Device\n"
            f"━━━━━━━━━━━━━━━━━━━━━━\n"
            f"<i>Pilih nomor server di bawah untuk melanjutkan {action.upper()}:</i>"
        )
        
        keyboard = {
            "inline_keyboard": [
                [
                    {"text": "1", "callback_data": f"do_{action}_{protocol}_1"},
                    {"text": "2", "callback_data": f"do_{action}_{protocol}_2"}
                ],
                [
                    {"text": "🔙 Kembali", "callback_data": f"menu_{action}_akun"}
                ]
            ]
        }
        edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)

    elif data.startswith("do_"):
        parts = data.split("_")
        action = parts[1]
        protocol = parts[2]
        server = parts[3]
        
        msg = (
            f"🛒 <b>{action.upper()} DALAM PROSES</b>\n"
            f"━━━━━━━━━━━━━━━━━━━━━━\n"
            f"Anda memilih Server <b>{server}</b> ({protocol}).\n\n"
            f"Silakan gunakan perintah manual untuk saat ini:\n"
            f"<code>/create [username] [password] [hari] [limit_ip]</code>\n\n"
            f"<i>*Sistem potong saldo otomatis sedang dalam tahap akhir pengembangan.</i>"
        )
        keyboard = {
            "inline_keyboard": [
                [{"text": "🔙 Kembali", "callback_data": f"select_{action}_{protocol.lower()}"}]
            ]
        }
        edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)

    # --- MENU TAMBAHAN (Saldo, Reseller, dll) ---
    elif data == "menu_isi_saldo":
        msg = (
            f"💰 <b>INPUT NOMINAL DEPOSIT</b>\n"
            f"━━━━━━━━━━━━━━━━━━━━━━\n"
            f"Metode: QRIS Otomatis\n"
            f"Limit: Rp 1.000 - Rp 500.000\n\n"
            f"Silakan ketik nominal deposit yang diinginkan.\n"
            f"Contoh: 10000"
        )
        keyboard = {"inline_keyboard": [[{"text": "⛔ Batal", "callback_data": "back_to_main"}]]}
        edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)

    elif data in ["menu_perpanjang", "menu_daftar_akun"]:
        msg = (
            f"⚠️ <b>TIDAK ADA AKUN</b>\n"
            f"━━━━━━━━━━━━━━━━━━━━━━\n"
            f"Anda belum memiliki layanan aktif atau tidak ada akun yang bisa diperbarui."
        )
        keyboard = {"inline_keyboard": [[{"text": "🔙 Kembali", "callback_data": "back_to_main"}]]}
        edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)

    elif data == "menu_upgrade_reseller":
        msg = (
            f"🚀 <b>UPGRADE RESELLER</b>\n"
            f"━━━━━━━━━━━━━━━━━━━━━━\n"
            f"Menjadi reseller memberikan keuntungan:\n"
            f"✅ Harga Lebih Murah\n"
            f"✅ Trial Akun TANPA BATAS\n"
            f"✅ Prioritas Support\n\n"
            f"💡 <b>Cara Upgrade:</b>\n"
            f"Silakan lakukan ISI SALDO sebesar Rp 25.000. Sistem akan otomatis mengubah role Anda menjadi RESELLER."
        )
        keyboard = {
            "inline_keyboard": [
                [{"text": "💸 Bayar Rp 25.000 (QRIS)", "callback_data": "menu_coming_soon"}],
                [{"text": "🔙 Kembali", "callback_data": "back_to_main"}]
            ]
        }
        edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)

    elif data == "menu_coming_soon":
        requests.post(f"https://api.telegram.org/bot{BOT_TOKEN}/answerCallbackQuery", json={
            "callback_query_id": callback_query["id"],
            "text": "⚠️ Fitur ini sedang dalam tahap pengembangan.",
            "show_alert": True
        })

def process_message(text, chat_id, first_name, user_id):
    text = text.strip()
    
    if text.startswith("/start") or text.startswith("/help") or text.lower() == "menu":
        msg = get_main_menu_text(first_name, user_id)
        keyboard = get_main_menu_keyboard()
        send_message_with_keyboard(chat_id, msg, reply_markup=keyboard)

    # === MENU CREATE AKUN MANUAL (Tetap dipertahankan untuk backup) ===
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

# === SETUP TOMBOL MENU UTAMA (Tombol Biru Kiri Bawah) ===
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

setup_bot_menu()

while True:
    try:
        req = requests.get(f"https://api.telegram.org/bot{BOT_TOKEN}/getUpdates?offset={LAST_UPDATE_ID}", timeout=5)
        data = req.json()
        for result in data.get("result", []):
            LAST_UPDATE_ID = result["update_id"] + 1
            
            if "callback_query" in result:
                process_callback(result["callback_query"])
            
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
