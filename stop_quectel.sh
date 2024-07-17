#!/bin/bash


process_name=run_quectel

# Get the list of PIDs for the given process name
pids=$(pgrep "$process_name")

# Check if any processes were found
if [ -z "$pids" ]; then
    echo "No processes found with name '$process_name'"
else
    # Iterate through each PID and kill the process
    for pid in $pids; do
        echo "Killing process $pid"
        kill $pid
    done
fi


# Environment variables for network configuration
INTERFACE=${INTERFACE:-wwan0}
DNN0=oai
#DNN1=ims
DNN_TYPE0=${DNN_TYPE0:-ipv4}
#DNN_TYPE1=${DNN_TYPE1:-ipv4v6}
DEVICE=/dev/cdc-wdm*

# Function to tear down network sessions
teardown_network() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - mbimcli -d ${DEVICE} -p --disconnect=0" 
    mbimcli -d $DEVICE -p --disconnect=0  2>&1
    if [[ -v DNN1 ]]; then
        echo "$(date +'%Y-%m-%d %H:%M:%S') - mbimcli -d ${DEVICE} -p --disconnect=1" 
        mbimcli -d $DEVICE -p --disconnect=1  2>&1
        echo "$(date +'%Y-%m-%d %H:%M:%S') - ip link set ${INTERFACE}.1 down" 
        ip link set $INTERFACE.1 down  2>&1
        echo "$(date +'%Y-%m-%d %H:%M:%S') - ip link del link wwan0 name ${INTERFACE}.1 type vlan id 1" 
        ip link del link wwan0 name $INTERFACE.1 type vlan id 1  2>&1
    fi
    echo "$(date +'%Y-%m-%d %H:%M:%S') - mbimcli -p -d ${DEVICE} --set-radio-state=off" 
    mbimcli -p -d $DEVICE --set-radio-state=off  2>&1

    echo "$(date +'%Y-%m-%d %H:%M:%S') - Removing the $INTERFACE" 
    ip link set $INTERFACE down  2>&1
}

teardown_network
echo "AT+CFUN=1,1" | socat - /dev/ttyUSB2,crnl
sleep 30
echo "Quectel Stopped"
