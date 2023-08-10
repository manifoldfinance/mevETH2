#!/bin/bash

# Output filename
output_file="subtree_commands_$(date +%s).sh"

# Check if .gitmodules file exists
if [ ! -f .gitmodules ]; then
    echo ".gitmodules file does not exist in the current directory."
    exit 1
fi

# Write shebang to output file
echo "#!/bin/bash" > "$output_file"

# Read the .gitmodules file line by line
while IFS= read -r line; do
    if [[ "$line" == '[submodule'* ]]; then
        # Extract the submodule name
        name=$(echo "$line" | cut -d'"' -f 2)
    elif [[ "$line" == *'path = '* ]]; then
        # Extract the path
        path=$(echo "$line" | cut -d'=' -f 2 | xargs)
    elif [[ "$line" == *'url = '* ]]; then
        # Extract the URL
        url=$(echo "$line" | cut -d'=' -f 2 | xargs)

        # Write the git subtree add command to the output file
        echo "git subtree add --prefix=$path $url master" >> "$output_file"
    fi
done < .gitmodules

# Make the output file executable
chmod +x "$output_file"
