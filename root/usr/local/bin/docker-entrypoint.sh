#!/usr/bin/env bash

. /etc/profile
. /usr/local/bin/docker-entrypoint-functions.sh

MYUSER="${APPUSER}"
MYUID="${APPUID}"
MYGID="${APPGID}"

AutoUpgrade
ConfigureUser

if [ "$1" == 'plex' ]; then
  mkdir -p /transcode
  chown -R "${MYUSER}":"${MYUSER}" /transcode
  chmod -R 0750 /transcode
  rm -rf /var/run/dbus
  mkdir -p /var/run/dbus
  cat <<EOF > /tmp/plex-env
PLEX_MEDIA_SERVER_APPLICATION_SUPPORT_DIR=/var/lib/plexmediaserver/Library/Application Support
PLEX_MEDIA_SERVER_HOME=/usr/lib/plexmediaserver
PLEX_MEDIA_SERVER_MAX_PLUGIN_PROCS=6
PLEX_MEDIA_SERVER_TMPDIR=/tmp
LC_ALL=en_US.UTF-8
LANG=en_US.UTF-8
PLEX_MEDIA_SERVER_INFO_VENDOR=$(grep ^NAME= /etc/os-release | awk -F= "{print \\$2}" | tr -d \\" )
PLEX_MEDIA_SERVER_INFO_DEVICE=docker
PLEX_MEDIA_SERVER_INFO_MODEL=$(uname -m)
PLEX_MEDIA_SERVER_INFO_PLATFORM_VERSION=$(grep ^VERSION= /etc/os-release | awk -F= "{print \\$2}" | tr -d \\" )
LD_LIBRARY_PATH=/usr/lib/plexmediaserver/lib
PLEX_MEDIA_SERVER_USER=${MYUSER}
EOF
  PrepareEnvironment /tmp/plex-env
  . /etc/profile

  RunDropletEntrypoint
  
  if [ -e "/var/lib/plexmediaserver/Library/Application\ Support/Plex\ Media\ Server/plexmediaserver.pid" ]; then
    DockLog "Removing pid file from unclean shutdown"
    rm -rf /var/lib/plexmediaserver/Library/Application\ Support/Plex\ Media\ Server/plexmediaserver.pid"
  fi
  #DockLog "Starting app: dbus-daemon"
  #exec dbus-daemon --system --nofork &
  #until [ -e /var/run/dbus/system_bus_socket ]; do
  #  DockLog  "dbus-daemon is not running on hosting server..."
  #  sleep 1s
  #done
  #DockLog "Starting app: avahi-daemon"
  #exec avahi-daemon --no-chroot &

  DockLog "Starting app: ${1}"
  exec su-exec "${MYUSER}" /usr/lib/plexmediaserver/Plex\ Media\ Server
else
  DockLog "Starting app: ${@}"
  exec "$@"
fi
