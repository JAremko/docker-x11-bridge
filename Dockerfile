FROM alpine:edge

MAINTAINER JAremko <w3techplaygound@gmail.com>

ENV XPRA_URL="https://www.xpra.org/dists/xenial/main/\
binary-amd64/xpra_0.17.6-r14318-1_amd64.deb"

RUN echo "http://nl.alpinelinux.org/alpine/edge/main"         \
      >> /etc/apk/repositories                             && \
    echo "http://nl.alpinelinux.org/alpine/edge/testing"      \
      >> /etc/apk/repositories                             && \
    echo "http://nl.alpinelinux.org/alpine/edge/community"    \
      >> /etc/apk/repositories                             && \

    apk --update add bash dbus-x11 fontconfig libgcc openrc openssh    \
      openssl-dev py-dbus py-gst0.10 python-dev python2 xpra        && \
    apk --update add --virtual build-deps build-base bzip2             \
      curl libstdc++ openssl-dev py2-pip python2-dev tar xz         && \

# ssh
    mkdir -p /var/run/sshd                                     && \
    chmod 0755 /var/run/sshd                                   && \
    echo "PasswordAuthentication no" >> "/etc/ssh/sshd_config" && \
    mkdir -p "/root/.ssh/"                                     && \
    chmod 700 "/root/.ssh/"                                    && \
    rc-update add sshd                                         && \
    rc-status                                                  && \
    touch /run/openrc/softlevel                                && \
    /etc/init.d/sshd start > /dev/null 2>&1                    && \
    /etc/init.d/sshd stop > /dev/null 2>&1                     && \

# add missing Xpra files
    cd /tmp/                                             && \
    curl "${XPRA_URL}" > xpra.deb                        && \
    ar x xpra.deb                                        && \
    tar xJf ./data.tar.xz                                && \
    mv ./usr/share/xpra/www/include /usr/share/xpra/www/ && \
    rm -rf /tmp/*                                        && \

# Python stuff for Xpra
    pip install pycrypto websockify                                         && \
    mv /usr/lib/python2.7/site-packages/ /usr/lib/python2.7/~site-packages/ && \
    apk del build-deps                                                      && \
    mv /usr/lib/python2.7/~site-packages/ /usr/lib/python2.7/site-packages/ && \
    rm -rf /var/cache/* /tmp/* /var/log/* ~/.cache

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
# Grant access to those who can mount the X11 volume
# If you have access to a docker volume you are effectively root level user
CMD "xhost +"
