DEPOT_TOOLS_PATH := $(shell realpath ./depot_tools)
export PATH := $(DEPOT_TOOLS_PATH):$(PATH)

.NOTPARALLEL:
.PHONY : build pull clean get_source test

.DEFAULT_GOAL := build

SHELL := /bin/bash

DIRS=lucet-spectre sfi-spectre-testing rlbox_lucet_sandbox

CURR_DIR := $(shell realpath ./)

bootstrap:
	sudo apt -y install curl cmake
	if [ ! -x "$(shell command -v rustc)" ] ; then \
		curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain stable -y; \
	fi
	if [ ! -d /opt/wasi-sdk/ ]; then \
		wget https://github.com/CraneStation/wasi-sdk/releases/download/wasi-sdk-8/wasi-sdk_8.0_amd64.deb -P /tmp/ && \
		sudo dpkg -i /tmp/wasi-sdk_8.0_amd64.deb; \
	fi
	@echo "--------------------------------------------------------------------------"
	@echo "Attention!!!!!!:"
	@echo ""
	@echo "Installed new packages."
	@echo "You need to reload the bash env before proceeding."
	@echo ""
	@echo "Run the command:"
	@echo "source ~/.profile"
	@echo "and run 'make' to build the source"
	@echo ""
	@echo "--------------------------------------------------------------------------"
	touch ./bootstrap

lucet-spectre:
	git clone git@github.com:shravanrn/lucet-spectre.git $@

sfi-spectre-testing:
	git clone git@github.com:shravanrn/sfi-spectre-testing.git $@

rlbox_lucet_sandbox: lucet-spectre
	git clone git@github.com:PLSysSec/rlbox_lucet_sandbox.git $@
	cd $@ && git checkout experimental
	CUSTOM_LUCET_DIR=$(CURR_DIR)/lucet-spectre cmake -S $@ -B $@/build

get_source: $(DIRS)

install_deps: get_source
	touch ./install_deps

pull: get_source
	git pull
	cd rlbox_lucet_sandbox && git pull --recurse-submodules
	cd lucet-spectre && git pull --recurse-submodules
	cd sfi-spectre-testing && git pull --recurse-submodules

build: install_deps pull
	cd lucet-spectre && cargo build
	$(MAKE) -C rlbox_lucet_sandbox/build
	$(MAKE) -C sfi-spectre-testing build

test: build
	$(MAKE) -C sfi-spectre-testing test

clean:
	-cd lucet-spectre && cargo clean
	-$(MAKE) -C sfi-spectre-testing clean
