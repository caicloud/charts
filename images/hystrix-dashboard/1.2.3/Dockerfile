# 版本信息 
FROM primetoninc/jdk:1.8
MAINTAINER stonesfour "sunshilei@caicloud.io"

ENV HYSTRIX_DASHBOARD_PORT=30008

RUN wget -q https://github.com/stonesfour/caicloud-spring/raw/master/caicloud-hystrix-dashboard/caicloud-hystrix-dashboard-0.0.1-SNAPSHOT.jar \
    -O app.jar

# change path to your repo dir
# COPY ./caicloud-hystrix-dashboard/target/caicloud-hystrix-dashboard-0.0.1-SNAPSHOT.jar  /app.jar

# CMD ["java", "-jar", "/caicloud-hystrix-dashboard.jar"]
ENTRYPOINT [ "sh","-c","java -jar $PARAM /app.jar"]