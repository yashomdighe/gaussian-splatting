#!/bin/zsh

# Define the range of indices
start=0
end=99

# Define maximum parallel processes
<<<<<<< HEAD
max_parallel=8
=======
max_parallel=12
>>>>>>> 5ed2cb59918add4e020a69f06902ee2107f4c110
current_processes=0

# Declare an array to store the pool of ports
port_pool=()

# Populate the port pool with unique ports
generate_port_pool() {
    for ((i = 1; i <= max_parallel; i++)); do
        while true; do
            port=$((RANDOM % 9000 + 1000))  # Generate a random 4-digit port
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
<<<<<<< HEAD
    for j in {10..100..10}; do
        o_path="/home/yashom/Developer/datasets/gaussian-splatting/slide_block_to_target/variation_0/episode_$i/$j/splat"
        i_path="/home/yashom/Developer/datasets/gaussian-splatting/slide_block_to_target/variation_0/episode_$i/$j"

        # Wait for a process slot to free up
        wait_for_process_slot

        # Get the next available port
        port=$(get_next_port)

        # Generate a unique log file for this process
        log_file="logs/episode_${i}_step_${j}_port_${port}.log"
        temp_log=$(mktemp)  # Create a temporary log file

        # Ensure the logs directory exists
        mkdir -p logs

        # Call the Python script and capture its output in the temporary file
        echo "Processing $i_path with port $port. Logs will be written to $log_file after completion."
        sudo rm -rf $o_path
        (python3 train.py -s "$i_path" -m "$o_path" --port "$port" --iterations 7000 >"$temp_log" 2>&1 && mv "$temp_log" "$log_file") &

        # Track the process ID and associate it with the port
        pid=$!
        pids+=($pid)
        used_ports[$port]=$pid

        # Sleep for boot-up time
        # sleep 5
    done
=======
    episode_dir="/home/ydighe/Developer/datasets/gaussian-splatting/slide_block_to_target/variation_0/episode_$i"

    # Check if the directory exists
    if [[ ! -d "$episode_dir" ]]; then
        echo "Skipping non-existent directory: $episode_dir"
        continue
    fi

    # Get the list of subdirectories dynamically and find the last one
    subdirs=($(find "$episode_dir" -mindepth 1 -maxdepth 1 -type d | sort -V))
    last_subdir=${subdirs[-1]}  # Get the numerically last subdirectory

    # Skip if no subdirectories are found
    if [[ -z "$last_subdir" ]]; then
        echo "No subdirectories found in: $episode_dir"
        continue
    fi
    # echo $last_subdir
    o_path="$last_subdir/splat"
    # echo $o_path
    # # Add the outer path and its last subdirectory to the JSON file
    # echo "  \"$episode_dir\": [" >> $output_file
    # echo "    \"$last_subdir\"" >> $output_file
    # echo "  ]," >> $output_file

    # Wait for a process slot to free up
    wait_for_process_slot

    # Get the next available port
    port=$(get_next_port)

    # Generate a unique log file for this process
    log_file="logs/episode_${i}_last_port_${port}.log"
    # temp_log=$(mktemp)  # Create a temporary log file

    # Ensure the logs directory exists
    mkdir -p logs

    # Call the Python script and capture its output in the temporary file
    echo "Processing $last_subdir with port $port. Logs will be written to $log_file after completion."
    sudo rm -rf $o_path
    python3 train.py -s "$last_subdir" -m "$o_path" --port "$port" --iterations 7000 >"$log_file" 2>&1 &

    # Track the process ID and associate it with the port
    pid=$!
    pids+=($pid)
    used_ports[$port]=$pid

    # Sleep for boot-up time
    # sleep 5
>>>>>>> 5ed2cb59918add4e020a69f06902ee2107f4c110
done

# Wait for all remaining processes to finish
for pid in $pids; do
    wait "$pid"
done

echo "All episodes processed successfully!"
