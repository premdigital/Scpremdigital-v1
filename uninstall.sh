#!/bin/bash
echo -e "\e[31mMenghapus instalasi Prem Digital Panel...\e[0m"

# Hapus alias menu
sed -i '/alias menu=/d' ~/.bashrc
source ~/.bashrc

# Hapus folder panel
rm -rf /root/premdigital-panel
rm -f /root/premdigital-panel.zip

# Hapus konfigurasi dan file terkait panel
rm -f /etc/xray/domain
rm -f /etc/xray/bot.json
rm -f /etc/xray/user-db.txt
rm -f /etc/xray/vpn_expiry.txt

# Menghentikan dan menghapus service udpgw jika ada
systemctl stop udpgw 2>/dev/null
systemctl disable udpgw 2>/dev/null
rm -f /etc/systemd/system/udpgw.service
rm -f /usr/local/bin/badvpn-udpgw

echo -e "\e[32mPenghapusan selesai!\e[0m"
