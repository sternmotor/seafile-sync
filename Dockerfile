# IMAGE CONFIG ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


FROM ubuntu:22.04

LABEL Description="Seafile repository syncer"
LABEL Maintainer="Sternmotor NET, dev team <dev@sternmotor.net>"


# SYSTEM ENVIRONMENT ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


ARG TIME_ZONE=Europe/Berlin
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=$TIME_ZONE
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8


# COPY FILES OF THIS BUILD PROJECT ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

COPY bin/* /usr/local/bin/


# PACKAGE INSTALLATION ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# packages
RUN set -eux \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
        bsdmainutils \
        ca-certificates \
        curl \
        jq \
        tini \
        tzdata \
# && curl -fsSL  https://deb.opera.com/archive.key \
#    > /usr/share/keyrings/seafile-keyring.asc \
# &&  wget https://linux-clients.seafile.com/seafile.asc -O /usr/share/keyrings/seafile-keyring.asc \
 && curl https://linux-clients.seafile.com/seafile.asc -o /usr/share/keyrings/seafile-keyring.asc \
 && os_release=$(awk -F= '/VERSION_CODENAME/{print $2}' /etc/os-release) \
 && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/seafile-keyring.asc] https://linux-clients.seafile.com/seafile-deb/$os_release/ stable main" > /etc/apt/sources.list.d/seafile.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
        seafile-cli \
 && apt-get --yes --purge autoremove \
 && apt-get clean autoclean \
 && bash -c "rm -rvf /usr/share/{doc,groff,info,locale,main} /var/lib/apt/lists/* {,/var}/tmp/*" \
 ;

# date and time, permissions
RUN set -eux \
 && ln -snvf /usr/share/zoneinfo/$TIME_ZONE /etc/localtime \
 && echo $TIME_ZONE > /etc/timezone \
 && chmod -v 0755 /usr/local/bin/seafile-sync \
 ;

# install user, set up working directories/ volumes
ARG CONTAINER_USER=seafile
ARG DATA_DIR=/seafile-data
ARG HOME_DIR=/var/lib/seafile
ARG CONTAINER_UID=1000
ARG CONTAINER_GID=1000

RUN set -eux \
 && groupadd --gid $CONTAINER_GID $CONTAINER_USER \
 && useradd  --uid $CONTAINER_UID --gid $CONTAINER_GID --home-dir "$HOME_DIR" \
             --no-log-init --create-home --shell /sbin/nologin $CONTAINER_USER \
 && mkdir -p "$DATA_DIR" \
 && chown -vR $CONTAINER_UID:$CONTAINER_GID "$HOME_DIR" "$DATA_DIR" \
 ;

# store user name for later use in entrypoint script and inheriting images
ENV CONTAINER_USER=$CONTAINER_USER

# prepare seafile config directory
USER "$CONTAINER_USER"
RUN set -eux \
 && mkdir -p "$HOME_DIR/seafile-client" \
 && seaf-cli init -d "$HOME_DIR/seafile-client" \
 ;

# DOCKER INTEGRATION ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


WORKDIR "$DATA_DIR"
VOLUME "$DATA_DIR"
CMD ["tini", "--", "seafile-sync"] 
#HEALTHCHECK --interval=5s --timeout=30s --start-period=5s CMD docker-healthcheck

# vim:ft=sh:ts=4:sw=4:
