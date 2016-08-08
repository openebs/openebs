# Makefile for setting up OpenEBS.
#
# Reference Guide - https://www.gnu.org/software/make/manual/make.html


#
# This is done to avoid conflict with a file of same name as the targets
# mentioned in this makefile.
#
.PHONY: help clean build install _install_base_img _install_make_conf _install_binary _post_install_msg _install_git_base_img _clean_git_base_img _clean_binaries

#
# Internal variables or constants.
# NOTE - These will be executed when any make target is invoked.
#
SET_OPENEBS_CONF_DIR      := $(shell mkdir -p /etc/openebs/.vsms)
IS_OPENEBSD_RUNNING       := $(shell ps aux | grep openebsd | grep -v grep | awk '{print $$NF}')
IS_DROPBOX_BASE_AVAIL     := $(shell ls -ltr /etc/openebs | grep base.tar.gz | awk '{print $$NF}')


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
_clean_git_base_img:
	@echo ""
	@echo -e "INFO:\tremoving openebs base img repo ..."
	@rm -rf ../vsm-image
	@rm -f ../base.tar.gz
	@echo -e "INFO:\topenebs base img repo removed successfully ..."
	@echo ""


#
# Will remove the openebs binaries at $GOPATH/bin
#
_clean_binaries:
	@echo ""
	@echo -e "INFO:\tremoving openebs binaries from $(GOPATH)/bin ..."
	@rm -f $(GOPATH)/bin/openebs
	@rm -f $(GOPATH)/bin/openebsd
	@echo -e "INFO:\topenebs binaries removed successfully from $(GOPATH)/bin ..."
	@echo ""


#
# The clean target to be used by user.
#
clean: _clean_git_base_img _clean_binaries



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
# Will download from dropbox.
# Will reuse the base image if available.
#
_install_base_img: 
ifndef IS_DROPBOX_BASE_AVAIL
	@echo ""
	@echo -e "INFO:\tdownloading openebs base image ..."
	@cd /etc/openebs && wget https://www.dropbox.com/s/b1voxh0t5xlrnqn/base.tar.gz?dl=0#
	@echo -e "INFO:\topenebs base image downloaded successfully ..."
	@echo ""
endif


#
# Internally used target.
# Will create the base image from git.
# Will reuse the base image if available.
#
_install_git_base_img:
	@echo ""
	@if [ -d ../vsm-image ]; then echo -e "INFO:\tgit clone of vsm-image not required"; else cd .. && git clone https://github.com/openebs/vsm-image.git ; fi
	@if [ -f ../base.tar.gz ]; then echo -e "INFO:\twill use ../base.tar.gz file"; else cd ../vsm-image/rootfs && tar -zcf ../../base.tar.gz . ; fi
	@cp ../base.tar.gz /etc/openebs/
	@echo ""


#
# Internally used target.
# Will place the openebs make configs at /etc/openebs/make
#
_install_make_conf: 
	@echo ""
	@echo -e "INFO:\tinstalling openebs make confs ..."
	@rm -rf /etc/openebs/make
	@cp -rp ./etc/openebs/make/ /etc/openebs/make
	@echo -e "INFO:\topenebs make confs installed successfully ..."
	@echo ""


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
	@echo "--------------------------------------------------------------------"
	@echo -e "INFO:\tRun openebs to use the CLI"
	@echo -e "INFO:\tRun below to start the deamon"
	@echo ""
	@echo -e "     \tnohup openebsd >> openebsd.log 2>&1 &"
	@echo ""
	@echo "--------------------------------------------------------------------"
	@echo ""

#
# The install target to be used by Admin.
#
install: build _install_make_conf _install_git_base_img _install_binary _post_install_msg

