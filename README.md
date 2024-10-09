## AlmaLinux Bootable Container Images

**Caution** AlmaLinux bootc images are currently *experimental*

- https://almalinux.org/get-almalinux/

- https://containers.github.io/bootc/

### Available Official Images

- https://quay.io/repository/almalinuxorg/almalinux-bootc?tab=tags

## News

- https://almalinux.org/blog/2024-09-02-bootc-almalinux-heliumos/

N/A

## Usage

### AlmaLinux 9

```sh
podman build --security-opt=label=disable --cap-add=all \
  --device /dev/fuse -t localhost/almalinux-9-bootc -f 9/Containerfile .
```
