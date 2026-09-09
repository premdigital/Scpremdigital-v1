#!/bin/bash
# ==========================================================
# PremDigital - Script Hapus Akun (Pilihan SSH, VMESS, VLESS, TROJAN)
# ==========================================================

C="\e[1;36m"
Y="\e[1;33m"
G="\e[1;32m"
R="\e[1;31m"
NC="\e[0m"

CONFIG_XRAY="/etc/xray/config.json"
XRAY_DB="/etc/premdigital/xray-users.db"
touch "$XRAY_DB" 2>/dev/null

hapus_ssh() {
    clear
    echo -e "${C}======================================================${NC}"
    echo -e "${Y}                 HAPUS AKUN SSH                       ${NC}"
    echo -e "${C}======================================================${NC}"
    
    # Ambil semua user SSH biasa (UID >= 1000)
    mapfile -t users < <(awk -F: '($3>=1000)&&($1!="nobody"){print $1}' /etc/passwd)
    
    if [ ${#users[@]} -eq 0 ]; then
        echo -e "${R}Tidak ada akun SSH yang terdaftar di VPS.${NC}"
        echo -e "${C}======================================================${NC}"
        read -r -p "Tekan [Enter] untuk kembali..." dummy
        return
    fi

    printf "${Y}%-5s %-16s %-14s %-10s${NC}\n" "NO" "USERNAME" "EXPIRED" "LIMIT IP"
    echo -e "------------------------------------------------------"
    
    i=1
    for u in "${users[@]}"; do
        exp=$(chage -l "$u" 2>/dev/null | grep "Account expires" | awk -F": " '{print $2}')
        if [[ -z "$exp" || "$exp" == "never" ]]; then
            exp_display="Never"
        else
            exp_display=$(date -d"$exp" +%Y-%m-%d 2>/dev/null || echo "$exp")
        fi
        
        limit_val="2 IP"
        if [ -f "/etc/premdigital/multilogin/$u" ]; then
            limit_val="$(cat /etc/premdigital/multilogin/$u 2>/dev/null) IP"
        fi
        
        printf "[%-2d] %-16s %-14s %-10s\n" "$i" "$u" "$exp_display" "$limit_val"
        ((i++))
    done
    echo -e "${C}======================================================${NC}"
    echo -e "Ketik [0] untuk batal."
    read -rp "Pilih Nomor Akun atau Nama User yang ingin dihapus: " pilih

    [ "$pilih" == "0" ] || [ -z "$pilih" ] && return

    target_user=""
    if [[ "$pilih" =~ ^[0-9]+$ ]] && [ "$pilih" -ge 1 ] && [ "$pilih" -le ${#users[@]} ]; then
        target_user="${users[$((pilih-1))]}"
    else
        for u in "${users[@]}"; do
            if [ "$u" == "$pilih" ]; then
                target_user="$u"
                break
            fi
        done
    fi

    if [ -z "$target_user" ]; then
        echo -e "${R}Pilihan tidak valid!${NC}"
        sleep 1.5
        return
    fi

    read -rp "Yakin ingin menghapus akun SSH '$target_user'? [y/N]: " confirm
    if [[ "$confirm" =~ ^[yY]$ ]]; then
        userdel -f "$target_user" 2>/dev/null
        rm -f "/etc/premdigital/multilogin/$target_user" 2>/dev/null
        killall -u "$target_user" 2>/dev/null
        echo -e "${G}Akun SSH '$target_user' berhasil dihapus!${NC}"
    else
        echo -e "${Y}Penghapusan dibatalkan.${NC}"
    fi
    sleep 1.5
}

hapus_xray_proto() {
    proto="$1"
    proto_upper=$(echo "$proto" | tr '[:lower:]' '[:upper:]')
    clear
    echo -e "${C}======================================================${NC}"
    echo -e "${Y}                 HAPUS AKUN ${proto_upper}                 ${NC}"
    echo -e "${C}======================================================${NC}"

    # Cari user dari /etc/premdigital/xray-users.db dan config.json
    declare -A user_exp
    declare -A user_uuid
    users_list=()

    if [ -f "$XRAY_DB" ]; then
        while IFS=" | " read -r xu xuuid xexp xp; do
            if [ "$xp" == "$proto" ] && [ -n "$xu" ]; then
                if [[ ! " ${users_list[*]} " =~ " ${xu} " ]]; then
                    users_list+=("$xu")
                    user_exp["$xu"]="$xexp"
                    user_uuid["$xu"]="$xuuid"
                fi
            fi
        done < "$XRAY_DB"
    fi

    # Cek juga langsung dari config.json jika belum ada di DB
    if [ -f "$CONFIG_XRAY" ]; then
        while read -r c_email; do
            if [ -n "$c_email" ] && [[ ! " ${users_list[*]} " =~ " ${c_email} " ]]; then
                users_list+=("$c_email")
                user_exp["$c_email"]="Aktif"
                user_uuid["$c_email"]="-"
            fi
        done < <(python3 -c "
import json
try:
    with open('$CONFIG_XRAY') as f:
        d = json.load(f)
    for ib in d.get('inbounds', []):
        if ib.get('protocol') == '$proto':
            for c in ib.get('settings', {}).get('clients', []):
                email = c.get('email')
                if email:
                    print(email)
except:
    pass
" 2>/dev/null)
    fi

    if [ ${#users_list[@]} -eq 0 ]; then
        echo -e "${R}Tidak ada akun ${proto_upper} yang ditemukan.${NC}"
        echo -e "${C}======================================================${NC}"
        read -r -p "Tekan [Enter] untuk kembali..." dummy
        return
    fi

    printf "${Y}%-5s %-18s %-14s %-16s${NC}\n" "NO" "USERNAME" "EXPIRED" "STATUS"
    echo -e "------------------------------------------------------"
    i=1
    for u in "${users_list[@]}"; do
        printf "[%-2d] %-18s %-14s %-16s\n" "$i" "$u" "${user_exp[$u]:--}" "Aktif"
        ((i++))
    done
    echo -e "${C}======================================================${NC}"
    echo -e "Ketik [0] untuk batal."
    read -rp "Pilih Nomor Akun atau Username yang ingin dihapus: " pilih

    [ "$pilih" == "0" ] || [ -z "$pilih" ] && return

    target_user=""
    if [[ "$pilih" =~ ^[0-9]+$ ]] && [ "$pilih" -ge 1 ] && [ "$pilih" -le ${#users_list[@]} ]; then
        target_user="${users_list[$((pilih-1))]}"
    else
        for u in "${users_list[@]}"; do
            if [ "$u" == "$pilih" ]; then
                target_user="$u"
                break
            fi
        done
    fi

    if [ -z "$target_user" ]; then
        echo -e "${R}Pilihan tidak valid!${NC}"
        sleep 1.5
        return
    fi

    read -rp "Yakin ingin menghapus akun ${proto_upper} '$target_user'? [y/N]: " confirm
    if [[ "$confirm" =~ ^[yY]$ ]]; then
        # Hapus dari config.json
        if [ -f "$CONFIG_XRAY" ]; then
            python3 - <<EOF
import json
try:
    with open("$CONFIG_XRAY", "r") as f:
        data = json.load(f)
    changed = False
    for ib in data.get("inbounds", []):
        if ib.get("protocol") == "$proto":
            clients = ib.get("settings", {}).get("clients", [])
            new_clients = [c for c in clients if c.get("email") != "$target_user"]
            if len(new_clients) != len(clients):
                ib["settings"]["clients"] = new_clients
                changed = True
    if changed:
        with open("$CONFIG_XRAY", "w") as f:
            json.dump(data, f, indent=2)
except Exception as e:
    print("Error:", e)
EOF
            systemctl restart xray >/dev/null 2>&1
        fi

        # Hapus dari DB
        if [ -f "$XRAY_DB" ]; then
            sed -i "/^$target_user |/d" "$XRAY_DB" 2>/dev/null
        fi

        echo -e "${G}Akun ${proto_upper} '$target_user' berhasil dihapus!${NC}"
    else
        echo -e "${Y}Penghapusan dibatalkan.${NC}"
    fi
    sleep 1.5
}

while true; do
    clear
    echo -e "${C}======================================${NC}"
    echo -e "${Y}           MENU HAPUS AKUN            ${NC}"
    echo -e "${C}======================================${NC}"
    echo -e " [1] Hapus Akun SSH"
    echo -e " [2] Hapus Akun VMESS"
    echo -e " [3] Hapus Akun VLESS"
    echo -e " [4] Hapus Akun TROJAN"
    echo -e " [0] Kembali ke Menu Utama"
    echo -e "${C}======================================${NC}"
    read -rp "Pilih Opsi [0-4]: " opt

    case $opt in
        1)
            hapus_ssh
            ;;
        2)
            hapus_xray_proto "vmess"
            ;;
        3)
            hapus_xray_proto "vless"
            ;;
        4)
            hapus_xray_proto "trojan"
            ;;
        0)
            break
            ;;
        *)
            echo -e "${R}Pilihan tidak valid!${NC}"
            sleep 1
            ;;
    esac
done
