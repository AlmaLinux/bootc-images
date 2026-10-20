# Registry — image publication

> **Status (2026-10-20)**: First CI build queued (`ghcr.io/daedalusys/almalinux-bootc:10-kitten`). This doc defines the tag convention.

## Registry

**`ghcr.io`** (GitHub-native, free for public packages, integrated with the fork repo's CI).

| Endpoint | URL |
|---|---|
| Container registry | `ghcr.io/daedalusys/almalinux-bootc` |
| Org | `Daedalusys` |
| Repo | `almalinux-bootc` |

## Image tags

| Tag | Source | When published | Stability |
|---|---|---|---|
| `:10-kitten` | latest `main` build | every push to `main` (excluding schedule) | rolling; pin by digest in consumers |
| `:10-kitten-<sha>` | per-commit build | every push to `main` | immutable; preferred for daedalus-core pin |
| `:10-kitten-v0.1.0` | tagged release | manual `git tag v0.1.0 && git push --tags` | stable; use for production |

## daedalus-core pin (recommended)

```dockerfile
# daedalus-core/Containerfile
ARG HEADLESS_BASE_IMAGE=ghcr.io/daedalusys/almalinux-bootc:10-kitten@sha256:<digest>
FROM ${HEADLESS_BASE_IMAGE}
```

The digest comes from the most recent successful CI run. To update:

```bash
# 1. Get latest digest from CI artifact
DIGEST=$(gh api repos/Daedalusys/almalinux-bootc/actions/runs/<RUN_ID>/artifacts 2>/dev/null | jq -r '.artifacts[] | select(.name=="manifest-digest") | .archive_download_url')

# 2. Update Containerfile with new digest
# 3. Open PR in daedalus-core; merge after CI green
```

## Authentication

`ghcr.io` uses GitHub Packages. Authentication options:

- **In CI**: `${{ secrets.GITHUB_TOKEN }}` (auto-injected by GitHub Actions)
- **Local pull** (read public packages): no auth required
- **Local push** (write): `docker login ghcr.io -u <github-username> -p <token-with-write:packages>`

## Signing

All published images are cosign-signed (keyless via GitHub OIDC):

```bash
# Verify signature
cosign verify --certificate-identity-regexp 'https://github.com/Daedalusys/almalinux-bootc' \
  ghcr.io/daedalusys/almalinux-bootc:10-kitten
```

The signing identity is bound to this repo's workflow runs, providing supply-chain integrity.

## Future considerations

- **Multi-arch support**: Currently `linux/amd64` + `linux/arm64`. Add `linux/amd64/v2` if upstream standardizes on it.
- **Reproducible builds**: Future work; current builds are reproducible if upstream is reproducible.
- **Mirror to quay.io?**: TBD; only do if daedalus users have a hard quay.io preference (most don't).
