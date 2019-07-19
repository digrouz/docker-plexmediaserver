# docker-ubu-plexmediaserver
Install Plex Media Server into a Linux Container

![Plex](https://s3-us-west-2.amazonaws.com/kotis-estores/layouts/plex/plex-logo.png)

## Tag
Several tag are available:
* latest: see centos
* centos: [Dockerfile_centos](https://github.com/digrouz/docker-plexmediaserver/blob/master/Dockerfile_centos)
* ubuntu: [Dockerfile_ubuntu](https://github.com/digrouz/docker-plexmediaserver/blob/master/Dockerfile_ubuntu)


## Description

Plex is a client-server media player system and software suite comprising two main components.

* The Plex Media Server either running on Windows, macOS, Linux, FreeBSD or a NAS which organizes audio (music) and visual (photos and videos) content from personal media libraries and streams it to their player counterparts.
* The players can either be the Plex Apps available for mobile devices, smart TVs, and streaming boxes, or the web UI of the Plex Media Server called Plex Web App, or the old Plex player called Plex Home Theater.

A premium version of the service, called Plex Pass, is also available and offers advanced features like synchronization with mobile devices, access to cloud storage providers, up to date and high quality metadata and matchings for music, multi-users mode, parental controls, access to high quality trailers and extras, wireless synchronization from mobile devices to the server, access to discounts on partner products and early access.

https://www.plex.tv/

## Usage
    docker create --name=plexmediaserver  \
      --network=host \
      -v /etc/localtime:/etc/localtime:ro \
      -v <path to config Library>:/var/lib/plexmediaserver/Library \
      -v <path to transcode folder>:/transcode \
      -v <path to media Library>:/media_library \
      -e DOCKUID=<UID default:10011> \
      -e DOCKGID=<GID default:10011> \
      -e DOCKUPGRADE=<0|1> \
      digrouz/plexmediaserver


## Environment Variables

When you start the `plexmediaserver` image, you can adjust the configuration of the `plexmediaserver` instance by passing one or more environment variables on the `docker run` command line.

### `DOCKUID`

This variable is not mandatory and specifies the user id that will be set to run the application. It has default value `10011`.

### `DOCKGID`

This variable is not mandatory and specifies the group id that will be set to run the application. It has default value `10011`.

### `DOCKUPGRADE`

This variable is not mandatory and specifies if the container has to launch software update at startup or not. Valid values are `0` and `1`. It has default value `0`.

## Notes

* The docker entrypoint can upgrade operating system at each startup. To enable this feature, just add `-e DOCKUPGRADE=1` at container creation.
* Running this container with the `host` network mode is a requirement.


