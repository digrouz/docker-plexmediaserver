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
  cat <<EOF > /tmp/plex-env
PLEX_MEDIA_SERVER_APPLICATION_SUPPORT_DIR="/var/lib/plexmediaserver/Library/Application Support"
PLEX_MEDIA_SERVER_HOME=/usr/lib/plexmediaserver
PLEX_MEDIA_SERVER_INFO_VENDOR=Docker
PLEX_MEDIA_SERVER_INFO_DEVICE="Docker Container"
PLEX_MEDIA_SERVER_INFO_MODEL=$(uname -m)
PLEX_MEDIA_SERVER_INFO_PLATFORM_VERSION=$(uname -r)
PLEX_MEDIA_SERVER_MAX_PLUGIN_PROCS=6
PLEX_MEDIA_SERVER_TMPDIR=/tmp
PLEX_MEDIA_SERVER_USER=$(echo ${MYUSER})
LC_ALL=en_US.UTF-8
LANG=en_US.UTF-8
LD_LIBRARY_PATH=/usr/lib/plexmediaserver/lib
EOF
  PrepareEnvironment /tmp/plex-env
  . /etc/profile

  RunDropletEntrypoint
  
  if [ -e "/var/lib/plexmediaserver/Library/Application\ Support/Plex\ Media\ Server/plexmediaserver.pid" ]; then
    DockLog "Removing pid file from unclean shutdown"
    rm -rf /var/lib/plexmediaserver/Library/Application\ Support/Plex\ Media\ Server/plexmediaserver.pid"
  fi
  #rm -rf /var/run/dbus
  #mkdir -p /var/run/dbus
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
