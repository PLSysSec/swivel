.NOTPARALLEL:
.PHONY : build

.DEFAULT_GOAL := build


init:
	git submodule update --init --recursive && \
	# git submodule foreach -q --recursive 'git checkout $$(git config -f $toplevel/.gitmodules submodule.$$name.branch || echo master)' && \
	cd lucet-spectre && git checkout master && cd .. && \
	cd lucet-spectre/cranelift && git checkout master && cd .. && \
	if [ ! -d /opt/wasi-sdk/ ]; then \
		wget https://github.com/CraneStation/wasi-sdk/releases/download/wasi-sdk-8/wasi-sdk_8.0_amd64.deb -P /tmp/ && \
		sudo dpkg -i /tmp/wasi-sdk_8.0_amd64.deb; \
	fi && \
	touch init

build: init
	cd lucet-spectre && cargo build
