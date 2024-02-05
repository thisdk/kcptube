FROM alpine:latest

ARG KCPTUBE_VERSION="0.5.3"
ARG KCPTUBE_URL="https://github.com/cnbatch/kcptube/releases/download/v${KCPTUBE_VERSION}/kcptube-linux-musl-x64.tar.bz2"

RUN set -ex && \
    apk add --no-cache tzdata && \
    wget -O /tmp/kcptube.tar.bz2 ${KCPTUBE_URL} && \
    tar -jxvf /tmp/kcptube.tar.bz2 kcptube -C /tmp/ && \
    mv /tmp/kcptube /usr/bin/kcptube && \
    rm -f /tmp/kcptube.tar.bz2

ENTRYPOINT ["kcptube"]
