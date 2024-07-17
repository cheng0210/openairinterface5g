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
