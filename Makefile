# Makefile for building Containers for Storage Testing
#
#
# Reference Guide - https://www.gnu.org/software/make/manual/make.html


#
# Internal variables or constants.
# NOTE - These will be executed when any make target is invoked.
#
IS_DOCKER_INSTALLED       := $(shell which docker >> /dev/null 2>&1; echo $$?)

help:
	@echo ""
	@echo "Usage:-"
	@echo "\tmake build             -- will build openebs components"
	@echo "\tmake deps              -- will verify build dependencies are installed"
	@echo ""


_build_check_docker:
	@if [ $(IS_DOCKER_INSTALLED) -eq 1 ]; \
		then echo "" \
		&& echo "ERROR:\tdocker is not installed. Please install it before build." \
		&& echo "" \
		&& exit 1; \
		fi;

deps: _build_check_docker
	@echo ""
	@echo "INFO:\tverifying dependencies for OpenEBS ..."

_build_operator_image:
	@echo "INFO: Building container image for OpenEBS K8s Operator"
	cd k8s/lib/operator && docker build -t openebs/operator .


_push_operator_image:
	@echo "INFO: Publish container (openebs/operator)"
	cd k8s/lib/operator/buildscripts && ./push


build: deps _build_operator_image _push_operator_image

spell:
	codespell \
		--ignore-words="./.codespell-ignores.txt" \
		--skip="./.git,*.png,*.jpg,*.ico,*.pdf,get-pip.py,dynamo"

#
# This is done to avoid conflict with a file of same name as the targets
# mentioned in this makefile.
#
.PHONY: help deps build spell
.DEFAULT_GOAL := build


