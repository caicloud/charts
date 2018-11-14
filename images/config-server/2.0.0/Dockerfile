FROM primetoninc/jdk:1.8

LABEL maintainer "luomin@caicloud.io"

ENV CONFIG_SERVER_PORT=8888
ENV ENABLE_EUREKA=true
ENV EUREKA_URL=http://eureka-server:8761/eureka
ENV CONFIG_SERVER_NAME=config-server

RUN wget -q https://github.com/stonesfour/caicloud-spring/raw/master/caicloud-config-server/caicloud-config-server-0.0.1-SNAPSHOT.jar \
    -O app.jar

ENTRYPOINT [ "sh","-c","java -jar $PARAM /app.jar"]