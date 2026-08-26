# docker-plexmediaserver

[![auto-update-workflow](https://github.com/digrouz/docker-plexmediaserver/actions/workflows/auto-update.yml/badge.svg)](https://github.com/digrouz/docker-plexmediaserver/actions/workflows/auto-update.yml)
[![dockerhub-workflow](https://github.com/digrouz/docker-plexmediaserver/actions/workflows/dockerhub.yml/badge.svg)](https://github.com/digrouz/docker-plexmediaserver/actions/workflows/dockerhub.yml)
![Docker Pulls](https://img.shields.io/docker/pulls/digrouz/plexmediaserver)

Install Plex Media Server into a Linux Container

![Plex](https://s3-us-west-2.amazonaws.com/kotis-estores/layouts/plex/plex-logo.png)

## Tag

Several tag are available:

* latest: see debian
* debian: [Dockerfile_debian](https://github.com/digrouz/docker-plexmediaserver/blob/master/Dockerfile_debian)

## Description

Plex is a client-server media player system and software suite comprising two main components.

* The Plex Media Server either running on Windows, macOS, Linux, FreeBSD or a NAS which organizes audio (music) and visual (photos and videos) content from personal media libraries and streams it to their player counterparts.
* The players can either be the Plex Apps available for mobile devices, smart TVs, and streaming boxes, or the web UI of the Plex Media Server called Plex Web App, or the old Plex player called Plex Home Theater.

A premium version of the service, called Plex Pass, is also available and offers advanced features like synchronization with mobile devices, access to cloud storage providers, up to date and high quality metadata and matchings for music, multi-users mode, parental controls, access to high quality trailers and extras, wireless synchronization from mobile devices to the server, access to discounts on partner products and early access.

[Official website](https://www.plex.tv/)

## Usage

    docker create --name=plexmediaserver  \
      --network=host \
      -v /etc/localtime:/etc/localtime:ro \
      -v <path to config Library>:/var/lib/plexmediaserver/Library \
      -v <path to transcode folder>:/transcode \
      -v <path to media Library>:/media_library \
      -e UID=<UID default:12345> \
      -e GID=<GID default:12345> \
      -e AUTOUPGRADE=<0|1 default:0> \
      -e TZ=<timezone default:Europe/Brussels> \
      digrouz/plexmediaserver

## Environment Variables

When you start the `plexmediaserver` image, you can adjust the configuration of the `plexmediaserver` instance by passing one or more environment variables on the `docker run` command line.

## `UID`

This variable is not mandatory and specifies the user id that will be set to run the application. It has default value `12345`.

### `GID`

This variable is not mandatory and specifies the group id that will be set to run the application. It has default value `12345`.

### `AUTOUPGRADE`

This variable is not mandatory and specifies if the container has to launch software update at startup or not. Valid values are `0` and `1`. It has default value `0`.

### `TZ`

This variable is not mandatory and specifies the timezone to be configured within the container. It has default value `Europe/Brussels`.

## Notes

* This container is built using [s6-overlay](https://github.com/just-containers/s6-overlay)
* The docker entrypoint can upgrade operating system at each startup. To enable this feature, just add `-e AUTOUPGRADE=1` at container creation.
* Running this container with the `host` network mode is a requirement.

## Helm Chart

A Helm chart is available in the [chart](https://github.com/digrouz/docker-plexmediaserver/tree/master/chart) directory.

    helm install plexmediaserver ./chart

Notable values (see [chart/values.yaml](https://github.com/digrouz/docker-plexmediaserver/blob/master/chart/values.yaml) for the full list):

* The Plex container is run as a **StatefulSet** (not a Deployment): Plex uses a single-writer SQLite database, so pods must never run concurrently. The StatefulSet gives ordered create/delete, a stable pod name and per-pod PVCs via `volumeClaimTemplates`.
* `podDisruptionBudget.enabled`: creates a PDB with `minAvailable: 1` so the pod is never evicted during voluntary disruptions (e.g. node drain).
* `persistence.library`: `pvc`, `nfs` or anything else (falls back to `emptyDir`). With `type: pvc` the PVC is created by the StatefulSet as `plex-library-<release>-plexmediaserver-0`.
* `extraVolumes` / `extraVolumeMounts`: to mount your media (hostPath, pvc, nfs, configMap, secret).
* `claimToken`: to skip the manual activation step, pass the claim code from https://app.plex.tv/claim and the chart creates the secret for you:

    helm install plexmediaserver ./chart --set claimToken.token=XXXXX

  Alternatively, bring your own secret:

    kubectl create secret generic plexmediaserver-claim --from-literal=plex_claim=XXXXX
    helm install plexmediaserver ./chart --set claimToken.name=plexmediaserver-claim

  Note: the claim code is one-time — once the server is activated, Plex no longer uses it, so clearing `claimToken.token` on a later upgrade is safe.

* `probes`: liveness/readiness TCP probes on port 32400, enabled by default, with `probes.initialDelaySeconds` to delay the first probe.
* `resources`: CPU/memory requests and limits.
* `terminationGracePeriodSeconds`: grace period for Plex to stop transcoding sessions on shutdown (default 180s).
* `ingress.traefik.enabled`: toggles the Traefik `IngressRouteTCP`/`IngressRouteUDP` objects for the Plex service ports (32469, 8324, 3005, 1900, 5353, 32410-32414).

### Upgrading from chart 0.1.x

0.2.0 switches from a Deployment to a StatefulSet, which changes the library PVC name (`<release>-library-pvc` → `plex-library-<release>-plexmediaserver-0`). It also no longer persists `/var/lib/plexmediaserver` itself (server settings, claim, tokens) — only the Library is mounted, so after migrating the server has to be claimed again and API tokens re-issued. Do not run a plain `helm upgrade` from 0.1.x without backing up your data first:

1. Stop Plex (`helm uninstall` or scale the deployment to 0) so the SQLite database is not modified while you copy it.
2. Back up `/var/lib/plexmediaserver/Library` from the old library PVC (e.g. with a temporary pod mounting it).
3. Run `helm upgrade --install`. The old Deployment and PVCs are removed and the StatefulSet creates a fresh, empty library PVC.
4. Restore the backup onto the new `plex-library-<release>-plexmediaserver-0` PVC, then start Plex.
5. Re-claim the server (see `claimToken` above) and re-issue any API tokens.

Note that StatefulSet `volumeClaimTemplates` are immutable: changing `persistence.*.pvc.size` or `storageClass` after install will make the upgrade fail; resize the PVC manually (or delete it, after backing up the data, if the storage class allows).
