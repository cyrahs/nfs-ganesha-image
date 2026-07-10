# NFS-Ganesha image

Minimal `linux/amd64` NFS-Ganesha image built directly from the latest stable
upstream release. A multi-stage Debian 13 slim build enables the VFS FSAL and
NFSv3/NFSv4, while excluding build tools, storage-specific FSALs, and optional
administration services from the runtime image.

Published image:

```text
ghcr.io/cyrahs/nfs-ganesha-image:<major.minor>
ghcr.io/cyrahs/nfs-ganesha-image:<major>
ghcr.io/cyrahs/nfs-ganesha-image:latest
```

The scheduled workflow resolves the current stable release from the official
NFS-Ganesha GitHub Releases API. A manual workflow run can pin a specific
official tag such as `V11.1`. Every image includes OCI source and revision
labels, an SBOM, and build provenance.

## Usage

Mount a Ganesha configuration at `/etc/ganesha/ganesha.conf` and the exported
filesystem at the path referenced by that configuration.

```bash
docker run --rm --privileged \
  -p 2049:2049/tcp \
  -p 20048:20048/tcp \
  -v ./ganesha.conf:/etc/ganesha/ganesha.conf:ro \
  -v /srv/export:/export \
  ghcr.io/cyrahs/nfs-ganesha-image:11.1
```

The entrypoint starts `rpcbind` and runs `ganesha.nfsd` in the foreground.
Pass a command to the container to bypass the default entrypoint behavior.

## Upstream

NFS-Ganesha is licensed under the LGPL and maintained at
<https://github.com/nfs-ganesha/nfs-ganesha>. This repository contains only
the image build and publishing configuration.
