NAME    := panubo/sensu-aio
BRANCH  := $(shell git rev-parse --abbrev-ref HEAD 2> /dev/null)
VERSION := $(shell sed -E -e '/^ENV BUILD_VERSION/!d' -e 's/^ENV BUILD_VERSION (.*)/\1/' Dockerfile)
VERSION_MAJOR  := $(shell echo $(VERSION) | sed -e 's/-/./' | cut -d\. -f1)
VERSION_MINOR  := $(shell echo $(VERSION) | sed -e 's/-/./' | cut -d\. -f2)
VERSION_PATCH := $(shell echo $(VERSION) | sed -e 's/-/./' | cut -d\. -f3)
VERSION_REV  := $(shell echo $(VERSION) | sed -e 's/-/./' | cut -d\. -f4)

.PHONY: help build vars git-release docker-release
help:
	@printf "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)\n"

build: ## Builds docker image latest
	docker build -t $(NAME):latest .

vars:
	@echo "Branch: $(BRANCH)"
	@echo "Version: $(VERSION)"
	@echo "Major: $(VERSION_MAJOR)"
	@echo "Minor: $(VERSION_MINOR)"
	@echo "Hotfix: $(VERSION_PATCH)"
	@echo "Buid: $(VERSION_REV)"

git-release: ## Creates git tag for release
	[ "x$$(git status --porcelain 2> /dev/null)" == "x" ]
	git tag $(VERSION)
	git push -u origin $(BRANCH)
	git push --tags

docker-release: ## Builds and pushes docker image
	git checkout tags/$(VERSION)
	docker build -t $(NAME):$(VERSION) .
	docker tag $(NAME):$(VERSION) docker.io/$(NAME):$(VERSION)
	docker tag $(NAME):$(VERSION) docker.io/$(NAME):$(VERSION_MAJOR).$(VERSION_MINOR).$(VERSION_PATCH)
	docker push docker.io/$(NAME):$(VERSION)
	docker push docker.io/$(NAME):$(VERSION_MAJOR).$(VERSION_MINOR).$(VERSION_PATCH)
	git checkout $(BRANCH)

run: ## Runs sensu-server
	touch env
	docker run --rm -it --name sensu-server --env-file env $(NAME):latest
