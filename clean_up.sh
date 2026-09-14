sed -i '/    IP=$(cat \/tmp\/.cached_ip 2>\/dev\/null)/d' install.sh
sed -i '/while true; do/a \    IP=$(cat \/tmp\/.cached_ip 2>\/dev\/null)\n    ISP=$(cat \/tmp\/.cached_isp 2>\/dev\/null || echo "PremDigital Cloud")\n    CITY=$(cat \/tmp\/.cached_city 2>\/dev\/null || echo "Singapore")' install.sh
