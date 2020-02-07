FROM cargo.caicloud.xyz/library/debian:stretch

LABEL maintainer="Jim Zhang <jim.zhang@caicloud.io>"

COPY build/templates/build.sh /build.sh
COPY templates /tmp/templates

ENV OUTPUT_DIR /templates
ENV INPUT_DIR /tmp/templates

CMD ["/build.sh"]

