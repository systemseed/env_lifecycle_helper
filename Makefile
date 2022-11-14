# Create local environment file if not exists.
$(shell cp -n \.env\.local\.default \.env\.local)
include .env

# Define function to highlight messages.
# @see https://gist.github.com/leesei/136b522eb9bb96ba45bd
yellow= \033[38;5;3m
bold = \033[1m
reset = \033[0m
message = @echo "${yellow}${bold}${1}${reset}"

cli:
	$(call message,$(COMPOSE_PROJECT_NAME): Opening bash terminal...)
	docker-compose run --rm --service-ports cli bash

build:
	$(call message,$(COMPOSE_PROJECT_NAME): Building docker image...)
	docker build . \
		-t $(COMPOSE_PROJECT_NAME) \
		--build-arg LINUX_ALPINE_VERSION=$(LINUX_ALPINE_VERSION) \
		--build-arg AWS_CLI_VERSION=$(AWS_CLI_VERSION) \
		--build-arg S3CMD_VERSION=$(S3CMD_VERSION) \
		-f Dockerfile

# https://stackoverflow.com/a/6273809/1826109
%:
	@:
