PODMAN = sudo podman

IMAGE_NAME = almalinux-bootc
VERSION_MAJOR = 10
PLATFORM = linux/amd64

image:
	$(PODMAN) build \
		--platform=$(PLATFORM) \
        --security-opt=label=disable \
        --cap-add=all \
        --device /dev/fuse \
        -t $(IMAGE_NAME) \
        -f $(VERSION_MAJOR)/Containerfile \
        .
