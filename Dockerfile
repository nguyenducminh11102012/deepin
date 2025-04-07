FROM ubuntu:20.04

# Cập nhật và cài đặt các gói cần thiết, bao gồm ubuntudde-dde, VNC và XRDP
RUN apt update && apt install -y software-properties-common && \
    add-apt-repository -y ppa:ubuntudde-dev/stable && \
    DEBIAN_FRONTEND=noninteractive apt install -y dde-session-ui && \
    DEBIAN_FRONTEND=noninteractive apt install -y ubuntudde-dde \
    xrdp locales sudo tigervnc-standalone-server ubuntudde-dde-extras python3-pip

# Cài đặt Websockify và noVNC qua apt
RUN apt install -y websockify novnc

# Thiết lập môi trường người dùng và cài đặt ngôn ngữ
RUN apt update && apt install -y xrdp locales sudo tigervnc-standalone-server ubuntudde-dde-extras && \
    adduser xrdp ssl-cert && \
    locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8

# Tạo người dùng với quyền sudo và mật khẩu
ARG USER=testuser
ARG PASS=1234
RUN useradd -m $USER -p $(openssl passwd $PASS) && \
    usermod -aG sudo $USER && \
    chsh -s /bin/bash $USER

# Tạo file cấu hình xsession
RUN echo "#!/bin/sh\n\
export XDG_SESSION_DESKTOP=deepin\n\
export XDG_SESSION_TYPE=x11\n\
export XDG_CURRENT_DESKTOP=Deepin\n\
export XDG_CONFIG_DIRS=/etc/xdg/xdg-deepin:/etc/xdg" > /env && chmod 555 /env

# Cập nhật cấu hình xrdp để sử dụng xsession từ /env
RUN sed -i '3 a cp /env ~/.xsessionrc' /etc/xrdp/startwm.sh

# Cấu hình VNC
RUN mkdir /home/$USER/.vnc && \
    echo $PASS | vncpasswd -f > /home/$USER/.vnc/passwd && \
    chmod 0600 /home/$USER/.vnc/passwd && \
    chown -R $USER:$USER /home/$USER/.vnc

RUN echo "#!/bin/sh\n\
. /env\n\
exec /etc/X11/xinit/xinitrc" > /home/$USER/.vnc/xstartup && chmod +x /home/$USER/.vnc/xstartup

# Tạo script để chạy VNC server
RUN echo "#!/bin/sh\n\
sudo -u $USER -g $USER -- vncserver -rfbport 5902 -geometry 1920x1080 -depth 24 -verbose -localhost no -autokill no" > /startvnc && chmod +x /startvnc

# Expose cổng cho VNC, XRDP và Websockify
EXPOSE 3389
EXPOSE 5902
EXPOSE 8080

# Chạy dịch vụ và Websockify trên cổng 8080
CMD service dbus start; /usr/lib/systemd/systemd-logind & service xrdp start; /startvnc & \
    websockify --web=/usr/share/novnc 8080 localhost:5902; bash
