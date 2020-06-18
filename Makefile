.NOTPARALLEL:
.PHONY : pull clean get_source \
build_sanity_test build_sanity_test_nocet \
run_sanity_test run_sanity_test_nocet \
build_rustc \
build_lucet build_lucet_nocet \
build_spec run_spec \
build_spec2017 run_spec2017 \
run_spec_all run_spec_combine_stats \
build_sightglass run_sightglass build_sightglass_nocet run_sightglass_nocet run_sightglass_pht_nocet \
build_transitions_benchmark run_transitions_benchmark \
build_macro_benchmark build_macro_benchmark_nocet \
run_macro_benchmark_server_sfischemes run_macro_benchmark_server_cetschemes \
run_macro_benchmark_client_sfischemes run_macro_benchmark_client_cetschemes \
build_firefox

.DEFAULT_GOAL := build

SHELL := /bin/bash

DIRS=rustc-cet rust_libloading_aslr lucet-spectre sfi-spectre-testing rlbox_spectre_sandboxing_api rlbox_lucet_spectre_sandbox btbflush-module spectresfi_webserver node_modules firefox-spectre wrk

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

rust_libloading_aslr:
	git clone git@github.com:PLSysSec/rust_libloading_aslr.git $@

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
		cd ./btbflush-module/module && make clean && make && make insert; \
	fi

spectresfi_webserver:
	git clone git@github.com:PLSysSec/sfispectre_webserver.git $@

node_modules:
	npm install autocannon

firefox-spectre:
	git clone git@github.com:PLSysSec/firefox-spectre.git $@

wrk:
	git clone git@github.com:wg/wrk
	cd wrk && $(MAKE) -j8

get_source: $(DIRS)

install_deps: $(DIRS)
	touch ./install_deps;

pull: $(DIRS)
	git pull
	cd rlbox_spectre_sandboxing_api && git pull
	cd rust_libloading_aslr && git pull
	cd rlbox_lucet_spectre_sandbox && git pull --recurse-submodules
	cd lucet-spectre && git pull --recurse-submodules
	cd sfi-spectre-testing && git pull --recurse-submodules
	cd btbflush-module && git pull
	cd spectresfi_webserver && git pull
	cd firefox-spectre && git pull
	cd rustc-cet && git pull --recurse-submodules
	cd sfi-spectre-spec && git pull

libnsl:
	git clone https://github.com/thkukuk/libnsl

libnsl/build/lib/libnsl.so: libnsl
	cd ./libnsl && \
	autoreconf -fi && \
	./configure --prefix "$(CURR_DIR)/libnsl/build" && \
	make -j8 all && \
	make install

libnsl/build/lib/libnsl.so.1: libnsl/build/lib/libnsl.so
	cp $< $@

sfi-spectre-spec: libnsl/build/lib/libnsl.so.1
	git clone git@github.com:PLSysSec/sfi-spectre-spec.git
	cd sfi-spectre-spec && LD_LIBRARY_PATH="$(CURR_DIR)/libnsl/build/lib/" SPEC_INSTALL_NOCHECK=1 SPEC_FORCE_INSTALL=1 sh install.sh -f

BASELINE_BUILDS=wasm_loadlfence wasm_strawman wasm_blade wasm_interlock wasm_phttobtb
OUR_SFI_BUILDS=wasm_lucet wasm_lucet_unroll wasm_sfi_full
SFI_BUILDS=$(BASELINE_BUILDS) $(OUR_SFI_BUILDS)
CET_BUILDS=wasm_cet_full
SFI_ASLR_BUILDS=wasm_sfi_aslr
CET_ASLR_BUILDS=wasm_cet_aslr
SPEC_BUILDS=$(SFI_BUILDS) $(CET_BUILDS) $(SFI_ASLR_BUILDS) $(CET_ASLR_BUILDS)
SPEC_BUILD_COUNT := $(shell echo "$(SPEC_BUILDS)" | wc -w)

build_spec: sfi-spectre-spec build_lucet_nocet
	export LD_LIBRARY_PATH="$(CURR_DIR)/libnsl/build/lib/" && \
	cd sfi-spectre-spec && source shrc && \
	cd config && \
	echo "Cleaning dirs" && \
	for spec_build in $(SPEC_BUILDS); do \
		runspec --config=$$spec_build.cfg --action=clobber oakland 2&>1 > /dev/null; \
	done && \
	for spec_build in $(SPEC_BUILDS); do \
		echo "Building $$spec_build" && runspec --config=$$spec_build.cfg --action=build oakland 2>&1 | grep "Build "; \
	done

run_spec: install_btbflush
	export LD_LIBRARY_PATH="$(CURR_DIR)/libnsl/build/lib/" && \
	sh cp_spec_data_into_tmp.sh && \
	cd sfi-spectre-spec && source shrc && cd config && \
	for spec_build in $(SFI_BUILDS); do \
		runspec --config=$$spec_build.cfg --iterations=1 --noreportable --size=ref --wasm oakland; \
	done && \
	for spec_build in $(CET_BUILDS); do \
		runspec --config=$$spec_build.cfg --iterations=1 --noreportable --size=ref --wasmcet oakland; \
	done && \
	for spec_build in $(SFI_ASLR_BUILDS); do \
		runspec --config=$$spec_build.cfg --iterations=1 --noreportable --size=ref --wasmaslr oakland; \
	done && \
	for spec_build in $(CET_ASLR_BUILDS); do \
		runspec --config=$$spec_build.cfg --iterations=1 --noreportable --size=ref --wasmcetaslr oakland; \
	done
	# Baseline
	python3 sfi-spectre-testing/scripts/spec_stats.py -i sfi-spectre-spec/result --filter  \
		"sfi-spectre-spec/result/spec_results_baseline=LoadLfence:LoadLfence,Strawman:Strawman,Blade:Blade" -n $(SPEC_BUILD_COUNT)
	# Ours
	python3 sfi-spectre-testing/scripts/spec_stats.py -i sfi-spectre-spec/result --usePercent --filter \
		"sfi-spectre-spec/result/spec_results_ours=Stock_Unrolled:Stock_Unrolled,Sfi_Aslr:Sfi_Aslr,Cet_Aslr:Cet_Aslr,Sfi_Full:Sfi_Full,Cet_Full:Cet_Full" -n $(SPEC_BUILD_COUNT)
	# Ours --- just the expensive parts
	python3 sfi-spectre-testing/scripts/spec_stats.py -i sfi-spectre-spec/result --usePercent --filter \
		"sfi-spectre-spec/result/spec_results_ours_expensive=PhtToBtb:PhtToBtb,Interlock:Interlock" -n $(SPEC_BUILD_COUNT)
	mv sfi-spectre-spec/result/ benchmarks/spec_$(shell date --iso=seconds)

run_spec_ours: install_btbflush
	export LD_LIBRARY_PATH="$(CURR_DIR)/libnsl/build/lib/" && \
	sh cp_spec_data_into_tmp.sh && \
	cd sfi-spectre-spec && source shrc && cd config && \
	for spec_build in $(OUR_SFI_BUILDS); do \
		runspec --config=$$spec_build.cfg --iterations=1 --noreportable --size=ref --wasm oakland; \
	done && \
	for spec_build in $(CET_BUILDS); do \
		runspec --config=$$spec_build.cfg --iterations=1 --noreportable --size=ref --wasmcet oakland; \
	done && \
	for spec_build in $(SFI_ASLR_BUILDS); do \
		runspec --config=$$spec_build.cfg --iterations=1 --noreportable --size=ref --wasmaslr oakland; \
	done && \
	for spec_build in $(CET_ASLR_BUILDS); do \
		runspec --config=$$spec_build.cfg --iterations=1 --noreportable --size=ref --wasmcetaslr oakland; \
	done
	# Ours
	python3 sfi-spectre-testing/scripts/spec_stats.py -i sfi-spectre-spec/result --usePercent --filter \
		"sfi-spectre-spec/result/spec_results_ours=Stock_Unrolled:Stock_Unrolled,Sfi_Aslr:Sfi_Aslr,Cet_Aslr:Cet_Aslr,Sfi_Full:Sfi_Full,Cet_Full:Cet_Full" -n $(SPEC_BUILD_COUNT)
	mv sfi-spectre-spec/result/ benchmarks/spec_$(shell date --iso=seconds)

run_spec_sfi: install_btbflush
	export LD_LIBRARY_PATH="$(CURR_DIR)/libnsl/build/lib/" && \
	sh cp_spec_data_into_tmp.sh && \
	cd sfi-spectre-spec && source shrc && cd config && \
	runspec --config=wasm_sfi_full.cfg --iterations=1 --noreportable --size=ref --wasm oakland && \
	for spec_build in $(SFI_ASLR_BUILDS); do \
		runspec --config=$$spec_build.cfg --iterations=1 --noreportable --size=ref --wasmaslr oakland; \
	done
	mv sfi-spectre-spec/result/ benchmarks/spec_sfi_$(shell date --iso=seconds)

build_spec2017: build_lucet_nocet
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


run_spec2017: build_spec2017 install_btbflush
	cd spec2017 && source shrc && cd config && \
	runcpu --config=wasm_lucet.cfg --action=run --wasm --iterations=1 --noreportable --define cores=1 osdi && \
	runcpu --config=wasm_loadlfence.cfg --action=run --wasm --iterations=1 --noreportable --define cores=1 osdi && \
	runcpu --config=wasm_strawman.cfg --action=run --wasm --iterations=1 --noreportable --define cores=1 osdi && \
	runcpu --config=wasm_sfi.cfg --action=run --wasm --iterations=1 --noreportable --define cores=1 osdi && \
	runcpu --config=wasm_cet.cfg --action=run --wasmcet --iterations=1 --noreportable --define cores=1 osdi && \
	runcpu --config=wasm_sfi_noblade.cfg --action=run --wasm --iterations=1 --noreportable --define cores=1 osdi && \
	runcpu --config=wasm_cet_noblade.cfg --action=run --wasmcet --iterations=1 --noreportable --define cores=1 osdi
	python3 sfi-spectre-testing/scripts/spec_stats.py --spec2017 -i spec2017/result --filter  "spec2017/result/spec_results=wasm_loadlfence:loadlfence,wasm_strawman:strawman,wasm_sfi:sfi,wasm_cet:cet" -n 7
	python3 sfi-spectre-testing/scripts/spec_stats.py --spec2017 -i spec2017/result --usePercent --filter "spec2017/result/spec_results_sbx_only=wasm_sfi_noblade:sfi_noblade,wasm_cet_noblade:cet_noblade" -n 7
	mv spec2017/result/ benchmarks/spec17_$(shell date --iso=seconds)

run_spec_all: run_spec run_spec2017

run_spec_combine_stats:
	echo "Spec2006 path?: "; \
	read SPEC06_PATH; \
	echo "Spec2017 path?: "; \
	read SPEC17_PATH; \
	mkdir -p ./benchmarks/speccombined_current; \
	python3 ./sfi-spectre-testing/scripts/spec_stats.py -i "$$SPEC06_PATH" --extraSpec2017Path "$$SPEC17_PATH" --extraSpec2017n 7  --filter "./benchmarks/speccombined_current/speccombined=wasm_loadlfence:loadlfence,wasm_strawman:strawman,wasm_sfi:sfi,wasm_cet:cet" -n 7; \
	python3 ./sfi-spectre-testing/scripts/spec_stats.py -i "$$SPEC06_PATH" --usePercent --extraSpec2017Path "$$SPEC17_PATH" --extraSpec2017n 7  --filter "./benchmarks/speccombined_current/speccombined_noblade=wasm_sfi_noblade:sfi_noblade,wasm_cet_noblade:cet_noblade" -n 7; \
	mv benchmarks/speccombined_current/ benchmarks/speccombined_$(shell date --iso=seconds)

out/rust_build/bin/rustc:
	mkdir -p out/rust_build
	cd ./rustc-cet && ./x.py build && ./x.py install
	rustup toolchain link rust-cet ./out/rust_build

build_rustc:
	# force rebuild
	mkdir -p out/rust_build
	cd ./rustc-cet && ./x.py build && ./x.py install
	rustup toolchain link rust-cet ./out/rust_build

build_lucet_nocet: rust_libloading_aslr
	cd lucet-spectre && cargo build
	cd lucet-spectre && cargo build --release

build_lucet: out/rust_build/bin/rustc build_lucet_nocet
	cd lucet-spectre && \
		CFLAGS="-fcf-protection=full" \
		CXXFLAGS="-fcf-protection=full" \
		CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER="$(CURR_DIR)/rustc-cet/rust_cet_linker" \
		CARGO_TARGET_DIR="${CURR_DIR}/lucet-spectre/target-cet" \
		cargo +rust-cet build
	cd lucet-spectre && \
		CFLAGS="-fcf-protection=full" \
		CXXFLAGS="-fcf-protection=full" \
		CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER="$(CURR_DIR)/rustc-cet/rust_cet_linker" \
		CARGO_TARGET_DIR="${CURR_DIR}/lucet-spectre/target-cet" \
		cargo +rust-cet build --release

build_sanity_test: install_deps build_lucet
	mkdir -p ./out
	# $(MAKE) -C rlbox_lucet_spectre_sandbox/build
	REALLY_USE_CET=1 $(MAKE) -C sfi-spectre-testing build -j8

build_sanity_test_nocet: install_deps
	mkdir -p ./out
	cd lucet-spectre && cargo build
	cp -r lucet-spectre/target lucet-spectre/target-cet
	# $(MAKE) -C rlbox_lucet_spectre_sandbox/build
	$(MAKE) -C sfi-spectre-testing build -j8

run_sanity_test:
	# $(MAKE) -C rlbox_lucet_spectre_sandbox/build check
	REALLY_USE_CET=1 $(MAKE) -C sfi-spectre-testing test

run_sanity_test_nocet:
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

run_sightglass_pht_nocet:
	if [ -x "$(shell command -v cpupower)" ]; then \
		sudo cpupower -c $(LAST_CPU_CORE) frequency-set --min 2700MHz --max 2700MHz; \
	else \
		sudo cpufreq-set -c $(LAST_CPU_CORE) --min 2700MHz --max 2700MHz; \
	fi
	$(MAKE) -C lucet-spectre/benchmarks/shootout run_pht

build_transitions_benchmark:
	$(MAKE) -C sfi-spectre-testing build_transitions -j8

run_transitions_benchmark: install_btbflush
	$(MAKE) -C sfi-spectre-testing run_transitions

build_macro_benchmark: spectresfi_webserver node_modules build_lucet out/rust_build/bin/rustc
	cd ./spectresfi_webserver && cargo build --release
	cd ./spectresfi_webserver && \
		CFLAGS="-fcf-protection=full" \
		CXXFLAGS="-fcf-protection=full" \
		CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER="$(CURR_DIR)/rustc-cet/rust_cet_linker" \
		CARGO_TARGET_DIR="${CURR_DIR}/spectresfi_webserver/target-cet" \
		cargo +rust-cet build --release
	cd ./spectresfi_webserver/modules && make clean
	cd ./spectresfi_webserver/modules && make -j8

build_macro_benchmark_nocet: spectresfi_webserver node_modules build_lucet_nocet
	cd ./spectresfi_webserver && cargo build --release
	cd ./spectresfi_webserver/modules && make clean
	cd ./spectresfi_webserver/modules && make -j8

run_macro_benchmark_server_cetschemes:
	./spectresfi_webserver/target-cet/release/spectresfi_webserver

run_macro_benchmark_server_sfischemes: install_btbflush
	./spectresfi_webserver/target/release/spectresfi_webserver

run_macro_benchmark_client_cetschemes:
	./spectresfi_webserver/spectre_testfib.sh spectre_cet_aslr
	./spectresfi_webserver/spectre_testfib.sh spectre_cet_full
	@echo "CET Server tests passed"
	cd ./spectresfi_webserver && node request_spectre_test.js --cet
	mkdir -p ./benchmarks/current_macro_cetschemes
	mv ./spectresfi_webserver/results.json ./benchmarks/current_macro_cetschemes/cet_results.json
	python3 ./spectresfi_webserver/autocanon_analysis.py -file ./benchmarks/current_macro_cetschemes/cet_results.json 2>&1 > ./benchmarks/current_macro_cetschemes/cet_results.tex
	mv ./benchmarks/current_macro_cetschemes ./benchmarks/macro_cetschemes_$(shell date --iso=seconds)

run_macro_benchmark_client_sfischemes:
	./spectresfi_webserver/spectre_testfib.sh stock
	./spectresfi_webserver/spectre_testfib.sh spectre_sfi_aslr
	./spectresfi_webserver/spectre_testfib.sh spectre_sfi_full
	@echo "Server tests passed"
	cd ./spectresfi_webserver && node request_spectre_test.js --nocet
	mkdir -p ./benchmarks/current_macro_sfischemes
	mv ./spectresfi_webserver/results.json ./benchmarks/current_macro_sfischemes/nocet_results.json
	python3 ./spectresfi_webserver/autocanon_analysis.py -file ./benchmarks/current_macro_sfischemes/nocet_results.json 2>&1 > ./benchmarks/current_macro_sfischemes/nocet_results.tex
	mv ./benchmarks/current_macro_sfischemes ./benchmarks/macro_sfischemes_$(shell date --iso=seconds)

run_macrobenchmark_wrk_client_sfischemes:
	./spectresfi_webserver/spectre_testfib.sh stock
	./spectresfi_webserver/spectre_testfib.sh spectre_sfi_aslr
	./spectresfi_webserver/spectre_testfib.sh spectre_sfi_full
	@echo "Server tests passed"
	rm -rf ./spectresfi_webserver/wrk_scripts/results
	cd ./spectresfi_webserver/wrk_scripts && ./runall.sh sfi
	mkdir -p ./benchmarks/current_macro_sfischemes_wrk
	cp ./spectresfi_webserver/wrk_scripts/results/* ./benchmarks/current_macro_sfischemes_wrk

run_macrobenchmark_wrk_client_cetschemes:
	./spectresfi_webserver/spectre_testfib.sh stock
	./spectresfi_webserver/spectre_testfib.sh spectre_cet_aslr
	./spectresfi_webserver/spectre_testfib.sh spectre_cet_full
	@echo "Server tests passed"
	rm -rf ./spectresfi_webserver/wrk_scripts/results
	cd ./spectresfi_webserver/wrk_scripts && ./runall.sh cet
	mkdir -p ./benchmarks/current_macro_cetschemes_wrk
	cp ./spectresfi_webserver/wrk_scripts/results/* ./benchmarks/current_macro_cetschemes_wrk

benchmarks/wrk_table.tex: ./benchmarks/current_macro_sfischemes_wrk ./benchmarks/current_macro_cetschemes_wrk
	python3 ./spectresfi_webserver/wrk_analysis.py -folders ./benchmarks/current_macro_sfischemes_wrk ./benchmarks/current_macro_cetschemes_wrk > $@

build_firefox: build_lucet_nocet
	$(MAKE) -C ./firefox-spectre/builds build

clean:
	-cd lucet-spectre && cargo clean
	-$(MAKE) -C sfi-spectre-testing clean
