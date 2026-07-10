# syntax=docker/dockerfile:1.7

FROM debian:13-slim AS build

ARG GANESHA_TAG

RUN test -n "${GANESHA_TAG}"

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        bison \
        build-essential \
        ca-certificates \
        cmake \
        flex \
        git \
        libacl1-dev \
        libblkid-dev \
        libcap-dev \
        libjemalloc-dev \
        libkrb5-dev \
        libnsl-dev \
        libssl-dev \
        libtirpc-dev \
        liburcu-dev \
        pkg-config \
        uuid-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

RUN git clone \
        --branch "${GANESHA_TAG}" \
        --depth 1 \
        --recurse-submodules \
        --shallow-submodules \
        https://github.com/nfs-ganesha/nfs-ganesha.git

RUN cmake \
        -S /src/nfs-ganesha/src \
        -B /build \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DENABLE_VFS_POSIX_ACL=ON \
        -DRADOS_URLS=OFF \
        -DUSE_9P=OFF \
        -DUSE_ADMIN_TOOLS=OFF \
        -DUSE_DBUS=OFF \
        -DUSE_FSAL_CEPH=OFF \
        -DUSE_FSAL_GLUSTER=OFF \
        -DUSE_FSAL_GPFS=OFF \
        -DUSE_FSAL_KVSFS=OFF \
        -DUSE_FSAL_LIZARDFS=OFF \
        -DUSE_FSAL_LUSTRE=OFF \
        -DUSE_FSAL_MEM=OFF \
        -DUSE_FSAL_NULL=OFF \
        -DUSE_FSAL_PROXY_V3=OFF \
        -DUSE_FSAL_PROXY_V4=OFF \
        -DUSE_FSAL_RGW=OFF \
        -DUSE_FSAL_SAUNAFS=OFF \
        -DUSE_FSAL_VFS=ON \
        -DUSE_FSAL_XFS=OFF \
        -DUSE_GSS=OFF \
        -DUSE_GUI_ADMIN_TOOLS=OFF \
        -DUSE_MAN_PAGE=OFF \
        -DUSE_MONITORING=OFF \
        -DUSE_NFSACL3=OFF \
        -DUSE_NFSIDMAP=OFF \
        -DUSE_NLM=OFF \
        -DUSE_RADOS_RECOV=OFF \
        -DUSE_RQUOTA=OFF \
        -D_MSPAC_SUPPORT=OFF \
    && cmake --build /build --parallel "$(nproc)" \
    && cmake --install /build \
    && mkdir -p /usr/local/share \
    && printf '%s\n' \
        "tag=${GANESHA_TAG}" \
        "commit=$(git -C /src/nfs-ganesha rev-parse HEAD)" \
        > /usr/local/share/nfs-ganesha-build.txt \
    && LD_LIBRARY_PATH=/usr/local/lib /usr/local/bin/ganesha.nfsd -v

FROM debian:13-slim

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        libacl1 \
        libblkid1 \
        libcap2 \
        libjemalloc2 \
        libstdc++6 \
        liburcu8t64 \
        libuuid1 \
        rpcbind \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /usr/local/ /usr/local/
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN chmod 0755 /usr/local/bin/docker-entrypoint.sh \
    && mkdir -p \
        /etc/ganesha \
        /usr/local/var/lib/nfs/ganesha \
        /usr/local/var/run/ganesha \
    && ln -s /proc/mounts /etc/mtab \
    && ldconfig

ENV GANESHA_CONFIG=/etc/ganesha/ganesha.conf
ENV LD_LIBRARY_PATH=/usr/local/lib

EXPOSE 111/tcp 111/udp 2049/tcp 2049/udp 20048/tcp 20048/udp

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
