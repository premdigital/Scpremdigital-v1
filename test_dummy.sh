#!/bin/bash
check_wsproxy() {
    if systemctl is-active --quiet ws-proxy 2>/dev/null || pgrep -f "ws-proxy" >/dev/null 2>&1; then
        echo -e "RUNNING"
    else
        echo -e "STOPPED"
    fi
}
check_wsproxy
