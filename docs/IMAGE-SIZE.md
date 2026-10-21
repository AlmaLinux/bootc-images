# Image Size — measurement

> **Last measured**: 2026-10-22 (T7 verification, first `main` push run 39644951213)
> **Method**: registry manifest API — sum of `layers[].size` + `config.size` for one
> architecture's child manifest. Every figure below is **compressed** bytes.

## Headline finding (departure from plan RF3)

Two claims, both measured now:

1. **The base image swap saves nothing.** Fork `10-kitten` amd64 = 814.9 MiB, upstream
   `:10` amd64 = 829.0 MiB, upstream `:10-kitten` amd64 = 841.7 MiB. The forked base is
   the headless source of truth, but its size sits within 3% of everything it replaced.
2. **The reduction happens at the daedalus-os level, and it is large.** `daedalus-os`
   fell from 3.14 GiB (KDE stages still in the build) to 1.13 GiB (headless) —
   **−2.01 GiB, −64.0%**, inside plan RF3's expected 1.5–3 GB window.

The value of the headless base is therefore the **sanity guarantee** — no GUI package is
reachable through any `include` — not a byte reduction.

## Upstream baseline

`quay.io/almalinuxorg/almalinux-bootc`, per-arch child manifests, `tar+gzip` layers.
Measured against the tags as published on 2026-10-22 — upstream rebuilds daily
(`10.2.20261021.0` at the time of measurement), so only the child digests are stable:

| Tag | Child | Compressed | Layers |
|---|---|---|---|
| `:10` | linux/amd64 (`sha256:49346f4b…`) | 869,270,428 B (829.0 MiB) | 65 |
| `:10` | linux/amd64, `platform.variant=v2` (`sha256:3dd2bd50…`) | 868,656,424 B (828.4 MiB) | 65 |
| `:10` | linux/arm64 (`sha256:f489e262…`) | 795,085,916 B (758.3 MiB) | 65 |
| `:10-kitten` | linux/amd64 (`sha256:301ed9de…`) | 882,594,614 B (841.7 MiB) | 65 |
| `:10-kitten` | linux/amd64, `platform.variant=v2` (`sha256:e2b28e55…`) | 881,824,658 B (840.9 MiB) | 65 |
| `:10-kitten` | linux/arm64 (`sha256:90f54b4a…`) | 807,887,094 B (769.6 MiB) | 65 |

Each tag carries **two** amd64 children, differing only in `platform.variant`. They are
separate builds, not two filesystems of one build: `:10`'s pair was created 8 minutes
apart (`build-date` 03:12 vs 03:20 on 2026-10-21), carries different `ostree.commit`
values, and shares only 13 of its 65 layer digests (`:10-kitten` shares 12). Their totals
land within 0.6 MiB of each other. Only the first row of each pair is used below as the
per-arch baseline, and the `variant=v2` row is kept so a future reader does not mistake
it for a third architecture.

`:10-kitten` vs `:10` on the same architecture: **+12.7 MiB (+1.5%)**. Kitten is not
smaller than the full variant.

An earlier revision of this doc recorded `1.49 GB` / `1.52 GB` from `podman inspect`
against the multi-arch reference. Those numbers are not reproducible from either
registry: they match neither a per-arch child nor the sum of children (blobs are shared
across architectures, so the children do not add up to a registry-side total). The
per-arch table above replaces them.

## Why kitten is not smaller (analysis)

Upstream kitten uses a **different base image**
(`quay.io/almalinuxorg/10-kitten-base:10-kitten`) with a smaller repo set
(`almalinux-kitten-repos` only, no `baseos + appstream`). But the standard
`manifest.yaml` it `include`s still pulls in a comparable set of base packages. The
kitten variant achieves "headless" by **not having access to GUI package sources**, not
by stripping GUI packages — so the on-disk footprint is similar.

The size difference comes from the layers being rebuilt against a different base, with
slightly different package versions and metadata.

## Fork baseline (measured)

`ghcr.io/daedalusys/almalinux-bootc`, the digest pinned at
`daedalus-core/Containerfile:10` (`sha256:a4bff88738b6…`), `tar+gzip` layers:

| Arch | Child digest | Compressed | Layers |
|---|---|---|---|
| linux/amd64 | `sha256:b4ae2a7ae9d2…` | 854,492,864 B (814.9 MiB) | 2 |
| linux/arm64 | `sha256:52788bcb6e3e…` | 780,754,400 B (744.6 MiB) | 2 |

`10-kitten/almalinux-10-kitten.yaml` adds (T4):

- `openssh-server` package (~50 MB on disk)
- `NetworkManager` package (~30 MB on disk)
- `kargs = ["console=ttyS0,115200n8"]` (no size impact)
- `systemctl enable sshd NetworkManager` postprocess (no size impact)

Fork vs upstream `:10-kitten`, same architecture: **−26.8 MiB (−3.2%)** — a fork that
adds two packages measures *smaller* than the image it forked.

That delta is not a package-count win. `bootc-base-imagectl build-rootfs --reinject`
writes the whole rootfs as a single layer; upstream ships the same content through 65
layers, where a file overwritten by a later layer is counted again in every layer that
carried it; at this rootfs size that duplication outweighs the ~80 MB of packages the
fork adds. The sign of the delta is explained by that mechanism; it was not measured
file by file. The
headless property is proved by `no-gui.sh` against the manifest, not by this number.

## Daedalus-os layer savings (measured — the actual win)

`ghcr.io/daedalusys/daedalus-os`, linux/amd64, `tar+zstd` layers on both builds:

| Build | Manifest | Date | Compressed | Layers |
|---|---|---|---|---|
| pre-headless (KDE/sddm/xrdp stages still run) | `2bba1a51b0d7…` | 2026-10-11 | 3,372,391,216 B (3.14 GiB) | 78 |
| headless (run 39644951213, `main` = `96ef0d1`) | `96ef0d19e0f4…` | 2026-10-21 | 1,214,371,566 B (1.13 GiB) | 16 |
| **delta** | | | **−2,158,019,650 B (−2.01 GiB, −64.0%)** | −62 |

The reinjected rootfs layer — the closest available proxy for installed size — went from
2,263,653,902 B to 807,192,017 B: **−1.36 GiB (−64.3%)**.

Notes on what this comparison can and cannot support:

- `2bba1a51` is a PR-head commit (`ci: trigger build-image`), not a `main` commit.
  Squash-merging rewrites the commit id, so the registry tag is the only surviving
  pointer to that build — the manifest is still readable by that ref.
- daedalus-os layers are zstd (push-side `--compression-format zstd`), the base images
  are gzip. Subtracting a base image from daedalus-os mixes units; the daedalus-os
  before/after comparison does not, because both builds pushed zstd.
- `:latest` and `:upstream` now point at the headless manifest; `:10-kitten` at the fork
  base digest.

Superseded estimate, kept for reference — the group-level attribution was never
instrumented, only the total was measured:

| Removed package group | Estimated uncompressed size |
|---|---|
| `plasma-*`, `kwin-*`, `*-kde*` | ~800 MB |
| `sddm` + deps | ~50 MB |
| `xrdp*` + deps | ~100 MB |
| `gnome-shell*` (if present) | ~300 MB |
| Mesa + X11 display libs (if no headless callers) | ~400 MB |
| **Total headless savings at daedalus-os layer** | **~1.5-1.7 GB** |

## Acceptance criteria (measured)

| Criterion | Original | Result | Evidence |
|---|---|---|---|
| Fork smaller than upstream `:10` | "at least 500 MB smaller" | **NOT MET — fork is 14.1 MiB smaller, not 500 MB** | base-image swap is not the savings mechanism |
| Daedalus-os headless smaller than kde | "1.5-3 GB reduction" | **MET (−2.01 GiB, −64.0%)** | manifest sum, both zstd, both amd64 |
| Sanity: no GUI packages in fork image | implicit | **VERIFIED (`no-gui.sh` passes against manifest)** | this is what the fork guarantees |
| Bootability of the headless image | implied by qcow2 | **NOT VERIFIED** | qcow2 leg red since 2026-10-15 (daedalus-core#50); CI has no boot job |

## Reproducibility

```bash
# daedalus-os — ghcr needs a bearer token exchanged from the GH token
P=$(gh auth token)
T=$(curl -s -u ":$P" "https://ghcr.io/token?scope=repository:daedalusys/daedalus-os:pull&service=ghcr.io" | jq -r .token)
for ref in 2bba1a51b0d705daee45520a3439668d305b0842 96ef0d19e0f426e8c88e07324f1ea585b0fa02a4; do
  curl -s -H "Authorization: Bearer $T" \
    -H "Accept: application/vnd.oci.image.manifest.v1+json" \
    "https://ghcr.io/v2/daedalusys/daedalus-os/manifests/$ref" |
    jq -r --arg ref "$ref" '[ $ref,
      ((.layers | map(.size) | add) + .config.size),
      (.layers | length),
      .layers[0].mediaType ] | @tsv'
done

# upstream — quay serves these anonymously. The tag is an INDEX, so ask for the index
# media type first, then the child manifest.
AMD=$(curl -sL -H "Accept: application/vnd.oci.image.index.v1+json" \
  "https://quay.io/v2/almalinuxorg/almalinux-bootc/manifests/10" |
  jq -r '.manifests[] | select(.platform.architecture=="amd64" and (.platform.variant==null)) | .digest')
curl -sL -H "Accept: application/vnd.oci.image.manifest.v1+json" \
  "https://quay.io/v2/almalinuxorg/almalinux-bootc/manifests/$AMD" |
  jq -r '[ ((.layers|map(.size)|add) + .config.size), (.layers|length), .layers[0].mediaType ] | @tsv'

# fork base — same token exchange with
# scope=repository:daedalusys/almalinux-bootc:pull, then resolve the digest pinned in
# daedalus-core/Containerfile (an index) to its amd64 child:
TF=$(curl -s -u ":$P" "https://ghcr.io/token?scope=repository:daedalusys/almalinux-bootc:pull&service=ghcr.io" | jq -r .token)
CHILD=$(curl -s -H "Authorization: Bearer $TF" \
  -H "Accept: application/vnd.oci.image.index.v1+json" \
  "https://ghcr.io/v2/daedalusys/almalinux-bootc/manifests/sha256:a4bff88738b674c666277de8ffbc64c8e59deedfcc9a054b55d785428f877040" |
  jq -r '.manifests[0].digest')
curl -s -H "Authorization: Bearer $TF" \
  -H "Accept: application/vnd.oci.image.manifest.v1+json" \
  "https://ghcr.io/v2/daedalusys/almalinux-bootc/manifests/$CHILD" |
  jq -r '[ ((.layers|map(.size)|add) + .config.size), (.layers|length), .layers[0].mediaType ] | @tsv'
```

If the same digests produce different byte sums under the same method, the measurement
is broken.

## Future measurement runs

After each fork or core CI build:

1. `GET /v2/daedalusys/almalinux-bootc/manifests/10-kitten` → children → byte sums; update
   "Fork baseline".
2. `GET /v2/daedalusys/daedalus-os/manifests/<git sha>` → byte sum + layer count; append a
   row to the savings table. One row per measurement, no overwriting — a regression is
   only visible against the previous row.
3. Re-check `layers[].mediaType` whenever a push config changes: a gzip→zstd switch moves
   the total without any package changing.
