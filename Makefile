# Makefile for building OpenEBS components
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

_build_tests_vdbench:
	@echo "INFO: Building container image for performing vdbench tests"


_push_test_vdbench_image:
	@echo "INFO: Publish container (openebs/test-vdbench)"


#
# Will build the go based binaries
# The binaries will be placed at $GOPATH/bin/
#
build: deps _build_test_vdbench _push_test_vdbench_image


#
# This is done to avoid conflict with a file of same name as the targets
# mentioned in this makefile.
#
.PHONY: help deps build
.DEFAULT_GOAL := build


