FROM kalilinux/kali-rolling:latest
ENV DEBIAN_FRONTEND=noninteractive

# 1. Install Systemd, FUSE 3 (AppImage support), GUI, and tools
RUN apt-get update && apt-get install -y systemd fuse3 kali-desktop-xfce xrdp curl sudo wget dbus-x11 gnupg && apt-get clean

# 2. PURGE DESKTOP BLOAT
RUN rm -f /etc/xdg/autostart/xfce4-power-manager.desktop /etc/xdg/autostart/light-locker.desktop /etc/xdg/autostart/xscreensaver.desktop

# 3. Mask unnecessary hardware systemd services and set boot target
RUN rm -f /etc/systemd/system/display-manager.service && \
    systemctl mask dev-mqueue.mount dev-hugepages.mount systemd-remount-fs.service sys-kernel-config.mount sys-kernel-debug.mount sys-fs-fuse-connections.mount display-manager.service graphical.target systemd-logind.service && \
    systemctl set-default multi-user.target

# 4. LOW-LATENCY XRDP NETWORK TUNING
RUN sed -i 's/crypt_level=high/crypt_level=low/g' /etc/xrdp/xrdp.ini && \
    sed -i 's/max_bpp=32/max_bpp=16/g' /etc/xrdp/xrdp.ini && \
    echo "tcp_nodelay=true" >> /etc/xrdp/xrdp.ini && \
    echo "tcp_send_buffer_bytes=4194304" >> /etc/xrdp/xrdp.ini

# 5. Install Tailscale VPN
RUN mkdir -p /usr/share/keyrings && \
    curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg > /dev/null && \
    curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list && \
    apt-get update && apt-get install -y tailscale && apt-get clean

# 6. Enable native systemd services
RUN systemctl enable xrdp tailscaled

# 7. FIX FOR ROOT GUI, SOFTWARE RENDERING, & XFCE PERFORMANCE OVERRIDES
RUN echo "#!/bin/sh" > /etc/xrdp/startwm.sh && \
    echo "export XDG_SESSION_DESKTOP=xfce" >> /etc/xrdp/startwm.sh && \
    echo "export XDG_CURRENT_DESKTOP=XFCE" >> /etc/xrdp/startwm.sh && \
    echo "export LIBGL_ALWAYS_SOFTWARE=1" >> /etc/xrdp/startwm.sh && \
    echo "export GALLIUM_DRIVER=llvmpipe" >> /etc/xrdp/startwm.sh && \
    echo "xfconf-query -c xfwm4 -p /general/use_compositing -t bool -s false &" >> /etc/xrdp/startwm.sh && \
    echo "xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-show -t bool -s false &" >> /etc/xrdp/startwm.sh && \
    echo "exec dbus-run-session startxfce4" >> /etc/xrdp/startwm.sh && \
    chmod +x /etc/xrdp/startwm.sh

RUN cp -r /etc/xdg/xfce4/ /root/.config/ || true

# 8. Import boot scripts and set permissions
COPY entrypoint.sh /entrypoint.sh
COPY lab-init.sh /usr/local/bin/lab-init.sh
COPY lab-init.service /etc/systemd/system/lab-init.service

RUN chmod +x /entrypoint.sh /usr/local/bin/lab-init.sh && systemctl enable lab-init.service

EXPOSE 3389
ENTRYPOINT ["/entrypoint.sh"]
