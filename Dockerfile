FROM ubuntu:jammy-20231211.1
ADD ./wubuntu.tar /

ARG USER=testuser
ARG PASS=1234

RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y locales sudo xrdp tigervnc-standalone-server && \
    adduser xrdp ssl-cert && \
    locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8

RUN sed -i 's#Exec=.*google-chrome.* #Exec=/usr/bin/google-chrome --no-sandbox --disable-gpu --disable-software-rasterizer --disable-dev-shm-usage #g' /usr/share/applications/* /home/$USER/.local/share/applications/* && \
    sed -i 's#Exec=.*microsoft-edge.* #Exec=/usr/bin/microsoft-edge --no-sandbox --disable-gpu --disable-software-rasterizer --disable-dev-shm-usage #g' /usr/share/applications/* /home/$USER/.local/share/applications/*

RUN echo "#!/bin/sh\n\
export XDG_SESSION_DESKTOP=KDE\n\
export XDG_SESSION_TYPE=x11\n\
export XDG_CURRENT_DESKTOP=KDE\n\
export XDG_CONFIG_DIRS=/home/agiledevart/.config/kdedefaults:/etc/xdg/xdg-plasma:/etc/xdg:/usr/share/kubuntu-default-settings/kf5-settings\n\
exec dbus-run-session -- startplasma-x11" > /xstartup && chmod +x /xstartup

RUN mkdir /home/$USER/.vnc && \
    echo $PASS | vncpasswd -f > /home/$USER/.vnc/passwd && \
    chmod 0600 /home/$USER/.vnc/passwd && \
    chown -R $USER:$USER /home/$USER/.vnc

RUN cp -f /xstartup /etc/xrdp/startwm.sh && \
    cp -f /xstartup /home/$USER/.vnc/xstartup

RUN echo "#!/bin/sh\n\
sudo -u $USER -g $USER -- vncserver -rfbport 5902 -geometry 1920x1080 -depth 24 -verbose -localhost no -autokill no" > /startvnc && chmod +x /startvnc

EXPOSE 3389
EXPOSE 5902

CMD service dbus start; /usr/lib/systemd/systemd-logind & service xrdp start; /startvnc; bash
