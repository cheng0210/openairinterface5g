#!/bin/bash

sh ./restart_open5gs.sh

sleep 10s

cd cmake_targets/ran_build/build
#sudo ./nr-softmodem -O ../../../targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb.sa.band78.fr1.106PRB.usrpb210.conf --gNBs.[0].min_rxtxtime 6 --rfsim --sa --telnetsrv
#sudo -E XDG_RUNTIME_DIR=/tmp/runtime-root gdb --args ./nr-softmodem -O ../../../targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb.sa.band78.fr1.106PRB.usrpb210.conf --gNBs.[0].min_rxtxtime 6 --rfsim --sa --dqt
#sudo ./nr-softmodem -O /home/oai/openairinterface5g/ci-scripts/conf_files/gnb.sa.band78.106prb.rfsim.2x2.conf --gNBs.[0].min_rxtxtime 6 --rfsim --sa
#sudo ./nr-softmodem -O ../../../targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb.sa.band41.fr1.106PRB.usrpb210.conf --sa -E --continuous-tx
#sudo -E XDG_RUNTIME_DIR=/run/user/0 ./nr-softmodem -O ../../../targets/PROJECTS/GENERIC-NR-5GC/CONF/test.conf --sa -E --continuous-tx --gNBs.[0].min_rxtxtime 6 --dqt
sudo ./nr-softmodem -O ../../../targets/PROJECTS/GENERIC-NR-5GC/CONF/band41_test_open5gs.conf --sa -E --continuous-tx --gNBs.[0].min_rxtxtime 6
