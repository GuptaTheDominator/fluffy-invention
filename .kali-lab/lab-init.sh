#!/bin/bash

# 1. Set root password dynamically from captured environment
if [ -n "$ROOT_PASSWORD" ]; then
  echo "root:$ROOT_PASSWORD" | chpasswd
else
  # Fallback default if secret mapping fails
  echo "root:kali" | chpasswd
fi

# 2. Authenticate Tailscale (Daemon initiated by systemd previously)
if [ -n "$TAILSCALE_AUTHKEY" ]; then
  tailscale up --authkey="${TAILSCALE_AUTHKEY}" --accept-routes
fi

# 3. Provision Desktop auto-save trigger directory
mkdir -p /root/Desktop
