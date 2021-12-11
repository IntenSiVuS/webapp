
.ONESHELL:
.SHELL := /bin/bash
.PHONY: fmt-check plan apply


WEBAPP_IMAGE := intensivus/webapp:v1.0.0
WEBAPP_WORKDIR ?= ./resources
MODULE_DIR := $$PWD/terraform
TEST_DIR ?= $$PWD/tests
REGION ?= eu-central-1

AWS_PROFILE ?= personal
# For simplicity i use the same profile for infra deploy and for state storage
# For security it's Best to use different accounts or roles for this though
AWS_BACKEND_PROFILE := $(AWS_PROFILE)
DOCKER_ENV_VARS := REGION=$(REGION) AWS_PROFILE=$(AWS_PROFILE)
DOCKER_WORK_DIR := /docker/
DOCKER_FLAGS := -v $(MODULE_DIR):/docker  -v ~/.aws:/root/.aws \
                $(foreach var, $(EXTRA_TF_VARS) $(DOCKER_ENV_VARS), -e $(var)) --rm -it

# AWS := aws
# Setting up the 'terraform' command to make it run inside docker so it won't be needed locally or on a
# build agent.
TERRAFORM := docker run -v  ~/.terraform:/root/.terraform \
				-v ~/.terraform.d:/root/.terraform.d \
				-w $(DOCKER_WORK_DIR)/ \
				$(DOCKER_FLAGS) --entrypoint terraform intensivus/ci_utils:v1.0.0 


# Makefile targets:

# giving some general help 
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

# Setting up the environment before running actual commands by setting a bunch of env variables
set-env:
	$(eval VARS:=./terraform/input.auto.tfvars)
	$(eval ENV=$(shell sed 's/\ *=\ */=/g' $(VARS) | awk -F= '/^environment/{ gsub(/"/, "", $$2); print $$2}'))
	$(eval REGION:=$(shell sed 's/\ *=\ */=/g' $(VARS) | awk -F= '/^region/{ gsub(/"/, "", $$2); print $$2}'))
	$(eval AWS_PROFILE:=$(shell sed 's/\ *=\ */=/g' $(VARS) | awk -F= '/^aws_profile_tf_deploy/{ gsub(/"/, "", $$2); print $$2}'))
	$(eval S3_BUCKET:="intensivus-tf-state")
	$(eval DYNAMODB_TABLE:="intensivus-tf-state")
	$(eval S3_KEY:="webapp/$(ENV)/terraform.tfstate")
	$(eval PIPENV := AWS_PROFILE=$(AWS_PROFILE) \
			REGION=$(REGION) \
			PIPENV_VENV_IN_PROJECT=1 pipenv)

# Set up the virtual environment used to run the python test(s)
set-pipenv: set-env
	cd tests
	pip install pipenv -q
	$(PIPENV) install

# Check if syntax and quality of the python code is good
pylint: set-pipenv
	$(PIPENV) run pylint $(TEST_DIR)/*.py

# Preperation to run the terraform commands that require initialization
# This is just a 'terraform init' which sets up the backend where the state is stored
prep: set-env
	$(info Configuring the terraform backend using $(AWS_BACKEND_PROFILE))
	$(TERRAFORM) init \
		-input=false \
		-backend-config="profile=$(AWS_BACKEND_PROFILE)" \
		-backend-config="region=eu-central-1" \
		-backend-config="bucket=$(S3_BUCKET)" \
		-backend-config="key=$(S3_KEY)" \
		-backend-config="encrypt=true" \
		-backend-config="dynamodb_table=$(DYNAMODB_TABLE)"

# A step which can be used while developing to check if your terraform code is valid
validate: prep ## Validate terraform code
	$(TERRAFORM) validate

# The terraform plan step which will show you what infra terraform would want to create for you.
# It will not actually create it but it will save the plan to a file.
# The plan output can then be used in the apply target.
plan: prep ## Show terraform plan
	$(TERRAFORM) plan \
		-input=false \
		-out=terraform.plan  $(terraform_plan_extra_args)

# The terraform apply step. We use the output from plan to apply it. This hard split is specifically useful
# when running this in a CICD pipeline as we make sure this way that what we planned in a previous step is applied
apply: prep ## Apply terraform plan
	$(TERRAFORM) apply \
		-input=false terraform.plan
	$(TERRAFORM) output --raw url > output.txt

# The terraform command to destroy the infrastructure. Obviously use it with care.
destroy: prep ## Destroy terraform only to use for test clusters
	$(TERRAFORM) destroy -input=false -auto-approve

# with this step we actually test if our infra works and serves our container
pytest: set-pipenv ## Run pytests
# this is a rather ugly way of getting the external url and have python use that to test.
# Usually i would build the url by using things like <product>.<env>.somedomain.com and use r53 for that
# but as we cant for free, i grab to url of the lb and let terraform output that to a file
# which then is used within python 
	$(PIPENV) run pytest -vv --junitxml=$(TEST_DIR)/reports.xml $(TEST_DIR)/*.py

# With this target we will check if the terraform code has been formatted according to standards.
# If it has not been formatted properly it will show output and we cuold let our pipeline fail. 
fmt-check: ## terraform format check
	@$(TERRAFORM) fmt -check -diff -recursive

# This is used to build the nginx docker image with the small website build in it
build:
	docker build -t $(WEBAPP_IMAGE)  $(WEBAPP_WORKDIR)/.

# Push our just build docker image to the image repository. In this case dockerhub, but could obviously also be ECR 
publish:
	printenv DOCKER_PASSWORD | docker login -u $(DOCKER_USERNAME) --password-stdin
	docker push $(WEBAPP_IMAGE)

.DEFAULT_GOAL := help
