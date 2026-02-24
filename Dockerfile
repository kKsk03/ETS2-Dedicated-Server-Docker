FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        gosu \
        libc6-i386 \
        lib32gcc-s1 \
        lib32stdc++6 \
        libatomic1 \
        libcurl4 \
        libgcc-s1 \
        libx11-6 \
        libxext6 \
        libxi6 \
        libxrandr2 \
        libxrender1 \
        libxcb1 \
        libstdc++6 \
        libtinfo6 \
        tini \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid 1000 steam \
    && useradd --uid 1000 --gid 1000 --create-home --home-dir /home/steam --shell /bin/bash steam

WORKDIR /home/steam

RUN mkdir -p /home/steam/steamcmd \
    && chown -R steam:steam /home/steam \
    && su -s /bin/bash steam -c "cd /home/steam/steamcmd && curl -fsSL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz | tar -xz"

COPY --chown=steam:steam docker/entrypoint.sh /home/steam/entrypoint.sh
COPY --chown=steam:steam docker/defaults/server_config.sii /home/steam/defaults/server_config.sii
RUN chmod +x /home/steam/entrypoint.sh

ENV ETS2_APP_ID=1948160 \
    ETS2_AUTO_UPDATE=true \
    ETS2_VALIDATE_ON_UPDATE=false \
    ETS2_BRANCH=public \
    ETS2_INSTALL_DIR=/data/server \
    ETS2_DATA_HOME=/data/ets2data \
    ETS2_FIX_PERMISSIONS=true \
    ETS2_REQUIRE_SERVER_PACKAGES=true

VOLUME ["/data"]

ENTRYPOINT ["/usr/bin/tini", "--", "/home/steam/entrypoint.sh"]
