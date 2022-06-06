# 1. Делаем хешбенг, чтобы интерпретатор знал чем исполнять наш скрипт
#!/bin/bash

# 2. Меняем переменную PATH, чтобы мы могли легко вызывать программы из bin/
PATH=$PATH:$PWD/bin

# 3. Создаём и экспортируем переменную IP, записываем туда IP-адрес первого компьютера
export IP="192.168.21.156"

# 4. Создаём и экспортируем переменную SIP (от Second IP), записываем туда IP-адрес
#    компьютера, на котором работает Orderer
export SIP="192.168.21.154"

# 5. Запускаем контейнеры второй и третьей организации, ждём 2 секунды для инициализации
docker-compose up -d cli-org2 cli-org3 peer-org2 peer-org3
sleep 2

# 6. Подключаем все организации к созданному каналу (цикл создаётся 
#    для удобства копирования в start2.sh)
for i in {2..3}; do
    # 7. Подключаем канал к организации
    docker exec cli-org$i peer channel join -o $SIP:7050 -b wsr.block

    # 8. Добавляем в канал информацию об Anchor-пирах
    docker exec cli-org$i peer channel update -o $SIP:7050 -c wsr -f /hl/common/anchor$i.tx
done