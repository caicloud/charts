FROM primetoninc/jdk:1.8
MAINTAINER stonesfour "sunshilei@caicloud.io"

ENV EUREKA_PORT=8761
ENV EUREKA_HOST_NAME=localhost

RUN wget -q https://github.com/stonesfour/caicloud-spring/raw/master/caicloud-discovery-eureka/caicloud-discovery-eureka-0.0.1-SNAPSHOT.jar \
    -O app.jar

ENTRYPOINT [ "sh","-c","java -jar $PARAM /app.jar"]