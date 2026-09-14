#!/bin/bash
# Simpan informasi statis ke cache saat instalasi
IP=$(curl -s -m 2 ipv4.icanhazip.com || echo "127.0.0.1")
ISP=$(curl -s -m 2 "https://ipinfo.io/${IP}/org" | sed -e 's/^AS[0-9]* //' | tr -d '"')
CITY=$(curl -s -m 2 "https://ipinfo.io/${IP}/city" | tr -d '"')
echo "$IP" > /tmp/.cached_ip
echo "$ISP" > /tmp/.cached_isp
echo "$CITY" > /tmp/.cached_city
