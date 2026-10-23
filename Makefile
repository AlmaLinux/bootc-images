PODMAN = sudo podman

IMAGE_NAME = almalinux-bootc
VERSION_MAJOR = 10
PLATFORM = linux/amd64
LABELS ?=

SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c
.ONESHELL:
.PHONY: all
all: image rechunk

.PHONY: image
image:
	$(PODMAN) build \
		--platform=$(PLATFORM) \
		--security-opt=label=disable \
		--cap-add=all \
		--device /dev/fuse \
		--iidfile /tmp/image-id \
		$(LABELS) \
		-t $(IMAGE_NAME) \
		-f $(VERSION_MAJOR)/Containerfile \
		.

.PHONY: rechunk
rechunk:
	# Images are used by ID. For platforms with a variant (amd64/v2), podman doesn't find a local
	# image by its name when given --platform, as images don't record the variant.
	IMAGE_ID=$$(cut -d: -f2 /tmp/image-id)
	# The image has bootc-base-imagectl, so it rechunks itself.
	# rpm-ostree needs /var/tmp as scratch space, which the image doesn't have (/var is empty)
	$(PODMAN) run --rm \
		--platform=$(PLATFORM) \
		--pull=never \
		--privileged \
		--security-opt=label=disable \
		-v /var/lib/containers:/var/lib/containers \
		-v /var/tmp:/var/tmp \
		--entrypoint=/usr/libexec/bootc-base-imagectl \
		$${IMAGE_ID} \
		rechunk $${IMAGE_ID} localhost/$(IMAGE_NAME):rechunked
	# The rechunker can only write to a name, move it to the name of the image and remove the original
	$(PODMAN) tag localhost/$(IMAGE_NAME):rechunked localhost/$(IMAGE_NAME):latest
	$(PODMAN) untag localhost/$(IMAGE_NAME):rechunked localhost/$(IMAGE_NAME):rechunked
	$(PODMAN) rmi $${IMAGE_ID}
