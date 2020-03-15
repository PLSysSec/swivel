.NOTPARALLEL:
.PHONY : build min_build pull clean get_source test

.DEFAULT_GOAL := build

SHELL := /bin/bash

MIN_DIRS=lucet-spectre sfi-spectre-testing
DIRS=lucet-spectre sfi-spectre-testing rlbox_spectre_sandboxing_api rlbox_lucet_spectre_sandbox aligned_clang firefox-stock firefox-spectre

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

rlbox_spectre_sandboxing_api:
	git clone git@github.com:PLSysSec/rlbox_spectre_sandboxing_api.git $@

rlbox_lucet_spectre_sandbox:
	git clone git@github.com:PLSysSec/rlbox_lucet_spectre_sandbox.git $@
	cd $@ && git checkout experimental
	cd $@ && git submodule update --init --recursive
	CUSTOM_LUCET_DIR=$(CURR_DIR)/lucet-spectre cmake -S $@ -B $@/build

aligned_clang:
	git clone https://github.com/llvm/llvm-project.git $@
	cd $@ && git checkout -b 14fc20ca6282

firefox-stock:
	git clone https://github.com/PLSysSec/firefox-spectre $@
	cd $@ && git checkout stock

firefox-spectre:
	git clone https://github.com/PLSysSec/firefox-spectre $@

get_source: $(DIRS)

install_deps: $(DIRS)
	$(MAKE) -C ./firefox-stock bootstrap
	# don't need to run bootstrap in second firefox repo
	touch ./firefox-spectre/builds/bootstrap
	touch ./install_deps

pull: $(DIRS)
	git pull
	cd rlbox_spectre_sandboxing_api && git pull
	cd rlbox_lucet_spectre_sandbox && git pull --recurse-submodules
	cd lucet-spectre && git pull --recurse-submodules
	cd sfi-spectre-testing && git pull --recurse-submodules
	cd firefox-stock && git pull
	cd firefox-spectre && git pull

min_pull: $(MIN_DIRS)
	git pull
	cd lucet-spectre && git pull --recurse-submodules
	cd sfi-spectre-testing && git pull --recurse-submodules

setup_spec:
	git clone git@github.com:PLSysSec/sfi-spectre-spec.git
	cd sfi-spectre-spec && sh install.sh 

build_spec:
	cd sfi-spectre-spec && source shrc
	cd sfi-spectre-spec/config && runspec --config=wasm_lucet.cfg --action=build oakland
	cd sfi-spectre-spec/config && runspec --config=wasm_spectre.cfg --action=build oakland
	cd sfi-spectre-spec/config && runspec --config=wasm_fence.cfg --action=build oakland

run_spec:
	sh cp_spec_data_into_tmp.sh 
	cd sfi-spectre-spec && source shrc
	cd sfi-spectre-spec/config && runspec --config=wasm_lucet.cfg --iterations=1 --noreportable --size=ref --wasm oakland
	cd sfi-spectre-spec/config && runspec --config=wasm_spectre.cfg --iterations=1 --noreportable --size=ref --wasm oakland
	cd sfi-spectre-spec/config && runspec --config=wasm_fence.cfg --iterations=1 --noreportable --size=ref --wasm oakland

out/aligned_clang/bin/clang:
	mkdir -p out/aligned_clang
	cd out/aligned_clang && cmake -DLLVM_ENABLE_PROJECTS=clang $(CURR_DIR)/aligned_clang/llvm
	# Some build failures exist which seem ignorable
	-$(MAKE) -C out/aligned_clang

build: install_deps out/aligned_clang/bin/clang
	mkdir -p ./out
	cd lucet-spectre && cargo build
	$(MAKE) -C rlbox_lucet_spectre_sandbox/build
	$(MAKE) -C sfi-spectre-testing build

min_build: $(MIN_DIRS)
	mkdir -p ./out
	cd lucet-spectre && cargo build
	$(MAKE) -C sfi-spectre-testing build

test:
	$(MAKE) -C rlbox_lucet_spectre_sandbox/build check
	$(MAKE) -C sfi-spectre-testing test
	
sightglass:
	$(MAKE) -C lucet-spectre/benchmarks/shootout run_all
	#$(MAKE) -C lucet-spectre/benchmarks/shootout run_sensitivity

clean:
	-cd lucet-spectre && cargo clean
	-$(MAKE) -C sfi-spectre-testing clean
	-$(MAKE) -C out/aligned_clang clean
	-$(MAKE) -C firefox-stock/builds clean
	-$(MAKE) -C firefox-spectre/builds clean
