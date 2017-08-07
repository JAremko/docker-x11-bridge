FROM alpine

MAINTAINER JAremko <w3techplaygound@gmail.com>

# Kudos to @urzds for Xpra building example
ENV XPRA_VERSION=2.0.1

RUN echo "http://nl.alpinelinux.org/alpine/edge/testing" \
    >> /etc/apk/repositories \
    && echo "http://nl.alpinelinux.org/alpine/edge/community" \
    >> /etc/apk/repositories \
# Deps
    && apk --no-cache upgrade \
    && apk --no-cache add \
    bash \
    curl \
    cython \
    dbus-x11 \
    desktop-file-utils \
    ffmpeg \
    gst-plugins-base1 \
    gst-plugins-good1 \
    gstreamer1 \
    libvpx \
    libxcomposite \
    libxdamage \
    libxext \
    libxfixes \
    libxkbfile \
    libxrandr \
    libxtst \
    musl-utils \
    openrc \
    openssh \
    openssl \
    py-asn1 \
    py-cffi \
    py-cryptography \
    py-dbus \
    py-enum34 \
    py-gobject3 \
    py-gtk \
    py-gtkglext \
    py-idna \
    py-ipaddress \
    py-lz4 \
    py-netifaces \
    py-numpy \
    py-pillow \
    py-rencode \
    py-six \
    shared-mime-info \
    x264 \
    xf86-video-dummy \
    xhost \
    xorg-server \
# Meta build-deps
    && apk --no-cache add --virtual build-deps \
    build-base \
    cython-dev \
    git \
    ffmpeg-dev \
    flac-dev \
    libc-dev \
    libvpx-dev \
    libxcomposite-dev \
    libxdamage-dev \
    libxext-dev \
    libxfixes-dev \
    libxkbfile-dev \
    libxrandr-dev \
    libxtst-dev \
    linux-headers \
    opus-dev \
    py-dbus-dev \
    py-gtk-dev \
    py-gtkglext-dev \
    py-numpy-dev \
    py2-pip \
    python-dev \
    which \
    x264-dev \
    xvidcore-dev \
# PIP
    && pip install \
    pycrypto \
    websockify \
    xxhash \
# Xpra
    && curl https://www.xpra.org/src/xpra-$XPRA_VERSION.tar.xz | tar -xJ \
    && cd xpra-$XPRA_VERSION \
    && echo -e 'Section "Module"\n  Load "fb"\n  EndSection' \
    >> etc/xpra/xorg.conf \
    && python2 setup.py install \
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
        --with-gtk2 \
        --with-gtk_x11 \
        --with-pillow \
        --with-server \
        --with-vpx \
        --with-vsock \
        --with-x11 \
        --without-client \
        --without-csc_libyuv \
        --without-dec_avcodec2 \
        --without-enc_x265 \
        --without-gtk3 \
        --without-mdns \
        --without-opengl \
        --without-printing \
        --without-sound \
        --without-webcam \
    && mkdir -p /var/run/xpra/ \
    && cd ../.. \
    && rm -fr xpra-$XPRA_VERSION \
# su-exec
    && git clone https://github.com/ncopa/su-exec.git /tmp/su-exec \
    && cd /tmp/su-exec \
    && make \
    && chmod 770 su-exec \
    && mv su-exec /usr/sbin/ \
# Cleanup
    && apk del build-deps \
    && rm -rf /var/cache/* /tmp/* /var/log/* ~/.cache \
    && mkdir -p /var/cache/apk \
# SSH
    && mkdir -p /var/run/sshd \
    && chmod 0755 /var/run/sshd \
    && rc-update add sshd \
    && rc-status \
    && touch /run/openrc/softlevel \
    && /etc/init.d/sshd start > /dev/null 2>&1 \
    && /etc/init.d/sshd stop > /dev/null 2>&1

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
