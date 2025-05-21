PODMAN = sudo podman

IMAGE_NAME = almalinux-bootc
# ${{ env.IMAGE_NAME }}
VERSION_MAJOR = 10
# ${{ inputs.VERSION_MAJOR }}
PLATFORM = linux/amd64
# ${{ env.PLATFORM }}

image:
	$(PODMAN) build \
		--platform=$(PLATFORM) \
        --security-opt=label=disable \
        --cap-add=all \
        --device /dev/fuse \
        -t $(IMAGE_NAME) \
        -f $(VERSION_MAJOR)/Containerfile \
        .