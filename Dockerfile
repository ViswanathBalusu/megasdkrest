FROM golang:alpine AS builder

ARG CPU_ARCH="amd64"
ENV HOST_CPU_ARCH=$CPU_ARCH

#Deps
RUN apk add --no-cache --update unzip tar xz wget alpine-sdk git libtool autoconf automake linux-headers musl-dev m4 \
    build-base perl ca-certificates

# #Libtool
# RUN wget -q https://ftpmirror.gnu.org/libtool/libtool-2.4.6.tar.gz --no-check-certificate && \
#     tar -xzf libtool*.tar.gz && rm -rf libtool*.tar.gz && cd libtool*/ && \
#     ./configure --enable-static --enable-shared --enable-ltdl-install && make -j$(getconf _NPROCESSORS_ONLN) && make install
    
#ZLib
RUN wget -q https://zlib.net/zlib-1.2.11.tar.gz --no-check-certificate && \
    tar -xzf zlib*.tar.gz && rm -rf zlib*.tar.gz && cd zlib*/ && \
    ./configure --static && make -j$(getconf _NPROCESSORS_ONLN) && make install

#OpenSSL
RUN wget -q https://www.openssl.org/source/openssl-1.1.1k.tar.gz --no-check-certificate && \
    tar -xzf openssl*.tar.gz && rm -rf openssl*.tar.gz && cd openssl*/ && \
    CFLAGS=-fPIC CPPFLAGS=-fPIC ./config -static && make -j$(getconf _NPROCESSORS_ONLN) && make install_sw

#CryptoPP
RUN wget -q https://github.com/weidai11/cryptopp/archive/refs/tags/CRYPTOPP_8_5_0.tar.gz --no-check-certificate && \
    tar -xzf CRYPTOPP*.tar.gz && rm -rf CRYPTOPP*.tar.gz && cd cryptopp*/ && \
    make libcryptopp.a -j$(getconf _NPROCESSORS_ONLN) && make -j$(getconf _NPROCESSORS_ONLN) && make install

#C-Ares
RUN wget -q https://c-ares.haxx.se/download/c-ares-1.17.1.tar.gz  --no-check-certificate && \
    tar -xzf c-ares*.tar.gz && rm -rf c-ares*.tar.gz && cd c-ares*/ && \
    ./configure --enable-static --enable-shared && make -j$(getconf _NPROCESSORS_ONLN) && make install

#Sqlite3
RUN wget -q https://www.sqlite.org/2021/sqlite-autoconf-3360000.tar.gz --no-check-certificate && \
    tar -xzf sqlite*.tar.gz && rm -rf sqlite*.tar.gz && cd sqlite*/ && \
    ./configure --enable-static --enable-shared && make -j$(getconf _NPROCESSORS_ONLN) && make install

#libsodium
RUN wget -q https://download.libsodium.org/libsodium/releases/libsodium-1.0.18.tar.gz --no-check-certificate && \
    tar -xzf libsodium*.tar.gz && rm -rf libsodium*.tar.gz && cd libsodium*/ && \
    ./configure --enable-static --enable-shared && make -j$(getconf _NPROCESSORS_ONLN) && make install

#cURL
RUN wget -q https://curl.se/download/curl-7.77.0.tar.gz --no-check-certificate && \
    tar -xzf curl*.tar.gz && rm -rf curl*.tar.gz && cd curl*/ && \
    ./buildconf && autoreconf -vif && \
    ./configure --with-openssl --enable-static --without-brotli CFLAGS=-fPIC CPPFLAGS=-fPIC && \
    make -j$(getconf _NPROCESSORS_ONLN) && make install -j$(getconf _NPROCESSORS_ONLN)

# MegaSDK
RUN git clone https://github.com/meganz/sdk.git sdk && cd sdk && \
    git checkout v3.9.1 && \
    sh autogen.sh && \
    ./configure --disable-examples --disable-shared --enable-static --without-freeimage && \
    make -j$(getconf _NPROCESSORS_ONLN) && \
    make install

#MegaSDKgo
RUN mkdir -p /usr/local/go/src/ && cd /usr/local/go/src/ && \
    git clone https://github.com/viswanathbalusu/megasdkgo && \
    cd megasdkgo && rm -rf .git && \
    mkdir include && cp -r /go/sdk/include/* include && \
    mkdir .libs && \
    cp /usr/local/lib/lib*.a .libs/ && \
    cp /usr/local/lib/lib*.la .libs/ && \
    go tool cgo megasdkgo.go

RUN git clone https://github.com/viswanathbalusu/megasdkrest && cd megasdkrest && \
    go get github.com/urfave/cli/v2 && \
    go build -ldflags "-linkmode external -extldflags '-static' -s -w" . && \
    mkdir -p /go/build/ && mv megasdkrpc ../build/megasdkrest-${HOST_CPU_ARCH}

FROM scratch AS megasdkrest

COPY --from=builder /go/build/ /
