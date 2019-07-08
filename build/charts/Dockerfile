#
# Copyright 2018 The Caicloud Authors.
#

FROM cargo.caicloudprivatetest.com/caicloud/debian:jessie

RUN apt-get update && \
    apt-get install -y ruby --force-yes&& \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
LABEL maintainer="Wei Guo <guowei@caicloud.io>"

COPY build/charts/build.sh /build.sh
COPY stable /stable
COPY templates /templates

ENV OUTPUT_DIR /data/library/release
ENV INPUT_DIR /stable/release
ENV APPLICATION_OUTPUT_DIR /data/library/application
ENV APPLICATION_INPUT_DIR /stable/application
ENV TEMPLATES_DIR /templates
ENV IMAGE_DOMAIN cargo.caicloudprivatetest.com
ENV FORCE_UPDATE false
ENV TEMPLATE_VERSION 1.0.0

CMD ["/build.sh"]

