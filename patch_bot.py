import re

with open('/app/applet/install.sh', 'r') as f:
    content = f.read()

# Fix DOMAIN variable in bot script to read from file
content = content.replace("🌍 Host: {$(cat /etc/vps-domain.txt)}", "🌍 Host: {DOMAIN}")
content = content.replace("BOT_TOKEN = \"ISI_TOKEN_BOT_DISINI\"\nLAST_UPDATE_ID = 0", "BOT_TOKEN = \"ISI_TOKEN_BOT_DISINI\"\nLAST_UPDATE_ID = 0\n\ntry:\n    with open('/etc/vps-domain.txt', 'r') as f:\n        DOMAIN = f.read().strip()\nexcept:\n    DOMAIN = \"IP_VPS\"\n")

with open('/app/applet/install.sh', 'w') as f:
    f.write(content)
