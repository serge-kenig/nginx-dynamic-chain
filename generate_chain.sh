#!/bin/bash

# Значения по умолчанию
NGINX_COUNT=5
PORT_START=8081

# Функция вывода справки
show_help() {
    echo -e "Использование: $0 [ОПЦИИ]"
    echo -e "Генератор инфраструктуры стенда 'nginx-dynamic-chain'.\n"
    echo -e "Опции:"
    echo -e "  -h           Вывод этой справки"
    echo -e "  -c КОЛ_ВО    Количество nginx-нод в цепочке (по умолчанию: 5)"
    echo -e "  -p ПОРТ      Начальный порт для нод цепочки (по умолчанию: 8081)"
    echo -e "\nПример запуска с флагами:"
    echo -e "  $0 -c 7 -p 7777"
    echo -e "\nЕсли запустить скрипт без опций, включится интерактивный режим запроса параметров."
    exit 0
}

# ============================================================
# Инициализация параметров (Флаги CLI или Интерактивно)
# ============================================================
if [ $# -eq 0 ]; then
    # Интерактивный режим, если скрипт запущен без флагов
    read -p "Сколько nginx-нод поднять в цепочке? [по умолчанию: ${NGINX_COUNT}]: " input_count
    NGINX_COUNT=${input_count:-5}
    
    read -p "Какой начальный порт для нод? [по умолчанию: ${PORT_START}]: " input_port
    PORT_START=${input_port:-8081}
else
    # Разбор стандартных флагов через getopts
    while getopts "hc:p:" opt; do
        case ${opt} in
            h )
                show_help
                ;;
            c )
                NGINX_COUNT=$OPTARG
                ;;
            p )
                PORT_START=$OPTARG
                ;;
            \? )
                echo -e "\nОшибка: Неверный флаг. Используйте $0 -h для вывода справки." >&2
                exit 1
                ;;
        esac
    done
fi

# Вычисляем конечный порт после того, как определились с переменными
PORT_END=$((PORT_START + NGINX_COUNT - 1))

echo "Генерация конфигурации для $NGINX_COUNT нод (порты $PORT_START-$PORT_END)..."

# Создаем директории, если их нет
mkdir -p nginx/my-includes

# ============================================================
# 1. Генерация nginx/load_balancer.conf
# ============================================================
cat <<EOF > nginx/load_balancer.conf
events {
    worker_connections 1024;
}

http {
    resolver 127.0.0.11 valid=5s;

    # Определяем реальный ip-клиента
    include /etc/nginx/my-includes/geoip.conf;

    upstream backend_chain {
EOF

for (( i=1; i<=NGINX_COUNT; i++ )); do
    echo "        server nginx${i}:80;" >> nginx/load_balancer.conf
done

cat <<EOF >> nginx/load_balancer.conf
    }
    # Лимиты
    include /etc/nginx/my-includes/limit.conf;
    
    server {
        listen 80;
        server_name _;

        # Безопасность заголовков
        include /etc/nginx/my-includes/security.conf;

        location / {
            # Еще настройки
            include /etc/nginx/my-includes/proxy-params.conf;

            proxy_set_header X-Real-IP \$first_client_ip;
            proxy_set_header X-Forwarded-For "\$first_client_ip, \$server_addr";
            proxy_set_header X-Internal-Chain "true"; 
            proxy_set_header Host \$host;
            proxy_pass http://backend_chain;
        }
    }
}
EOF

# ============================================================
# 2. Генерация docker-compose.yml
# ============================================================
cat <<EOF > docker-compose.yml
services:
  app:
    image: php:8.2-apache
    container_name: app
    restart: unless-stopped    
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:80 || exit 1"]
      interval: 5s
      timeout: 3s
      retries: 3
    volumes:
      - ./app_code:/var/www/html/:ro
    networks:
      - backend_net
EOF

for (( i=1; i<=NGINX_COUNT; i++ )); do
    PORT=$((PORT_START + i - 1))
    
    # Логика определения следующего хопа
    if [ "$i" -eq 1 ] && [ "$NGINX_COUNT" -gt 1 ]; then
        NEXT_HOP="nginx2"
    elif [ "$i" -eq "$NGINX_COUNT" ] && [ "$NGINX_COUNT" -gt 1 ]; then
        NEXT_HOP="app"
    elif [ "$NGINX_COUNT" -eq 1 ]; then
        NEXT_HOP="app"
    else
        NEXT_HOP="nginx$((i + 1))"
    fi

cat <<EOF >> docker-compose.yml

  nginx${i}:
    image: nginx:1.27.4-alpine
    container_name: nginx${i}
    restart: unless-stopped
    depends_on:
      app:
        condition: service_healthy
    volumes:
      - ./nginx/default.conf.template:/etc/nginx/template/default.conf.template:ro
      - ./nginx/my-includes/:/etc/nginx/my-includes/:ro
    ports:
      - "${PORT}:80"
    environment:
      - NEXT_HOP=${NEXT_HOP}
    command: >
      sh -c "envsubst '\$\${NEXT_HOP}' < /etc/nginx/template/default.conf.template > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"
    networks:
      - backend_net
EOF
done

cat <<EOF >> docker-compose.yml

  load_balancer:
    image: nginx:1.27.4-alpine
    container_name: load_balancer
    restart: unless-stopped  
    ports:
      - "80:80"
    volumes:
      - ./nginx/load_balancer.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/my-includes/:/etc/nginx/my-includes/:ro      

    networks:
      - backend_net

networks:
  backend_net:
    driver: bridge
EOF

# ============================================================
# 3. Генерация test_protocol.sh
# ============================================================

cat << 'EOF' > test_protocol.sh
#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
EOF

# Добавляем вычисленные значения портов
echo "PORT_CHAIN_START=${PORT_START}" >> test_protocol.sh
echo "PORT_CHAIN_END=${PORT_END}" >> test_protocol.sh

cat << 'EOF' >> test_protocol.sh

echo -e "${CYAN}========================================================================${NC}"
echo -e "${CYAN}    ПРОТОКОЛ ТЕСТИРОВАНИЯ: Nginx Reverse Proxy & X-Forwarded-For      ${NC}"
echo -e "${CYAN}========================================================================${NC}\n"

curl_and_show() {
    local url=$1
    local header=$2
    local response    

    if [ -z "$header" ]; then
        response=$(curl -s "$url")
    else
        response=$(curl -s -H "$header" "$url")
    fi

    # Вытаскиваем отдельно X-Real-Ip и X-Forwarded-For
    local forwarded=$(echo "$response" | grep -i "X-Forwarded-For" | tr -d '\r' | awk '{$1=$1;print $0}')
    
    # Возвращаем их в красивых скобках
    echo "[$forwarded]"
}

# ============================================================
# ТЕСТ: Проверка всех nginx-нод цепочки
# ============================================================

EOF

# Собираем массив портов: 80 (LB) + цепочка
PORTS=(80)
for (( p=PORT_START; p<=PORT_END; p++ )); do
    PORTS+=($p)
done

# Динамически генерируем проверки для каждого порта
for PORT in "${PORTS[@]}"; do
cat << EOF >> test_protocol.sh

echo -e "\n\${CYAN}--------------------------------- PORT ${PORT} ----------------------------\${NC}"
echo -e "\${YELLOW}[ТЕСТ] Проверка ноды на порту ${PORT}:\${NC}"

for i in {1..3}; do
    echo -n "Запрос \$i  -> "

    res=\$(curl_and_show "http://localhost:${PORT}")
    
    count=\$(echo "\$res" | tr -cd ',' | wc -c)

    if [ "\$count" -eq 1 ]; then
        echo -e "\${GREEN}Прямой путь (App)\${NC}    \${GREEN}| \$res\${NC}"
    else
        echo -e "\${YELLOW}Путь через цепочку\${NC}   \${GREEN}| \$res\${NC}"
    fi
done

echo ""
echo -e "\${YELLOW}[ТЕСТ] Проверка подстановки X-Forwarded-For на значения = 1.1.1.1, 8.8.8.8:\${NC}"
echo -n "Результат -> "

res=\$(curl_and_show \\
    "http://localhost:${PORT}" \\
    "X-Forwarded-For: 1.1.1.1, 8.8.8.8")

if [[ "\$res" == *"1.1.1.1"* ]]; then
    echo -e "\${RED}УЯЗВИМОСТЬ! подмена заголовка прошла.\${NC}"
else
    echo -e "\${GREEN}OK                   | \$res\${NC}"
fi

echo -e "\n\${CYAN}--------------------------------- PORT ${PORT} ----------------------------\${NC}"


EOF
done

chmod +x test_protocol.sh

echo "Готово! Сгенерированы файлы: nginx/load_balancer.conf, docker-compose.yml и test_protocol.sh"