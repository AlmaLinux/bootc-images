# Rebase Procedure

> **Why this exists**: This fork must track upstream `AlmaLinux/bootc-images` to receive security patches, new AlmaLinux releases, and bug fixes. Without a tested rebase cadence, the fork rots in 3-6 months. This document is the rebase runbook.

## Cadence

| Trigger | Action | Owner |
|---|---|---|
| Monthly (1st of month) | Check upstream for new releases; rebase if needed | automated cron |
| AlmaLinux security advisory | Immediate rebase + cherry-pick | manual |
| Upstream release tagged | Rebase within 7 days | manual |

The cron job in `.github/workflows/rebase-check.yml` checks monthly and opens an issue if upstream is behind.

## Rebase command (clean history)

```bash
cd /home/lofibass/code/Daedalus/almalinux-bootc
git fetch upstream
git rebase upstream/main
```

If the rebase is clean (no conflicts), push to origin:

```bash
git push origin main
```

## Conflict resolution

The fork only modifies `10-kitten/almalinux-10-kitten.yaml`, `docs/IMAGE-SIZE.md`, `docs/REGISTRY.md`, `docs/REBASE.md`, `docs/UPSTREAM.md`, `README.md`, `.github/workflows/build.yml`, `tests/no-gui.sh`, and `tests/rescue-path.sh`. **The only conflict you should see is `LICENSE`** (if upstream updates copyright year) and **potentially `Makefile`** if upstream restructures the variant directory layout.

**Resolution strategy**:

1. **`LICENSE`** — take upstream version verbatim (GPL-3.0 mandates preservation).
2. **`Makefile`** — check if upstream renamed/removed variants. The fork only builds `10-kitten`; if upstream changes the variant list, update `IMAGE_NAME` and `VERSION_MAJOR` defaults to keep `10-kitten`.
3. **`.github/workflows/`** — if upstream restructured actions, port the fork's adaptations (SHA pinning, ghcr.io target) onto the new layout.
4. **All fork-owned files** (`docs/*`, `tests/*`, `README.md`) — these should never conflict; if they do, our changes are likely lost; git reflog + reset.

## Post-rebase verification

After every rebase + push:

```bash
# 1. Manifest still clean of GUI packages
./tests/no-gui.sh
# Expected: "==> RESULT: PASS"

# 2. Rescue-path script still passes against the published image (if available)
IMAGE=quay.io/almalinuxorg/almalinux-bootc:10-kitten ./tests/rescue-path.sh
# Expected: "==> RESULT: PASS — rescue path intact (static)"

# 3. CI is green on the fork
gh run list -R Daedalusys/almalinux-bootc --limit 3
# Expected: most recent run "completed" + "success"

# 4. Image is bootable
podman pull ghcr.io/daedalusys/almalinux-bootc:10-kitten
podman run --rm ghcr.io/daedalusys/almalinux-bootc:10-kitten /sbin/init --help 2>&1 | head -3
# Expected: init process help text; no errors about missing /sbin/init
```

If any of these fail, the rebase introduced a regression — investigate before merging.

## Cherry-pick workflow (for specific fixes)

If you only need one upstream commit (not a full rebase):

```bash
# Get the commit you want from upstream
git fetch upstream
UPSTREAM_SHA=$(git log upstream/main --oneline | grep "<fix-description>" | head -1 | cut -d' ' -f1)

# Cherry-pick onto current main
git cherry-pick -x $UPSTREAM_SHA

# Resolve any conflicts (rare for cherry-picks); run verification suite above
```

## Emergency: roll back the rebase

If a rebase goes wrong and you need to roll back:

```bash
# Find the pre-rebase commit
git reflog | head -10

# Reset to pre-rebase state (replace <SHA> with the pre-rebase commit)
git reset --hard <pre-rebase-SHA>

# Force-push to origin (CAREFUL — only do this on this fork, never on a shared branch)
git push origin main --force-with-lease
```

The fork has admin bypass enabled, so `--force-with-lease` will not be blocked by branch protection.

## When to give up on the fork

If a rebase introduces unfixable conflicts (e.g., upstream moved to a completely different build system), and the maintenance burden exceeds 4 hours/month, **deprecate the fork and use upstream `:10-kitten` directly** (with the manifest modifications documented in `docs/MANIFEST-PATCHES.md` — TBD if we get there).