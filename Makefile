# Required environment variables
#
include environments/$(ENVIRONMENT)
export COMPOSE_FILE=docker-compose-$(ENVIRONMENT).yml
export $(shell sed 's/=.*//' environments/$(ENVIRONMENT))

REQUIRED_ENV := ENVIRONMENT DOCKER_REPO COMPOSE_PROJECT_NAME DOMAIN SSL
ALL_ENV := $(.VARIABLES)
MISSING_ENV := $(filter-out $(ALL_ENV), $(REQUIRED_ENV))

ifneq (,$(MISSING_ENV))
	$(error missing environment variables [$(MISSING_ENV)])
endif

SERVICES ?= $(shell cat docker-compose-local.yml|  python3 -c  'import sys, yaml, json; y=yaml.load(sys.stdin.read()); print(json.dumps(y))' | jq -r '.services | keys | join(" ")')
# Required executables
REQUIRED_PROGRAMS = bash git docker docker-compose

GIT := $(shell command -v git 2> /dev/null)
SHELL :=/bin/bash
BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
COMMIT_HASH := $(shell git rev-parse --short HEAD)
IMAGES ?= $(shell docker-compose -f docker-compose-$(ENVIRONMENT).yml config | grep 'image: ' | tr -d ' ' | cut -d ':' -f2 | xargs)
REPO_IMAGES ?= $(foreach img, $(IMAGES), $(DOCKER_REPO)/$(img);)
REPO_COMMANDS := $(foreach repo_img,$(REPO_IMAGES), $(foreach(tag, $(TAGS), docker tag $(repo_img) $(tag))))
RELEASE := $(shell $(ENV_VARS) head -n 1 RELEASE_NOTES | cut -d ' ' -f2)
TAG ?= $(ENVIRONMENT)
TAGS ?= latest $(BRANCH) $(COMMIT_HASH) $(TAG)

.PHONY: help
help: ## print this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | cut -d ':' -f2,3 | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-10s\033[0m %s\n", $$1, $$2 $$3}'

.PHONY: require-docker-up
require-docker-up: ## check that that the system is up


.PHONY: tag
tag: ## tag $IMAGES with $TAGS.
	@for img in $(IMAGES); \
	do \
		for tag in $(TAGS); \
		do \
		docker tag $$img $$img:$$tag; \
		done \
	done 

.PHONY: tag-repo
tag-repo: ## tag $IMAGES with the current docker $DOCKER_REPO
	@for img in $(IMAGES); \
	do \
		for tag in $(TAGS); \
		do \
		docker tag $$img $(DOCKER_REPO)/$$img; \
		docker tag $(DOCKER_REPO)/$$img $(DOCKER_REPO)/$$img:$$tag; \
		done \
	done 

.PHONY: build
build: ## build all services in $COMPOSE_FILE
	docker-compose build $(SERVICES)

.PHONY: push
push: tag-repo ## push all $IMAGES to $DOCKER_REPO/$IMAGE:[$(TAG)]. 
	@for img in $(IMAGES); \
	do \
		for tag in $(TAGS); \
		do \
		docker push $(DOCKER_REPO)/$$img:$$tag; \
		done \
	done 

.PHONY: pull
pull: ## pull $IMAGES with specific tags $TAGS
	@for img in $(IMAGES); \
	do \
		for tag in $(TAGS); \
		do \
		docker pull $(DOCKER_REPO)/$$img:$$tag; \
		done \
	done 

.PHONY: swarmdown
swarmdown:
	-docker swarm leave --force

.PHONY: swarmup
swarmup: swarmdown
	docker swarm init 
	docker stack deploy --compose-file=$(COMPOSE_FILE) $(ENVIRONMENT)

.PHONY: dcu
dcu: ## start docker compose using $TAG to specify the image
	docker-compose up -d 

.PHONY: dcps
dcps: 
	docker-compose ps

.PHONY: dcd
dcd:  ## stop docker instances launched using docker-compose
	docker-compose down

.PHONY: 
dce: ## bring down docker-compose and remove all images and volumes
	docker-compose down --rmi all -v 

.PHONY: cert
cert: ## generate a self-signed ssl certificate for development
	www/cert.sh

dctest: ## run bats tests on docker-compose
	bats/bin/bats --tap tests/docker-compose.bats

swarmtest: ## run bats tests on docker swarm
	bats/bin/bats --tap tests/docker-swarm.bats

