FROM kalilinux/kali-rolling:latest
ENV DEBIAN_FRONTEND=noninteractive

# 1. Install Systemd, FUSE 3 (AppImage support), GUI, XRDP, Tailscale prerequisites, and tools.
#    iproute2/procps are included explicitly because the runtime tuning scripts use ip/sysctl-style diagnostics.
RUN apt-get update && apt-get install -y \
    systemd \
    fuse3 \
    kali-desktop-xfce \
    xrdp \
    xorgxrdp \
    curl \
    sudo \
    wget \
    dbus-x11 \
    gnupg \
    ca-certificates \
    iproute2 \
    procps \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 2. PURGE DESKTOP BLOAT THAT CAUSES USELESS REDRAWS / BACKGROUND WAKEUPS IN RDP.
#    This keeps the same full-machine persistence model, but the live GUI session sends fewer screen updates.
RUN rm -f \
    /etc/xdg/autostart/xfce4-power-manager.desktop \
    /etc/xdg/autostart/light-locker.desktop \
    /etc/xdg/autostart/xscreensaver.desktop \
    /etc/xdg/autostart/blueman.desktop \
    /etc/xdg/autostart/nm-applet.desktop \
    /etc/xdg/autostart/print-applet.desktop \
    /etc/xdg/autostart/pulseaudio.desktop \
    /etc/xdg/autostart/geoclue-demo-agent.desktop \
    || true

# Disable hardware/desktop services that do not help inside the remote lab and can create background activity.
RUN rm -f /etc/systemd/system/display-manager.service && \
    systemctl mask \
      dev-mqueue.mount \
      dev-hugepages.mount \
      systemd-remount-fs.service \
      sys-kernel-config.mount \
      sys-kernel-debug.mount \
      sys-fs-fuse-connections.mount \
      display-manager.service \
      graphical.target \
      systemd-logind.service \
      apt-daily.timer \
      apt-daily-upgrade.timer \
      man-db.timer \
      fstrim.timer \
      avahi-daemon.service \
      cups.service \
      cups-browsed.service \
      bluetooth.service \
      ModemManager.service \
      NetworkManager.service \
      wpa_supplicant.service \
      packagekit.service \
      upower.service \
      power-profiles-daemon.service \
      2>/dev/null || true && \
    systemctl set-default multi-user.target

# 3. LOW-BANDWIDTH XRDP TUNING.
#    Goal: only transfer keyboard/mouse/screen plus shared clipboard over the Tailnet; disable audio,
#    drives, printers, RemoteApp/video helper channels, and dynamic virtual channels.
RUN set -eux; \
    XRDP_INI=/etc/xrdp/xrdp.ini; \
    ensure_setting() { \
      section="$1"; key="$2"; value="$3"; file="$4"; \
      if grep -q "^${key}=" "$file"; then \
        sed -i "s|^${key}=.*|${key}=${value}|" "$file"; \
      elif grep -q "^\\[${section}\\]" "$file"; then \
        sed -i "/^\\[${section}\\]/a ${key}=${value}" "$file"; \
      else \
        printf '\n[%s]\n%s=%s\n' "$section" "$key" "$value" >> "$file"; \
      fi; \
    }; \
    ensure_setting Globals crypt_level low "$XRDP_INI"; \
    ensure_setting Globals security_layer rdp "$XRDP_INI"; \
    ensure_setting Globals max_bpp 16 "$XRDP_INI"; \
    ensure_setting Globals xserverbpp 16 "$XRDP_INI"; \
    ensure_setting Globals bitmap_compression true "$XRDP_INI"; \
    ensure_setting Globals bulk_compression true "$XRDP_INI"; \
    ensure_setting Globals use_fastpath both "$XRDP_INI"; \
    ensure_setting Globals tcp_nodelay true "$XRDP_INI"; \
    ensure_setting Globals tcp_keepalive true "$XRDP_INI"; \
    ensure_setting Globals tcp_send_buffer_bytes 4194304 "$XRDP_INI"; \
    ensure_setting Globals tcp_recv_buffer_bytes 4194304 "$XRDP_INI"; \
    ensure_setting Channels rdpdr false "$XRDP_INI"; \
    ensure_setting Channels rdpsnd false "$XRDP_INI"; \
    ensure_setting Channels drdynvc false "$XRDP_INI"; \
    ensure_setting Channels cliprdr true "$XRDP_INI"; \
    ensure_setting Channels rail false "$XRDP_INI"; \
    ensure_setting Channels xrdpvr false "$XRDP_INI"; \
    ensure_setting Channels tcutils false "$XRDP_INI"

# 4. Install Tailscale VPN.
RUN mkdir -p /usr/share/keyrings && \
    curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg > /dev/null && \
    curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list && \
    apt-get update && apt-get install -y tailscale && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 5. Enable native systemd services.
RUN systemctl enable xrdp tailscaled

# 6. ROOT GUI, SOFTWARE RENDERING, AND CELLULAR-FRIENDLY XFCE OVERRIDES.
#    box_move/box_resize make window movement send outlines instead of continuous full-window repaints.
RUN cat > /etc/xrdp/startwm.sh <<'EOF'
#!/bin/sh

export XDG_SESSION_DESKTOP=xfce
export XDG_CURRENT_DESKTOP=XFCE
export LIBGL_ALWAYS_SOFTWARE=1
export GALLIUM_DRIVER=llvmpipe
export NO_AT_BRIDGE=1

xset s off -dpms 2>/dev/null || true

exec dbus-run-session -- sh -c '
  xfconf-query -c xfwm4 -p /general/use_compositing -n -t bool -s false >/dev/null 2>&1 || true
  xfconf-query -c xfwm4 -p /general/box_move -n -t bool -s true >/dev/null 2>&1 || true
  xfconf-query -c xfwm4 -p /general/box_resize -n -t bool -s true >/dev/null 2>&1 || true
  xfconf-query -c xfwm4 -p /general/cycle_preview -n -t bool -s false >/dev/null 2>&1 || true
  xfconf-query -c xfwm4 -p /general/workspace_count -n -t int -s 1 >/dev/null 2>&1 || true

  xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-show -n -t bool -s false >/dev/null 2>&1 || true
  xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/color-style -n -t int -s 0 >/dev/null 2>&1 || true

  xfconf-query -c thunar -p /misc-thumbnail-mode -n -t string -s THUNAR_THUMBNAIL_MODE_NEVER >/dev/null 2>&1 || true

  exec startxfce4
'
EOF
RUN chmod +x /etc/xrdp/startwm.sh

# Ensure default Kali XFCE profile exists for root; runtime settings remain fully persistent after export/squash.
RUN cp -r /etc/xdg/xfce4/ /root/.config/ || true

# 7. Import boot scripts and set permissions.
COPY entrypoint.sh /entrypoint.sh
COPY lab-init.sh /usr/local/bin/lab-init.sh
COPY lab-init.service /etc/systemd/system/lab-init.service

RUN chmod +x /entrypoint.sh /usr/local/bin/lab-init.sh && systemctl enable lab-init.service

EXPOSE 3389
ENTRYPOINT ["/entrypoint.sh"]
