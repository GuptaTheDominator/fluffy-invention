#!/bin/bash
set -e

# 1. Set root password dynamically from captured environment.
if [ -n "$ROOT_PASSWORD" ]; then
  echo "root:$ROOT_PASSWORD" | chpasswd
else
  # Fallback default if secret mapping fails.
  echo "root:kali" | chpasswd
fi

# 2. Authenticate Tailscale with cellular-friendly routing.
#    The lab only needs inbound RDP over the Tailnet, so do not accept subnet routes or Tailnet DNS.
#    This reduces unnecessary route/DNS traffic and avoids pulling unrelated Tailnet traffic through the lab.
if [ -n "$TAILSCALE_AUTHKEY" ]; then
  LAB_HOSTNAME="${TAILSCALE_HOSTNAME:-kali-${GITHUB_RUN_ID:-lab}}"

  tailscale up \
    --authkey="${TAILSCALE_AUTHKEY}" \
    --hostname="${LAB_HOSTNAME}" \
    --accept-routes=false \
    --accept-dns=false \
    --ssh=false

  # Conservative MTU helps avoid fragmentation on mobile networks and DERP/relay paths.
  ip link set dev tailscale0 mtu "${TAILSCALE_MTU:-1280}" 2>/dev/null || true
fi

# 3. Provision Desktop auto-save trigger directory.
mkdir -p /root/Desktop
