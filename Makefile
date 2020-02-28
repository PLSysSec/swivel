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
	if [ ! -d /opt/binaryen/ ]; then \
		wget https://github.com/WebAssembly/binaryen/releases/download/version_90/binaryen-version_90-x86_64-linux.tar.gz -P /tmp/ && \
		sudo mkdir /opt/binaryen && \
		sudo tar -xzf /tmp/binaryen-version_90-x86_64-linux.tar.gz -C /opt/binaryen && \
		sudo mv /opt/binaryen/binaryen-version_90 /opt/binaryen/bin; \
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
	git clone git@github.com:PLSysSec/lucet-spectre.git $@
	cd $@ && git submodule update --init --recursive

sfi-spectre-testing:
	git clone git@github.com:PLSysSec/sfi-spectre-testing.git $@
	cd $@ && git submodule update --init --recursive

rlbox_lucet_sandbox:
	git clone git@github.com:PLSysSec/rlbox_lucet_sandbox.git $@
	cd $@ && git checkout experimental
	cd $@ && git submodule update --init --recursive
	CUSTOM_LUCET_DIR=$(CURR_DIR)/lucet-spectre cmake -S $@ -B $@/build

get_source: $(DIRS)

install_deps: $(DIRS)
	touch ./install_deps

pull: get_source
	git pull
	cd rlbox_lucet_sandbox && git pull --recurse-submodules
	cd lucet-spectre && git pull --recurse-submodules
	cd sfi-spectre-testing && git pull --recurse-submodules

spec:
	git clone git@github.com:PLSysSec/sfi-spectre-spec.git

build: install_deps
	cd lucet-spectre && cargo build
	# cd rlbox_lucet_sandbox/build && $(MAKE)
	$(MAKE) -C sfi-spectre-testing build

test:
	# $(MAKE) -C rlbox_lucet_sandbox/build check
	$(MAKE) -C sfi-spectre-testing test
	$(MAKE) -C lucet-spectre/benchmarks/shootout


clean:
	-cd lucet-spectre && cargo clean
	-$(MAKE) -C sfi-spectre-testing clean
