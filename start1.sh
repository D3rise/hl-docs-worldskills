# 1. Делаем хешбенг, чтобы интерпретатор знал чем исполнять наш скрипт
#!/bin/bash

# 2. Меняем переменную PATH, чтобы мы могли легко вызывать программы из bin/
PATH=$PATH:$PWD/bin

# 3. Создаём и экспортируем переменную IP, записываем туда IP-адрес первого компьютера
export IP="192.168.21.154"

# 4. Создаём генезис-блок, блок канала и блоки с Anchor-пирами
configtxgen -profile WSRGenesis -channelID syschannel -outputBlock ./orgs/0/orderer/genesis.block
configtxgen -profile WSR -channelID wsr -outputCreateChannelTx ./orgs/common/wsr.tx

configtxgen -profile WSR -channelID wsr -asOrg Users -outputAnchorPeersUpdate ./orgs/common/anchor1.tx
configtxgen -profile WSR -channelID wsr -asOrg Shops -outputAnchorPeersUpdate ./orgs/common/anchor2.tx
configtxgen -profile WSR -channelID wsr -asOrg Bank -outputAnchorPeersUpdate ./orgs/common/anchor3.tx

# 5. Поднимаем контейнеры orderer, peer-org1 и cli-org1 и
# ждем несколько секунд для их запуска
docker-compose up -d orderer peer-org1 cli-org1
sleep 2

# 6. Создаём канал (получаем файл блока)
docker exec cli-org1 peer channel create -o $IP:7050 -c wsr -f /hl/common/wsr.tx

# 7. Подключаем все организации к созданному каналу (цикл создаётся 
#    для удобства копирования в start2.sh)
for i in {1..1}; do
    # 8. Подключаем канал к организации
    docker exec cli-org$i peer channel join -b wsr.block

    # 9. Добавляем в канал информацию об Anchor-пирах
    docker exec cli-org$i peer channel update -o $IP:7050 -c wsr -f /hl/common/anchor$i.tx
done