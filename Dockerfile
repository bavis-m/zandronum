
# syntax=docker/dockerfile:1

ARG ALPINE_VERSION=3.23

# ------------------------------------------------------------
# Build stage
# ------------------------------------------------------------
FROM alpine:${ALPINE_VERSION} AS builder

ARG BUILD_JOBS=4

RUN apk add --no-cache \
    build-base \
    cmake \
    git \
    python3 \
    pkgconf \
    sdl12-compat-dev \
    bzip2-dev \
    libjpeg-turbo-dev \
    zlib-dev \
    libgme-dev \
    openssl-dev \
    zstd-dev \
    musl-fts-dev

WORKDIR /src/zandronum
COPY . .

# Build dedicated server.
RUN cmake -S . -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DSERVERONLY=ON \
    -DNO_ASM=ON \
    -DNO_STRIP=OFF \
    -DFORCE_INTERNAL_GME=ON \
    && cmake --build build --verbose --parallel "${BUILD_JOBS}"

# Stage the executable and generated PK3 files.
RUN mkdir -p /opt/zandronum \
    && cp build/zandronum-server /opt/zandronum/ \
    && find build -maxdepth 1 -name '*.pk3' \
        -exec cp {} /opt/zandronum/ \;


# ------------------------------------------------------------
# Runtime stage
# ------------------------------------------------------------
FROM alpine:${ALPINE_VERSION} AS runtime

RUN apk add --no-cache \
    libstdc++ \
    sdl12-compat \
    libbz2 \
    libjpeg-turbo \
    zlib \
    libcrypto3 \
    libssl3 \
    zstd \
    musl-fts \
    shadow \
    su-exec && \
    mkdir /usr/share/GeoIP/

WORKDIR /opt/zandronum

COPY --from=builder /opt/zandronum/ /opt/zandronum/
COPY --from=builder /src/zandronum/src/gitinfo.h /opt/zandronum/
COPY GeoIP.dat /usr/share/GeoIP/GeoIP.dat

# Run unprivileged.
RUN addgroup -S zandronum \
    && adduser -S -D -h /home/zandronum -G zandronum zandronum

COPY entrypoint.sh /entrypoint.sh

VOLUME ["/home/zandronum"]

WORKDIR /home/zandronum

CMD ["/entrypoint.sh", "/home/zandronum/bin/start"]

