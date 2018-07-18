#!/usr/bin/bash

MYSQL_CTNER=
MYSQL_IMG=
MYSQL_PWD=$(pwd)
MYSQL_DATA=
MYSQL_PORT=3306
MYSQL_TIMEOUT=200

while getopts "c:i:w:d:p:t:" arg  # 选项后面的冒号表示该选项需要参数
do
    case $arg in
        c)
            MYSQL_CTNER=$OPTARG  # 容器名
            ;;
        i)
            MYSQL_IMG=$OPTARG  # 镜像名
            ;;
        w)
            MYSQL_PWD=$OPTARG  # 镜像名
            ;;
        d)
            MYSQL_DATA=$OPTARG  # 数据存储文件夹名
            ;;
        p)
            MYSQL_PORT=$OPTARG  # 端口名
            ;;
        t)
            MYSQL_TIMEOUT=$OPTARG  # 启动超时
            ;;
    esac
done

if [ -z "$MYSQL_CTNER" -o -z "$MYSQL_IMG" -o -z "$MYSQL_DATA" ]; then
    echo -e "必要参数：-c <自定义 mysql 容器名> -i <mysql 镜像名> -w <mysql 工作目录> -d <自定义 mysql 数据存储文件夹> -p <mysql 端口>"
    exit
fi

echo -e "\t$MYSQL_CTNER stopping ..."
docker stop $MYSQL_CTNER > /dev/null 2>&1
docker rm $MYSQL_CTNER > /dev/null 2>&1
echo -e "\t$MYSQL_CTNER restarting ..."

docker run --name $MYSQL_CTNER \
-v $MYSQL_PWD:/app \
-v $MYSQL_DATA:/var/lib/mysql/ \
-e MYSQL_DATABASE=admin \
-e MYSQL_USER=pi \
-e MYSQL_PASSWORD=raspberry \
-e MYSQL_ROOT_PASSWORD=root \
-p $MYSQL_PORT:3306 \
-d catcuts/mysql:latest-alpine3.6

# docker run --name $MYSQL_CTNER \
# -v $MYSQL_DATA:/var/lib/mysql \
# -e MYSQL_ROOT_PASSWORD=root \
# -p $MYSQL_PORT:3306 \
# -d daocloud.io/library/mysql:5.7 \
# --character-set-server=utf8 \
# --collation-server=utf8_unicode_ci

echo -e "\t$MYSQL_CTNER restarted. waiting init. to be finished ..."

MYSQL_HOST=$(docker inspect --format='{{.NetworkSettings.Gateway}}' $MYSQL_CTNER)

checking_interval=0.1
checking_timeout=$MYSQL_TIMEOUT
checking_not_ok=1

while [ checking_not_ok ]; do
    echo -n "请等待 mysql 配置，还有 $checking_timeout ……"
    mysql -u root -proot -h$MYSQL_HOST -P$MYSQL_PORT -e "select version();" &> /dev/null
    if [ $? -eq 0 ]; then
        checking_not_ok=0
        echo -e "\t$MYSQL_CTNER is ready ."
        break
    fi
    if [ $checking_timeout -ne 0 ]; then
        ((checking_timeout--))
        sleep 0.1
    else
        echo -e "\t$MYSQL_CTNER timeout !"
        exit 1
    fi
    echo -ne "\r                                        \r"
done
