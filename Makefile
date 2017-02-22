NAME = panubo/sensu-aio
VERSION = $(shell sed -E -e '/^ENV BUILD_VERSION/!d' -e 's/^ENV BUILD_VERSION (.*)/\1/' Dockerfile)

help:
	@printf "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)\n"

build: ## Builds docker image latest
	docker build -t $(NAME):latest .

git-release: ## Creates git tag for release
	[ "x$$(git status --porcelain 2> /dev/null)" == "x" ]
	git tag $(VERSION)
	git push -u origin release/$(VERSION)
	git push --tags

docker-release: ## Builds and pushes docker image
	git checkout tags/$(VERSION)
	docker build -t $(NAME):$(VERSION) .
	docker tag $(NAME):$(VERSION) docker.io/$(NAME):$(VERSION)
	docker tag $(NAME):$(VERSION) quay.io/$(NAME):$(VERSION)
	docker push docker.io/$(NAME):$(VERSION)
	docker push quay.io/$(NAME):$(VERSION)
