#!/bin/zsh

# I declare arrays to store the results
available=()
unavailable=()

# I iterate through all applications in the Applications folder
for app in /Applications/*.app; do
    # I extract the filename and remove the extension
    name=$(basename "$app" .app)

    # I convert the name to lowercase and replace spaces with hyphens
    # Homebrew usually follows this convention for package names
    token=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

    # I check if the specific cask exists in the repository while silencing output
    if brew info --cask "$token" &> /dev/null; then
        available+=("$name")
    else
        unavailable+=("$name")
    fi
done

# I display the section with available applications
echo "Available in Homebrew:"
printf '%s\n' "${available[@]}"

echo ""

# I display the section with applications not found automatically
echo "Unavailable (or using a different name in the repository):"
printf '%s\n' "${unavailable[@]}"