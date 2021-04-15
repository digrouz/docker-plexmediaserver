#!/usr/bin/env bash

PLEX_URL="https://plex.tv/api/downloads/5.json"


LAST_VERSION=$(curl -SsL ${PLEX_URL} | jq .computer.Linux.version | sed -e 's/-.*//' -e 's/"//')
LAST_HASH=$(curl -SsL ${PLEX_URL} | jq .computer.Linux.version | sed -e 's/.*-//' -e 's/"//')


sed -i -e "s|PLEXVERSION='.*'|PLEXVERSION='$LAST_VERSION'|" Dockerfile_*
sed -i -e "s|PLEXHASH='.*'|PLEXHASH='$LAST_HASH'|" Dockerfile_*


git commit -a -m "update to version: ${LAST_VERSION}-${LAST_HASH}"
git push
