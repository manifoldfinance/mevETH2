#!/bin/bash

# Input file name
INPUT_FILE="output.txt"

# Get the current UNIX epoch timestamp
TIMESTAMP=$(date +%s)

# Output file name based on UNIX epoch timestamp
OUTPUT_FILE="${TIMESTAMP}.txt"

# Assert that the input file exists and is readable
if [ ! -f "$INPUT_FILE" ] || [ ! -r "$INPUT_FILE" ]; then
    echo "Error: Cannot read the input file '$INPUT_FILE'." >&2
    exit 1
fi

# Assert that the current directory is writable (for our output file)
if [ ! -w "$PWD" ]; then
    echo "Error: The current directory is not writable." >&2
    exit 1
fi

# Read 'output.txt' line by line, prepend with "import", and surround with quotes
while IFS= read -r line; do
    echo "import \"$line\"" >> "$OUTPUT_FILE"
done < "$INPUT_FILE"

echo "Processing completed. Check '$OUTPUT_FILE' for the results."
