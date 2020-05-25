.NOTPARALLEL:
.PHONY : build build_nocet pull clean get_source \
test test_nocet \
build_lucet build_lucet_nocet \
build_spec run_spec \
build_spec2017 run_spec2017 \
run_spec_all \
build_sightglass run_sightglass build_sightglass_nocet run_sightglass_nocet \
build_transitions_benchmark run_transitions_benchmark \
build_cdn_benchmark build_cdn_benchmark_nocet run_cdn_benchmark_server run_cdn_benchmark_server_nocet \
run_cdn_benchmark_client run_cdn_benchmark_client_nocet

.DEFAULT_GOAL := build

SHELL := /bin/bash

DIRS=rustc-cet lucet-spectre sfi-spectre-testing rlbox_spectre_sandboxing_api rlbox_lucet_spectre_sandbox btbflush-module wasm_compartments node_modules

CURR_DIR := $(shell realpath ./)

LAST_CPU_CORE := $(shell echo "$$(( $$(nproc --all) - 1 ))" )

FOUND_BTBMODULE := $(shell lsmod | grep "cool")

bootstrap:
	if [ -x "$(shell command -v apt)" ]; then \
		sudo apt -y install curl cmake msr-tools cpuid cpufrequtils npm; \
	elif [ -x "$(shell command -v dnf)" ]; then \
		sudo dnf -y install curl cmake msr-tools cpuid cpufrequtils npm; \
	else \
		echo "Unknown installer. apt/dnf not found"; \
		exit 1; \
	fi
	if [ ! -x "$(shell command -v rustc)" ] ; then \
		curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain nightly -y; \
	fi
	rustup target add wasm32-wasi
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
	npm install autocannon

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

btbflush-module:
	git clone git@github.com:PLSysSec/btbflush-module.git $@

install_btbflush: btbflush-module
	# make -C does not work below
	if [ -z "$(FOUND_BTBMODULE)" ]; then  \
		echo "Installing BTB flush module" && \
		cd ./btbflush-module/module && make && make insert; \
	fi

wasm_compartments:
	git clone git@github.com:PLSysSec/wasm_compartments.git $@
	cd $@ && git submodule update --init --recursive

node_modules:
	npm install autocannon

get_source: $(DIRS)

install_deps: $(DIRS)
	touch ./install_deps;

pull: $(DIRS)
	git pull
	cd rlbox_spectre_sandboxing_api && git pull
	cd rlbox_lucet_spectre_sandbox && git pull --recurse-submodules
	cd lucet-spectre && git pull --recurse-submodules
	cd sfi-spectre-testing && git pull --recurse-submodules
	cd rustc-cet && git pull --recurse-submodules
	cd btbflush-module && git pull
	cd wasm_compartments && git pull --recurse-submodules

libnsl:
	git clone https://github.com/thkukuk/libnsl

libnsl/build/lib/libnsl.so: libnsl
	cd ./libnsl && \
	autoreconf -fi && \
	./configure --prefix "$(CURR_DIR)/libnsl/build" && \
	make -j8 build && \
	make install

libnsl/build/lib/libnsl.so.1: libnsl/build/lib/libnsl.so
	cp $< $@

sfi-spectre-spec: libnsl/build/lib/libnsl.so.1
	git clone git@github.com:PLSysSec/sfi-spectre-spec.git
	cd sfi-spectre-spec && LD_LIBRARY_PATH="$(CURR_DIR)/libnsl/build/lib/" SPEC_INSTALL_NOCHECK=1 SPEC_FORCE_INSTALL=1 sh install.sh -f

build_spec: sfi-spectre-spec
	export LD_LIBRARY_PATH="$(CURR_DIR)/libnsl/build/lib/" && \
	cd sfi-spectre-spec && source shrc && \
	cd config && \
	runspec --config=wasm_lucet.cfg --action=clobber oakland && \
	runspec --config=wasm_lucet.cfg --action=build oakland && \
	runspec --config=wasm_loadlfence.cfg --action=clobber oakland && \
	runspec --config=wasm_loadlfence.cfg --action=build oakland && \
	runspec --config=wasm_strawman.cfg --action=build oakland && \
	runspec --config=wasm_strawman.cfg --action=clobber oakland && \
	runspec --config=wasm_sfi.cfg --action=build oakland && \
	runspec --config=wasm_sfi.cfg --action=clobber oakland && \
	runspec --config=wasm_cet.cfg --action=build oakland && \
	runspec --config=wasm_cet.cfg --action=clobber oakland && \
	runspec --config=wasm_sfi_noblade.cfg --action=build oakland && \
	runspec --config=wasm_sfi_noblade.cfg --action=clobber oakland && \
	runspec --config=wasm_cet_noblade.cfg --action=build oakland && \
	runspec --config=wasm_cet_noblade.cfg --action=clobber oakland && \
	runspec --config=wasm_blade.cfg --action=build oakland && \
	runspec --config=wasm_blade.cfg --action=clobber oakland

run_spec: build_spec
	export LD_LIBRARY_PATH="$(CURR_DIR)/libnsl/build/lib/" && \
	sh cp_spec_data_into_tmp.sh && \
	cd sfi-spectre-spec && source shrc && cd config && \
	runspec --config=wasm_lucet.cfg --iterations=1 --noreportable --size=ref --wasm oakland && \
	runspec --config=wasm_loadlfence.cfg --iterations=1 --noreportable --size=ref --wasm oakland && \
	runspec --config=wasm_strawman.cfg --iterations=1 --noreportable --size=ref --wasm oakland && \
	runspec --config=wasm_sfi.cfg --iterations=1 --noreportable --size=ref --wasm oakland && \
	runspec --config=wasm_cet.cfg --iterations=1 --noreportable --size=ref --wasmcet oakland && \
	runspec --config=wasm_blade.cfg --iterations=1 --noreportable --size=ref --wasm oakland && \
	runspec --config=wasm_sfi_noblade.cfg --iterations=1 --noreportable --size=ref --wasm oakland && \
	runspec --config=wasm_cet_noblade.cfg --iterations=1 --noreportable --size=ref --wasmcet oakland && \
	python3 sfi-spectre-testing/scripts/spec_stats.py sfi-spectre-spec/result 8 sfi-spectre-spec/result
	mv sfi-spectre-spec/result/ benchmarks/spec_$(shell date --iso=seconds)

build_spec2017:
	cd spec2017 && source shrc && cd config && \
	runcpu --config=wasm_lucet.cfg --action=clobber --define cores=1 osdi && \
	runcpu --config=wasm_loadlfence.cfg --action=clobber --define cores=1 osdi && \
        runcpu --config=wasm_strawman.cfg --action=clobber --define cores=1 osdi && \
        runcpu --config=wasm_sfi.cfg --action=clobber --define cores=1 osdi && \
        runcpu --config=wasm_cet.cfg --action=clobber --define cores=1 osdi && \
        runcpu --config=wasm_sfi_noblade.cfg --action=clobber --define cores=1 osdi && \
        runcpu --config=wasm_cet_noblade.cfg --action=clobber --define cores=1 osdi && \
        runcpu --config=wasm_blade.cfg --action=clobber --define cores=1 osdi && \
	runcpu --config=wasm_lucet.cfg --action=build --define cores=1 osdi && \
	runcpu --config=wasm_loadlfence.cfg --action=build --define cores=1 osdi && \
        runcpu --config=wasm_strawman.cfg --action=build --define cores=1 osdi && \
        runcpu --config=wasm_sfi.cfg --action=build --define cores=1 osdi && \
        runcpu --config=wasm_cet.cfg --action=build --define cores=1 osdi && \
        runcpu --config=wasm_sfi_noblade.cfg --action=build --define cores=1 osdi && \
        runcpu --config=wasm_cet_noblade.cfg --action=build --define cores=1 osdi && \
        runcpu --config=wasm_blade.cfg --action=build --define cores=1 osdi


run_spec2017: build_spec2017
	cd spec2017 && source shrc && cd config && \
	runcpu --config=wasm_lucet.cfg --action=run --wasm --iterations=1 --noreportable --define cores=1 osdi && \
	runcpu --config=wasm_loadlfence.cfg --action=run --wasm --iterations=1 --noreportable --define cores=1 osdi && \
	runcpu --config=wasm_strawman.cfg --action=run --wasm --iterations=1 --noreportable --define cores=1 osdi && \
	runcpu --config=wasm_sfi.cfg --action=run --wasm --iterations=1 --noreportable --define cores=1 osdi && \
	runcpu --config=wasm_cet.cfg --action=run --wasmcet --iterations=1 --noreportable --define cores=1 osdi && \
	runcpu --config=wasm_blade.cfg --action=run --wasm --iterations=1 --noreportable --define cores=1 osdi && \
	runcpu --config=wasm_sfi_noblade.cfg --action=run --wasm --iterations=1 --noreportable --define cores=1 osdi && \
	runcpu --config=wasm_cet_noblade.cfg --action=run --wasmcet --iterations=1 --noreportable --define cores=1 osdi

run_spec_all: run_spec run_spec2017

out/rust_build/bin/rustc:
	mkdir -p out/rust_build
	cd ./rustc-cet && ./x.py build && ./x.py install
	rustup toolchain link rust-cet ./out/rust_build

build_lucet_nocet:
	cd lucet-spectre && cargo build
	cd lucet-spectre && cargo build --release

build_lucet: out/rust_build/bin/rustc build_lucet_nocet
	cd lucet-spectre && \
		CFLAGS="-fcf-protection=full" \
		CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER="$(CURR_DIR)/rustc-cet/rust_cet_linker" \
		CARGO_TARGET_DIR="${CURR_DIR}/lucet-spectre/target-cet" \
		cargo +rust-cet build
	cd lucet-spectre && \
		CFLAGS="-fcf-protection=full" \
		CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER="$(CURR_DIR)/rustc-cet/rust_cet_linker" \
		CARGO_TARGET_DIR="${CURR_DIR}/lucet-spectre/target-cet" \
		cargo +rust-cet build --release

build: install_deps build_lucet
	mkdir -p ./out
	# $(MAKE) -C rlbox_lucet_spectre_sandbox/build
	REALLY_USE_CET=1 $(MAKE) -C sfi-spectre-testing build -j8

build_nocet: install_deps
	mkdir -p ./out
	cd lucet-spectre && cargo build
	cp -r lucet-spectre/target lucet-spectre/target-cet
	# $(MAKE) -C rlbox_lucet_spectre_sandbox/build
	$(MAKE) -C sfi-spectre-testing build -j8

test:
	# $(MAKE) -C rlbox_lucet_spectre_sandbox/build check
	REALLY_USE_CET=1 $(MAKE) -C sfi-spectre-testing test

test_nocet:
	# $(MAKE) -C rlbox_lucet_spectre_sandbox/build check
	$(MAKE) -C sfi-spectre-testing test

build_sightglass: install_deps build_lucet
	$(MAKE) -C lucet-spectre/benchmarks/shootout clean
	REALLY_USE_CET=1 $(MAKE) -C lucet-spectre/benchmarks/shootout build -j8

run_sightglass:
	if [ -x "$(shell command -v cpupower)" ]; then \
		sudo cpupower -c $(LAST_CPU_CORE) frequency-set --min 2700MHz --max 2700MHz; \
	else \
		sudo cpufreq-set -c $(LAST_CPU_CORE) --min 2700MHz --max 2700MHz; \
	fi
	REALLY_USE_CET=1 $(MAKE) -C lucet-spectre/benchmarks/shootout run

build_sightglass_nocet: install_deps build_lucet_nocet
	$(MAKE) -C lucet-spectre/benchmarks/shootout clean
	$(MAKE) -C lucet-spectre/benchmarks/shootout build -j8

run_sightglass_nocet:
	if [ -x "$(shell command -v cpupower)" ]; then \
		sudo cpupower -c $(LAST_CPU_CORE) frequency-set --min 2700MHz --max 2700MHz; \
	else \
		sudo cpufreq-set -c $(LAST_CPU_CORE) --min 2700MHz --max 2700MHz; \
	fi
	$(MAKE) -C lucet-spectre/benchmarks/shootout run

build_transitions_benchmark:
	$(MAKE) -C sfi-spectre-testing build_transitions -j8

run_transitions_benchmark: install_btbflush
	$(MAKE) -C sfi-spectre-testing run_transitions

build_cdn_benchmark: wasm_compartments node_modules build_lucet out/rust_build/bin/rustc
	cd ./wasm_compartments && cargo build --release
	cd ./wasm_compartments && \
		CFLAGS="-fcf-protection=full" \
		CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER="$(CURR_DIR)/rustc-cet/rust_cet_linker" \
		CARGO_TARGET_DIR="${CURR_DIR}/wasm_compartments/target-cet" \
		cargo +rust-cet build --release
	cd ./wasm_compartments && make modules -j8

build_cdn_benchmark_nocet: wasm_compartments node_modules build_lucet_nocet
	cd ./wasm_compartments && cargo build --release
	cd ./wasm_compartments && make modules -j8

run_cdn_benchmark_server:
	cd ./wasm_compartments && \
	CARGO_TARGET_DIR="${CURR_DIR}/wasm_compartments/target-cet"
	./wasm_compartments/target-cet/release/server

run_cdn_benchmark_server_nocet:
	./wasm_compartments/target/release/server

run_cdn_benchmark_client:
	./wasm_compartments/spectre_testfib.sh fib_c_spectre_cet
	./wasm_compartments/spectre_testfib.sh fib_c_spectre_cet_no_cross_sbx
	@echo "CET Server tests passed"
	cd ./wasm_compartments && node request_spectre_test.js --cet
	mkdir -p ./benchmarks/current_macro_cet
	mv ./wasm_compartments/results.json ./benchmarks/current_macro_cet/cet_results.json
	mv ./benchmarks/current_macro_cet ./benchmarks/macro_cet_$(shell date --iso=seconds)

run_cdn_benchmark_client_nocet:
	./wasm_compartments/spectre_testfib.sh fib_c_stock
	./wasm_compartments/spectre_testfib.sh fib_c_spectre_sfi
	./wasm_compartments/spectre_testfib.sh fib_c_spectre_sfi_no_cross_sbx
	@echo "Server tests passed"
	cd ./wasm_compartments && node request_spectre_test.js --nocet
	mkdir -p ./benchmarks/current_macro_nocet
	mv ./wasm_compartments/results.json ./benchmarks/current_macro_nocet/nocet_results.json
	mv ./benchmarks/current_macro_nocet ./benchmarks/macro_nocet_$(shell date --iso=seconds)

clean:
	-cd lucet-spectre && cargo clean
	-$(MAKE) -C sfi-spectre-testing clean
