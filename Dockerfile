FROM alpine:3.22.1 AS curl

RUN apk update && apk add build-base c-ares-dev libidn2-dev libpsl-dev nghttp2-dev openssl-dev zlib-dev zstd-dev ca-certificates-bundle perl

WORKDIR /root
RUN wget -O - https://curl.se/download/curl-8.15.0.tar.xz | tar -Jx

WORKDIR /root/curl-8.15.0
RUN ./configure \
	--prefix=/usr \
	--enable-ares \
	--enable-ipv6 \
	--enable-unix-sockets \
	--enable-static \
	--with-libidn2 \
	--with-nghttp2 \
	--with-openssl \
	--with-ca-bundle=/etc/ssl/certs/ca-certificates.crt \
	--with-ca-path=/etc/ssl/certs \
	--with-zsh-functions-dir \
	--with-fish-functions-dir \
	--disable-ldap \
	--with-pic \
	--enable-websockets \
	--without-libssh2 \
	--without-brotli \
	--disable-shared \
	--disable-manual 

RUN make -j$(nproc) && make install

FROM alpine:3.22.1 AS builder
RUN apk update && apk add build-base git automake cmake texinfo libtool autoconf linux-headers openssl-libs-static zstd-static nghttp2-static libpsl-static zlib-static libidn2-static libunistring-static curl-dev libffi-dev

COPY --from=curl /usr/lib/libcurl.a /usr/lib/
COPY txiki.js.patch HEAD_txiki.js /tmp/

WORKDIR /root
RUN git clone --recursive https://github.com/saghul/txiki.js.git --shallow-submodules

WORKDIR /root/txiki.js
RUN git checkout $(cat /tmp/HEAD_txiki.js)
RUN git apply /tmp/txiki.js.patch
RUN cp /usr/lib/libatomic.a /usr/lib/libatomic.so
RUN make -j$(nproc) USE_EXTERNAL_FFI=ON
RUN strip build/tjs


FROM scratch
COPY --from=builder /root/txiki.js/build/tjs /