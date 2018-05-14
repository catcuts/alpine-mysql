FROM alpine:3.6

WORKDIR /app
VOLUME /app
COPY startup.sh /app/startup.sh

RUN \
    echo 'http://mirrors.aliyun.com/alpine/v3.6/main' > /etc/apk/repositories && \
    echo 'http://mirrors.aliyun.com/alpine/v3.6/community' >>/etc/apk/repositories && \ 
    apk update && apk add tzdata && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \ 
    echo "Asia/Shanghai" > /etc/timezone && \
    apk add --update mysql mysql-client && rm -f /var/cache/apk/*

COPY my.cnf /etc/mysql/my.cnf

EXPOSE 3306
CMD ["/app/startup.sh"]
