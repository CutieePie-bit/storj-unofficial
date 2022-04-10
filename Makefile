GO_VERSION ?= 1.17.5
GOOS ?= linux
GOARCH ?= amd64
GOPATH ?= $(shell go env GOPATH)
NODE_VERSION ?= 16.11.1
COMPOSE_PROJECT_NAME := ${TAG}-$(shell git rev-parse --abbrev-ref HEAD)
BRANCH_NAME ?= $(shell git rev-parse --abbrev-ref HEAD | sed "s!/!-!g")
ifeq (${BRANCH_NAME},main)
TAG    := $(shell git rev-parse --short HEAD)-go${GO_VERSION}
TRACKED_BRANCH := true
LATEST_TAG := latest
else
TAG    := $(shell git rev-parse --short HEAD)-${BRANCH_NAME}-go${GO_VERSION}
ifneq (,$(findstring release-,$(BRANCH_NAME)))
TRACKED_BRANCH := true
LATEST_TAG := ${BRANCH_NAME}-latest
endif
endif
CUSTOMTAG ?=
JENKINS_DOCKER_NAMESPACE := jenkins/docker_namespace
DOCKER_NAMESPACE := $(shell cat ${JENKINS_DOCKER_NAMESPACE})
DOCKER_EXT := -unofficial01

FILEEXT :=
ifeq (${GOOS},windows)
FILEEXT := .exe
endif

#--------GitRepo for pull images
GIT_REPO := "storj/storj"
LATEST_RELEASE := v1.52.2
#LATEST_RELEASE = $(shell curl --silent "https://api.github.com/repos/$(GIT_REPO)/releases/latest" | \
    		grep '"tag_name":' | \
    		sed -E 's/.*"([^"]+)".*/\1/' \
	  )

#--------Use BuildX with QEMU overlay to allow multi architecture builds, to ensure full ARM support when built on X64 - if building on ARM things might break (tm)
# apt-get install qemu binfmt-support qemu-user-static
# docker run --rm --privileged multiarch/qemu-user-static --reset -p yes 
#
DOCKER_BUILD := docker buildx build \
        --build-arg=TAG=${TAG} --build-arg=RELVER=${LATEST_RELEASE}

DOCKER_BUILD_ARCH32 := docker buildx build --platform linux/arm/v6  \
        --build-arg=TAG=${TAG} --build-arg=RELVER=${LATEST_RELEASE}

DOCKER_BUILD_ARCH64 := docker buildx build --platform linux/arm64/v8  \
        --build-arg=TAG=${TAG} --build-arg=RELVER=${LATEST_RELEASE}

.DEFAULT_GOAL := help
.PHONY: help
help:
	@awk 'BEGIN { \
		FS = ":.*##"; \
		printf "\nUsage:\n  make \033[36m<target>\033[0m\n"\
	} \
	/^[a-zA-Z_-]+:.*?##/ { \
		printf "  \033[36m%-17s\033[0m %s\n", $$1, $$2 \
	} \
	/^##@/ { \
		printf "\n\033[1m%s\033[0m\n", substr($$0, 5) \
	} ' $(MAKEFILE_LIST)

##@:Binary

.PHONY: pull-release
pull-release: ## Pull the latest binary release from github repo
ifeq ($(strip $(LATEST_RELEASE)),)
	$(error >> Unable to query Git Repo)
else
	$(info >> Querying Github Repo: $(GIT_REPO))
	$(info >> Latest Release: $(LATEST_RELEASE))

	mkdir -p releases
	mkdir -p releases/$(LATEST_RELEASE)

	$(info ++ pulling binarys for storagenode)
	for c in arm arm64 amd64 ; do \
		wget -q -O /tmp/tmp.zip https://github.com/storj/storj/releases/download/$(LATEST_RELEASE)/storagenode_linux_$$c.zip && unzip -o /tmp/tmp.zip -d releases/$(LATEST_RELEASE)/$$c && rm /tmp/tmp.zip \
	; done

	$(info ++ pulling binarys for multinode)
	for c in arm arm64 amd64 ; do \
		wget -q -O /tmp/tmp.zip https://github.com/storj/storj/releases/download/$(LATEST_RELEASE)/multinode_linux_$$c.zip && unzip -o /tmp/tmp.zip -d releases/$(LATEST_RELEASE)/$$c && rm /tmp/tmp.zip \
	; done

endif

##@:Docker Images (needs buildx and Qemu)
.PHONY: multinode-image
multinode-image: ## Build multinode Docker image
ifeq ($(strip $(LATEST_RELEASE)),)
	$(error >> Unable to query Git Repo)
else
	${DOCKER_BUILD} --pull=true -t ${DOCKER_NAMESPACE}/multinode${DOCKER_EXT}:${TAG}-${LATEST_RELEASE}${CUSTOMTAG}-amd64 \
		-f cmd/multinode/Dockerfile .
	${DOCKER_BUILD_ARCH32} --pull=true -t ${DOCKER_NAMESPACE}/multinode${DOCKER_EXT}:${TAG}-${LATEST_RELEASE}${CUSTOMTAG}-arm32v6 \
		--build-arg=GOARCH=arm --build-arg=DOCKER_ARCH=arm32v6 \
		-f cmd/multinode/Dockerfile .
	${DOCKER_BUILD_ARCH64} --pull=true -t ${DOCKER_NAMESPACE}/multinode${DOCKER_EXT}:${TAG}-${LATEST_RELEASE}${CUSTOMTAG}-arm64v8 \
		--build-arg=GOARCH=arm64 --build-arg=DOCKER_ARCH=arm64v8 \
		-f cmd/multinode/Dockerfile .
endif

.PHONY: storagenode-image
storagenode-image: ## Build storagenode Docker image
	${DOCKER_BUILD} --pull=true -t ${DOCKER_NAMESPACE}/storagenode${DOCKER_EXT}:${TAG}-${LATEST_RELEASE}${CUSTOMTAG}-amd64 \
		-f cmd/storagenode/Dockerfile .
	${DOCKER_BUILD_ARCH32} --pull=true -t ${DOCKER_NAMESPACE}/storagenode${DOCKER_EXT}:${TAG}-${LATEST_RELEASE}${CUSTOMTAG}-arm32v6 \
		--build-arg=GOARCH=arm --build-arg=DOCKER_ARCH=arm32v6 \
		-f cmd/storagenode/Dockerfile .
	${DOCKER_BUILD_ARCH64} --pull=true -t ${DOCKER_NAMESPACE}/storagenode${DOCKER_EXT}:${TAG}-${LATEST_RELEASE}${CUSTOMTAG}-arm64v8 \
		--build-arg=GOARCH=arm64 --build-arg=DOCKER_ARCH=arm64v8 --build-arg=APK_ARCH=aarch64 \
		-f cmd/storagenode/Dockerfile .

##@ Deploy

.PHONY: push-images
push-images: ## Push Docker images to Docker Hub (dockerhub security token needs to be registered)
        # images have to be pushed before a manifest can be created
	for c in storagenode multinode ; do \
		docker push ${DOCKER_NAMESPACE}/$$c${DOCKER_EXT}:${TAG}-${LATEST_RELEASE}${CUSTOMTAG}-amd64 \
		&& docker push ${DOCKER_NAMESPACE}/$$c${DOCKER_EXT}:${TAG}-${LATEST_RELEASE}${CUSTOMTAG}-arm32v6 \
		&& docker push ${DOCKER_NAMESPACE}/$$c${DOCKER_EXT}:${TAG}-${LATEST_RELEASE}${CUSTOMTAG}-arm64v8 \
		&& for t in ${TAG}-${LATEST_RELEASE}${CUSTOMTAG} ${LATEST_TAG}; do \
			docker manifest create ${DOCKER_NAMESPACE}/$$c${DOCKER_EXT}:$$t \
			${DOCKER_NAMESPACE}/$$c${DOCKER_EXT}:${TAG}-${LATEST_RELEASE}${CUSTOMTAG}-amd64 \
			${DOCKER_NAMESPACE}/$$c${DOCKER_EXT}:${TAG}-${LATEST_RELEASE}${CUSTOMTAG}-arm32v6 \
			${DOCKER_NAMESPACE}/$$c${DOCKER_EXT}:${TAG}-${LATEST_RELEASE}${CUSTOMTAG}-arm64v8 \
			&& docker manifest annotate ${DOCKER_NAMESPACE}/$$c${DOCKER_EXT}:$$t ${DOCKER_NAMESPACE}/$$c${DOCKER_EXT}:${TAG}-${LATEST_RELEASE}${CUSTOMTAG}-amd64 --os linux --arch amd64 \
			&& docker manifest annotate ${DOCKER_NAMESPACE}/$$c${DOCKER_EXT}:$$t ${DOCKER_NAMESPACE}/$$c${DOCKER_EXT}:${TAG}-${LATEST_RELEASE}${CUSTOMTAG}-arm32v6 --os linux --arch arm --variant v6 \
			&& docker manifest annotate ${DOCKER_NAMESPACE}/$$c${DOCKER_EXT}:$$t ${DOCKER_NAMESPACE}/$$c${DOCKER_EXT}:${TAG}-${LATEST_RELEASE}${CUSTOMTAG}-arm64v8 --os linux --arch arm64 --variant v8 \
			&& docker manifest push --purge ${DOCKER_NAMESPACE}/$$c${DOCKER_EXT}:$$t \
                ; done \
        ; done

##@ Clean

.PHONY: clean
clean: bin-clean clean-images ## Clean local docker images, release binaries

.PHONY: binaries-clean
bin-clean: ## Remove all local release binaries for current release only
	rm -rf releases/$(LATEST_RELEASE)

.PHONY: binaries-clean-all
bin-clean-all: ## WARNING - this will remove all local binary releases 
	rm -rf releases

.PHONY: clean-images
clean-images: ## Purge docker images from local build environment
        -docker rmi ${DOCKER_NAMESPACE}/multinode${DOCKER_EXT}:${TAG}-${LATEST_RELEASE}${CUSTOMTAG}*
        -docker rmi ${DOCKER_NAMESPACE}/storagenode${DOCKER_EXT}:${TAG}-${LATEST_RELEASE}${CUSTOMTAG}*

