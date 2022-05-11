# Для исполнения скрипта необходимо:
# 1. Сделать его исполняемым (chmod +x ca-start1.sh)
# 2. Запустить его от имени root (sudo ./ca-start1.sh)

# 1. Делаем хешбенг, чтобы интерпретатор знал через что исполнять
#    наш скрипт
#!/bin/bash
# 2. Меняем переменную PATH, чтобы мы могли легко вызывать программы из bin/
PATH=$PATH:$PWD/bin

# 3. Создаём и экспортируем переменную окружения IP, присваиваем ей адрес
# первого компьютера в локальной сети
export IP="192.168.21.23"

# 4. Запускаем центры сертификации (CA) 1 и 2 организаций (Orderer и Users),
#    поскольку эти две организации работают на первом компьютере
docker-compose up -d ca-org0 ca-org1

# 5. Спим 2 секунды (на медленных компьюьтерах может быть необходимо больше),
#    чтобы CA запустились и инициализировались
sleep 2

# 6. Выпускаем сертификаты адиминистраторов и создаём MSP организаций
for i in {0..1}; do
    # 7. Создаём переменную CA, в ней будем указывать адрес центра сертификации
    # * Все порты CA начинаются на 705, а последняя цифра каждый раз увеличивается на 1
    #   (начиная с 1)
    # * Команда expr исполняет подаваемое математическое выражение
    CA=${IP}:705$(expr 1 + $i)

    # 8. Выпускаем сертификат (MSP) администратора, сохраняем его в orgs/$i/admin
    # * Данные для входа по-умолчанию (указаны в docker-compose.yml):
    #  - логин: admin
    #  - пароль: adminpw
    fabric-ca-client enroll -H orgs/$i/admin -u http://admin:adminpw@$CA

    # 9. Создаём структуру папки MSP нашей организации
    mkdir -p orgs/$i/msp/{admincerts,cacerts,users}

    # 10. Копируем сертификат CA в MSP нашей организации
    cp orgs/ca/$i/ca-cert.pem orgs/$i/msp/cacerts/ca.pem

    # 11. Копируем сертификат администратора в MSP нашей организации
    cp orgs/$i/admin/msp/signcerts/cert.pem orgs/$i/msp/admincerts/admin.pem

    # 12. Копируем сертификат администратора в MSP администратора
    # * Это делается для того, чтобы не создавать файл с NodeOU с указанием
    #   ролей организации (client, admin, peer и orderer)
    cp -r orgs/$i/admin/msp/signcerts orgs/$i/admin/msp/admincerts
done

# 13. Создаём пользователя orderer и выпускаем его сертификат
fabric-ca-client register -u http://${IP}:7051 -H orgs/0/admin --id.name orderer --id.secret ordererpw --id.type orderer

# 14. Выпускаем сертификат пользователя orderer и сохраняем его в orgs/0/orderer
fabric-ca-client enroll -u http://orderer:ordererpw@${IP}:7051 -H orgs/0/orderer

# 15. Копируем сертификат администратора в MSP пользователя orderer
cp -r orgs/0/admin/msp/signcerts orgs/0/orderer/msp/admincerts

# 16. Создаём сертификаты пиров, выпускаем их и копируем в них сертификаты администраторов
# * Цикл с одной итерацией создаётся для удобства копирования в скрипт ca-start2.sh
for i in {1..1}; do
    # 17. Указываем адрес CA
    CA=${IP}:705$(expr 1 + $i)

    # 18. Создаём пользователя peer
    fabric-ca-client register -u http://$CA -H orgs/$i/admin --id.name peer --id.secret peerpw --id.type peer
    
    # 19. Выпускаем сертификат пользователя peer
    fabric-ca-client enroll -u http://peer:peerpw@$CA -H orgs/$i/peer

    # 20. Копируем сертификат администратора в MSP пользователя peer
    cp -r orgs/$i/admin/msp/signcerts orgs/$i/peer/msp/admincerts
done