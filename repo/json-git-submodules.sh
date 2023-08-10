#!/bin/bash

# Empty JSON object
json='{}'

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

        # Add the submodule to the JSON object
        json=$(echo "$json" | jq --arg name "$name" --arg path "$path" --arg url "$url" '. + {($name): {"path": $path, "url": $url}}')
    fi
done < .gitmodules

# Print the JSON object
echo "$json" > git_submodules.json
