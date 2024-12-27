.PHONY: test test-docker test-kubernetes test-helm test-nix

test: test-docker test-kubernetes test-helm test-nix

test-docker:
	conftest test ./tests/docker/*.yaml -p ./policies/docker

test-kubernetes:
	conftest test ./tests/kubernetes/*.yaml -p ./policies/kubernetes

test-helm:
	conftest test ./tests/helm/*.yaml -p ./policies/helm

test-nix:
	conftest test ./tests/nix/*.yaml -p ./policies/nix

test-all:
	conftest test ./tests/**/*.yaml -p ./policies

verify:
	conftest verify --policy ./policies
