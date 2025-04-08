FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Cài Budgie Desktop
RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y ubuntu-budgie-desktop

# Cài XRDP và thêm user vào nhóm ssl-cert
RUN apt install -y xrdp && adduser xrdp ssl-cert

# Tạo user testuser và cấp quyền sudo
RUN useradd -m testuser -p $(openssl passwd 1234) && \
    usermod -aG sudo testuser

#####################
# Budgie panel (fix)
#####################
RUN sed -i '3 a echo "\
budgie-panel & budgie-wm --x11 & plank" > ~/.Xsession' /etc/xrdp/startwm.sh

RUN sed -i '3 a echo "\
export XDG_SESSION_DESKTOP=budgie-desktop\\n\
export XDG_SESSION_TYPE=x11\\n\
export XDG_CURRENT_DESKTOP=Budgie:GNOME\\n\
export XDG_CONFIG_DIRS=/etc/xdg/xdg-budgie-desktop:/etc/xdg\\n\
" > ~/.xsessionrc' /etc/xrdp/startwm.sh

# Cài TigerVNC và thiết lập mật khẩu VNC cho testuser
RUN apt install -y tigervnc-standalone-server novnc websockify && \
    mkdir -p /home/testuser/.vnc && \
    echo "1234" | vncpasswd -f > /home/testuser/.vnc/passwd && \
    chown -R testuser:testuser /home/testuser/.vnc && \
    chmod 600 /home/testuser/.vnc/passwd

# Expose cổng RDP và noVNC
EXPOSE 3389 8080

# CMD: khởi chạy dbus, XRDP, VNC server, và noVNC
CMD service dbus start; \
    /usr/lib/systemd/systemd-logind & \
    service xrdp start; \
    su - testuser -c "vncserver :1"; \
    websockify --web=/usr/share/novnc/ 8080 localhost:5901; \
    bash
