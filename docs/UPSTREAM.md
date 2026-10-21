# Upstream — source, license, build system

`almalinux-bootc` is a fork of the AlmaLinux bootc base images. This file records the facts
needed before rebasing or replacing it: where upstream lives, how upstream turns a config file
into a bootable image, and which parts of the fork are deviations from upstream. Read it before
touching `10-kitten/`, `Makefile`, or `cosign.pub`.

## Identity

| | |
|---|---|
| Upstream | <https://github.com/AlmaLinux/bootc-images> |
| Upstream `main` tip when forked | `67ed16e` — 2026-07-08, "Merge pull request #64 from yuravk/main" |
| License | GPL-3.0; `LICENSE` copied verbatim, fork code stays GPL-3.0 |
| Published upstream images | `quay.io/almalinuxorg/almalinux-bootc` — `9`, `10`, and dated tags (`10.2.20261021.0`) |
| Upstream status | labelled *experimental* by upstream's own README |

Upstream source barely moves (`67ed16e` is the last commit before the fork point), but images are
rebuilt every day, so the content that reaches Daedalus comes mainly from package updates rather
than git history. Rebasing therefore has low conflict risk and high staleness risk: check the
published tags, not the commit log, when deciding whether upstream has something worth taking.

## Build system

No kickstart, no spec file, no mock. Each version directory holds two inputs and `make` drives them:

**Image config** (`10-kitten/almalinux-10-kitten.yaml`) is the real configuration surface:

- `releasever`, `repos` — which AlmaLinux repositories to solve against
- `packages` — the package set; `include: standard/manifest.yaml` pulls the common bootc base
  package list. That file is not in this repo — it arrives with
  `/usr/share/doc/bootc-base-imagectl/`, copied out of `quay.io/centos-bootc/centos-bootc:stream10`
- `postprocess` — bash blocks run inside the assembling root filesystem; upstream uses them to
  write `/usr/lib/bootc/install/*.toml` (installer defaults) and to clean caches

**Containerfile** (`10-kitten/Containerfile`) is a two-stage driver around that config:

1. `builder` stage starts from `quay.io/almalinuxorg/10-kitten-base`, installs
   `podman bootc ostree rpm-ostree`, copies in `bootc-base-imagectl` (extracted from the
   centos-bootc image), drops the repo files and GPG key from the base stage, copies the YAML into
   `/usr/share/doc/bootc-base-imagectl/manifests/`, then runs
   `/usr/libexec/bootc-base-imagectl build-rootfs --reinject --manifest=almalinux-10-kitten /target-rootfs`
2. final stage is `FROM scratch`, `COPY --from=builder /target-rootfs/ /`, labels
   `containers.bootc=1` and `ostree.bootable=1`, `STOPSIGNAL SIGRTMIN+3`, `CMD ["/sbin/init"]`,
   and a closing `bootc container lint --fatal-warnings`

Local build:

```bash
make image     # podman build -f 10-kitten/Containerfile — needs /dev/fuse, --cap-add=all, --security-opt=label=disable
make rechunk   # bootc-base-imagectl rechunk — collapses the layer stack into localhost/rechunked-*
```

`PODMAN = sudo podman` in the Makefile, and `make` with no target runs `rechunk`, so a bare `make`
expects an image already built by `make image`. Both stages need privileged podman; the build host
must be able to run EL10 userspace (a machine without `x86-64-v3` support fails at `/sbin/init`
and can only verify this pipeline in CI).

## Upstream CI

Upstream `.github/workflows/build.yml`:

- `schedule: cron '00 03 * * *'` UTC, plus `workflow_dispatch` with a `RELEASE` choice input
  (`9` / `10` / `10-kitten` / `ALL`); the matrix is versions × `amd64`/`arm64`
- scheduled runs are gated to the upstream repository (`github.repository == 'AlmaLinux/bootc-images'`),
  so forks never get cron builds
- push target comes from `secrets.IMAGE_REGISTRY` with tags `latest`, `<major>`, `<version-id>`,
  `<version-id>-<date-stamp>`, `<long-version>`
- signing uses OIDC into AWS (`AWS_ROLE_ARN`, KMS alias `cloudsig`) and results are posted to a
  Mattermost channel from `vars.MATTERMOST_CHANNEL`

None of those secrets exist in this org, which is why the fork rewrites `build.yml`: ghcr push,
keyless cosign, no Mattermost. Details in [`REGISTRY.md`](REGISTRY.md).

## Fork deviations in upstream-owned files

`10-kitten/almalinux-10-kitten.yaml` — four additions, nothing removed:

```yaml
packages:
  - openssh-server        # rescue path over ssh, no GUI
  - NetworkManager
```

```toml
kargs = ["console=ttyS0,115200n8"]   # serial console login
```

```bash
systemctl enable sshd NetworkManager   # preset-driven enable, bootc-safe
```

`9/` and `10/` directories are deleted; `Makefile`, `Containerfile`, and `LICENSE` are unchanged
from upstream. Everything else in the fork is new files (`README.md`, `CONTRIBUTING.md`,
`docs/*`, `tests/*`, `.github/workflows/rebase-check.yml`). Rebase conflicts should therefore be
expected in `10-kitten/almalinux-10-kitten.yaml`, `.github/workflows/build.yml`, and `README.md`
only — see [`REBASE.md`](REBASE.md).
