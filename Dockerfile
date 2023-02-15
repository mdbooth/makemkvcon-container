##
## ffmpeg
##
FROM    registry.fedoraproject.org/fedora:37 as ffmpeg_build

SHELL   ["/bin/bash", "-o", "pipefail", "-c"]
RUN     dnf install -y gcc-c++ nasm diffutils
ARG     FFMPEG=5.1.2

# Download
WORKDIR /build
RUN     curl -LO https://ffmpeg.org/releases/ffmpeg-${FFMPEG}.tar.gz

# Verify signature
RUN     curl -LO https://ffmpeg.org/releases/ffmpeg-${FFMPEG}.tar.gz.asc
COPY    ffmpeg.gpg .
RUN     gpg --import ffmpeg.gpg
RUN     gpg --verify ffmpeg-${FFMPEG}.tar.gz.asc

# Build
RUN     tar zxvf ffmpeg-${FFMPEG}.tar.gz
WORKDIR /build/ffmpeg-"${FFMPEG}"
RUN     dnf install -y diffutils
RUN     ./configure --prefix=/ffmpeg --enable-static --disable-shared --enable-pic
RUN     make install

##
## MakeMKV
##
FROM    registry.fedoraproject.org/fedora:36 as makemkv_build

SHELL   ["/bin/bash", "-o", "pipefail", "-c"]
RUN     dnf install -y gcc-c++ openssl-devel expat-devel zlib-devel qt5-qtbase-devel diffutils file
ARG     MAKEMKV=1.17.3

# Download
WORKDIR /build
RUN     curl -LO https://www.makemkv.com/download/makemkv-oss-${MAKEMKV}.tar.gz
RUN     curl -LO https://www.makemkv.com/download/makemkv-bin-${MAKEMKV}.tar.gz

# Verify signature and extract
RUN     curl -LO https://www.makemkv.com/download/makemkv-sha-${MAKEMKV}.txt
COPY    makemkv.gpg .
RUN     gpg --import makemkv.gpg
RUN     gpg --decrypt makemkv-sha-${MAKEMKV}.txt | grep -E 'makemkv-(bin|oss)-'${MAKEMKV}'.tar.gz' | sha256sum -c

# Build
COPY --from=ffmpeg_build /ffmpeg/ /ffmpeg/
RUN     tar zxvf makemkv-oss-${MAKEMKV}.tar.gz
WORKDIR /build/makemkv-oss-${MAKEMKV}
RUN     PKG_CONFIG_PATH=/ffmpeg/lib/pkgconfig ./configure
RUN     make install

WORKDIR /build
RUN     tar zxvf makemkv-bin-${MAKEMKV}.tar.gz

WORKDIR /build/makemkv-bin-${MAKEMKV}
RUN	mkdir tmp && touch tmp/eula_accepted
RUN	make install

##
## Base release image (no java)
##
FROM    registry.fedoraproject.org/fedora-minimal:36 as makemkvcon-nojava

RUN	microdnf install -y expat && microdnf clean all
COPY	--from=makemkv_build /lib/libmakemkv.so.1 /lib64/libmakemkv.so.1
COPY	--from=makemkv_build /lib/libdriveio.so.0 /lib64/libdriveio.so.0
COPY	--from=makemkv_build /usr/bin/makemkvcon /usr/bin/makemkvcon
COPY	--from=makemkv_build /usr/bin/mmccextr /usr/bin/mmccextr
COPY	--from=makemkv_build /usr/bin/mmgplsrv /usr/bin/mmgplsrv
COPY	--from=makemkv_build /usr/bin/sdftool /usr/bin/sdftool

VOLUME  ["/working"]
WORKDIR /working

ENV 	MAKEMKV_APP_KEY ""
COPY	entrypoint.sh /entrypoint.sh

ENTRYPOINT	["/entrypoint.sh"]

##
## Release image
##
FROM makemkvcon-nojava as makemkvcon

RUN	microdnf install -y java-17-openjdk-headless && microdnf clean all
COPY	--from=makemkv_build /usr/share/MakeMKV/ /usr/share/MakeMKV/

FROM makemkvcon as makemkvcon-rip

RUN     microdnf install -y util-linux && microdnf clean all

COPY	rip-device.sh /rip-device.sh
ENTRYPOINT	["/rip-device.sh"]

FROM makemkvcon as makemkvcon-backup

RUN     microdnf install -y util-linux && microdnf clean all

COPY	backup-device.sh /backup-device.sh
ENTRYPOINT	["/backup-device.sh"]
