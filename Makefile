PROJECT_DIR = $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

BUILD_IMAGE      = local/pspy-build:latest
BUILD_DOCKERFILE = $(PROJECT_DIR)/docker/Dockerfile.build

DEV_IMAGE      = local/pspy-development:latest
DEV_DOCKERFILE = $(PROJECT_DIR)/docker/Dockerfile.development

TEST_IMAGE      = local/pspy-testing:latest
TEST_DOCKERFILE = $(PROJECT_DIR)/docker/Dockerfile.testing

# Run unit test and integration test inside container
test:
	docker build -f $(TEST_DOCKERFILE) -t $(TEST_IMAGE) . 
	docker run -it --rm $(TEST_IMAGE)

# Build Docker image for development
# pspy has to run on Linux - use this if you develop on another OS
dev-build:
	docker build -f $(DEV_DOCKERFILE) -t $(DEV_IMAGE) .

# Drops you into a shell in the development container and mounts the source code
# You can edit to source on your host, then run go commans (e.g., `go test ./...`) inside the container
dev:
	docker run -it \
		       --rm \
			   -v $(PROJECT_DIR):/go/src/github.com/dominicbreuker/pspy \
			   -w "/go/src/github.com/dominicbreuker/pspy" \
			   $(DEV_IMAGE)

EXAMPLE_IMAGE      = local/pspy-example:latest
EXAMPLE_DOCKERFILE = $(PROJECT_DIR)/docker/Dockerfile.example

# Run the example demonstrating what pspy does
example:
	docker build -t $(EXAMPLE_IMAGE) -f $(EXAMPLE_DOCKERFILE) .
	docker run -it --rm $(EXAMPLE_IMAGE)


build-build-image:
	docker build -f $(BUILD_DOCKERFILE) -t $(BUILD_IMAGE) .

# Build different binaries
# builds binaries for both 32bit and 64bit systems
# builds one set of static binaries that should work on any system without dependencies, but are huge
# builds another set of binaries that are as small as possible, but may not work 
build:
	mkdir -p $(PROJECT_DIR)/bin
	docker run -it \
		       --rm \
		       -v $(PROJECT_DIR):/go/src/github.com/dominicbreuker/pspy \
			   -w "/go/src/github.com/dominicbreuker" \
			   --env CGO_ENABLED=0 \
			   --env GOOS=linux \
			   --env GOARCH=386 \
	           $(BUILD_IMAGE) /bin/sh -c "go build -a -ldflags '-extldflags \"-static\"' -o pspy/bin/pspy32 pspy/main.go"
	docker run -it \
		       --rm \
		       -v $(PROJECT_DIR):/go/src/github.com/dominicbreuker/pspy \
			   -w "/go/src/github.com/dominicbreuker" \
			   --env CGO_ENABLED=0 \
			   --env GOOS=linux \
			   --env GOARCH=amd64 \
	           $(BUILD_IMAGE) /bin/sh -c "go build -a -ldflags '-extldflags \"-static\"' -o pspy/bin/pspy64 pspy/main.go"
	docker run -it \
		       --rm \
		       -v $(PROJECT_DIR):/go/src/github.com/dominicbreuker/pspy \
			   -w "/go/src/github.com/dominicbreuker" \
			   --env GOOS=linux \
			   --env GOARCH=386 \
	           $(BUILD_IMAGE) /bin/sh -c "go build -ldflags '-w -s' -o pspy/bin/pspy32s pspy/main.go && upx pspy/bin/pspy32s"
	docker run -it \
		       --rm \
		       -v $(PROJECT_DIR):/go/src/github.com/dominicbreuker/pspy \
			   -w "/go/src/github.com/dominicbreuker" \
			   --env GOOS=linux \
			   --env GOARCH=amd64 \
	           $(BUILD_IMAGE) /bin/sh -c "go build -ldflags '-w -s' -o pspy/bin/pspy64s pspy/main.go && upx pspy/bin/pspy64s"
