FROM primetoninc/jdk:1.8
MAINTAINER stonesfour "sunshilei@caicloud.io"

ENV ZUUL_NAME=zuul-gateway
ENV ZUUL_PORT=8080
ENV EUREKA_URL=http://eureka-server:8761/eureka

RUN wget -q https://github.com/stonesfour/caicloud-spring/raw/master/caicloud-zuul-gateway/caicloud-zuul-gateway-0.0.1-SNAPSHOT.jar \
    -O app.jar

ENTRYPOINT [ "sh","-c","java -jar $PARAM /app.jar"]