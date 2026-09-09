#!/usr/bin/python3
import requests, time, os, subprocess, json, random, string
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
OWNER_ID = "6010478011"
GROUP_TESTI_ID = "-1004466282250" 

TRIAL_SETTING_FILE = "/etc/premdigital/trial_setting.txt"
TRIAL_LIMIT_FILE = "/etc/premdigital/trial_limit.txt"
SERVER_LIMIT_FILE = "/etc/premdigital/server_limit.txt"
DB_FILE = "/etc/premdigital/users_db.json"

USER_STATE = {}

# --- FUNGSI DATABASE USER ---
def load_db():
    if not os.path.exists(DB_FILE):
        os.makedirs('/etc/premdigital', exist_ok=True)
        with open(DB_FILE, 'w') as f:
            json.dump({}, f)
        return {}
    with open(DB_FILE, 'r') as f:
        try: return json.load(f)
        except: return {}

def save_db(data):
    os.makedirs('/etc/premdigital', exist_ok=True)
    with open(DB_FILE, 'w') as f:
        json.dump(data, f, indent=4)

def get_user(user_id):
    db = load_db()
    uid = str(user_id)
    if uid not in db:
        db[uid] = {"balance": 0, "role": "USER", "trial_count": 0, "last_trial_date": ""}
        if uid == str(OWNER_ID):
            db[uid]["role"] = "ADMIN"
        save_db(db)
    return db[uid]

# --- FUNGSI MANAJEMEN SETTING ---
def get_trial_duration():
    try:
        with open(TRIAL_SETTING_FILE, 'r') as f: return f.read().strip()
    except: return "15 Menit"

def set_trial_duration(duration):
    try:
        os.makedirs('/etc/premdigital', exist_ok=True)
        with open(TRIAL_SETTING_FILE, 'w') as f: f.write(duration)
    except: pass

def get_trial_limit():
    try:
        with open(TRIAL_LIMIT_FILE, 'r') as f: return f.read().strip()
    except: return "1"

def set_trial_limit(limit):
    try:
        os.makedirs('/etc/premdigital', exist_ok=True)
        with open(TRIAL_LIMIT_FILE, 'w') as f: f.write(limit)
    except: pass

def get_server_limit():
    try:
        with open(SERVER_LIMIT_FILE, 'r') as f: return f.read().strip()
    except: return "150"

def set_server_limit(limit):
    try:
        os.makedirs('/etc/premdigital', exist_ok=True)
        with open(SERVER_LIMIT_FILE, 'w') as f: f.write(str(limit))
    except: pass

# --- FUNGSI TELEGRAM BOT API ---
def send_message_with_keyboard(chat_id, text, reply_markup=None):
    url = f"https://api.telegram.org/bot{BOT_TOKEN}/sendMessage"
    payload = {"chat_id": chat_id, "text": text, "parse_mode": "HTML", "disable_web_page_preview": True}
    if reply_markup: payload["reply_markup"] = reply_markup
    try: requests.post(url, json=payload)
    except: pass

def edit_message_with_keyboard(chat_id, message_id, text, reply_markup=None):
    url = f"https://api.telegram.org/bot{BOT_TOKEN}/editMessageText"
    payload = {"chat_id": chat_id, "message_id": message_id, "text": text, "parse_mode": "HTML", "disable_web_page_preview": True}
    if reply_markup: payload["reply_markup"] = reply_markup
    try: requests.post(url, json=payload)
    except: pass

def get_main_menu_text(first_name, user_id):
    user_data = get_user(user_id)
    saldo_str = f"Rp {user_data['balance']:,}".replace(',', '.')
    role_str = user_data['role']
    if str(user_id) == str(OWNER_ID): role_str = "ADMIN / OWNER"
    try: ssh_count = int(subprocess.getoutput("ls -1 /etc/premdigital/multilogin 2>/dev/null | wc -l"))
    except: ssh_count = 0
    vmess_count = vless_count = trojan_count = 0
    total_count = ssh_count + vmess_count + vless_count + trojan_count
    return (
        f"📦━━━━━━━[ <b>PREMDIGITAL</b> ]━━━━━━━📦\n\n"
        f"👋 Selamat datang di <b>VPN AUTO ORDER</b> 💎\n"
        f"Solusi kelola akun VPN cepat, aman, & otomatis 🚀\n\n"
        f"🧭 <b>Informasi Akun (Bot)</b>\n"
        f"┌───────────────────────┐\n"
        f"├ 👤 <b>Nama  :</b> {first_name}\n"
        f"├ 🆔 <b>ID    :</b> <code>{user_id}</code>\n"
        f"├ 💰 <b>Saldo :</b> {saldo_str}\n"
        f"├ 👑 <b>Role  :</b> {role_str}\n"
        f"└───────────────────────┘\n\n"
        f"📊 <b>Akun Aktif</b>\n"
        f"┌───────────────────────┐\n"
        f"│ SSH       : {ssh_count}\n"
        f"│ VMESS     : {vmess_count}\n"
        f"│ VLESS     : {vless_count}\n"
        f"│ TROJAN    : {trojan_count}\n"
        f"├───────────────────────┤\n"
        f"│ 📦 Total  : {total_count}\n"
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
            [{"text": "🛒 Order Akun", "callback_data": "menu_order_akun"}, {"text": "🆓 Trial Akun", "callback_data": "menu_trial_akun"}],
            [{"text": "🔄 Perpanjang", "callback_data": "menu_perpanjang"}, {"text": "💳 Isi Saldo", "callback_data": "menu_isi_saldo"}],
            [{"text": "📋 Daftar Akun Saya", "callback_data": "menu_daftar_akun"}],
            [{"text": "🚀 Upgrade Reseller", "callback_data": "menu_upgrade_reseller"}],
            [{"text": "👨‍💻 Hubungi Admin ↗️", "url": f"https://{ADMIN_CONTACT}"}]
        ]
    }

def get_admin_menu_text():
    return (
        f"🛠 <b>PANEL ADMIN PDI</b>\n"
        f"━━━━━━━━━━━━━━━━━━━━━━\n"
        f"Selamat datang di Control Panel Administrator.\n"
        f"Silakan pilih menu manajemen di bawah ini:"
    )

def get_admin_menu_keyboard():
    return {
        "inline_keyboard": [
            [{"text": "💰 Tambah Saldo User", "callback_data": "admin_add_saldo"}],
            [{"text": "📢 Broadcast Pesan", "callback_data": "admin_broadcast"}],
            [{"text": "⚙️ Pengaturan Trial", "callback_data": "admin_trial_setting"}],
            [{"text": "⚙️ Limit Max Server", "callback_data": "admin_server_limit"}],
            [{"text": "🔙 Kembali ke Main Menu", "callback_data": "back_to_main"}]
        ]
    }

def render_admin_trial_setting(chat_id, message_id):
    current_dur = get_trial_duration()
    current_lim = get_trial_limit()
    lim_label = "Unlimited" if current_lim == "999" else f"{current_lim}x / Hari"
    msg = (
        f"⚙️ <b>PENGATURAN TRIAL AKUN</b>\n"
        f"━━━━━━━━━━━━━━━━━━━━━━\n"
        f"⏱ <b>Durasi Trial :</b> {current_dur}\n"
        f"🛡 <b>Limit per ID :</b> {lim_label}\n\n"
        f"<i>Silakan klik tombol di bawah untuk mengubah pengaturan:</i>"
    )
    keyboard = {
        "inline_keyboard": [
            [{"text": "⏱ 15 Mnt", "callback_data": "set_trial_15 Menit"}, {"text": "⏱ 30 Mnt", "callback_data": "set_trial_30 Menit"}],
            [{"text": "⏱ 1 Jam", "callback_data": "set_trial_1 Jam"}, {"text": "⏱ 1 Hari", "callback_data": "set_trial_1 Hari"}],
            [{"text": "🛡 Limit 1x/Hari", "callback_data": "set_tlimit_1"}, {"text": "🛡 Limit 2x/Hari", "callback_data": "set_tlimit_2"}],
            [{"text": "🛡 Limit 3x/Hari", "callback_data": "set_tlimit_3"}, {"text": "🛡 Unlimited", "callback_data": "set_tlimit_999"}],
            [{"text": "🔙 Kembali", "callback_data": "back_to_admin"}]
        ]
    }
    edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)

def render_admin_server_limit(chat_id, message_id):
    current_limit = get_server_limit()
    msg = (
        f"⚙️ <b>PENGATURAN LIMIT SERVER</b>\n"
        f"━━━━━━━━━━━━━━━━━━━━━━\n"
        f"👥 Limit Maksimal Akun di VPS ini: <b>{current_limit} Akun</b>\n\n"
        f"<i>Silakan pilih atau ketik manual limit yang diinginkan:</i>"
    )
    keyboard = {
        "inline_keyboard": [
            [{"text": "50 Akun", "callback_data": "set_slimit_50"}, {"text": "100 Akun", "callback_data": "set_slimit_100"}],
            [{"text": "150 Akun", "callback_data": "set_slimit_150"}, {"text": "200 Akun", "callback_data": "set_slimit_200"}],
            [{"text": "✍️ Input Manual", "callback_data": "set_slimit_manual"}],
            [{"text": "🔙 Kembali", "callback_data": "back_to_admin"}]
        ]
    }
    edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)


def process_callback(callback_query):
    chat_id = callback_query["message"]["chat"]["id"]
    message_id = callback_query["message"]["message_id"]
    first_name = callback_query["message"]["chat"].get("first_name", "User")
    user_id = callback_query["from"]["id"]
    data = callback_query["data"]
    
    requests.post(f"https://api.telegram.org/bot{BOT_TOKEN}/answerCallbackQuery", json={"callback_query_id": callback_query["id"]})

    if data == "back_to_main":
        if user_id in USER_STATE: del USER_STATE[user_id]
        msg = get_main_menu_text(first_name, user_id)
        keyboard = get_main_menu_keyboard()
        edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)
        
    elif data == "cancel_order":
        if user_id in USER_STATE: del USER_STATE[user_id]
        msg = get_main_menu_text(first_name, user_id)
        keyboard = get_main_menu_keyboard()
        edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)

    elif data == "back_to_admin":
        if user_id in USER_STATE: del USER_STATE[user_id]
        msg = get_admin_menu_text()
        keyboard = get_admin_menu_keyboard()
        edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)

    elif data == "admin_add_saldo":
        msg = "💰 <b>TAMBAH SALDO USER</b>\n━━━━━━━━━━━━━━━━━━━━━━\nUntuk menambah saldo, ketik:\n<code>/addsaldo [ID_USER] [JUMLAH]</code>\nContoh: <code>/addsaldo 123456789 50000</code>"
        keyboard = {"inline_keyboard": [[{"text": "🔙 Kembali", "callback_data": "back_to_admin"}]]}
        edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)

    elif data == "admin_broadcast":
        msg = "📢 <b>BROADCAST PESAN</b>\n━━━━━━━━━━━━━━━━━━━━━━\nKirim pesan massal ke semua member bot dengan:\n<code>/bc [PESAN ANDA]</code>\nContoh: <code>/bc Halo semuanya!</code>"
        keyboard = {"inline_keyboard": [[{"text": "🔙 Kembali", "callback_data": "back_to_admin"}]]}
        edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)

    elif data == "admin_trial_setting":
        render_admin_trial_setting(chat_id, message_id)
        
    elif data == "admin_server_limit":
        render_admin_server_limit(chat_id, message_id)

    elif data.startswith("set_trial_"):
        new_duration = data.split("_", 2)[2]
        set_trial_duration(new_duration)
        requests.post(f"https://api.telegram.org/bot{BOT_TOKEN}/answerCallbackQuery", json={"callback_query_id": callback_query["id"], "text": f"✅ Durasi trial diubah ke {new_duration}!", "show_alert": True})
        render_admin_trial_setting(chat_id, message_id)
        
    elif data.startswith("set_tlimit_"):
        new_limit = data.split("_", 2)[2]
        set_trial_limit(new_limit)
        lim_label = "Unlimited" if new_limit == "999" else f"{new_limit}x / Hari"
        requests.post(f"https://api.telegram.org/bot{BOT_TOKEN}/answerCallbackQuery", json={"callback_query_id": callback_query["id"], "text": f"✅ Limit trial diubah ke {lim_label}!", "show_alert": True})
        render_admin_trial_setting(chat_id, message_id)
        
    elif data.startswith("set_slimit_"):
        val = data.replace("set_slimit_", "")
        if val == "manual":
            USER_STATE[user_id] = {'step': 'set_server_limit'}
            msg = "✍️ <b>INPUT LIMIT MANUAL</b>\n━━━━━━━━━━━━━━━━━━━━━━\nSilakan ketik angka limit maksimal akun untuk VPS ini (Contoh: 150):"
            keyboard = {"inline_keyboard": [[{"text": "⛔ Batal", "callback_data": "admin_server_limit"}]]}
            edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)
        else:
            set_server_limit(val)
            requests.post(f"https://api.telegram.org/bot{BOT_TOKEN}/answerCallbackQuery", json={"callback_query_id": callback_query["id"], "text": f"✅ Limit Server diubah ke {val} Akun!", "show_alert": True})
            render_admin_server_limit(chat_id, message_id)

    elif data in ["menu_order_akun", "menu_trial_akun"]:
        tipe = "ORDER" if data == "menu_order_akun" else "TRIAL"
        msg = f"⚙️ <b>PILIH PROTOKOL/LAYANAN {tipe}</b>\n━━━━━━━━━━━━━━━━━━━━━━\nSilakan pilih jenis layanan VPN yang ingin Anda buat:"
        keyboard = {
            "inline_keyboard": [
                [{"text": "SSH", "callback_data": f"select_{tipe.lower()}_ssh"}, {"text": "VMESS", "callback_data": "menu_coming_soon"}],
                [{"text": "VLESS", "callback_data": "menu_coming_soon"}, {"text": "TROJAN", "callback_data": "menu_coming_soon"}],
                [{"text": "🔙 Kembali", "callback_data": "back_to_main"}]
            ]
        }
        edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)

    elif data.startswith("select_"):
        parts = data.split("_")
        action = parts[1] # order atau trial
        protocol = parts[2].upper()
        
        isp = "Unknown ISP"; country = "Unknown"; country_code = "UN"
        try:
            req_ip = requests.get("http://ip-api.com/json/", timeout=5).json()
            isp = req_ip.get("isp", "Unknown ISP")
            country = req_ip.get("country", "Unknown").upper()
            country_code = req_ip.get("countryCode", "UN")
        except: pass

        try:
            ping_ms = subprocess.getoutput("ping -c 1 8.8.8.8 | grep time= | awk '{print $7}' | cut -d '=' -f2")
            if not ping_ms: ping_ms = "30"
        except: ping_ms = "30"
            
        server_code = f"{country_code}-{isp[:3].upper().replace(' ', '')}-1IP"
        
        # Kalkulasi Total Create Akun Realtime vs Limit Admin
        try: current_acc = int(subprocess.getoutput("ls -1 /etc/premdigital/multilogin 2>/dev/null | wc -l"))
        except: current_acc = 0
        max_limit = get_server_limit()

        msg = (
            f"🌐 <b>{server_code}</b>\n"
            f"📍 Lokasi: {country}\n"
            f"📡 ISP: {isp}\n"
            f"⚡ Ping: {ping_ms} ms 🟢\n"
            f"💰 Harga per hari: Rp200\n"
            f"📅 Harga per 30 hari: Rp6000\n"
            f"📊 Quota: Unlimited\n"
            f"👥 Total Create Akun: {current_acc}/{max_limit}\n"
        )
        
        keyboard = {
            "inline_keyboard": [
                [{"text": server_code, "callback_data": f"do_{action}_{protocol}_{server_code}"}],
                [{"text": "🔙 Kembali", "callback_data": f"menu_{action}_akun"}]
            ]
        }
        edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)

    elif data.startswith("do_"):
        parts = data.split("_")
        action = parts[1]
        protocol = parts[2]
        server = parts[3]
        
        user_id_str = str(user_id)
        db = load_db()
        user_data = get_user(user_id)
        
        if action == "trial":
            # --- CEK LIMIT TRIAL ---
            limit_str = get_trial_limit()
            today = datetime.now().strftime("%Y-%m-%d")
            
            if user_data.get("last_trial_date") != today:
                user_data["trial_count"] = 0
                user_data["last_trial_date"] = today
                
            current_count = user_data.get("trial_count", 0)
            
            if user_data["role"] not in ["RESELLER", "ADMIN"]:
                if limit_str != "999" and current_count >= int(limit_str):
                    requests.post(f"https://api.telegram.org/bot{BOT_TOKEN}/answerCallbackQuery", json={
                        "callback_query_id": callback_query["id"],
                        "text": f"❌ Limit Trial Anda hari ini sudah habis ({limit_str}x).",
                        "show_alert": True
                    })
                    return
            
            # --- GENERATE AKUN TRIAL OTOMATIS ---
            rnd_user = ''.join(random.choices(string.ascii_lowercase + string.digits, k=4))
            rnd_pass = ''.join(random.choices(string.ascii_lowercase + string.digits, k=5))
            
            user = f"trial{rnd_user}"
            pwd = rnd_pass
            ip_limit = "1"
            kuota_gb = "5"
            
            exp_date = (datetime.now() + timedelta(days=1)).strftime('%Y-%m-%d')
            os.system(f'useradd -e {exp_date} -m -s /bin/false -M {user}')
            os.system(f'echo "{user}:{pwd}" | chpasswd')
            os.system('mkdir -p /etc/premdigital/multilogin /etc/premdigital/user_quota')
            os.system(f'echo "{ip_limit}" > /etc/premdigital/multilogin/{user}')
            os.system(f'echo "{kuota_gb}" > /etc/premdigital/user_quota/{user}')
            
            if user_data["role"] not in ["RESELLER", "ADMIN"]:
                user_data["trial_count"] = current_count + 1
                db[user_id_str] = user_data
                save_db(db)
                
            durasi_label = get_trial_duration()
            
            msg = (
                f"<b>✅ AKUN TRIAL {protocol.upper()} BERHASIL DIBUAT</b>\n"
                f"━━━━━━━━━━━━━━━━━━━━━━\n"
                f"👤 <b>Username :</b> <code>{user}</code>\n"
                f"🔑 <b>Password :</b> <code>{pwd}</code>\n"
                f"🌐 <b>Host/IP  :</b> <code>{DOMAIN}</code>\n"
                f"⏳ <b>Durasi   :</b> {durasi_label}\n"
                f"📅 <b>Expired  :</b> {exp_date}\n"
                f"📱 <b>Limit IP :</b> {ip_limit} Device\n"
                f"📦 <b>Kuota    :</b> {kuota_gb} GB\n"
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
            keyboard = {"inline_keyboard": [[{"text": "🔙 Kembali", "callback_data": f"select_{action}_{protocol.lower()}"}]]}
            edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)
            
            MSG_GROUP = (
                f"📢 <b>NOTIFIKASI TRIAL AKUN</b>\n"
                f"━━━━━━━━━━━━━━━━━━━━━━\n"
                f"👤 <b>Pelanggan :</b> <a href='tg://user?id={user_id}'>{first_name}</a>\n"
                f"🛠 <b>Layanan   :</b> {protocol.upper()}\n"
                f"⏳ <b>Durasi    :</b> {durasi_label}\n"
                f"📱 <b>Limit IP  :</b> {ip_limit} Device\n"
                f"✅ <b>Status    :</b> Berhasil (Sukses)\n"
                f"━━━━━━━━━━━━━━━━━━━━━━\n"
                f"<i>🚀 Powered by PremDigital AutoBot</i>"
            )
            send_message_with_keyboard(GROUP_TESTI_ID, MSG_GROUP)

        else:
            # === JIKA ACTION ADALAH ORDER (PEMBELIAN) ===
            USER_STATE[user_id] = {'step': 'username', 'server': server, 'protocol': protocol}
            msg = (
                f"📝 <b>PEMBUATAN AKUN {protocol.upper()}</b>\n"
                f"━━━━━━━━━━━━━━━━━━━━━━\n"
                f"Server : <b>{server}</b>\n\n"
                f"Silakan masukkan <b>username</b>:\n"
                f"<i>(⚠️ Username tidak boleh menggunakan huruf kapital/spasi. Gunakan huruf kecil & angka saja)</i>"
            )
            keyboard = {"inline_keyboard": [[{"text": "⛔ Batal", "callback_data": "cancel_order"}]]}
            edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)

    elif data == "menu_isi_saldo":
        msg = f"💰 <b>INPUT NOMINAL DEPOSIT</b>\n━━━━━━━━━━━━━━━━━━━━━━\nMetode: QRIS Otomatis\nLimit: Rp 1.000 - Rp 500.000\n\nSilakan ketik nominal deposit yang diinginkan.\nContoh: 10000"
        keyboard = {"inline_keyboard": [[{"text": "⛔ Batal", "callback_data": "back_to_main"}]]}
        edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)

    elif data == "menu_upgrade_reseller":
        user_data = get_user(user_id)
        if user_data["role"] in ["RESELLER", "ADMIN"]:
            msg = f"✅ <b>ANDA SUDAH RESELLER</b>\n━━━━━━━━━━━━━━━━━━━━━━\nStatus Anda saat ini sudah RESELLER / ADMIN.\nNikmati harga khusus dan fitur trial tanpa batas!"
            keyboard = {"inline_keyboard": [[{"text": "🔙 Kembali", "callback_data": "back_to_main"}]]}
            edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)
        else:
            msg = f"🚀 <b>UPGRADE RESELLER</b>\n━━━━━━━━━━━━━━━━━━━━━━\nMenjadi reseller memberikan keuntungan:\n✅ Harga Lebih Murah\n✅ Trial Akun TANPA BATAS\n✅ Prioritas Support\n\n💡 <b>Cara Upgrade:</b>\nSistem akan memotong Saldo Anda sebesar Rp 25.000."
            keyboard = {
                "inline_keyboard": [
                    [{"text": "💸 Bayar Rp 25.000 (Potong Saldo)", "callback_data": "do_upgrade_reseller"}],
                    [{"text": "🔙 Kembali", "callback_data": "back_to_main"}]]
            }
            edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)
            
    elif data == "do_upgrade_reseller":
        db = load_db()
        uid = str(user_id)
        if uid in db:
            if db[uid]["balance"] >= 25000:
                db[uid]["balance"] -= 25000
                db[uid]["role"] = "RESELLER"
                save_db(db)
                requests.post(f"https://api.telegram.org/bot{BOT_TOKEN}/answerCallbackQuery", json={"callback_query_id": callback_query["id"], "text": "🎉 SELAMAT! Anda resmi menjadi RESELLER.", "show_alert": True})
                msg = get_main_menu_text(first_name, user_id)
                keyboard = get_main_menu_keyboard()
                edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)
            else:
                requests.post(f"https://api.telegram.org/bot{BOT_TOKEN}/answerCallbackQuery", json={"callback_query_id": callback_query["id"], "text": "❌ Saldo tidak cukup! Silakan isi saldo minimal Rp 25.000.", "show_alert": True})

    elif data == "menu_coming_soon":
        requests.post(f"https://api.telegram.org/bot{BOT_TOKEN}/answerCallbackQuery", json={"callback_query_id": callback_query["id"], "text": "⚠️ Fitur ini sedang dalam tahap pengembangan.", "show_alert": True})

def process_message(text, chat_id, first_name, user_id):
    text = text.strip()
    get_user(user_id)
    
    # --- LOGIKA CHAT INTERAKTIF ORDER AKUN & LIMIT SERVER ---
    if user_id in USER_STATE and not text.startswith("/"):
        state = USER_STATE[user_id]
        
        # Setup Server Limit Manual
        if state['step'] == 'set_server_limit':
            if not text.isdigit():
                send_message_with_keyboard(chat_id, "❌ <b>Format salah!</b>\nHarap masukkan angka saja.\n\nSilakan ketik angka limit maksimal:")
                return
            set_server_limit(text)
            del USER_STATE[user_id]
            send_message_with_keyboard(chat_id, f"✅ Limit maksimal server berhasil diubah menjadi <b>{text}</b> Akun.")
            
            msg = get_admin_menu_text()
            keyboard = get_admin_menu_keyboard()
            send_message_with_keyboard(chat_id, msg, reply_markup=keyboard)
            return

        # Setup Username
        elif state['step'] == 'username':
            if text != text.lower() or not text.isalnum():
                send_message_with_keyboard(chat_id, "❌ <b>Username tidak boleh menggunakan huruf kapital atau spasi.</b>\nGunakan huruf kecil dan angka saja.\n\nSilakan masukkan username kembali:")
                return
            state['username'] = text
            state['step'] = 'password'
            send_message_with_keyboard(chat_id, "✅ <i>Username diterima.</i>\n\nSilakan masukkan <b>password</b>:\n<i>(⚠️ Sama seperti username, huruf kecil & angka saja)</i>")
            return
            
        # Setup Password
        elif state['step'] == 'password':
            if text != text.lower() or not text.isalnum():
                send_message_with_keyboard(chat_id, "❌ <b>Password tidak boleh menggunakan huruf kapital atau spasi.</b>\nGunakan huruf kecil dan angka saja.\n\nSilakan masukkan password kembali:")
                return
            state['password'] = text
            state['step'] = 'duration'
            send_message_with_keyboard(chat_id, "✅ <i>Password diterima.</i>\n\nSilakan masukkan <b>masa aktif (hari)</b>:\n<i>Contoh: 30</i>")
            return
            
        # Setup Duration
        elif state['step'] == 'duration':
            if not text.isdigit() or int(text) < 1 or int(text) > 365:
                send_message_with_keyboard(chat_id, "❌ <b>Masa aktif tidak valid!</b>\nHarus berupa angka (1 - 365).\n\nSilakan masukkan masa aktif kembali:")
                return
            
            hari = int(text)
            user_data = get_user(user_id)
            
            harga_per_hari = 150 if user_data['role'] in ["RESELLER", "ADMIN"] else 200
            total_harga = hari * harga_per_hari
            
            if user_data['role'] not in ["ADMIN", "OWNER"] and user_data['balance'] < total_harga:
                send_message_with_keyboard(chat_id, f"❌ <b>Saldo tidak mencukupi!</b>\n\nTotal Harga : Rp {total_harga:,}\nSaldo Anda : Rp {user_data['balance']:,}\n\nSilakan klik /start dan isi saldo terlebih dahulu.")
                del USER_STATE[user_id]
                return
                
            if user_data['role'] not in ["ADMIN", "OWNER"]:
                db = load_db()
                db[str(user_id)]["balance"] -= total_harga
                save_db(db)
                user_data['balance'] -= total_harga
            
            send_message_with_keyboard(chat_id, "⏳ <i>Memproses pesanan, mohon tunggu sebentar...</i>")
            
            user_ssh = state['username']
            pwd_ssh = state['password']
            protocol = state['protocol']
            ip_limit = "2"
            kuota_gb = "70"
            
            try: exp_date = (datetime.now() + timedelta(days=hari)).strftime('%Y-%m-%d')
            except: exp_date = (datetime.now() + timedelta(days=30)).strftime('%Y-%m-%d')

            os.system(f'useradd -e {exp_date} -m -s /bin/false -M {user_ssh}')
            os.system(f'echo "{user_ssh}:{pwd_ssh}" | chpasswd')
            os.system('mkdir -p /etc/premdigital/multilogin /etc/premdigital/user_quota')
            os.system(f'echo "{ip_limit}" > /etc/premdigital/multilogin/{user_ssh}')
            os.system(f'echo "{kuota_gb}" > /etc/premdigital/user_quota/{user_ssh}')
            
            MSG = (
                f"<b>✅ PEMBELIAN AKUN {protocol.upper()} BERHASIL</b>\n"
                f"━━━━━━━━━━━━━━━━━━━━━━\n"
                f"👤 <b>Username :</b> <code>{user_ssh}</code>\n"
                f"🔑 <b>Password :</b> <code>{pwd_ssh}</code>\n"
                f"🌐 <b>Host/IP  :</b> <code>{DOMAIN}</code>\n"
                f"⏳ <b>Durasi   :</b> {hari} Hari\n"
                f"📅 <b>Expired  :</b> {exp_date}\n"
                f"📱 <b>Limit IP :</b> {ip_limit} Device\n"
                f"📦 <b>Kuota    :</b> {kuota_gb} GB\n"
                f"━━━━━━━━━━━━━━━━━━━━━━\n"
                f"💰 <b>Harga    :</b> Rp {total_harga:,}\n"
                f"💳 <b>Sisa Saldo:</b> Rp {user_data['balance']:,}\n"
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
            
            MSG_GROUP = (
                f"📢 <b>NOTIFIKASI ORDER AKUN</b>\n"
                f"━━━━━━━━━━━━━━━━━━━━━━\n"
                f"👤 <b>Pelanggan :</b> <a href='tg://user?id={user_id}'>{first_name}</a>\n"
                f"🛠 <b>Layanan   :</b> {protocol.upper()}\n"
                f"⏳ <b>Durasi    :</b> {hari} Hari\n"
                f"📱 <b>Limit IP  :</b> {ip_limit} Device\n"
                f"✅ <b>Status    :</b> Berhasil (Sukses)\n"
                f"━━━━━━━━━━━━━━━━━━━━━━\n"
                f"<i>🚀 Powered by PremDigital AutoBot</i>"
            )
            send_message_with_keyboard(GROUP_TESTI_ID, MSG_GROUP)
            
            del USER_STATE[user_id]
            return

    # JIKA USER MENGIRIM PERINTAH (/), BATALKAN SESI INTERAKTIF JIKA ADA
    if text.startswith("/"):
        if user_id in USER_STATE:
            del USER_STATE[user_id]
            
        if text.startswith("/start") or text.startswith("/help") or text.lower() == "/menu":
            msg = get_main_menu_text(first_name, user_id)
            keyboard = get_main_menu_keyboard()
            send_message_with_keyboard(chat_id, msg, reply_markup=keyboard)
            
        elif text.startswith("/admin"):
            if str(user_id) == str(OWNER_ID):
                msg = get_admin_menu_text()
                keyboard = get_admin_menu_keyboard()
                send_message_with_keyboard(chat_id, msg, reply_markup=keyboard)
            else:
                send_message_with_keyboard(chat_id, "⛔ <b>Akses Ditolak!</b> Anda bukan Administrator.")
                
        elif text.startswith("/addsaldo"):
            if str(user_id) == str(OWNER_ID):
                parts = text.split()
                if len(parts) == 3:
                    target_id = parts[1]
                    try:
                        amount = int(parts[2])
                        db = load_db()
                        if target_id in db:
                            db[target_id]["balance"] += amount
                            save_db(db)
                            send_message_with_keyboard(chat_id, f"✅ Berhasil menambah saldo <b>Rp {amount:,}</b> ke ID <code>{target_id}</code>")
                            send_message_with_keyboard(target_id, f"💰 <b>SALDO MASUK!</b>\nAdmin telah menambahkan saldo sebesar <b>Rp {amount:,}</b> ke akun Anda.")
                        else:
                            send_message_with_keyboard(chat_id, "❌ ID User tidak ditemukan di database.")
                    except: send_message_with_keyboard(chat_id, "❌ Format salah. Jumlah harus berupa angka tanpa titik.")
                else: send_message_with_keyboard(chat_id, "❌ Format: <code>/addsaldo [ID] [JUMLAH]</code>")
                    
        elif text.startswith("/bc"):
            if str(user_id) == str(OWNER_ID):
                pesan = text.replace("/bc ", "")
                if pesan and pesan != "/bc":
                    db = load_db()
                    sukses = 0
                    for uid in db.keys():
                        try:
                            send_message_with_keyboard(uid, f"📢 <b>BROADCAST ADMIN</b>\n━━━━━━━━━━━━━━━━━━━━━━\n{pesan}")
                            sukses += 1
                            time.sleep(0.1)
                        except: pass
                    send_message_with_keyboard(chat_id, f"✅ Broadcast selesai dikirim ke {sukses} user.")
                else: send_message_with_keyboard(chat_id, "❌ Format: <code>/bc [PESAN ANDA]</code>")

def setup_bot_menu():
    url = f"https://api.telegram.org/bot{BOT_TOKEN}/setMyCommands"
    commands = {"commands": [{"command": "start", "description": "Tampilkan Main Menu"}, {"command": "admin", "description": "Admin PDI"}]}
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
                if text: process_message(text, chat_id, first_name, user_id)
    except: pass
    time.sleep(2)
