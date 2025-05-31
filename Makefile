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
		-t $(IMAGE_NAME) \
		-f $(VERSION_MAJOR)/Containerfile \
		.

.PHONY: rechunk
rechunk:
	$(PODMAN) run \
	        --platform=$(PLATFORM) \
		--rm --privileged \
	        --security-opt=label=disable \
		-v /var/lib/containers:/var/lib/containers:z \
		quay.io/centos-bootc/centos-bootc:stream10 \
		/usr/libexec/bootc-base-imagectl rechunk \
		localhost/$(IMAGE_NAME):latest localhost/rechunked-$(IMAGE_NAME):latest && \
	$(PODMAN) tag localhost/rechunked-$(IMAGE_NAME):latest localhost/$(IMAGE_NAME):latest && \
	$(PODMAN) rmi localhost/rechunked-$(IMAGE_NAME):latest
