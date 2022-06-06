# Для исполнения скрипта необходимо:
# 1. Сделать его исполняемым (chmod +x ca-start1.sh)
# 2. Запустить его от имени root (sudo ./ca-start1.sh)

# 1. Делаем хешбенг, чтобы интерпретатор знал через что исполнять
#    наш скрипт
#!/bin/bash
# 2. Меняем переменную PATH, чтобы мы могли легко вызывать программы из bin/
PATH=$PATH:$PWD/bin

# 3. Создаём и экспортируем переменную окружения IP, присваиваем ей адрес
# второго компьютера в локальной сети
export IP="192.168.21.156"

# 4. Создаём контейнеры ca-org2 и ca-org3
docker-compose up -d ca-org2 ca-org3

# 5. Ждём 2 секунды для инициализации (обычно этого достаточно, 
# но если понадобится - увеличьте на несколько секунд)
sleep 2

# 6. проходимся по организациям от 2 до 3 включительно
for i in {2..3}; do
    # 7. Копируем строчки из первого цикла в ca-start1.sh и вставляем сюда
    # (шаги от 10 до 15 идентичны шагам 7-12 в ca-start1.sh)
    
    # 8. Создаём переменную CA, в ней будем указывать адрес центра сертификации
    # * Все порты CA начинаются на 705, а последняя цифра каждый раз увеличивается на 1
    #   (начиная с 1)
    # * Команда expr исполняет подаваемое математическое выражение
    CA=${IP}:705$(expr 1 + $i)

    # 9. Выпускаем сертификат (MSP) администратора, сохраняем его в orgs/$i/admin
    # * Данные для входа по-умолчанию (указаны в docker-compose.yml):
    #  - логин: admin
    #  - пароль: adminpw
    fabric-ca-client enroll -H orgs/$i/admin -u http://admin:adminpw@$CA

    # 10. Создаём структуру папки MSP нашей организации
    mkdir -p orgs/$i/msp/{admincerts,cacerts,users}

    # 11. Копируем сертификат CA в MSP нашей организации
    cp orgs/ca/$i/ca-cert.pem orgs/$i/msp/cacerts/ca.pem

    # 12. Копируем сертификат администратора в MSP нашей организации
    cp orgs/$i/admin/msp/signcerts/cert.pem orgs/$i/msp/admincerts/admin.pem

    # 13. Копируем сертификат администратора в MSP администратора
    # * Это делается для того, чтобы не создавать файл с NodeOU с указанием
    #   ролей организации (client, admin, peer и orderer)
    cp -r orgs/$i/admin/msp/signcerts orgs/$i/admin/msp/admincerts

    # 14. Создаём пользователя peer
    fabric-ca-client register -u http://$CA -H orgs/$i/admin --id.name peer --id.secret peerpw --id.type peer

    # 15. Выпускаем сертификат пользователя peer
    fabric-ca-client enroll -u http://peer:peerpw@$CA -H orgs/$i/peer

    # 16. Копируем сертификат администратора в MSP пользователя peer
    cp -r orgs/$i/admin/msp/signcerts orgs/$i/peer/msp/admincerts

    # 17. Создаём пользователя peer
    fabric-ca-client register -u http://$CA -H orgs/$i/admin --id.name peer --id.secret peerpw --id.type peer

    # 18. Выпускаем сертификат пользователя peer
    fabric-ca-client enroll -u http://peer:peerpw@$CA -H orgs/$i/peer

    # 19. Копируем сертификат администратора в MSP пользователя peer
    cp -r orgs/$i/admin/msp/signcerts orgs/$i/peer/msp/admincerts
done