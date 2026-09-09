#!/bin/bash
# ==========================================================
# PremDigital - Script List Akun (Tabel SSH, VMESS, VLESS, TROJAN)
# ==========================================================

C="\e[1;36m"
Y="\e[1;33m"
G="\e[1;32m"
R="\e[1;31m"
NC="\e[0m"

CONFIG_XRAY="/etc/xray/config.json"
XRAY_DB="/etc/premdigital/xray-users.db"
touch "$XRAY_DB" 2>/dev/null
HARI_INI=$(date +%Y-%m-%d)

tabel_ssh() {
    echo -e "${C}==================================================================${NC}"
    echo -e "${Y}                     TABEL DAFTAR AKUN SSH                        ${NC}"
    echo -e "${C}==================================================================${NC}"
    
    mapfile -t users < <(awk -F: '($3>=1000)&&($1!="nobody"){print $1}' /etc/passwd)
    
    if [ ${#users[@]} -eq 0 ]; then
        echo -e " ${R}Tidak ada akun SSH yang terdaftar di VPS.${NC}"
        echo -e "${C}==================================================================${NC}"
        return
    fi

    printf "${Y}%-5s %-18s %-15s %-12s %-10s${NC}\n" "NO" "USERNAME" "EXPIRED" "LIMIT IP" "STATUS"
    echo -e "------------------------------------------------------------------"
    
    i=1
    aktif_count=0
    exp_count=0
    for u in "${users[@]}"; do
        exp=$(chage -l "$u" 2>/dev/null | grep "Account expires" | awk -F": " '{print $2}')
        if [[ -z "$exp" || "$exp" == "never" ]]; then
            exp_display="Never"
            status_display="${G}Aktif${NC}"
            ((aktif_count++))
        else
            exp_clean=$(date -d"$exp" +%Y-%m-%d 2>/dev/null || echo "$exp")
            exp_display="$exp_clean"
            if [[ "$exp_clean" < "$HARI_INI" ]]; then
                status_display="${R}Expired${NC}"
                ((exp_count++))
            else
                status_display="${G}Aktif${NC}"
                ((aktif_count++))
            fi
        fi
        
        limit_val="2 IP"
        if [ -f "/etc/premdigital/multilogin/$u" ]; then
            limit_val="$(cat /etc/premdigital/multilogin/$u 2>/dev/null) IP"
        fi
        
        printf "[%-2d] %-18s %-15s %-12s " "$i" "$u" "$exp_display" "$limit_val"
        echo -e "$status_display"
        ((i++))
    done
    echo -e "${C}==================================================================${NC}"
    echo -e " Total Akun SSH: ${Y}${#users[@]}${NC} (Aktif: ${G}${aktif_count}${NC} | Expired: ${R}${exp_count}${NC})"
}

tabel_xray() {
    proto="$1"
    proto_upper=$(echo "$proto" | tr '[:lower:]' '[:upper:]')
    echo -e "${C}==================================================================${NC}"
    echo -e "${Y}                   TABEL DAFTAR AKUN ${proto_upper}                    ${NC}"
    echo -e "${C}==================================================================${NC}"

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

    # Sinkronisasi akun dari config.json jika ada
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
        echo -e " ${R}Tidak ada akun ${proto_upper} yang terdaftar di VPS.${NC}"
        echo -e "${C}==================================================================${NC}"
        return
    fi

    printf "${Y}%-5s %-18s %-15s %-16s %-10s${NC}\n" "NO" "USERNAME" "EXPIRED" "UUID/PASS" "STATUS"
    echo -e "------------------------------------------------------------------"
    
    i=1
    aktif_count=0
    exp_count=0
    for u in "${users_list[@]}"; do
        raw_exp="${user_exp[$u]:--}"
        if [[ "$raw_exp" == "Aktif" || "$raw_exp" == "-" || -z "$raw_exp" ]]; then
            exp_display="Aktif"
            status_display="${G}Aktif${NC}"
            ((aktif_count++))
        else
            exp_display="$raw_exp"
            if [[ "$raw_exp" < "$HARI_INI" ]]; then
                status_display="${R}Expired${NC}"
                ((exp_count++))
            else
                status_display="${G}Aktif${NC}"
                ((aktif_count++))
            fi
        fi

        uuid_val="${user_uuid[$u]:--}"
        if [ ${#uuid_val} -gt 14 ]; then
            uuid_display="${uuid_val:0:11}..."
        else
            uuid_display="$uuid_val"
        fi

        printf "[%-2d] %-18s %-15s %-16s " "$i" "$u" "$exp_display" "$uuid_display"
        echo -e "$status_display"
        ((i++))
    done
    echo -e "${C}==================================================================${NC}"
    echo -e " Total Akun ${proto_upper}: ${Y}${#users_list[@]}${NC} (Aktif: ${G}${aktif_count}${NC} | Expired: ${R}${exp_count}${NC})"
}

tampil_semua() {
    clear
    tabel_ssh
    echo ""
    tabel_xray "vmess"
    echo ""
    tabel_xray "vless"
    echo ""
    tabel_xray "trojan"
    echo ""
    read -r -p "Tekan [Enter] untuk kembali ke menu..." dummy
}

while true; do
    clear
    echo -e "${C}======================================${NC}"
    echo -e "${Y}        MENU LIST AKUN VPS            ${NC}"
    echo -e "${C}======================================${NC}"
    echo -e " [1] List Tabel Akun SSH"
    echo -e " [2] List Tabel Akun VMESS"
    echo -e " [3] List Tabel Akun VLESS"
    echo -e " [4] List Tabel Akun TROJAN"
    echo -e " [5] Tampilkan Semua Tabel Protokol"
    echo -e " [0] Kembali ke Menu Utama"
    echo -e "${C}======================================${NC}"
    read -rp "Pilih Opsi [0-5]: " opt

    case $opt in
        1)
            clear
            tabel_ssh
            echo ""
            read -r -p "Tekan [Enter] untuk kembali..." dummy
            ;;
        2)
            clear
            tabel_xray "vmess"
            echo ""
            read -r -p "Tekan [Enter] untuk kembali..." dummy
            ;;
        3)
            clear
            tabel_xray "vless"
            echo ""
            read -r -p "Tekan [Enter] untuk kembali..." dummy
            ;;
        4)
            clear
            tabel_xray "trojan"
            echo ""
            read -r -p "Tekan [Enter] untuk kembali..." dummy
            ;;
        5)
            tampil_semua
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
