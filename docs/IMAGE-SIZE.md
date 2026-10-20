# Image Size — measurement baseline

> **Status (2026-10-20)**: Initial baseline. Will be populated by T5 measurements after CI runs.

## Upstream baseline (for reference)

| Image | Tag | Compressed | Uncompressed | Notes |
|---|---|---|---|---|
| `quay.io/almalinuxorg/almalinux-bootc` | `:10` | TBD | ~1.46 GB | full variant (baseos + appstream); published daily by AlmaLinux |
| `quay.io/almalinuxorg/almalinux-bootc` | `:10-kitten` | TBD | TBD | minimal variant (kitten-repos only); published daily |

> Note: `daedalus-core` currently pins `:10` at `sha256:d8679e022ff2b9f9873becf262e4447beb5b0551a8dc83c146e2e6f27bd5183f` per `daedalus-core/Containerfile`. This pin will be replaced by the headless fork digest (T7).

## Fork baseline (post T2)

To be measured after first fork CI build (T2.5, T5).

| Image | Tag | Compressed | Uncompressed | Build commit |
|---|---|---|---|---|
| `ghcr.io/daedalusys/almalinux-bootc` | `:10-kitten` | TBD | TBD | TBD |

## Measurement method

After each CI build:

```bash
# Pull
podman pull ghcr.io/daedalusys/almalinux-bootc:10-kitten

# Compressed size (registry size)
curl -sL "https://ghcr.io/token"  # get bearer token (browser cookies)
# Or use:  podman images --format "{{.Size}}" ghcr.io/daedalusys/almalinux-bootc:10-kitten

# Uncompressed size
podman inspect --format "{{.Size}}" ghcr.io/daedalusys/almalinux-bootc:10-kitten
```

Per-arch sizes are recorded separately; total = manifest-list size (sum of per-arch after de-dup).

## Acceptance criteria (per plan RF3)

- Fork `:10-kitten` must be at least 500 MB smaller than upstream `:10` (the full variant).
- Target: 1.5-3 GB reduction vs `:10` (post-rebuild).
- If delta < 500 MB after first fork build, the fork isn't worth maintaining (rebase burden > savings) — defer to re-evaluation.

## Reproducibility

Every measurement must record:
- Image digest (`podman images --digests`)
- podman version (`podman --version`)
- Build commit (CI run URL)

If two measurements using the same digest + podman version + commit differ, the measurement is broken.
