#!/usr/bin/env bash

MYUSER="plex"
MYGID="10011"
MYUID="10011"
OS=""
MYUPGRADE="0"

DectectOS(){
  if [ -e /etc/alpine-release ]; then
    OS="alpine"
  elif [ -e /etc/os-release ]; then
    if grep -q "NAME=\"Ubuntu\"" /etc/os-release ; then
      OS="ubuntu"
    fi
    if grep -q "NAME=\"CentOS Linux\"" /etc/os-release ; then
      OS="centos"
    fi
  fi
}

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
        local var="$1"
        local fileVar="${var}_FILE"
        local def="${2:-}"
        if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
                echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
                exit 1
        fi
        local val="$def"
        if [ "${!var:-}" ]; then
                val="${!var}"
        elif [ "${!fileVar:-}" ]; then
                val="$(< "${!fileVar}")"
        fi
        export "$var"="$val"
        unset "$fileVar"
}

AutoUpgrade(){
  file_env 'DOCKUPGRADE'
  if [ -n "${DOCKUPGRADE}" ]; then
    MYUPGRADE="${DOCKUPGRADE}"
  fi
  if [ "${MYUPGRADE}" == 1 ]; then
    if [ "${OS}" == "alpine" ]; then
      apk --no-cache upgrade
      rm -rf /var/cache/apk/*
    elif [ "${OS}" == "ubuntu" ]; then
      export DEBIAN_FRONTEND=noninteractive
      apt-get update
      apt-get -y --no-install-recommends dist-upgrade
      apt-get -y autoclean
      apt-get -y clean
      apt-get -y autoremove
      rm -rf /var/lib/apt/lists/*
    elif [ "${OS}" == "centos" ]; then
      yum upgrade -y
      yum clean all
      rm -rf /var/cache/yum/*
    fi
  fi
}

ConfigureUser () {
  # Managing user
  if [ -n "${DOCKUID}" ]; then
    MYUID="${DOCKUID}"
  fi
  # Managing group
  if [ -n "${DOCKGID}" ]; then
    MYGID="${DOCKGID}"
  fi
  local OLDHOME
  local OLDGID
  local OLDUID

  if grep -q "${MYUSER}" /etc/passwd; then
    OLDUID=$(id -u "${MYUSER}")
    if [ "${DOCKUID}" != "${OLDUID}" ]; then
      OLDHOME=$(grep "$MYUSER" /etc/passwd | awk -F: '{print $6}')
      if [ "${OS}" == "alpine" ]; then
        deluser "${MYUSER}"
      else
        userdel "${MYUSER}"
      fi
      logger "Deleted user ${MYUSER}"
    fi
    if grep -q "${MYUSER}" /etc/group; then
      OLDGID=$(id -g "${MYUSER}")
      if [ "${DOCKGID}" != "${OLDGID}" ]; then
        if [ "${OS}" == "alpine" ]; then
          delgroup "${MYUSER}"
        else
          groupdel "${MYUSER}"
        fi
        logger "Deleted group ${MYUSER}"
      fi
    fi
  fi
  if ! grep -q "${MYUSER}" /etc/group; then
    if [ "${OS}" == "alpine" ]; then
      addgroup -S -g "${MYGID}" "${MYUSER}"
    else
      groupadd -r -g "${MYGID}" "${MYUSER}"
    fi
    logger "Created group ${MYUSER}"
  fi
  if ! grep -q "${MYUSER}" /etc/passwd; then
    if [ -z "${OLDHOME}" ]; then
      OLDHOME="/home/${MYUSER}"
    fi
    if [ "${OS}" == "alpine" ]; then
      adduser -S -D -H -s /sbin/nologin -G "${MYUSER}" -h "${OLDHOME}" -u "${MYUID}" "${MYUSER}"
    else
      useradd --system --shell /sbin/nologin --gid "${MYGID}" --home "${OLDHOME}" --uid "${MYUID}" "${MYUSER}"
    fi
    logger "Created user ${MYUSER}"

  fi
  if [ -n "${OLDUID}" ] && [ "${DOCKUID}" != "${OLDUID}" ]; then
    logger "Fixing permissions for group ${MYUSER}"
    find / -user "${OLDUID}" -exec chown ${MYUSER} {} \; &> /dev/null
    logger "... done!"
  fi
  if [ -n "${OLDGID}" ] && [ "${DOCKGID}" != "${OLDGID}" ]; then
    logger "Fixing permissions for group ${MYUSER}"
    find / -group "${OLDGID}" -exec chgrp ${MYUSER} {} \; &> /dev/null
    logger "... done!"
  fi
}

DectectOS
AutoUpgrade
ConfigureUser


if [ "$1" = "plex" ]; then
    if [ ! -d /config ]; then
      mkdir /config
    fi
    if [ -d /config ]; then
      chown -R "${MYUSER}":"${MYUSER}" /config
      chmod -R 0750 /config
    fi
    if [ ! -d /transcode ]; then
      mkdir /transcode
    fi
    if [ -d /transcode ]; then
      chown -R "${MYUSER}":"${MYUSER}" /transcode
      chmod -R 0750 /transcode
    fi

    cd /config
    rm -rf /var/run/dbus
    mkdir -p /var/run/dbus
    exec dbus-daemon --system --nofork &
    until [ -e /var/run/dbus/system_bus_socket ]; do
      logger  "dbus-daemon is not running on hosting server..."
      sleep 1s
    done
    exec avahi-daemon --no-chroot &
    exec su-exec "${MYUSER}" start_pms
else
  exec "$@"
fi
