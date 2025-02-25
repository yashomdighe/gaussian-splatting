#!/bin/zsh

# Define the range of episode indices
start=0
end=99

# Define maximum parallel processes
max_parallel=8
current_processes=0

# Declare an array to store the pool of ports
port_pool=()

# Populate the port pool with unique ports
generate_port_pool() {
    for ((i = 1; i <= max_parallel; i++)); do
        while true; do
            port=$((RANDOM % 64512 + 1024))  # Ports in the range 1024–65535
            if [[ ! " ${port_pool} " =~ " ${port} " ]]; then
                port_pool+=($port)  # Add unique port to the pool
                break
            fi
        done
    done
}

# Function to get the next available port
get_next_port() {
    for port in $port_pool; do
        # Check if the port is available
        if [[ -z ${used_ports[$port]} ]]; then
            used_ports[$port]=1  # Mark the port as used
            echo $port
            return
        fi
    done
}

# Function to release a port
release_port() {
    port=$1
    unset "used_ports[$port]"  # Mark the port as free
}

# Declare an associative array to track port usage
typeset -A used_ports

# Initialize the port pool
generate_port_pool

# Array to track process IDs
pids=()

# Function to wait for a process slot to free up
wait_for_process_slot() {
    while [[ ${#pids[@]} -ge $max_parallel ]]; do
        for pid in $pids; do
            if ! kill -0 "$pid" 2>/dev/null; then
                # Get the associated port and release it
                for port in ${(k)used_ports}; do
                    if [[ ${used_ports[$port]} -eq $pid ]]; then
                        release_port $port
                        break
                    fi
                done
                # Remove the finished process from the list
                pids=("${(@)pids:#$pid}")
            fi
        done
        sleep 1  # Avoid busy-waiting
    done
}

# Function to clean up all processes and exit
cleanup() {
    echo "Caught SIGINT! Cleaning up..."
    # Kill all background processes
    for pid in $pids; do
        kill -TERM "$pid" 2>/dev/null || true
    done
    wait  # Wait for all background processes to terminate
    echo "All processes terminated. Exiting."
    exit 1
}

# Trap SIGINT and SIGTERM
trap cleanup SIGINT SIGTERM

# Main processing loop
for i in {$start..$end}; do
    episode_dir="/home/ydighe/Developer/datasets/gaussian-splatting/slide_block_to_target/variation_0/episode_$i"

    # Get the list of subdirectories dynamically
    subdirs=($(find "$episode_dir" -mindepth 1 -maxdepth 1 -type d))

    for subdir in $subdirs; do
        o_path="$subdir/splat"
        # echo $subdir
        # echo $o_path

        # break
        # # Wait for a process slot to free up
        wait_for_process_slot

        # Get the next available port
        port=$(get_next_port)

        # Generate a unique log file for this process
        log_file="logs/episode_${i}_$(basename $subdir)_port_${port}.log"
        temp_log=$(mktemp)  # Create a temporary log file

        # Ensure the logs directory exists
        mkdir -p logs

        # Call the Python script and capture its output in the temporary file
        echo "Processing $subdir with port $port. Logs will be written to $log_file after completion."
        sudo rm -rf $o_path
        python3 train.py -s "$subdir" -m "$o_path" --port "$port" --iterations 7000 >"$log_file" 2>&1 &

        # Track the process ID and associate it with the port
        pid=$!
        pids+=($pid)
        used_ports[$port]=$pid

        # Sleep for boot-up time
        # sleep 5
    done
done

# Wait for all remaining processes to finish
for pid in $pids; do
    wait "$pid"
done

echo "All episodes processed successfully!"
