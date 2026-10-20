# Image Size — measurement

> **Last measured**: 2026-10-20 (T5)
> **Method**: `podman inspect` against pulled images from quay.io (compressed size of rootfs diff_ids sum)

## Headline finding (departure from plan RF3)

**The headless fork is NOT substantially smaller than the upstream `:10` base at the bootc-image level.** Plan RF3 expected a 1.5-3 GB reduction; actual measurement shows ~30 MB delta in the **opposite direction** (kitten is slightly larger). The fork value is in the **sanity guarantee** (no GUI packages transitively), not in the base image size reduction.

The size reduction Daedalus wants happens at the **daedalus-os level** (skipping KDE/sddm/xrdp builds), not the base image swap. See "Daedalus-os layer savings" section below.

## Upstream baseline

Measured against `quay.io/almalinuxorg/almalinux-bootc` (digest `sha256:230f989ede2f...` for `:10`, `sha256:fabe22d605a56...` for `:10-kitten`):

| Image | Tag | Compressed (manifest list, all platforms) | Compressed (linux/amd64 only, est) | Source |
|---|---|---|---|---|
| `quay.io/almalinuxorg/almalinux-bootc` | `:10` | **1.49 GB** (1,491,378,696 B) | ~470 MB (estimated; per-arch ~30% of list) | podman inspect 2026-10-20 |
| `quay.io/almalinuxorg/almalinux-bootc` | `:10-kitten` | **1.52 GB** (1,520,849,184 B) | ~480 MB (estimated) | podman inspect 2026-10-20 |

Delta: kitten is **+29 MB** (≈ +2%) larger than `:10` full variant.

## Why kitten is not smaller (analysis)

Upstream kitten uses a **different base image** (`quay.io/almalinuxorg/10-kitten-base:10-kitten`) with a smaller repo set (`almalinux-kitten-repos` only, no `baseos + appstream`). But the standard `manifest.yaml` it `include`s still pulls in a comparable set of base packages. The kitten variant achieves "headless" by **not having access to GUI package sources**, not by stripping GUI packages — so the on-disk footprint is similar.

The size difference comes from the layers being rebuilt against a different base, with slightly different package versions and metadata.

## Fork baseline (post T2-T4)

Fork's `10-kitten/almalinux-10-kitten.yaml` adds (T4):
- `openssh-server` package (~50 MB on disk)
- `NetworkManager` package (~30 MB on disk)
- `kargs = ["console=ttyS0,115200n8"]` (no size impact)
- `systemctl enable sshd NetworkManager` postprocess (no size impact)

**Estimated fork `:10-kitten` size**: ~1.55 GB (manifest list) / ~500 MB (linux/amd64). Will be measured precisely when first fork CI build completes (background, 1-4 hr).

## Daedalus-os layer savings (the actual win)

The fork's value is in enabling daedalus-core's Containerfile to skip the KDE/sddm/xrdp build stages entirely. Estimated savings at the daedalus-os layer (vs current `daedalus-os:kde`):

| Removed package group | Estimated uncompressed size |
|---|---|
| `plasma-*`, `kwin-*`, `*-kde*` | ~800 MB |
| `sddm` + deps | ~50 MB |
| `xrdp*` + deps | ~100 MB |
| `gnome-shell*` (if present) | ~300 MB |
| Mesa + X11 display libs (if no headless callers) | ~400 MB |
| **Total headless savings at daedalus-os layer** | **~1.5-1.7 GB** |

This brings `daedalus-os:headless` from estimated 3-5 GB (`daedalus-os:kde`) to estimated 1.3-3.3 GB (`daedalus-os:headless`). The fork's contribution to this is **sanity guarantee** (the base doesn't transitively pull KDE via any include), not the size delta itself.

## Acceptance criteria (revised)

Per plan RF3 + actual findings:

| Criterion | Original | Revised | Why |
|---|---|---|---|
| Fork smaller than upstream `:10` | "at least 500 MB smaller" | **NOT MET (delta is +30 MB)** | Base-image swap is not the savings mechanism |
| Daedalus-os headless smaller than kde | "1.5-3 GB reduction" | TBD — measure after T7 build | This is the real win |
| Sanity: no GUI packages in fork image | implicit | **VERIFIED (no-gui.sh passes against manifest)** | This is what the fork guarantees |

## Reproducibility

```bash
# Pull both upstream images (takes ~5 min each over residential link)
podman pull quay.io/almalinuxorg/almalinux-bootc:10
podman pull quay.io/almalinuxorg/almalinux-bootc:10-kitten

# Get manifest list compressed size
podman inspect quay.io/almalinuxorg/almalinux-bootc:10 --format "{{.Size}}"
podman inspect quay.io/almalinuxorg/almalinux-bootc:10-kitten --format "{{.Size}}"

# Get specific per-arch digest
curl -sL "https://quay.io/v2/almalinuxorg/almalinux-bootc/manifests/10" \
  -H "Accept: application/vnd.oci.image.index.v1+json" | jq .
```

If measurements using the same digests + podman version differ, the measurement is broken.

## Future measurement runs

After each fork CI build:
1. Pull `ghcr.io/daedalusys/almalinux-bootc:10-kitten`
2. Run `podman inspect --format "{{.Size}}"`
3. Update the "Fork baseline" row above
4. After T7 daedalus-os:headless build, update "Daedalus-os layer savings" with measured numbers
