# SpectreSandboxing

This is the top level repo for the paper "" presented at USENIX 2021


This is the top level repo for the paper [Swivel: Hardening WebAssembly against Spectre](https://www.usenix.org/conference/usenixsecurity21/presentation/narayan) published at USENIX 2021
in which we demonstrate protecting Wasm code from Spectre attacks.

This repo will download and build all tools used in the paper, such as modified compilers, and benchmarks.

**Note** - this repo contains code used in our research prototypes. This is **not production ready**. 


# Build Instructions

**Requirements** - This repo has been tested on Ubuntu 20.04.2 LTS. 

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

More build instructions coming soon
