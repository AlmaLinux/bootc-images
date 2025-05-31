## AlmaLinux Bootable Container Images

**Caution** AlmaLinux bootc images are currently *experimental*

- https://almalinux.org/get-almalinux/

- https://containers.github.io/bootc/

    This is based off the [CentOS Bootc Base Images](https://gitlab.com/redhat/centos-stream/containers/bootc/-/tree/c10s?ref_type=heads) using 
[bootc-base-imagectl](https://gitlab.com/fedora/bootc/base-images/-/blob/main/bootc-base-imagectl.md?ref_type=heads)
  

### Available Official Images

- https://quay.io/repository/almalinuxorg/almalinux-bootc?tab=tags

## News

- https://almalinux.org/blogalma linux kitten/2024-09-02-bootc-almalinux-heliumos/

## Usage

This repo uses make to build the images. The following example will build the x86_64-v2 variant of AlmaLinux OS Kitten 10.  

```
make \
PLATFORM=linux/amd64/v2 \
IMAGE_NAME=almalinux-bootc \
VERSION_MAJOR=10-kitten
```

or Almalinux 9

```
make \
PLATFORM=linux/amd64 \
IMAGE_NAME=almalinux-bootc \
VERSION_MAJOR=9
```

## Contributing

Come share what you are building or get guidance and get involved at 
the [Atomic SIG](https://wiki.almalinux.org/sigs/Atomic.html) and [Cloud SIG](https://wiki.almalinux.org/sigs/Cloud.html)

### Chat

- Atomic SIG  [Mattermost](https://chat.almalinux.org/almalinux/channels/sigatomic) [Matrix](https://matrix.to/#/#sig-atomic:almalinux.im)

- Cloud SIG [Mattermost](https://chat.almalinux.org/almalinux/channels/sigcloud) [Matrix](https://matrix.to/#/#sig-cloud:almalinux.im)
