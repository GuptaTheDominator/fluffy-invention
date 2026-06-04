#!/bin/bash
# Dump variables into an environment file that systemd can read post-boot
echo "ROOT_PASSWORD=${ROOT_PASSWORD}" > /etc/lab-environment
echo "TAILSCALE_AUTHKEY=${TAILSCALE_AUTHKEY}" >> /etc/lab-environment

# Replace this shell script with systemd as PID 1
exec /lib/systemd/systemd
