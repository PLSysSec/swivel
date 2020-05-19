.NOTPARALLEL:
.PHONY : build min_build pull clean get_source test build_spec run_spec build_sightglass run_sightglass build_sightglass_nocet run_sightglass_nocet

.DEFAULT_GOAL := build

SHELL := /bin/bash

MIN_DIRS=lucet-spectre sfi-spectre-testing
DIRS=rustc-cet lucet-spectre sfi-spectre-testing rlbox_spectre_sandboxing_api rlbox_lucet_spectre_sandbox

CURR_DIR := $(shell realpath ./)

LAST_CPU_CORE := $(shell echo "$$(( $$(nproc --all) - 1 ))" )

bootstrap:
	if [ -x "$(shell command -v apt)" ]; then \
		sudo apt -y install curl cmake msr-tools cpuid cpufrequtils; \
	elif [ -x "$(shell command -v dnf)" ]; then \
		sudo dnf -y install curl cmake msr-tools cpuid cpufrequtils; \
	else \
		echo "Unknown installer. apt/dnf not found"; \
		exit 1; \
	fi
	if [ ! -x "$(shell command -v rustc)" ] ; then \
		curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain stable -y; \
	fi
	if [ ! -d /opt/wasi-sdk/ ]; then \
		wget https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-10/wasi-sdk-10.0-linux.tar.gz -P /tmp/ && \
		tar -xzf /tmp/wasi-sdk-10.0-linux.tar.gz && \
		sudo mv wasi-sdk-10.0 /opt/wasi-sdk; \
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

rustc-cet:
	git clone git@github.com:PLSysSec/rustc-cet.git $@
	cd $@ && git submodule update --init --recursive

get_source: $(DIRS)

install_deps: $(DIRS)
	touch ./install_deps;

pull: $(DIRS)
	git pull
	cd rlbox_spectre_sandboxing_api && git pull
	cd rlbox_lucet_spectre_sandbox && git pull --recurse-submodules
	cd lucet-spectre && git pull --recurse-submodules
	cd sfi-spectre-testing && git pull --recurse-submodules

min_pull: $(MIN_DIRS)
	git pull
	cd lucet-spectre && git pull --recurse-submodules
	cd sfi-spectre-testing && git pull --recurse-submodules

sfi-spectre-spec:
	git clone git@github.com:PLSysSec/sfi-spectre-spec.git
	cd sfi-spectre-spec && SPEC_INSTALL_NOCHECK=1 SPEC_FORCE_INSTALL=1 sh install.sh -f

build_spec: sfi-spectre-spec
	cd sfi-spectre-spec && source shrc && \
	cd config && \
	runspec --config=wasm_lucet.cfg --action=build oakland && \
	runspec --config=wasm_loadlfence.cfg --action=build oakland && \
	runspec --config=wasm_strawman.cfg --action=build oakland && \
	runspec --config=wasm_sfi.cfg --action=build oakland && \
	runspec --config=wasm_cet.cfg --action=build oakland && \
	runspec --config=wasm_blade.cfg --action=build oakland

run_spec:
	sh cp_spec_data_into_tmp.sh 
	cd sfi-spectre-spec && source shrc && cd config && \
	runspec --config=wasm_lucet.cfg --iterations=1 --noreportable --size=ref --wasm oakland && \
	runspec --config=wasm_loadlfence.cfg --iterations=1 --noreportable --size=ref --wasm oakland && \
	runspec --config=wasm_strawman.cfg --iterations=1 --noreportable --size=ref --wasm oakland && \
	runspec --config=wasm_sfi.cfg --iterations=1 --noreportable --size=ref --wasm oakland && \
	runspec --config=wasm_cet.cfg --iterations=1 --noreportable --size=ref --wasm oakland && \
	runspec --config=wasm_blade.cfg --iterations=1 --noreportable --size=ref --wasm oakland && \
	python3 sfi-spectre-testing/scripts/spec_stats.py

out/rust_build/bin/rustc:
	mkdir -p out/rust_build
	cd ./rustc-cet && ./x.py build && ./x.py install
	rustup toolchain link rust-cet ./out/rust_build

build: install_deps out/rust_build/bin/rustc
	mkdir -p ./out
	cd lucet-spectre && cargo build
	cd lucet-spectre && \
		CFLAGS="-fcf-protection=full" \
		CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER="$(CURR_DIR)/rustc-cet/rust_cet_linker" \
		CARGO_TARGET_DIR="${CURR_DIR}/lucet-spectre/target-cet" \
		cargo +rust-cet build
	# $(MAKE) -C rlbox_lucet_spectre_sandbox/build
	$(MAKE) -C sfi-spectre-testing build

min_build: $(MIN_DIRS)
	mkdir -p ./out
	cd lucet-spectre && cargo build
	$(MAKE) -C sfi-spectre-testing build

test:
	# $(MAKE) -C rlbox_lucet_spectre_sandbox/build check
	$(MAKE) -C sfi-spectre-testing test

build_sightglass: install_deps out/rust_build/bin/rustc
	cd lucet-spectre && cargo build --release
	cd lucet-spectre && \
		CFLAGS="-fcf-protection=full" \
		CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER="$(CURR_DIR)/rustc-cet/rust_cet_linker" \
		CARGO_TARGET_DIR="${CURR_DIR}/lucet-spectre/target-cet" \
		cargo +rust-cet build --release
	$(MAKE) -C lucet-spectre/benchmarks/shootout clean
	REALLY_USE_CET=1 $(MAKE) -C lucet-spectre/benchmarks/shootout build

run_sightglass:
	if [ -x "$(shell command -v cpupower)" ]; then \
		sudo cpupower -c $(LAST_CPU_CORE) frequency-set --min 2700MHz --max 2700MHz; \
	else \
		sudo cpufreq-set -c $(LAST_CPU_CORE) --min 2700MHz --max 2700MHz; \
	fi
	REALLY_USE_CET=1 $(MAKE) -C lucet-spectre/benchmarks/shootout run

build_sightglass_nocet: install_deps
	cd lucet-spectre && cargo build --release
	$(MAKE) -C lucet-spectre/benchmarks/shootout clean
	$(MAKE) -C lucet-spectre/benchmarks/shootout build

run_sightglass_nocet:
	if [ -x "$(shell command -v cpupower)" ]; then \
		sudo cpupower -c $(LAST_CPU_CORE) frequency-set --min 2700MHz --max 2700MHz; \
	else \
		sudo cpufreq-set -c $(LAST_CPU_CORE) --min 2700MHz --max 2700MHz; \
	fi
	$(MAKE) -C lucet-spectre/benchmarks/shootout run

clean:
	-cd lucet-spectre && cargo clean
	-$(MAKE) -C sfi-spectre-testing clean
