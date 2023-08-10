#!/bin/bash

# Name of the output file
OUTPUT_FILE="output.txt"

# Assert that the current directory is writable (for our output file)
if [ ! -w "$PWD" ]; then
    echo "Error: The current directory is not writable." >&2
    exit 1
fi

# Clear the output file or create it if it doesn't exist
> "$OUTPUT_FILE"

# Find all '.sol' files and list contents of their directories
find . -type f -name "*.sol" -exec dirname {} \; | sort -u | while read -r dir; do
    # Check if the directory is readable
    if [ ! -r "$dir" ]; then
        echo "Warning: Cannot read directory '$dir'. Skipping." >&2
        continue
    fi

    # List contents of the directory and append to the output file
    find "$dir" -maxdepth 1 -type f >> "$OUTPUT_FILE"
done

echo "Script completed. Check '$OUTPUT_FILE' for the results."
