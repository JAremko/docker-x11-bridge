FROM alpine:3.17
RUN apk add bash git py3-cairo py3-xdg su-exec xhost xpra
RUN mkdir /tmp/xpra-html5 && cd /tmp/xpra-html5 && git clone https://github.com/Xpra-org/xpra-html5 && cd xpra-html5 && ./setup.py install && cd / && rm -rf /tmp/xpra-html5

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
    XPRA_TCP_PORT="10000"    \
    XPRA_WS_PORT="10001"

ENV GID="1000"         \
    GNAME="xpra"       \
    SHELL="/bin/bash"  \
    UHOME="/home/xpra" \
    UID="1000"         \
    UNAME="xpra"

EXPOSE $SSHD_PORT $XPRA_TCP_PORT $XPRA_WS_PORT

ENTRYPOINT ["/usr/local/bin/run"]
CMD ["xhost +"]
