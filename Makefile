.PHONY: dev-requirements format help release release-push release-tag \
        release-unsafe requirements test test-format test-install test-lint \
        test-pythonpackage test-types upgrade version

.DEFAULT_GOAL := help

PACKAGE=tutorcoursegraph
PROJECT=tutor-contrib-coursegraph

SOURCES=./setup.py ./$(PACKAGE)

UPGRADE=CUSTOM_COMPILE_COMMAND='make upgrade' pip-compile --upgrade

###### Development

upgrade: ## Upgrade requirements files
	pip install -r requirements/pip.txt
	$(UPGRADE) --allow-unsafe requirements/pip.in
	pip install -r requirements/pip.txt
	$(UPGRADE) requirements/base.in
	$(UPGRADE) requirements/dev.in

requirements: ## Install packages from base requirement files
	pip install -r requirements/pip.txt
	pip install -r requirements/base.txt
	pip uninstall --yes $(PROJECT)
	pip install .

dev-requirements: ## Install packages from developer requirement files
	pip install -r requirements/pip.txt
	pip install -r requirements/dev.txt
	pip uninstall --yes $(PROJECT)
	pip install -e .

test: test-lint test-install test-types test-format test-pythonpackage ## Run all tests by decreasing order of priority

test-format: ## Run code formatting tests
	black --check --diff ${SOURCES}

test-lint: ## Run code linting tests
	pylint ${SOURCES}

test-install: ## Run installation test script
	tests/test-install.sh

test-types: ## Check type definitions
	mypy --ignore-missing-imports --strict ${SOURCES}

test-pythonpackage: ## Test that package can be uploaded to pypi
	python setup.py sdist
	twine check dist/$(PROJECT)-$(shell make version).tar.gz

format: ## Format code automatically
	black ${SOURCES}

###### Deployment

release: test release-unsafe ## Create a release tag and push it to origin
release-unsafe:
	$(MAKE) release-tag release-push TAG=v$(shell make version)
release-tag:
	@echo "=== Creating tag $(TAG)"
	git tag -d $(TAG) || true
	git tag $(TAG)
release-push:
	@echo "=== Pushing tag $(TAG) to origin"
	git push origin
	git push origin :$(TAG) || true
	git push origin $(TAG)

###### Additional commands

version: ## Print the current tutor version
	@python -c 'import io, os; about = {}; exec(io.open(os.path.join("$(PACKAGE)", "__about__.py"), "rt", encoding="utf-8").read(), about); print(about["__version__"])'

ESCAPE = 
help: ## Print this help
	@grep -E '^([a-zA-Z_-]+:.*?## .*|######* .+)$$' Makefile \
		| sed 's/######* \(.*\)/@               $(ESCAPE)[1;31m\1$(ESCAPE)[0m/g' | tr '@' '\n' \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[33m%-30s\033[0m %s\n", $$1, $$2}'
