SHELL = bash
.ONESHELL:

MACHINENAME   = $(NAME)

DOCKER_COMPOSE= docker-compose
DOCKER        = docker
CONTAINER_NAME= dropbox
EMAIL         = ivan@42algoritmos.local

latest        = $(VERSION)

all: help

.PHONY: help
help:
	@printf "%s\n" "Useful targets:"
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m  make %-15s\033[0m %s\n", $$1, $$2}'

.PHONY: config
config: ## Create .env file
	cat <<- EOF > .env
		OWNCLOUD_VERSION=10.10
		OWNCLOUD_DOMAIN=localhost:8080
		ADMIN_USERNAME=admin
		ADMIN_PASSWORD=admin
		HTTP_PORT=8080
	EOF

.PHONY: up
up: ## Turn on the container as a background server
	$(DOCKER_COMPOSE) up -d

.PHONY: ps
ps: ## Shows processes that are running or suspended
	$(DOCKER) ps -a

.PHONY: status
status: ## Show Name, cpu and memory usage per machine
	$(DOCKER) stats --all --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"

info:
	$(DOCKER) inspect -f '{{ index .Config.Labels "build_version" }}' $(MACHINENAME):$(latest)

pause:
	$(DOCKER) pause dropbox          
	$(DOCKER) pause owncloud_redis
	$(DOCKER) pause owncloud_mariadb
unpause:
	$(DOCKER) unpause dropbox          
	$(DOCKER) unpause owncloud_redis
	$(DOCKER) unpause owncloud_mariadb

images:
	$(DOCKER) images --format "{{.Repository}}:{{.Tag}}"| sort
ls:
	$(DOCKER) images --format "{{.ID}}: {{.Repository}}"
size:
	$(DOCKER) images --format "{{.Size}}\t: {{.Repository}}"
tags:
	$(DOCKER) images --format "{{.Tag}}\t: {{.Repository}}"| sort -t ':' -k2 -n

net:
	$(DOCKER) network ls

rm-network:
	$(DOCKER) network ls| awk '$$2 !~ "(bridge|host|none)" {print "docker network rm " $$1}' | sed '1d'

rmi:
	docker rmi $(MACHINENAME):$(latest)

rm-all:
	$(DOCKER) ps -aq -f status=exited| xargs $(DOCKER) rm

stop-all:
	$(DOCKER) ps -aq -f status=running| xargs $(DOCKER) stop

log:
	$(DOCKER) logs -f $(CONTAINER_NAME)

ip:
	$(DOCKER) ps -q \
	| xargs $(DOCKER) inspect --format '{{ .Name }}:{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'\
	| \sed 's/^.*://'

memory:
	$(DOCKER) inspect `$(DOCKER) ps -aq` | grep -i mem

fix:
	$(DOCKER) images -q --filter "dangling=true"| xargs $(DOCKER) rmi -f

stop:
	$(DOCKER) stop dropbox          
	$(DOCKER) stop owncloud_redis
	$(DOCKER) stop owncloud_mariadb

rm:
	$(DOCKER) rm dropbox          
	$(DOCKER) rm owncloud_redis
	$(DOCKER) rm owncloud_mariadb

exec:
	$(DOCKER) exec -it $(CONTAINER_NAME) /bin/sh

restart:
	$(DOCKER) restart  $(CONTAINER_NAME)

unbuild: rmi

.PHONY: clean
clean: stop rm ## remove shut down the container and remove

