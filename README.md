# Daedalus Bootc Base — headless variant of `almalinux-bootc`

**This is a fork** of [`AlmaLinux/bootc-images`](https://github.com/AlmaLinux/bootc-images), stripped to the **`10-kitten`** variant only. It exists to give the [Daedalus](https://github.com/Daedalusys/daedalus-core) fleet a smaller, headless base image than the full `quay.io/almalinuxorg/almalinux-bootc:10`.

## What this fork ships

- **`10-kitten/`** directory unchanged from upstream — uses `almalinux-kitten-repos` only (no `baseos + appstream`)
- GitHub Actions matrix: `[10-kitten] × [amd64, arm64]`
- Publishes multi-arch manifest to **`ghcr.io/daedalusys/almalinux-bootc:10-kitten`**
- cosign-signed (keyless, via GitHub OIDC)

## What this fork does NOT ship

- `9/` directory — drop, we only care about AlmaLinux 10
- `10/` directory — drop, full variant is overkill for headless Daedalus nodes
- AWS KMS cosign signing — replaced with keyless cosign (no AWS dependency)
- Mattermost notifications — drop, fork CI is local to this org

## Rebase strategy

See [`docs/REBASE.md`](docs/REBASE.md). Briefly: monthly `git fetch upstream && git rebase upstream/main`, expect conflicts in `Makefile` and `cosign.pub` only.

## License

Inherited from upstream: **GPL-3.0**. See [`LICENSE`](LICENSE). Fork source code (Makefile, Containerfile, helper scripts) MUST remain GPL-3.0 by upstream copyleft.

## Related repos

- [`Daedalusys/daedalus-core`](https://github.com/Daedalusys/daedalus-core) — the consumer; uses this image as `FROM ${HEADLESS_BASE_IMAGE}` in its Containerfile
- [`AlmaLinux/bootc-images`](https://github.com/AlmaLinux/bootc-images) — the upstream

## Repository status

This repo is **active** but **passively maintained**: it is rebuilt when upstream changes, plus on-demand for security patches. New versions are published automatically on push to `main` (when triggered). Manual rebuild via `Actions → build → Run workflow`.
