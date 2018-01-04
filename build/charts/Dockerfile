#
# Copyright 2018 The Caicloud Authors.
#

FROM cargo.caicloudprivatetest.com/caicloud/debian:jessie

RUN apt-get update && \
    apt-get install -y ruby && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
LABEL maintainer="Wei Guo <guowei@caicloud.io>"

COPY build/charts/build.sh /build.sh
COPY stable /stable
COPY templates /templates

ENV OUTPUT_DIR /data/library
ENV INPUT_DIR /stable
ENV TEMPLATES_DIR /templates
ENV IMAGE_DOMAIN cargo.caicloudprivatetest.com
ENV FORCE_UPDATE false
ENV TEMPLATE_VERSION 1.0.0

CMD ["/build.sh"]

