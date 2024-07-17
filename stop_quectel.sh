#!/bin/bash


process_name=run_quectel

# Get the list of PIDs for the given process name
pids=$(pgrep "$process_name")

# Check if any processes were found
if [ -z "$pids" ]; then
    echo "No processes found with name '$process_name'"
    exit 1
fi

# Iterate through each PID and kill the process
for pid in $pids; do
    echo "Killing process $pid"
    kill $pid
done

# Environment variables for network configuration
INTERFACE=${INTERFACE:-wwan0}
DNN0=oai
#DNN1=ims
DNN_TYPE0=${DNN_TYPE0:-ipv4}
#DNN_TYPE1=${DNN_TYPE1:-ipv4v6}
DEVICE=/dev/cdc-wdm*
LOG_FILE="quectel_connection.log"  # Path to the log file

# Function to tear down network sessions
teardown_network() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - mbimcli -d ${DEVICE} -p --disconnect=0" >> "$LOG_FILE"
    mbimcli -d $DEVICE -p --disconnect=0 >> "$LOG_FILE" 2>&1
    if [[ -v DNN1 ]]; then
        echo "$(date +'%Y-%m-%d %H:%M:%S') - mbimcli -d ${DEVICE} -p --disconnect=1" >> "$LOG_FILE"
        mbimcli -d $DEVICE -p --disconnect=1 >> "$LOG_FILE" 2>&1
        echo "$(date +'%Y-%m-%d %H:%M:%S') - ip link set ${INTERFACE}.1 down" >> "$LOG_FILE"
        ip link set $INTERFACE.1 down >> "$LOG_FILE" 2>&1
        echo "$(date +'%Y-%m-%d %H:%M:%S') - ip link del link wwan0 name ${INTERFACE}.1 type vlan id 1" >> "$LOG_FILE"
        ip link del link wwan0 name $INTERFACE.1 type vlan id 1 >> "$LOG_FILE" 2>&1
    fi
    echo "$(date +'%Y-%m-%d %H:%M:%S') - mbimcli -p -d ${DEVICE} --set-radio-state=off" >> "$LOG_FILE"
    mbimcli -p -d $DEVICE --set-radio-state=off >> "$LOG_FILE" 2>&1

    echo "$(date +'%Y-%m-%d %H:%M:%S') - Removing the $INTERFACE" >> "$LOG_FILE"
    ip link set $INTERFACE down >> "$LOG_FILE" 2>&1
}

teardown_network
