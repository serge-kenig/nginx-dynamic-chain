#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

PORT_CHAIN_START=8081
PORT_CHAIN_END=8085

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



echo -e "\n${CYAN}--------------------------------- PORT 80 ----------------------------${NC}"
echo -e "${YELLOW}[ТЕСТ] Проверка всех nginx-нод:${NC}"

for i in {1..3}; do

    echo -n "Запрос $i  -> "

    res=$(curl_and_show "http://localhost:80")

    count=$(echo "$res" | tr -cd ',' | wc -c)

    if [ "$count" -eq 1 ]; then
        echo -e "${GREEN}Прямой путь (App)${NC}    ${GREEN}| $res${NC}"
    else
        echo -e "${YELLOW}Путь через цепочку${NC}   ${GREEN}| $res${NC}"
    fi
done

echo ""
echo -e "${YELLOW}[ТЕСТ] Проверка подстановки X-Forwarded-For на значения = 1.1.1.1, 8.8.8.8:${NC}"
echo -n "Результат -> "

res=$(curl_and_show \
    "http://localhost:80" \
    "X-Forwarded-For: 1.1.1.1, 8.8.8.8")

if [[ "$res" == *"1.1.1.1"* ]]; then
    echo -e "${RED}УЯЗВИМОСТЬ! подмена заголовка прошела.${NC}"
else
    echo -e "${GREEN}OK                   | $res${NC}"
fi

echo -e "\n${CYAN}--------------------------------- PORT 80 ----------------------------${NC}"

echo -e "\n${CYAN}--------------------------------- PORT 8081 ----------------------------${NC}"
echo -e "${YELLOW}[ТЕСТ] Проверка всех nginx-нод:${NC}"

for i in {1..3}; do

    echo -n "Запрос $i  -> "

    res=$(curl_and_show "http://localhost:8081")

    count=$(echo "$res" | tr -cd ',' | wc -c)

    if [ "$count" -eq 1 ]; then
        echo -e "${GREEN}Прямой путь (App)${NC}    ${GREEN}| $res${NC}"
    else
        echo -e "${YELLOW}Путь через цепочку${NC}   ${GREEN}| $res${NC}"
    fi
done

echo ""
echo -e "${YELLOW}[ТЕСТ] Проверка подстановки X-Forwarded-For на значения = 1.1.1.1, 8.8.8.8:${NC}"
echo -n "Результат -> "

res=$(curl_and_show \
    "http://localhost:8081" \
    "X-Forwarded-For: 1.1.1.1, 8.8.8.8")

if [[ "$res" == *"1.1.1.1"* ]]; then
    echo -e "${RED}УЯЗВИМОСТЬ! подмена заголовка прошела.${NC}"
else
    echo -e "${GREEN}OK                   | $res${NC}"
fi

echo -e "\n${CYAN}--------------------------------- PORT 8081 ----------------------------${NC}"

echo -e "\n${CYAN}--------------------------------- PORT 8082 ----------------------------${NC}"
echo -e "${YELLOW}[ТЕСТ] Проверка всех nginx-нод:${NC}"

for i in {1..3}; do

    echo -n "Запрос $i  -> "

    res=$(curl_and_show "http://localhost:8082")

    count=$(echo "$res" | tr -cd ',' | wc -c)

    if [ "$count" -eq 1 ]; then
        echo -e "${GREEN}Прямой путь (App)${NC}    ${GREEN}| $res${NC}"
    else
        echo -e "${YELLOW}Путь через цепочку${NC}   ${GREEN}| $res${NC}"
    fi
done

echo ""
echo -e "${YELLOW}[ТЕСТ] Проверка подстановки X-Forwarded-For на значения = 1.1.1.1, 8.8.8.8:${NC}"
echo -n "Результат -> "

res=$(curl_and_show \
    "http://localhost:8082" \
    "X-Forwarded-For: 1.1.1.1, 8.8.8.8")

if [[ "$res" == *"1.1.1.1"* ]]; then
    echo -e "${RED}УЯЗВИМОСТЬ! подмена заголовка прошела.${NC}"
else
    echo -e "${GREEN}OK                   | $res${NC}"
fi

echo -e "\n${CYAN}--------------------------------- PORT 8082 ----------------------------${NC}"

echo -e "\n${CYAN}--------------------------------- PORT 8083 ----------------------------${NC}"
echo -e "${YELLOW}[ТЕСТ] Проверка всех nginx-нод:${NC}"

for i in {1..3}; do

    echo -n "Запрос $i  -> "

    res=$(curl_and_show "http://localhost:8083")

    count=$(echo "$res" | tr -cd ',' | wc -c)

    if [ "$count" -eq 1 ]; then
        echo -e "${GREEN}Прямой путь (App)${NC}    ${GREEN}| $res${NC}"
    else
        echo -e "${YELLOW}Путь через цепочку${NC}   ${GREEN}| $res${NC}"
    fi
done

echo ""
echo -e "${YELLOW}[ТЕСТ] Проверка подстановки X-Forwarded-For на значения = 1.1.1.1, 8.8.8.8:${NC}"
echo -n "Результат -> "

res=$(curl_and_show \
    "http://localhost:8083" \
    "X-Forwarded-For: 1.1.1.1, 8.8.8.8")

if [[ "$res" == *"1.1.1.1"* ]]; then
    echo -e "${RED}УЯЗВИМОСТЬ! подмена заголовка прошела.${NC}"
else
    echo -e "${GREEN}OK                   | $res${NC}"
fi

echo -e "\n${CYAN}--------------------------------- PORT 8083 ----------------------------${NC}"

echo -e "\n${CYAN}--------------------------------- PORT 8084 ----------------------------${NC}"
echo -e "${YELLOW}[ТЕСТ] Проверка всех nginx-нод:${NC}"

for i in {1..3}; do

    echo -n "Запрос $i  -> "

    res=$(curl_and_show "http://localhost:8084")

    count=$(echo "$res" | tr -cd ',' | wc -c)

    if [ "$count" -eq 1 ]; then
        echo -e "${GREEN}Прямой путь (App)${NC}    ${GREEN}| $res${NC}"
    else
        echo -e "${YELLOW}Путь через цепочку${NC}   ${GREEN}| $res${NC}"
    fi
done

echo ""
echo -e "${YELLOW}[ТЕСТ] Проверка подстановки X-Forwarded-For на значения = 1.1.1.1, 8.8.8.8:${NC}"
echo -n "Результат -> "

res=$(curl_and_show \
    "http://localhost:8084" \
    "X-Forwarded-For: 1.1.1.1, 8.8.8.8")

if [[ "$res" == *"1.1.1.1"* ]]; then
    echo -e "${RED}УЯЗВИМОСТЬ! подмена заголовка прошела.${NC}"
else
    echo -e "${GREEN}OK                   | $res${NC}"
fi

echo -e "\n${CYAN}--------------------------------- PORT 8084 ----------------------------${NC}"

echo -e "\n${CYAN}--------------------------------- PORT 8085 ----------------------------${NC}"
echo -e "${YELLOW}[ТЕСТ] Проверка всех nginx-нод:${NC}"

for i in {1..3}; do

    echo -n "Запрос $i  -> "

    res=$(curl_and_show "http://localhost:8085")

    count=$(echo "$res" | tr -cd ',' | wc -c)

    if [ "$count" -eq 1 ]; then
        echo -e "${GREEN}Прямой путь (App)${NC}    ${GREEN}| $res${NC}"
    else
        echo -e "${YELLOW}Путь через цепочку${NC}   ${GREEN}| $res${NC}"
    fi
done

echo ""
echo -e "${YELLOW}[ТЕСТ] Проверка подстановки X-Forwarded-For на значения = 1.1.1.1, 8.8.8.8:${NC}"
echo -n "Результат -> "

res=$(curl_and_show \
    "http://localhost:8085" \
    "X-Forwarded-For: 1.1.1.1, 8.8.8.8")

if [[ "$res" == *"1.1.1.1"* ]]; then
    echo -e "${RED}УЯЗВИМОСТЬ! подмена заголовка прошела.${NC}"
else
    echo -e "${GREEN}OK                   | $res${NC}"
fi

echo -e "\n${CYAN}--------------------------------- PORT 8085 ----------------------------${NC}"


