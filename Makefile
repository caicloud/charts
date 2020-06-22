# Copyright 2019 The Caicloud Authors.
#
# The old school Makefile, following are required targets. The Makefile is written
# to allow building multiple binaries. You are free to add more targets or change
# existing implementations, as long as the semantics are preserved.
#
#   make              - default to 'build' target
#   make lint         - code analysis
#   make test         - run unit test (or plus integration test)
#   make build        - alias to build-local target
#   make build-local  - build local binary targets
#   make build-linux  - build linux binary targets
#   make container    - build containers
#   $ docker login registry -u username -p xxxxx
#   make push         - push containers
#   make clean        - clean up targets
#
# Not included but recommended targets:
#   make e2e-test
#
# The makefile is also responsible to populate project version information.
#

#
# Tweak the variables based on your project.
#

# This repo's root import path (under GOPATH).
ROOT := github.com/caicloud/charts

# Target binaries. You can build multiple binaries for a single project.
TARGETS := charts templates

# Container image prefix and suffix added to targets.
# The final built images are:
#   $[REGISTRY]/$[IMAGE_PREFIX]$[TARGET]$[IMAGE_SUFFIX]:$[VERSION]
# $[REGISTRY] is an item from $[REGISTRIES], $[TARGET] is an item from $[TARGETS].
IMAGE_PREFIX ?= $(strip )
IMAGE_SUFFIX ?= $(strip )

# Go build GOARCH, you can choose to build amd64 or arm64
ARCH ?= amd64

# Change Dockerfile name and registry project name for arm64
ifeq ($(ARCH),arm64)
DOCKERFILE := Dockerfile.arm64
REGISTRY ?= cargo.dev.caicloud.xyz/arm64v8
else
DOCKERFILE := Dockerfile
REGISTRY ?= cargo.dev.caicloud.xyz/release
endif

#
# These variables should not need tweaking.
#

# Project main package location (can be multiple ones).
CMD_DIR := ./build

# Build direcotory.
BUILD_DIR := ./build

# Current version of the project.
VERSION      ?= $(shell git describe --tags --always --dirty)

#
# Define all targets. At least the following commands are required:
#

# All targets.
.PHONY: lint test build container push

build: build-local

lint: 
	@echo 'no lint'

test:
	@echo 'no test'

test-linux: 
	@for target in $(TARGETS); do                                                      \
	  $(CMD_DIR)/$${target}/test.sh;                                                   \
	done

container: test-linux
	@for target in $(TARGETS); do                                                      \
	  image=$(IMAGE_PREFIX)$${target}$(IMAGE_SUFFIX);                                  \
	  docker build -t $(REGISTRY)/$${image}:$(VERSION)                                 \
	    -f $(BUILD_DIR)/$${target}/$(DOCKERFILE) .;                                    \
	done

push: container
	@for target in $(TARGETS); do                                                      \
	  image=$(IMAGE_PREFIX)$${target}$(IMAGE_SUFFIX);                                  \
	  docker push $(REGISTRY)/$${image}:$(VERSION);                                    \
	done

.PHONY: clean
clean:
	@-rm -vrf ${OUTPUT_DIR}
