#!/bin/bash
cd cmake_targets/
rm -rf ran_build/
#./build_oai -I -w SIMU --ninja --nrUE --gNB  -C --build-e2 --build-lib telnetsrv
#./build_oai -w SIMU --ninja --nrUE --gNB -C --build-lib "telnetsrv" --build-lib "nrqtscope"
./build_oai -w USRP --ninja --gNB -C