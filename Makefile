# Copyright 2017 The Caicloud Authors.
#
# The old school Makefile, following are required targets. The Makefile is written
# to allow building multiple binaries. You are free to add more targets or change
# existing implementations, as long as the semantics are preserved.
#
#   make        - default to 'build' target
#   make lint   - code analysis
#   make test   - run unit test (or plus integration test)
#   make build        - alias to build-local target
#   make build-local  - build local binary targets
#   make build-linux  - build linux binary targets
#   make container    - build containers
#   make push    - push containers
#   make clean   - clean up targets
#
# Not included but recommended targets:
#   make e2e-test
#
# The makefile is also responsible to populate project version information.
#
# TODO: implement 'make push'

#
# Tweak the variables based on your project.
#

# Current version of the project.
VERSION ?= v1.3.1

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

# Container registries.
REGISTRIES ?= cargo.caicloudprivatetest.com/caicloud

#
# These variables should not need tweaking.
#

# Project main package location (can be multiple ones).
CMD_DIR := ./build

# Build direcotory.
BUILD_DIR := ./build

# Git commit sha.
COMMIT := $(shell git rev-parse --short HEAD)

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
	  $(CMD_DIR)/$${target}/test.sh;                                                  \
	done

container: test-linux
	@for target in $(TARGETS); do                                                      \
	  for registry in $(REGISTRIES); do                                                \
	    image=$(IMAGE_PREFIX)$${target}$(IMAGE_SUFFIX);                                \
	    docker build -t $${registry}/$${image}:$(VERSION)                              \
	      -f $(BUILD_DIR)/$${target}/Dockerfile .;                                     \
	  done                                                                             \
	done

push: container
	@for target in $(TARGETS); do                                                      \
	  for registry in $(REGISTRIES); do                                                \
	    image=$(IMAGE_PREFIX)$${target}$(IMAGE_SUFFIX);                                \
	    docker push $${registry}/$${image}:$(VERSION);                                 \
	  done                                                                             \
	done

.PHONY: clean
clean:
	-rm -vrf ${OUTPUT_DIR}
