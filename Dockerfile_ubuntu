FROM ubuntu:16.04
LABEL maintainer "DI GREGORIO Nicolas <nicolas.digregorio@gmail.com>"

### Environment variables
ENV DEBIAN_FRONTEND='noninteractive' \
    TERM='xterm' \
    APPUSER='plex' \
    APPUID='10011' \
    APPGID='10011' \
    PLEX_MEDIA_SERVER_INFO_DEVICE='docker' \
    PLEXVERSION='1.27.2.5929' \
    PLEXHASH='a806c5905'

# Copy config files
COPY root/ /

### Install Applications DEBIAN_FRONTEND=noninteractive  --no-install-recommends
RUN set -x && \
    chmod 1777 /tmp && \
    . /usr/local/bin/docker-entrypoint-functions.sh && \
    MYUSER=${APPUSER} && \
    MYUID=${APPUID} && \
    MYGID=${APPGID} && \
    apt-get update && \
    apt-get -y --no-install-recommends dist-upgrade && \
    apt-get install -y --no-install-recommends\
      ca-certificates \
      apt-transport-https \
      avahi-daemon \
      dbus \
      libnss-mdns \
      curl \
    && \
    mv /tmp/custom.list /etc/apt/sources.list.d/custom.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      su-exec \
    && \
    curl -sL https://downloads.plex.tv/plex-media-server-new/${PLEXVERSION}-${PLEXHASH}/debian/plexmediaserver_${PLEXVERSION}-${PLEXHASH}_amd64.deb -o /tmp/plexmediaserver_${PLEXVERSION}-${PLEXHASH}_amd64.deb && \
    echo deb https://downloads.plex.tv/repo/deb ./public main | tee /etc/apt/sources.list.d/my-plexmediaserver.list && \
    curl -o /tmp/PlexSign.key https://downloads.plex.tv/plex-keys/PlexSign.key && \
    apt-key add /tmp/PlexSign.key && \
    apt-get update && \
    dpkg -i --force-confold \
      /tmp/plexmediaserver_${PLEXVERSION}-${PLEXHASH}_amd64.deb \
    && \
    bash -c ". /usr/local/bin/docker-entrypoint-functions.sh && ConfigureUser" && \
    mkdir /docker-entrypoint.d && \
    chmod +x /usr/local/bin/docker-entrypoint.sh && \
    ln -snf /usr/local/bin/docker-entrypoint.sh /docker-entrypoint.sh && \
    apt-get -y autoclean && \
    apt-get -y clean && \
    apt-get -y autoremove && \
    rm -rf /tmp/* \
           /var/lib/apt/lists/* \
           /var/tmp/*

### Volume
VOLUME ["/transcode", "/tv", "/movies", "/animes", "/music"]

### Expose ports
EXPOSE 3005
EXPOSE 8324
EXPOSE 32400
EXPOSE 32400/udp
EXPOSE 32410/udp
EXPOSE 32412/udp
EXPOSE 32413/udp
EXPOSE 32414/udp
EXPOSE 32469
EXPOSE 32469/udp
EXPOSE 5353/udp
EXPOSE 1900/udp

### Running User: not used, managed by docker-entrypoint.sh
#USER plex

### Start Plex
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["plex"]
