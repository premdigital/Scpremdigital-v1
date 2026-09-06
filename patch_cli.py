import re

with open('/app/applet/install.sh', 'r') as f:
    content = f.read()

# Fix CLI menu output
old_cli = '''        echo -e "\n${Y}Akun Berhasil Dibuat!${NC}"
        echo -e "Username : $user"
        echo -e "Password : $pass"
        echo -e "Expired  : $exp"
        echo -e "Host     : $DOMAIN"'''

new_cli = '''        echo -e "\n${Y}✅ AKUN SSH SUKSES DIBUAT${NC}"
        echo -e "━━━━━━━━━━━━━━━━━━"
        echo -e "👤 Username: $user"
        echo -e "🔑 Password: $pass"
        echo -e "🌍 Host: $DOMAIN"
        echo -e "⏳ Durasi: $masaaktif Hari"
        echo -e ""
        echo -e "🔌 Port Info:"
        echo -e "• TLS: 443, 8443"
        echo -e "• HTTP: 80, 8080"
        echo -e "• SlowDNS: 53, 5300"
        echo -e "• SSH OHP: 9080"
        echo -e "• UDP Custom: 1-65535"
        echo -e "• UDPGW: 7100-7600"
        echo -e ""
        echo -e "📥 Payload WS:"
        echo -e "GET / HTTP/1.1[crlf]Host: [host_port][crlf]User-Agent: [ua][crlf]Upgrade: websocket[crlf][crlf]"
        echo -e "━━━━━━━━━━━━━━━━━━"'''

content = content.replace(old_cli, new_cli)

# Fix Web API output
old_api = '''    return jsonify({
        "status": "success",
        "username": username,
        "password": password,
        "expired": exp_date
    })'''

new_api = '''    # Baca Domain
    try:
        with open('/etc/vps-domain.txt', 'r') as f:
            domain = f.read().strip()
    except:
        domain = "IP_VPS"
        
    return jsonify({
        "status": "success",
        "data": {
            "username": username,
            "password": password,
            "host": domain,
            "durasi": f"{expired_days} Hari",
            "port_info": {
                "tls": "443, 8443",
                "http": "80, 8080",
                "slowdns": "53, 5300",
                "ssh_ohp": "9080",
                "udp_custom": "1-65535",
                "udpgw": "7100-7600"
            },
            "payload_ws": "GET / HTTP/1.1[crlf]Host: [host_port][crlf]User-Agent: [ua][crlf]Upgrade: websocket[crlf][crlf]"
        }
    })'''

content = content.replace(old_api, new_api)

with open('/app/applet/install.sh', 'w') as f:
    f.write(content)
