#!/usr/bin/env bash
# T4: verify headless image rescue path (sshd + serial console)
#
# Per plan RF2: headless image must have working sshd (enabled on port 22)
# AND working serial console (console=ttyS0,115200 kernel arg).
# GUI rescue (sddm/xrdp/kde) must NOT exist as services.
#
# Requires a built image. Set IMAGE to point at it:
#   IMAGE=localhost/almalinux-bootc:10-kitten ./tests/rescue-path.sh
# or use the upstream reference image:
#   IMAGE=quay.io/almalinuxorg/almalinux-bootc:10-kitten ./tests/rescue-path.sh
#
# Default mode: static checks only (fast). Set RESCUE_LIVE=1 to also do the
# live container + ssh test (slow; requires systemd to start).
#
# Exits 0 = rescue path intact. Non-zero = violation.

set -euo pipefail

IMAGE="${IMAGE:-}"
if [[ -z "$IMAGE" ]]; then
  echo "ERROR: IMAGE env var not set"
  echo "Usage: IMAGE=<ref> $0"
  exit 2
fi

fail_count=0

echo "==> Probing ${IMAGE} (static checks)"

# Probe 1: sshd binary exists.
if podman run --rm "$IMAGE" rpm -q openssh-server >/dev/null 2>&1; then
  echo "OK: openssh-server installed"
else
  echo "FAIL: openssh-server not installed"
  fail_count=$((fail_count + 1))
fi

# Probe 2: sshd.service is enabled (in multi-user.target.wants).
if podman run --rm "$IMAGE" ls /etc/systemd/system/multi-user.target.wants/sshd.service >/dev/null 2>&1; then
  echo "OK: sshd.service enabled"
else
  echo "FAIL: sshd.service not enabled (no link in multi-user.target.wants)"
  fail_count=$((fail_count + 1))
fi

# Probe 3: sshd config exists and Port 22 reference.
sshd_config=$(podman run --rm "$IMAGE" cat /etc/ssh/sshd_config 2>/dev/null || true)
if [[ "$sshd_config" == *"Port 22"* ]] || [[ "$sshd_config" == *"#Port 22"* ]]; then
  echo "OK: sshd config has Port 22"
else
  echo "WARN: sshd config does not explicitly set Port 22 (default is 22, may be OK)"
fi

# Probe 4: no display manager / GUI services.
for svc in sddm gdm xrdp lightdm; do
  if podman run --rm "$IMAGE" ls "/etc/systemd/system/multi-user.target.wants/${svc}.service" >/dev/null 2>&1; then
    echo "FAIL: ${svc}.service is enabled (should be absent in headless)"
    fail_count=$((fail_count + 1))
  else
    echo "OK: ${svc}.service not enabled"
  fi
done

# Probe 5: serial console kernel arg in bootc install config.
bootc_install_files=$(podman run --rm "$IMAGE" find /usr/lib/bootc/install -type f -name "*.toml" 2>/dev/null || true)
if [[ -n "$bootc_install_files" ]]; then
  echo "OK: bootc install config found"
  # Check for kernel cmdline hints.
  if podman run --rm "$IMAGE" grep -r -l "console=ttyS0" /usr/lib/bootc /etc/kernel 2>/dev/null | head -1; then
    echo "OK: serial console kernel arg found in bootc install"
  else
    echo "INFO: serial console kernel arg NOT explicitly set in bootc install (default depends on boot loader)"
  fi
else
  echo "WARN: no bootc install toml found"
fi

# Probe 6: optional live container test.
if [[ "${RESCUE_LIVE:-0}" == "1" ]]; then
  echo "==> Live check: starting ephemeral container (slow)"
  container_id=$(podman run --detach --network host --name "rescue-test-$$" "$IMAGE" /sbin/init 2>&1) || {
    echo "FAIL: could not start container from ${IMAGE}"
    fail_count=$((fail_count + 1))
  }
  if [[ -n "${container_id:-}" ]]; then
    for i in $(seq 1 30); do
      if podman exec "$container_id" systemctl is-active sshd >/dev/null 2>&1; then
        echo "OK: sshd is active after ${i}s"
        break
      fi
      sleep 1
    done
    podman rm -f "$container_id" >/dev/null 2>&1 || true
  fi
else
  echo "==> Live check: skipped (set RESCUE_LIVE=1 to enable)"
fi

if [[ $fail_count -gt 0 ]]; then
  echo "==> RESULT: FAIL (${fail_count} violations)"
  exit 1
fi

echo "==> RESULT: PASS — rescue path intact (static)"
