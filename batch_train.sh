#!/bin/zsh

# Define the range of indices
start=10
end=20


# Define maximum parallel processes
max_parallel=5
current_processes=0

# Loop through the indices
for i in {$start..$end}; do
    # Construct the path

    for j in {10..100..10}; do
        i_path="/home/ydighe/Developer/datasets/gaussian-splatting/slide_block_to_target/variation_0/episode_$i/$j"
        o_path="/home/ydighe/Developer/datasets/gaussian-splatting/slide_block_to_target/variation_0/episode_$i/$j/splat"

        # Call the Python script with the constructed path as an argument
        echo "Processing $i_path..."
        sudo rm -rf $o_path
        python train.py -s "$i_path" -m "$o_path"

        # Wait for the Python script to complete
        if [[ $? -ne 0 ]]; then
            echo "Error occurred while processing $path. Exiting."
            exit 1
        fi
    done
done

echo "All episodes processed successfully!"

