ARG BUILD_FROM
FROM ${BUILD_FROM}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV \
    LANG="C.UTF-8" \
    DEBIAN_FRONTEND="noninteractive" \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    S6_CMD_WAIT_FOR_SERVICES=1 \
    S6_SERVICES_READYTIME=50

ARG BASHIO_VERSION=0.17.5
ARG S6_OVERLAY_VERSION=3.2.2.0
ARG PG_MAJOR=18

RUN \
    apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        jq \
        tzdata \
        xz-utils \
        gnupg \
        lsb-release \
    && rm -rf /var/lib/apt/lists/*

# PostgreSQL 18 packages plus bundled extensions.
RUN \
    install -d /etc/apt/keyrings \
    && curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/keyrings/postgresql.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/postgresql.gpg] http://apt.postgresql.org/pub/repos/apt bookworm-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        postgresql-18 \
        postgresql-client-18 \
        postgresql-18-timescaledb \
        postgresql-18-pgvector \
    && rm -rf /var/lib/apt/lists/*

# S6-Overlay.
ADD --unpack=true "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz" /
ADD --unpack=true "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-arch.tar.xz" /
ADD --unpack=true "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-noarch.tar.xz" /

# Bashio.
ADD --unpack=true "https://github.com/hassio-addons/bashio/archive/v${BASHIO_VERSION}.tar.gz" /usr/src/bashio
RUN \
    mv /usr/src/bashio/bashio-*/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio \
    && rm -rf /usr/src/bashio

# Add addon runtime files.
COPY rootfs/ /

# Writable runtime paths.
RUN \
    mkdir -p /data \
    /run/postgresql \
    /var/lib/postgresql \
    /var/log/postgresql \
    /etc/fix-attrs.d \
    /etc/services.d

ENTRYPOINT ["/init"]
