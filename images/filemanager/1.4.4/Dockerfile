FROM busybox:1.28.4-glibc

WORKDIR /

RUN wget -q https://github.com/filebrowser/filebrowser/releases/download/v1.4.4/linux-amd64-filemanager.tar.gz -O filemanager.tar.gz \
  && tar -xvf filemanager.tar.gz \
  && rm -rf filemanager.tar.gz

VOLUME /tmp
VOLUME /srv
EXPOSE 80

COPY Docker.json /config.json

ENTRYPOINT ["/filemanager"]
CMD ["--config", "/config.json"]
