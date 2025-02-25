#!/bin/zsh

# Define the range of outer paths (episodes)
start=10
end=20

# Define the fixed inner path range
inner_start=10
inner_end=100
inner_step=10

# JSON output file
output_file="paths.json"

# Initialize JSON structure
echo "{" > $output_file

# Main processing loop
for i in {$start..$end}; do
    outer_path="/home/ydighe/Developer/datasets/gaussian-splatting/slide_block_to_target/variation_0/episode_$i"

    # Add the outer path (episode) to JSON
    echo "  \"$outer_path\": [" >> $output_file

    # Inner loop through fixed inner paths
    for j in {$inner_start..$inner_end..$inner_step}; do
        inner_path="$outer_path/$j"
        echo "    \"$inner_path\"," >> $output_file
    done

    # Remove trailing comma and close the array for the current outer path
    sed -i '$ s/,$//' $output_file  # Remove the last comma in the list
    echo "  ]," >> $output_file
done

# Remove trailing comma and close the JSON object
sed -i '$ s/,$//' $output_file  # Remove the last comma at the end of the JSON object
echo "}" >> $output_file

# Print completion message
echo "Path structure saved to $output_file."
