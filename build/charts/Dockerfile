FROM cargo.caicloud.xyz/library/debian:stretch-ruby

COPY build/charts/build.sh /build.sh
COPY stable /stable
COPY templates /templates

ENV OUTPUT_DIR /data/library/release
ENV INPUT_DIR /stable/release
ENV APPLICATION_OUTPUT_DIR /data/library/application
ENV APPLICATION_INPUT_DIR /stable/application
ENV TEMPLATES_DIR /templates
ENV IMAGE_DOMAIN cargo.dev.caicloud.xyz
ENV FORCE_UPDATE false
ENV TEMPLATE_VERSION 1.0.0

CMD ["/build.sh"]

