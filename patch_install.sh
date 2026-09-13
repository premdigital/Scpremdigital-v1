sed -i '/read -p "Masukkan Domain/i \
    read -p "Masukkan API Key Web (Kosongkan jika tidak pakai Web): " input_apikey\
    if [ -n "$input_apikey" ]; then\
        echo "$input_apikey" > /etc/premdigital/web_apikey.txt\
        read -p "Masukkan Server ID / Node ID (Contoh: sg-premium-01): " input_nodeid\
        if [ -n "$input_nodeid" ]; then\
            echo "$input_nodeid" > /etc/premdigital/web_nodeid.txt\
        else\
            echo "Node-01" > /etc/premdigital/web_nodeid.txt\
        fi\
    fi\
' install.sh
