.PHONY: build-pythonpackage coverage coverage-browse-report coverage-html \
        coverage-report coverage-tests dev-requirements format help \
        push-pythonpackage release release-push release-tag release-unsafe \
        requirements test test-format test-k8s test-lint test-pythonpackage \
        test-types test-unit upgrade version

.DEFAULT_GOAL := help

PACKAGE=tutorcoursegraph
PROJECT=tutor-contrib-coursegraph

SOURCES=./setup.py ./$(PACKAGE) ./tests

UPGRADE=CUSTOM_COMPILE_COMMAND='make upgrade' pip-compile --upgrade

###### Development

upgrade: ## Upgrade requirements files
	pip install -r requirements/piptools.txt
	$(UPGRADE) requirements/piptools.in
	pip install -r requirements/piptools.txt
	$(UPGRADE) requirements/base.in
	$(UPGRADE) requirements/dev.in

requirements: ## Install packages from base requirement files
	pip install -r requirements/piptools.txt
	pip install -r requirements/base.txt
	pip uninstall --yes $(PROJECT)
	pip install .

dev-requirements: ## Install packages from developer requirement files
	pip install -r requirements/piptools.txt
	pip install -r requirements/dev.txt
	pip uninstall --yes $(PROJECT)
	pip install -e .

build-pythonpackage: ## Build Python packages ready to upload to pypi
	python setup.py sdist

push-pythonpackage: ## Push python package to pypi
	twine upload --skip-existing dist/$(PROJECT)-$(shell make version).tar.gz

test: test-lint test-unit test-types test-format test-pythonpackage ## Run all tests by decreasing order of priority

test-format: ## Run code formatting tests
	black --check --diff ${SOURCES}

test-lint: ## Run code linting tests
	pylint ${SOURCES}

test-unit: ## Run unit tests
	python -m unittest discover tests

test-types: ## Check type definitions
	mypy --ignore-missing-imports --strict ${SOURCES}

test-pythonpackage: build-pythonpackage ## Test that package can be uploaded to pypi
	twine check dist/$(PROJECT)-$(shell make version).tar.gz

test-k8s: ## Validate the k8s format with kubectl. Not part of the standard test suite.
	tutor k8s apply --dry-run=client --validate=true

format: ## Format code automatically
	black ${SOURCES}

###### Code coverage

coverage: ## Run unit-tests before analyzing code coverage and generate report
	$(MAKE) --keep-going coverage-tests coverage-report

coverage-tests: ## Run unit-tests and analyze code coverage
	coverage run -m unittest discover

coverage-report: ## Generate CLI report for the code coverage
	coverage report

coverage-html: coverage-report ## Generate HTML report for the code coverage
	coverage html

coverage-browse-report: coverage-html ## Open the HTML report in the browser
	sensible-browser htmlcov/index.html

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
