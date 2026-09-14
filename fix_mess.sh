sed -i '/    ISP=$(cat \/tmp\/.cached_isp 2>\/dev\/null)/d' install.sh
sed -i '/    CITY=$(cat \/tmp\/.cached_city 2>\/dev\/null)/d' install.sh
sed -i '/    if \[ -z "$IP" \]; then/a \        ISP=$(cat \/tmp\/.cached_isp 2>\/dev\/null || echo "PremDigital Cloud")\n        CITY=$(cat \/tmp\/.cached_city 2>\/dev\/null || echo "Singapore")' install.sh
