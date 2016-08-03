# Makefile for setting up OpenEBS.
#
# Reference Guide - https://www.gnu.org/software/make/manual/make.html


#
# This is done to avoid conflict with a file of same name as the targets
# mentioned in this makefile.
#
.PHONY: help clean build install

#
# Internal variables or constants
#
IS_OPENEBSD_RUNNING       := $(shell ps -aux | grep openebsd | grep -v grep | awk '{print $$NF}')


#
# The first target is the default.
# i.e. 'make' is same as 'make help'
#
help:
	@echo ""
	@echo "Usage:-"
	@echo -e "\tmake clean              -- will remove openebs binaries from $(GOPATH)/bin"
	@echo -e "\tmake build              -- will build openebs binaries"
	@echo -e "\tmake install            -- will build & install the openebs binaries"
	@echo ""


#
# Will remove the openebs binaries at $GOPATH/bin
#
clean:
	@echo ""
	@echo -e "INFO:\tremoving openebs binaries from $(GOPATH)/bin ..."
	@rm -f $(GOPATH)/bin/openebs
	@rm -f $(GOPATH)/bin/openebsd
	@echo -e "INFO:\topenebs binaries removed successfully from $(GOPATH)/bin ..."
	@echo ""
	@echo -e "INFO:\tremoving openebs conf from /etc/openebs ..."
	@rm -rf /etc/openebs/
	@echo -e "INFO:\topenebs conf removed successfully from /etc/openebs ..."
	@echo ""


#
# Will build the go based binaries
# The binaries will be placed at $GOPATH/bin/
#
build:
	@echo ""
	@echo -e "INFO:\tbuilding openebs ..."
	@go get -t ./...
	@go get -u github.com/golang/lint/golint
	@echo -e "INFO:\topenebs built successfully ..."
	@echo ""


#
# Will place the openebs binaries at /sbin/
#
install: 
	@echo ""
	@echo -e "INFO:\tinstalling openebs ..."
ifdef IS_OPENEBSD_RUNNING
	@$(error ERROR: openebsd is running. It needs to be stopped before re-install.)
endif
	@cp $(GOPATH)/bin/openebs /sbin/
	@cp $(GOPATH)/bin/openebsd /sbin/
	@rm -rf /etc/openebs/
	@cp -rp ./etc/openebs /etc
	@echo -e "INFO:\topenebs installed successfully ..."
	@echo ""
	@echo -e "INFO:\tRun openebs to use the CLI"
	@echo -e "INFO:\tRun openebsd in a new terminal to start the openebs daemon"
	@echo ""
