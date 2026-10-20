#!/usr/bin/env bash
# T3: verify headless image has no GUI/desktop packages
#
# Two checks:
#   1. Static: scan the YAML manifest for GUI package patterns (sddm, xrdp,
#      kde, plasma, kwin, gnome-shell). Anything that matches is a regression.
#   2. Live (optional): if IMAGE env var is set, run rpm -q in a podman
#      container and assert "not installed" for each GUI package.
#
# Exits 0 = headless property holds. Non-zero = GUI package slipped in.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="${MANIFEST:-${REPO_ROOT}/10-kitten/almalinux-10-kitten.yaml}"
IMAGE="${IMAGE:-}"

# Package patterns we forbid in the headless variant.
GUI_PATTERNS='sddm|xrdp|.*-kde.*|plasma-|kwin-|gnome-shell'

fail_count=0

# Static check: scan manifest.
echo "==> Static check: scanning ${MANIFEST}"
if [[ ! -f "$MANIFEST" ]]; then
  echo "FAIL: manifest not found: $MANIFEST"
  exit 1
fi

if grep -E "$GUI_PATTERNS" "$MANIFEST"; then
  echo "FAIL: manifest contains GUI package patterns"
  fail_count=$((fail_count + 1))
else
  echo "OK: manifest clean of GUI patterns"
fi

# Live check: probe image with rpm -q if IMAGE is set.
if [[ -n "$IMAGE" ]]; then
  echo "==> Live check: probing ${IMAGE}"
  for pkg in sddm xrdp plasma-workspace kwin-wayland gnome-shell; do
    if podman run --rm "$IMAGE" rpm -q "$pkg" >/dev/null 2>&1; then
      echo "FAIL: ${IMAGE} has ${pkg} installed"
      fail_count=$((fail_count + 1))
    else
      echo "OK: ${pkg} not installed"
    fi
  done
else
  echo "==> Live check: skipped (set IMAGE to enable, e.g. IMAGE=quay.io/almalinuxorg/almalinux-bootc:10-kitten)"
fi

if [[ $fail_count -gt 0 ]]; then
  echo "==> RESULT: FAIL (${fail_count} violations)"
  exit 1
fi

echo "==> RESULT: PASS — headless invariants hold"
