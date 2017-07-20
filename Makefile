# Copyright 2015 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and

GO := go
goversion = 1.6.2
pkgs  = $(shell $(GO) list ./... | grep -v vendor)
build-image = cadvisor-build-image
container = cadvisor
BUILD_ARGS    ?= --build-arg http_proxy=$$http_proxy \
		 --build-arg https_proxy=$$https_proxy \
		 --build-arg no_proxy=$$no_proxy

all: presubmit build test

build-image:
	@docker build $(BUILD_ARGS) -t $(build-image) -f build/Dockerfile.build .

test: build-image
	@echo ">> running tests using docker"
	@docker run --rm -i -v $(PWD):/go/src/github.com/google/cadvisor $(build-image) $(GO) test -tags test -short -race $(pkgs)

test-integration:
	@./build/integration.sh

test-runner:
	@$(GO) build github.com/google/cadvisor/integration/runner

format:
	@echo ">> formatting code"
	@$(GO) fmt $(pkgs)

vet:
	@echo ">> vetting code"
	@$(GO) vet $(pkgs)

build: build-image
	@echo ">> building binaries using docker"
	@docker run --rm -v $(PWD):/go/src/github.com/google/cadvisor $(build-image) /bin/sh -c "./build/assets.sh;./build/build.sh"

assets:
	@echo ">> building assets"
	@./build/assets.sh

release:
	@echo ">> building release binaries"
	@./build/release.sh

docker:
	@docker build $(BUILD_ARGS) -t $(container) -f deploy/Dockerfile .

presubmit: vet
	@echo ">> checking go formatting"
	@./build/check_gofmt.sh
	@echo ">> checking file boilerplate"
	@./build/check_boilerplate.sh

.PHONY: all build docker format release test test-integration vet presubmit
