#!/bin/bash

rm quectel_connection.log
sudo apt-get install -y libmbim-utils

# Environment variables for network configuration
INTERFACE=${INTERFACE:-wwan0}
DNN0=oai
#DNN1=ims
DNN_TYPE0=${DNN_TYPE0:-ipv4}
#DNN_TYPE1=${DNN_TYPE1:-ipv4v6}
DEVICE=/dev/cdc-wdm*
LOG_FILE="quectel_connection.log"  # Path to the log file

# Function to check if network interface exists
check_interface() {
    if ip link show $INTERFACE &> /dev/null; then
        echo "$(date +'%Y-%m-%d %H:%M:%S') - Network interface $INTERFACE already exists. Skipping setup..." >> "$LOG_FILE"
        return 1
    else
        echo "$(date +'%Y-%m-%d %H:%M:%S') - Network interface $INTERFACE does not exist." >> "$LOG_FILE"
        return 0
    fi
}


# Function to set up network sessions
setup_network() {
    if ! check_interface; then
        echo "$(date +'%Y-%m-%d %H:%M:%S') - Setting up $INTERFACE for testing..." >> "$LOG_FILE"
        ip link set $INTERFACE up >> "$LOG_FILE" 2>&1

        echo "$(date +'%Y-%m-%d %H:%M:%S') - mbimcli -p -d ${DEVICE} --set-radio-state=on" >> "$LOG_FILE"
        mbimcli -p -d $DEVICE --set-radio-state=on >> "$LOG_FILE" 2>&1
        sleep 2
        echo "$(date +'%Y-%m-%d %H:%M:%S') - mbimcli -p -d ${DEVICE} --attach-packet-service" >> "$LOG_FILE"
        mbimcli -p -d $DEVICE --attach-packet-service >> "$LOG_FILE" 2>&1
        echo "$(date +'%Y-%m-%d %H:%M:%S') - mbimcli -p -d ${DEVICE} --connect=session-id=0,apn=${DNN0},ip-type=${DNN_TYPE0}" >> "$LOG_FILE"
        mbimcli -p -d $DEVICE --connect=session-id=0,apn=$DNN0,ip-type=$DNN_TYPE0 >> "$LOG_FILE" 2>&1
        echo "$(date +'%Y-%m-%d %H:%M:%S') - ./mbim-set-ip.sh ${DEVICE} ${INTERFACE} 0" >> "$LOG_FILE"
        ./mbim-set-ip.sh $DEVICE $INTERFACE 0 >> "$LOG_FILE" 2>&1

        if [[ -v DNN1 ]]; then
            echo "$(date +'%Y-%m-%d %H:%M:%S') - ip link add link wwan0 name ${INTERFACE}.1 type vlan id 1" >> "$LOG_FILE"
            ip link add link wwan0 name $INTERFACE.1 type vlan id 1 >> "$LOG_FILE" 2>&1
            echo "$(date +'%Y-%m-%d %H:%M:%S') - ip link set ${INTERFACE}.1 up" >> "$LOG_FILE"
            ip link set $INTERFACE.1 up >> "$LOG_FILE" 2>&1
            echo "$(date +'%Y-%m-%d %H:%M:%S') - mbimcli -p -d ${DEVICE} --connect=session-id=1,apn=${DNN1},ip-type=${DNN_TYPE1}" >> "$LOG_FILE"
            mbimcli -p -d $DEVICE --connect=session-id=1,apn=$DNN1,ip-type=$DNN_TYPE1 >> "$LOG_FILE" 2>&1
            echo "$(date +'%Y-%m-%d %H:%M:%S') - ./mbim-set-ip.sh ${DEVICE} ${INTERFACE}.1 1" >> "$LOG_FILE"
            ./mbim-set-ip.sh $DEVICE $INTERFACE.1 1 >> "$LOG_FILE" 2>&1
        fi
    fi
}

# Function to perform internet connectivity check
check_internet() {
    while true; do
        if ping -I ${INTERFACE} -c 1 8.8.8.8 >/dev/null 2>&1; then
            echo "$(date +'%Y-%m-%d %H:%M:%S') - Internet connection is up" >> "$LOG_FILE"
        else
            echo "$(date +'%Y-%m-%d %H:%M:%S') - Internet connection is down. Executing network teardown..." >> "$LOG_FILE"
            teardown_network
            echo "$(date +'%Y-%m-%d %H:%M:%S') - Restarting network services..." >> "$LOG_FILE"
            setup_network
        fi
        sleep 10  # Check every 10 sec, adjust as needed
    done
}

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

# Main script execution starts here
if [ "$1" != "background" ]; then
    echo "Starting script in background..."
    setsid "$0" background "$@" </dev/null &>/dev/null &
    exit 0
fi

# If we're here, we're running in the background
setup_network
check_internet
