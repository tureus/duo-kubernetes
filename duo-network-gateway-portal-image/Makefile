.PHONY: create-repository build push deploy

REPO_NAME := "duo-network-gateway-portal"
REPO := $(shell aws ecr describe-repositories | jq '.repositories[].repositoryUri | select( . | contains(${REPO_NAME}))')
TAG := $(shell date +%Y-%m-%d-%H-%M)

build:
	docker build -t $(REPO):$(TAG) .

push: build
	docker push $(REPO):$(TAG)

deploy: push
	kubectl -n duo set image deploy/portal network-gateway-portal=$(REPO):$(TAG)

login:
	aws ecr --region=eu-central-1 get-login --no-include-email | sh

create-repository:
	aws ecr --region=eu-central-1 create-repository --repository-name=$(REPO_NAME)
