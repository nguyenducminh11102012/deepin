FROM ubuntu:impish-20220404

RUN apt update && apt install -y software-properties-common && \
    add-apt-repository -y ppa:ubuntudde-dev/stable && \
    DEBIAN_FRONTEND=noninteractive apt install -y ubuntudde-dde

RUN apt update && apt install -y xrdp locales sudo tigervnc-standalone-server ubuntudde-dde-extras && \
    adduser xrdp ssl-cert && \
    locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8

ARG USER=testuser
ARG PASS=1234

RUN useradd -m $USER -p $(openssl passwd $PASS) && \
    usermod -aG sudo $USER && \
    chsh -s /bin/bash $USER

RUN echo "#!/bin/sh\n\
export XDG_SESSION_DESKTOP=deepin\n\
export XDG_SESSION_TYPE=x11\n\
export XDG_CURRENT_DESKTOP=Deepin\n\
export XDG_CONFIG_DIRS=/etc/xdg/xdg-deepin:/etc/xdg" > /env && chmod 555 /env

RUN sed -i '3 a cp /env ~/.xsessionrc' /etc/xrdp/startwm.sh

RUN mkdir /home/$USER/.vnc && \
    echo $PASS | vncpasswd -f > /home/$USER/.vnc/passwd && \
    chmod 0600 /home/$USER/.vnc/passwd && \
    chown -R $USER:$USER /home/$USER/.vnc

RUN echo "#!/bin/sh\n\
. /env\n\
exec /etc/X11/xinit/xinitrc" > /home/$USER/.vnc/xstartup && chmod +x /home/$USER/.vnc/xstartup

RUN echo "#!/bin/sh\n\
sudo -u $USER -g $USER -- vncserver -rfbport 5902 -geometry 1920x1080 -depth 24 -verbose -localhost no -autokill no" > /startvnc && chmod +x /startvnc

EXPOSE 3389
EXPOSE 5902

CMD service dbus start; /usr/lib/systemd/systemd-logind & service xrdp start; /startvnc; bash
