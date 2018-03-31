SHELL :=/bin/bash
ifndef ENVIRONMENT
$(error ENVIRONMENT is not set)
endif
BRANCH := $(shell git branch)
COMMIT_HASH := $(shell git rev-parse --short HEAD)
ENV_VARS := $(shell cat environments/$(ENVIRONMENT) | grep -v ^\# | xargs)
IMAGES := $(shell $(ENV_VARS) docker-compose -f docker-compose-$(ENVIRONMENT).yml config | grep 'image: ' | tr -d ' ' | cut -d ':' -f2 | xargs)
COMPOSE_FILE := docker-compose-$(ENVIRONMENT).yml
MANAGER_IP := $(shell aws ec2 describe-instances --filter Name=tag:swarm-node-type,Values=manager | jq -r '.Reservations[0].Instances[0].PublicIpAddress')
RELEASE := $(shell head -n 1 RELEASE_NOTES | cut -d ' ' -f2)
.PHONY: help
help:
	@echo IMAGES $(IMAGES)
	@echo ENVIRONMENT $(ENV_VARS)
	@echo MANAGER_IP $(MANAGER_IP)

.PHONY: tag-as
tag-as:
	$(foreach img,$(IMAGES), docker tag $(img) $(img):$(as);)
	$(foreach img,$(IMAGES), docker push $(img):$(as);)


.PHONY: tag-release
tag-release: as=$(shell head -n 1 RELEASE_NOTES | cut -d ' ' -f2)
tag-release: tag-as

.PHONY: tag-commit
tag-commit: as=$(COMMIT_HASH)
tag-commit: tag-as

.PHONY: tag-environment
tag-environment: as=$(ENVIRONMENT)
tag-environment: tag-as

.PHONY: tag-branch
tag-branch: as=$(BRANCH)
tag-branch: tag-as

.PHONY: tag
tag: tag-environment tag-commit tag-branch

.PHONY: build
build:
	$(ENV_VARS) docker-compose -f $(COMPOSE_FILE) build --pull

.PHONY: release
release: build tag-release tag push
	@echo "Release Finished: $(RELEASE)"

.PHONY: deploy
deploy: 
	@echo $(shell ssh -f -L 127.0.0.1:2374:/var/run/docker.sock docker@$(MANAGER_IP) sleep 10; ENVIRONMENT=$(ENVIRONMENT) TAG=$(RELEASE) $(ENV_VARS) docker -H localhost:2374 stack deploy -c $(COMPOSE_FILE) $(ENVIRONMENT))

.PHONY: push
push:
	$(foreach img,$(IMAGES), docker push $(img);)

.PHONY: pull
pull:
	$(foreach img,$(IMAGES), docker pull $(img);)

.PHONY: swarmdown
swarmdown:
	-docker swarm leave --force

.PHONY: swarmup
swarmup: swarmdown
	docker swarm init
	$(ENV_VARS) docker stack deploy -c $(COMPOSE_FILE) $(ENVIRONMENT)

.PHONY: du
dcu: 
	$(ENV_VARS) docker-compose -f $(COMPOSE_FILE) up -d 

.PHONY: ds
dcs: 
	$(ENV_VARS) docker-compose -f $(COMPOSE_FILE) down

.PHONY: dd
dcd: 
	$(ENV_VARS) docker-compose -f $(COMPOSE_FILE) down

dps: 
	@ $(ENV_VARS) docker-compose -f $(COMPOSE_FILE) ps 

.PHONY: 
de:
	$(ENV_VARS) docker-compose -f $(COMPOSE_FILE) down --rmi all -v 

.PHONY: cert
cert:
	$(ENV_VARS) www/cert.sh

dctest:
	bats/bin/bats --tap tests/docker-compose.bats


