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
IS_BASE_AVAIL             := $(shell if [ -d "/etc/openebs" ]; then ls -ltr /etc/openebs | grep base.tar.gz | awk '{print $$NF}'; fi)

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
	@echo -e "INFO:\tremoving openebs conf from /etc/openebs/make ..."
	@rm -rf /etc/openebs/make
	@echo -e "INFO:\topenebs conf removed successfully from /etc/openebs/make ..."
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
# Internally used target.
# Will place the openebs config or script files at /etc/openebs
# Will reuse the base image if available.
#
_install_conf: 
	@echo ""
	@echo -e "INFO:\tinstalling openebs conf ..."
	@rm -rf /etc/openebs/make
	@cp -rp ./etc/openebs /etc
	@echo -e "INFO:\topenebs conf installed successfully ..."
	@echo ""
ifndef IS_BASE_AVAIL
	@echo -e "INFO:\tdownloading openebs base image ..."
	@cd /etc/openebs && wget https://www.dropbox.com/s/b1voxh0t5xlrnqn/base.tar.gz?dl=0#
	@echo -e "INFO:\topenebs base image downloaded successfully ..."
	@echo ""
endif


#
# Internally used target.
# Will place the openebs binaries at /sbin/
#
_install_binary:
	@echo ""
	@echo -e "INFO:\tinstalling openebs binaries ..."
ifdef IS_OPENEBSD_RUNNING
	@$(error ERROR: openebsd is running. It needs to be stopped before re-install.)
endif
	@cp $(GOPATH)/bin/openebs /sbin/
	@cp $(GOPATH)/bin/openebsd /sbin/
	@echo -e "INFO:\topenebs binaries installed successfully ..."
	@echo ""


#
# Internally used target.
# Will post a simple usage message.
#
_post_install_msg:
	@echo ""
	@echo -e "INFO:\tRun openebs to use the CLI"
	@echo -e "INFO:\tRun openebsd in a new terminal to start the openebs daemon"
	@echo ""

#
# The install target to be used by Admin.
#
install: _install_conf _install_binary _post_install_msg
