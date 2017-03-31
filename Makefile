SOURCEDIR=./pkg ./plugins
SOURCES := $(shell find $(SOURCEDIR) -name '*.go')
ROOT := $(shell pwd)
LOCAL_ENI_PLUGIN_BINARY=bin/plugins/eni
LOCAL_IPAM_PLUGIN_BINARY=bin/plugins/ipam
GIT_PORCELAIN=$(shell git status --porcelain | wc -l)
GIT_SHORT_HASH=$(shell git rev-parse --short HEAD)

.PHONY: get-deps
get-deps:
	go get github.com/golang/mock/gomock
	go get github.com/golang/mock/mockgen
	go get golang.org/x/tools/cmd/goimports
	go get github.com/tools/godep

.PHONY: plugins
plugins: $(LOCAL_ENI_PLUGIN_BINARY) $(LOCAL_IPAM_PLUGIN_BINARY)

$(LOCAL_ENI_PLUGIN_BINARY): $(SOURCES)
	GOOS=linux CGO_ENABLED=0 go build -installsuffix cgo -a -ldflags '-s' -o ${ROOT}/bin/plugins/eni github.com/aws/amazon-ecs-cni-plugins/plugins/eni
	@echo "Built eni plugin"

$(LOCAL_IPAM_PLUGIN_BINARY): $(SOURCES)
	GOOS=linux CGO_ENABLED=0 go build -installsuffix cgo -a -ldflags \
	     "-X github.com/aws/amazon-ecs-cni-plugins/plugins/ipam/version.GitShortHash=$(GIT_SHORT_HASH) \
	     -X github.com/aws/amazon-ecs-cni-plugins/plugins/ipam/version.GitPorcelain=$(GIT_PORCELAIN) -s" \
	     -o ${ROOT}/bin/plugins/ipam github.com/aws/amazon-ecs-cni-plugins/plugins/ipam
	@echo "Built ipam plugin"

.PHONY: generate
generate: $(SOURCES)
	go generate -x ./pkg/... ./plugins/...

.PHONY: unit-test integration-test
unit-test: $(SOURCES)
	go test -v -cover -race -timeout 10s ./pkg/... ./plugins/...

integration-test: $(SOURCE)
	go test -v -tags integration -race -timeout 10s ./pkg/... ./plugins/...

.PHONY: clean
clean:
	rm -rf ${ROOT}/bin ||:
