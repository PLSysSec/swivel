# SpectreSandboxing

This is the top level repo for the paper [Swivel: Hardening WebAssembly against Spectre](https://www.usenix.org/conference/usenixsecurity21/presentation/narayan) published at USENIX 2021
in which we demonstrate protecting Wasm code from Spectre attacks.

This repo will download and build all tools used in the paper, such as modified compilers, and benchmarks.

**Note** - this repo contains code used in our research prototypes. This is **not production ready**. 

## Build Instructions

**Requirements** - This repo has been tested on Ubuntu 20.04.2 LTS (recommended) and 64-bit Fedora 32 with the 5.7.0 Linux kernel.

**Note** - Do not use an existing machine. Use a fresh VM or machine.

To download all the dependencies of the repo, run

```bash
# Need make to run the scripts
sudo apt-get install make
# This installs required packages on the system.
# Only need to run once per system.
make bootstrap
# load the changes
source ~/.profile
```

To build the code, run

```bash
make build
```

Note that this builds several compilers (rust, several versions of lucet etc.)
so this will take a while.

## Software being built by this repo

**[rustc-cet](https://github.com/PLSysSec/rustc-cet.git)** - Our modified version of rust compiler that supports CET.

**[rust_libloading_aslr](https://github.com/PLSysSec/rust_libloading_aslr.git)** - A modified version of a rust package that allows us to customize library loading.

**[lucet-spectre](https://github.com/PLSysSec/lucet-spectre.git)** - Our modified and hardened version of lucet that provides compile flags that allow various Spectre hardenings.

**[lucet-spectre-repro](https://github.com/PLSysSec/lucet-spectre/tree/more-wasi-primitives)** - A modified version of lucet that simplifies our proof-of-concept demos showing Spectre vulnerabilities in Wasm. These modifications expose primitives like cache flushing or timer instructions. These are simply for the purpose of proof-of-concepts. In practice, these primitives are not necessary and can be effectively simulated purely in software.

**[sfi-spectre-testing](https://github.com/PLSysSec/sfi-spectre-testing.git)** - Our repo with several tests, benchmarks graphing scripts etc.

**[btbflush-module](https://github.com/PLSysSec/btbflush-module.git)** - A kernel module that allows userspace use of BTB flushing.

**[sfispectre_webserver](https://github.com/PLSysSec/sfispectre_webserver.git)** - Our macrobenchmark of Wasm web services that measures the overhead of using Swivel.

**[safeside](https://github.com/PLSysSec/safeside.git)** - Our modifications of safeside to show that Spectre proof-of-concepts of PHT and RSB work in Wasm also.

**[swivel-btb-exploit](https://github.com/PLSysSec/swivel-btb-exploit.git)** - Our hand written proof-of-concept that shows BTB Spectre attacks work in Wasm.

## Running benchmarks/proof-of-concepts

Make sure to first follow the steps to build all code by following the instructions above.

**Note** - proof of concepts exploits have been tested on baremetal Skylake 6700K. Use of VMs or other CPUs may introduce some britleness in the POCs.

The transitions micro benchmark can be run with the command

```bash
make run_transitions_benchmark
```

The sightglass benchmarks can be run with the command

```bash
make run_sightglass
```

Macro benchmark of Wasm web services are split into 2 parts: the machine learning benchmark, everything else.

To run the machine learning macro benchmark, run

```bash
make run_macro_benchmark_except_tflite
```

To run the remainder of macro benchmark

```bash
make run_macro_benchmark_tflite
```

To run each of the proof of concept exploits you can run the following commands

```bash
make run_pht_breakout_repro # Will print "Leaking the string: It's a s3kr3t!!!\nDone!"
make run_btb_poison_repro # Runs in gdb. Will print an infinite "SSS...".
make run_rsb_poison_repro # Will print "Leaking the string: It's a s3kr3t!!!\nDone!"
make run_btb_breakout_repro # Runs in gdb. 
```
