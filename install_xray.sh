#!/bin/bash
set -euo pipefail

# Обновление системы
apt update && apt upgrade -y

# Установка Xray
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install.sh)"

# Генерация ключей и UUID
PRIVATE_KEY=$(xray x25519 | awk '/Private key:/ {print $3}')
PUBLIC_KEY=$(xray x25519 | awk '/Public key:/ {print $3}')
UUID=$(xray uuid)

# Создание конфига
cat > /usr/local/etc/xray/config.json <<EOF
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "port": 443,
      "protocol": "vless",
      "settings": { "clients": [{ "id": "$UUID", "flow": "xtls-rprx-vision" }], "decryption": "none" },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "www.yandex.ru:443",
          "xver": 0,
          "serverNames": ["www.yandex.ru"],
          "privateKey": "$PRIVATE_KEY",
          "publicKey": "$PUBLIC_KEY",
          "shortIds": ["a1b2c3d4"]
        }
      }
    }
  ],
  "outbounds": [{ "protocol": "freedom" }]
}
EOF

# Включаем и запускаем
systemctl enable --now xray

echo "Done."
echo "UUID: $UUID"
echo "Private Key: $PRIVATE_KEY"
echo "Public Key: $PUBLIC_KEY"
