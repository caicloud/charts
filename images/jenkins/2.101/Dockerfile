FROM jenkins/jenkins:2.101-alpine 

USER root

ENV JENKINS_VERSION=2.101
ENV JENKINS_UC_DOWNLOAD="https://mirrors.tuna.tsinghua.edu.cn/jenkins"

RUN echo ${JENKINS_VERSION} > /usr/share/jenkins/ref/jenkins.install.UpgradeWizard.state 
COPY basic-secrity.groovy /usr/share/jenkins/ref/init.groovy.d/basic-secrity.groovy

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    /usr/local/bin/install-plugins.sh \ 
    kubernetes \ 
    workflow-aggregator \
    pipeline-stage-view \
    git \
    credentials-binding \
    ws-cleanup \
    ant \
    ldap \
    email-ext \
    simple-theme-plugin \
    github-organization-folder \
    ghprb \
    subversion \
    gitlab-plugin \
    ansicolor \
    dashboard-view \
    build-timeout \
    gitlab-hook \
    blueocean
