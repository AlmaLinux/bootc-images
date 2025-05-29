PODMAN = sudo podman

IMAGE_NAME = almalinux-bootc
VERSION_MAJOR = 10
PLATFORM = linux/amd64

.PHONY: all
all: rechunk

.PHONY: image
image:
	$(PODMAN) build \
		--platform=$(PLATFORM) \
		--security-opt=label=disable \
		--cap-add=all \
		--device /dev/fuse \
		-t $(IMAGE_NAME)-prechunk \
		-f $(VERSION_MAJOR)/Containerfile \
		.

.PHONY: rechunk
rechunk: image
	$(PODMAN) run \
		--rm --privileged \
		-v /var/lib/containers:/var/lib/containers \
		quay.io/centos-bootc/centos-bootc:stream10 \
		/usr/libexec/bootc-base-imagectl rechunk \
		$(IMAGE_NAME)-prechunk $(IMAGE_NAME)
	-$(PODMAN) rmi $(IMAGE_NAME) $(IMAGE_NAME)-prechunk 2>/dev/null || true
