# Makefile for setting up OpenEBS.
#
# Reference Guide - https://www.gnu.org/software/make/manual/make.html


#
# This is done to avoid conflict with a file of same name as the targets
# mentioned in this makefile.
#
.PHONY: help clean build install _install_make_conf _install_binary _post_install_msg _install_git_base_img _clean_git_base_img _clean_binaries _install_openebs_conf_dir _build_check_go _build_check_lxc _install_check_openebs_daemon

#
# Internal variables or constants.
# NOTE - These will be executed when any make target is invoked.
#
IS_OPENEBSD_RUNNING       := $(shell ps aux | grep -v grep | grep -c openebsd)
IS_GO_INSTALLED           := $(shell which go >> /dev/null 2>&1; echo $$?)
IS_LXC_INSTALLED          := $(shell which lxc-create >> /dev/null 2>&1; echo $$?)

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
	@echo -e "INFO:\tremoving openebs base img repos and tar file ..."
	@rm -rf ../vsm-image
	@rm -rf ../tgt
	@rm -f ../base.tar.gz
	@echo -e "INFO:\topenebs base img repos and tar file removed successfully ..."
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


_build_check_lxc:
	@if [ $(IS_LXC_INSTALLED) -eq 1 ]; \
		then echo "" \
		&& echo -e "ERROR:\tlinux containers (i.e. lxc) is not installed. Please install it before build." \
		&& echo "" \
		&& exit 1; \
		fi;

_build_check_go:
	@if [ $(IS_GO_INSTALLED) -eq 1 ]; \
		then echo "" \
		&& echo -e "ERROR:\tgo is not installed. Please install it before build." \
		&& echo -e "Refer:\thttps://github.com/openebs/openebs#building-from-sources" \
		&& echo "" \
		&& exit 1; \
		fi;


#
# Will build the go based binaries
# The binaries will be placed at $GOPATH/bin/
#
build: _build_check_go _build_check_lxc
	@echo ""
	@echo -e "INFO:\tbuilding openebs ..."
	@go get -t ./...
	@go get -u github.com/golang/lint/golint
	@echo -e "INFO:\topenebs built successfully ..."
	@echo ""



_install_check_openebs_daemon:
	@if [ $(IS_OPENEBSD_RUNNING) -eq 1 ]; \
		then echo "" \
		&& echo -e "ERROR:\topenebsd is running. It needs to be stopped before re-install." \
		&& echo "" \
		&& exit 1; \
		fi;


#
# Internally used target.
# Will create openebs config directory structure.
#
_install_openebs_conf_dir:
	@mkdir -p /etc/openebs/.vsms


#
# Internally used target.
# Will create the base image from git.
# Will reuse the base image if available.
#
_install_git_base_img:
	@echo ""
	@if [ -d ../vsm-image ]; then echo -e "INFO:\tgit clone of vsm-image not required"; else \
		echo "" \
		&& cd .. \
		&& git clone https://github.com/openebs/vsm-image.git \
		&& echo "" ;\
		fi
	@if [ -d ../tgt ]; then echo -e "INFO:\tbuild  tgt binaries not required"; else \
		echo "" \
		&& cd .. \
		&& git clone https://github.com/openebs/tgt.git \
		&& cd ./tgt \
		&& make -s programs CFS=1 \
		&& cp usr/tgtd usr/tgtadm usr/tgtimg ../vsm-image/rootfs/sbin/ \
		&& echo "" ; \
		fi
	@if [ -f ../base.tar.gz ]; then echo -e "INFO:\twill use existing base file at ../base.tar.gz"; else \
		cd ../vsm-image/rootfs \
		&& tar -zcf ../../base.tar.gz . ; \
		fi
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
install: _install_check_openebs_daemon build _install_openebs_conf_dir _install_make_conf _install_git_base_img _install_binary _post_install_msg

