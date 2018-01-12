FROM centos:7

COPY ./galera.repo /etc/yum.repos.d/galera.repo 

RUN yum install -y galera-3 mysql-wsrep-5.7 &&\
    yum install -y which &&\
    yum install -y rsync &&\
    rm -rf /etc/my.cnf &&\
    yum clean all

ADD ./mysql /etc/mysql

COPY ./entrypoint.sh /entrypoint.sh

RUN chmod u+x /entrypoint.sh

EXPOSE 3306 4444 4567 4568

ENTRYPOINT ["/entrypoint.sh"]

CMD ["mysqld"]
