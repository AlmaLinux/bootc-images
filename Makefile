PODMAN = sudo podman

IMAGE_NAME = almalinux-bootc
VERSION_MAJOR = 10
PLATFORM = linux/amd64

.ONESHELL:
.PHONY: all
all: rechunk

.PHONY: image
image:
	if [ "$(PLATFORM)" = */v2 ]; then
		VARIANT_FLAG="--variant=v2";
	fi;

	$(PODMAN) build \
		--platform=$(PLATFORM) \
		$$VARIANT_FLAG \
		--security-opt=label=disable \
		--cap-add=all \
		--device /dev/fuse \
		--iidfile /tmp/image-id \
		-t $(IMAGE_NAME) \
		-f $(VERSION_MAJOR)/Containerfile \
		.

rechunk:
	$(PODMAN) run \
		--rm --privileged \
		--security-opt=label=disable \
		-v /var/lib/containers:/var/lib/containers:z \
		quay.io/centos-bootc/centos-bootc:stream10 \
		/usr/libexec/bootc-base-imagectl rechunk \
		localhost/$(IMAGE_NAME):latest localhost/rechunked-$(IMAGE_NAME):latest && \
	$(PODMAN) tag localhost/rechunked-$(IMAGE_NAME):latest localhost/$(IMAGE_NAME):latest && \
	$(PODMAN) rmi localhost/rechunked-$(IMAGE_NAME):latest
