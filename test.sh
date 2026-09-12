#!/bin/bash
C="\e[36m"
NC="\e[0m"
CLIENT_NAME="Arivpnstore"
SISA_HARI=30
echo -e "${C}┌──────────────────────────────────────┐${NC}"
printf "${C}│${NC}  Version     : %-20s ${C}│${NC}\n" "SPv25.8.31"
printf "${C}│${NC}  Order By    : %-20s ${C}│${NC}\n" "Premdigital"
printf "${C}│${NC}  Client Name : %-20s ${C}│${NC}\n" "$CLIENT_NAME"
printf "${C}│${NC}  Expiry In   : %-20s ${C}│${NC}\n" "$SISA_HARI Days"
echo -e "${C}└──────────────────────────────────────┘${NC}"
