#!/bin/bash
set -e

# Dump runtime variables into an environment file that systemd can read post-boot.
# This preserves the original VM-parity boot chain and full-machine state behavior.
{
  printf 'ROOT_PASSWORD=%s\n' "${ROOT_PASSWORD}"
  printf 'TAILSCALE_AUTHKEY=%s\n' "${TAILSCALE_AUTHKEY}"
  printf 'GITHUB_RUN_ID=%s\n' "${GITHUB_RUN_ID}"
  printf 'TAILSCALE_MTU=%s\n' "${TAILSCALE_MTU:-1280}"
  printf 'TAILSCALE_HOSTNAME=%s\n' "${TAILSCALE_HOSTNAME}"
} > /etc/lab-environment

# Replace this shell script with systemd as PID 1.
exec /lib/systemd/systemd
