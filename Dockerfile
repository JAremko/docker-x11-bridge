FROM alpine:3.17

# Kudos to @urzds for Xpra building example
# NOTE: Don't forget to update xpra_sha file:
#       sha1sum  "xpra-${XPRA_VERSION}.tar.xz" > xpra_sha
ENV XPRA_VERSION=4.4.3

COPY video_dummy_patches /tmp/video_dummy_patches
COPY xpra_sha /tmp/

RUN echo "http://nl.alpinelinux.org/alpine/edge/testing" \
    >> /etc/apk/repositories \
    && echo "http://nl.alpinelinux.org/alpine/v3.10/community" \
    >> /etc/apk/repositories \
# Deps
    && apk --no-cache upgrade \
    && apk --no-cache add \
    bash \
    curl \
    dbus-x11 \
    inotify-tools \
    ffmpeg \
    gstreamer \
    libvpx \
    libxcomposite \
    libxdamage \
    libxext \
    libxfixes \
    libxkbfile \
    libxrandr \
    libxtst \
    lz4 \
    lzo \
    openrc \
    openssh \
    openssl \
    py3-asn1 \
    py3-dbus \
    py3-gobject3 \
    py3-idna \
    py3-ipaddress \
    py3-lz4 \
    py3-netifaces \
    py3-numpy \
    py3-pillow \
    py3-rencode \
    py3-six \
    shared-mime-info \
    x264 \
    xhost \
    xorg-server \
# Meta build-deps
    && apk --no-cache add --virtual build-deps \
    autoconf \
    automake \
    build-base \
    coreutils \
    inotify-tools-dev \
    ffmpeg-dev \
    flac-dev \
    git \
    gtk+3.0-dev \
    libc-dev \
    libtool \
    libvpx-dev \
    libxcomposite-dev \
    libxdamage-dev \
    libxext-dev \
    libxfixes-dev \
    libxi-dev \
    libxkbfile-dev \
    libxrandr-dev \
    libxres-dev \
    libxtst-dev \
    linux-headers \
    lz4-dev \
    musl-utils \
    npm \
    opus-dev \
    pandoc \
    py3-dbus-dev \
    py3-gobject3-dev \
    py3-numpy-dev \
    py3-pip \
    py3-yuicompressor \
    python3-dev \
    util-macros \
    which \
    x264-dev \
    xorg-server-dev \
    xorgproto \
    xvidcore-dev \
    xz \
    && npm install uglify-js@2 -g \
    && pip3 install -U wheel pip \
    && pip3 install paramiko pycryptodome PyInotify websockify cython \
# Xpra
    && cd /tmp \
    && curl http://www.xpra.org/src/xpra-$XPRA_VERSION.tar.xz -o xpra.tar.xz \
    && sha1sum -c xpra_sha \
    && tar -xf "xpra.tar.xz" \
    && echo -e 'Section "Module"\n  Load "fb"\n  EndSection' \
    >> fs/etc/xpra/xorg.conf \
    && cd "/tmp/xpra-${XPRA_VERSION}" \
    && python3 setup.py install \
    --verbose \
    --with-Xdummy \
    --with-Xdummy_wrapper \
    --with-bencode \
    --with-clipboard \
    --with-csc_swscale \
    --with-cython_bencode \
    --with-dbus \
    --with-enc_ffmpeg \
    --with-enc_x264 \
    --with-gtk3 \
    --with-gtk_x11 \
    --with-pillow \
    --with-server \
    --with-vpx \
    --with-vsock \
    --with-x11 \
    --without-client \
    --without-csc_libyuv \
    --without-cuda_kernels \
    --without-cuda_rebuild \
    --without-dec_avcodec2 \
    --without-enc_x265 \
    --without-mdns \
    --without-opengl \
    --without-printing \
    --without-uinput \
    --without-sound \
    --without-strict \
    --without-webcam \
    && mkdir -p /var/run/xpra/ \
    && cd /tmp \
# su-exec
    && git clone https://github.com/ncopa/su-exec.git \
    /tmp/su-exec \
    && cd /tmp/su-exec \
    && make \
    && chmod 770 su-exec \
    && mv su-exec /usr/sbin/ \
# xf86-video-dummy
    && git clone https://github.com/JAremko/xf86-video-dummy.git \
    /tmp/xf86-video-dummy \
    && cd /tmp/xf86-video-dummy \
    && git apply \
    /tmp/video_dummy_patches/Constant-DPI.patch \
    /tmp/video_dummy_patches/fix-pointer-limits.patch \
    /tmp/video_dummy_patches/30-bit-depth.patch \
    && libtoolize \
    && aclocal \
    && autoconf \
    && automake \
    --add-missing \
    --force-missing \
    && ./configure \
    && make \
    && make install \
    && mv /usr/local/lib/xorg/modules/drivers/dummy_drv.so \
    /usr/lib/xorg/modules/drivers/ \
# Cleanup
    && apk del build-deps \
    && rm -rf /var/cache/* /tmp/* /var/log/* ~/.cache \
    && mkdir -p /var/cache/apk \
# SSH
    && mkdir -p /var/run/sshd \
    && chmod 0755 /var/run/sshd \
    && rc-update add sshd \
    && rc-status \
    && touch /run/openrc/softlevel
# RUN /etc/init.d/sshd start \
#     && /etc/init.d/sshd stop

# docker run ... --volumes-from <ME> -e DISPLAY=<MY_DISPLAY> ... firefox
VOLUME /tmp/.X11-unix

# Mount <some_ssh_key>.pub in here to enable xpra via ssh
VOLUME /etc/pub-keys

COPY bin/* /usr/local/bin/

ENV DISPLAY=":14"            \
    SHELL="/bin/bash"        \
    SSHD_PORT="22"           \
    START_XORG="yes"         \
    XPRA_HTML="no"           \
    XPRA_MODE="start"        \
    XPRA_READONLY="no"       \
    XORG_DPI="96"            \
    XPRA_COMPRESS="0"        \
    XPRA_DPI="0"             \
    XPRA_ENCODING="rgb"      \
    XPRA_HTML_DPI="96"       \
    XPRA_KEYBOARD_SYNC="yes" \
    XPRA_MMAP="yes"          \
    XPRA_SHARING="yes"       \
    XPRA_TCP_PORT="10000"

ENV GID="1000"         \
    GNAME="xpra"       \
    SHELL="/bin/bash"  \
    UHOME="/home/xpra" \
    UID="1000"         \
    UNAME="xpra"

EXPOSE $SSHD_PORT $XPRA_TCP_PORT

ENTRYPOINT ["/usr/local/bin/run"]
CMD ["xhost +"]
