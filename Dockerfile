FROM alpine:edge

MAINTAINER JAremko <w3techplaygound@gmail.com>

ENV XPRA_URL="https://www.xpra.org/dists/xenial/main/binary-amd64/\
xpra_1.0.1-r14723-1_amd64.deb"

RUN echo "http://nl.alpinelinux.org/alpine/edge/testing" \
    >> /etc/apk/repositories \
    && echo "http://nl.alpinelinux.org/alpine/edge/community" \
    >> /etc/apk/repositories \
    && apk --update add \
    bash \
    dbus-x11 \
    fontconfig \
    libgcc \
    libffi \
    openrc \
    openssh \
    openssl \
    py-dbus \
    py-gst0.10 \
    python2 \
    xpra \
    && apk --update add --virtual build-deps \
    build-base \
    bzip2 \
    curl \
    libffi-dev \
    libstdc++ \
    openssl-dev \
    py2-pip \
    python2-dev \
    tar \
    xz \
# ssh
    && mkdir -p /var/run/sshd \
    && chmod 0755 /var/run/sshd \

    && mkdir -p "/root/.ssh/" \
    && chmod 700 "/root/.ssh/" \
    && rc-update add sshd \
    && rc-status \
    && touch /run/openrc/softlevel \
    && /etc/init.d/sshd start > /dev/null 2>&1 \
    && /etc/init.d/sshd stop > /dev/null 2>&1 \

# add missing Xpra files
    && mkdir -p /var/run/xpra \
    && cd /tmp/ \
    && curl "${XPRA_URL}" > xpra.deb \
    && ar x xpra.deb \
    && tar xJf ./data.tar.xz \
    && mv ./usr/share/xpra/www/ /usr/share/xpra/www/ \
    && rm -rf /tmp/* \

# Python stuff for Xpra
    && pip install \
    cffi \
    gi \
    pycrypto \
    pytools \
    six \
    websockify \
    xxhash \
    && mv /usr/lib/python2.7/site-packages/ \
    /usr/lib/python2.7/~site-packages/ \
    && apk del build-deps \
    && mv /usr/lib/python2.7/~site-packages/ \
    /usr/lib/python2.7/site-packages/ \
    && rm -rf /var/cache/* /tmp/* /var/log/* ~/.cache

# docker run ... --volumes-from <ME> -e DISPLAY=<MY_DISPLAY> ... firefox
VOLUME /tmp/.X11-unix

COPY bin/* /usr/local/bin/

ENV SHELL="/bin/bash"        \
    SSHD_PORT="22"           \
    XPRA_DISPLAY=":14"       \
    XPRA_SHARING="yes"       \
    XPRA_ENCODING="rgb"      \
    XPRA_MMAP="yes"          \
    XPRA_KEYBOARD_SYNC="yes" \
    XPRA_COMPRESS="0"        \
    XPRA_TCP_PORT="10000"    \
    XPRA_DPI="0"             \
    XORG_DPI="96"            \
    MODE="html"

EXPOSE $SSHD_PORT $XPRA_TCP_PORT

ENTRYPOINT ["/bin/bash", "-c", "/usr/local/bin/run"]
CMD "xhost +"
