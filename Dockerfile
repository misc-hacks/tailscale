FROM golang:latest AS builder
WORKDIR /app

# ========= CONFIG =========
ARG MODIFIED_DERPER_GIT=https://github.com/misc-hacks/tailscale
ARG BRANCH=no-hostname-chk
# ==========================

RUN git clone -b $BRANCH $MODIFIED_DERPER_GIT tailscale \
    && cd /app/tailscale/cmd/derper \
    && /usr/local/go/bin/go build -ldflags "-s -w" -o /app/derper

FROM ubuntu:20.04
WORKDIR /app

RUN apt-get update \
    && apt-get install -y openssl curl \
    && rm -rf /var/lib/apt/lists/*

COPY build_cert.sh /app/
COPY --from=builder /app/derper /app/derper

# ========= CONFIG =========
ENV DERP_HOST=127.0.0.1
ENV DERP_CERTS=/app/certs/
ENV DERP_STUN true
ENV DERP_VERIFY_CLIENTS false
ENV DERP_PORT=443
ENV DERP_STUN=3478
# ==========================

CMD bash /app/build_cert.sh $DERP_HOST $DERP_CERTS /app/san.conf \
    && /app/derper --hostname=$DERP_HOST \
        --certmode=manual \
        --certdir=$DERP_CERTS \
        --stun=$DERP_STUN  \
        --verify-clients=$DERP_VERIFY_CLIENTS \
        -http-port -1 \
        -a ":$DERP_PORT" \
        -stun-port $DERP_STUN
