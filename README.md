## AlmaLinux Bootable Container Images

**Caution** AlmaLinux bootc images are currently *experimental*

- https://almalinux.org/get-almalinux/

- https://containers.github.io/bootc/

### Available Official Images

N/A

## Usage

### AlmaLinux 9

```sh
podman build --security-opt=label=disable --cap-add=all \
  --device /dev/fuse -t localhost/almalinux-9-bootc -f 9/Containerfile .
```
