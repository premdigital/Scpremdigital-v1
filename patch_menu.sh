sed -i 's/echo -e " \[13\] Backup & Restore Data VPS"/echo -e " \[13\] Backup \& Restore Data VPS"\'$'\n    echo -e " \[14\] Hubungkan VPS ke Web Auto-Creator"/g' install.sh
sed -i 's/read -p " Pilih Opsi \[0-13\]: " opt/read -p " Pilih Opsi \[0-14\]: " opt/g' install.sh
