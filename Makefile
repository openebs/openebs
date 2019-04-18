# Makefile for building Containers for Storage Testing
#
#
# Reference Guide - https://www.gnu.org/software/make/manual/make.html


.PHONY: spell
spell:
	codespell \
		--ignore-words="./.codespell-ignores.txt" \
		--skip="./.git,*.png,*.jpg,*.ico,*.pdf,get-pip.py,dynamo"

#
# This is done to avoid conflict with a file of same name as the targets
# mentioned in this makefile.
#
.DEFAULT_GOAL := spell


