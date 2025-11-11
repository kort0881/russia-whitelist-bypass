# Как поднять VPS для Reality (XRay/VLESS) — Обход белых списков РФ

**Цель:** Настроить VPS с XRay + Reality, чтобы маскировать трафик под `yandex.ru` и обходить DPI при шатдаунах.  
**Тестировалось:** Ubuntu 22.04, МТС/Билайн, ноябрь 2025  
**Время установки:** ~15 минут

---

## Шаг 1: Выбор VPS

| Провайдер        | Локация | Цена     | Рекомендация               |
|------------------|---------|----------|----------------------------|
| Hetzner          | EU/USA  | от 3€    | Лучший (чистые IP)         |
| Vultr            | EU/USA  | от $5    | Хорошо                     |
| DigitalOcean     | EU      | от $6    | Норм                       |
| FirstVDS / Beget | РФ      | от 200₽  | Не бери — блокируют DPI    |

> **Важно:** IP должен быть **не из РФ**, иначе DPI может блокировать трафик.

---

## Шаг 2: Подключаемся к VPS и обновляем систему
```bash
ssh root@ВАШ_IP
apt update && apt upgrade -y
Шаг 3: Установка XRay
bash
Копировать код
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install.sh)"
XRay будет установлен в /usr/local/bin/xray.

Шаг 4: Генерация ключей Reality
bash
Копировать код
xray x25519
Пример вывода:

vbnet
Копировать код
Private key: XXXXXXXXXXXXXXXXXXXXXXXXXXXX
Public key:  YYYYYYYYYYYYYYYYYYYYYYYYYYYY
Сохрани оба ключа — они понадобятся в конфиге.

Шаг 5: Генерация UUID для VLESS
bash
Копировать код
xray uuid
Пример вывода:

Копировать код
123e4567-e89b-12d3-a456-426614174000
Сохрани UUID.

Шаг 6: Создание конфигурационного файла
bash
Копировать код
nano /usr/local/etc/xray/config.json
Пример конфига:

json
Копировать код
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [
          { "id": "123e4567-e89b-12d3-a456-426614174000", "flow": "xtls-rprx-vision" }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "www.yandex.ru:443",
          "xver": 0,
          "serverNames": ["www.yandex.ru"],
          "privateKey": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
          "publicKey": "YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY",
          "shortIds": ["a1b2c3d4"]
        }
      }
    }
  ],
  "outbounds": [{ "protocol": "freedom" }]
}
Заменить:

id → UUID из xray uuid

privateKey / publicKey → ключи из xray x25519

shortIds можно оставить ["a1b2c3d4"] или задать свои.

Шаг 7: Запуск и автозапуск XRay
bash
Копировать код
systemctl restart xray
systemctl enable xray
systemctl status xray
Ожидаемый статус: active (running)

Шаг 8: Автообновление ядра
bash
Копировать код
crontab -e
Добавить:

ruby
Копировать код
0 3 * * * /usr/local/bin/xray update:core
Шаг 9: Подключение клиента (Android / ПК)
Приложения: Nekobox, v2rayNG
Тип подключения: VLESS

Параметры:

Адрес: ВАШ_IP_VPS

Порт: 443

UUID: тот же, что в конфиге

Flow: xtls-rprx-vision

TLS: reality

SNI / Server Name: www.yandex.ru

Public Key: из xray x25519

Short ID: a1b2c3d4

Шаг 10: Полезные команды
bash
Копировать код
xray uuid          # новый UUID
xray x25519        # новые ключи Reality
journalctl -u xray -f  # логи в реальном времени
Шаг 11: Проблемы и решения
Проблема	Решение
Отваливается на 2G	Попробуй dest: vk.com:443
Блок по IP	Сменить VPS или включить Cloudflare CDN
Ошибка handshake	Проверь shortIds и publicKey

Теги: #vps #reality #xray #обход #whitelist

php
Копировать код

---

### Быстро заменить в GitHub (через веб‑интерфейс)
1. Открой `README.md` в репозитории.  
2. Нажми значок карандаша (Edit).  
3. Полностью замени содержимое на текст выше.  
4. Внизу добавь commit message `Fix README: clean formatting` и нажми **Commit changes**.

---

### Я подготовлю и `install_xray.sh`, если нужно
Ниже готовый скрипт `install_xray.sh`. Если хочешь — вставь его в репо как отдельный файл.

```bash
#!/bin/bash
set -euo pipefail

# Обновление
apt update && apt upgrade -y

# Установка Xray
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install.sh)"

# Генерация ключей и UUID (два отдельных вызова, чтобы корректно получить обе пары)
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
      "settings": {
        "clients": [{ "id": "$UUID", "flow": "xtls-rprx-vision" }],
        "decryption": "none"
      },
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

# Запуск
systemctl enable --now xray

echo "Done."
echo "UUID: $UUID"
echo "Private Key: $PRIVATE_KEY"
echo "Public Key: $PUBLIC_KEY"
Как добавить install_xray.sh с правом выполнения корректно (локально):

bash
Копировать код
git clone https://github.com/ТВОЙ_ЛОГИН/имя-репо.git
cd имя-репо
# создать файл install_xray.sh (вставить скрипт)
git add install_xray.sh README.md
git commit -m "Add install script and clean README"
git update-index --add --chmod=+x install_xray.sh
git push origin main
