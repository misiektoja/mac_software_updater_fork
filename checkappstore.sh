#!/bin/zsh

# I check if the mas CLI tool is installed in the system
if ! command -v mas &> /dev/null; then
    echo "Error: The 'mas' tool is not installed. Please run 'brew install mas'."
    exit 1
fi

# I declare arrays for the results
found_apps=()
missing_apps=()

# I iterate through all arguments passed to the script
for app_name in "$@"; do
    # I search the App Store and retrieve only the first result
    # I use head to keep the variable output clean
    result=$(mas search "$app_name" | head -n 1)

    if [[ -n "$result" ]]; then
        # I add the application name to the found list if the result is not empty
        found_apps+=("$app_name")
    else
        # I add it to the missing list if mas returned nothing
        missing_apps+=("$app_name")
    fi
done

# I display the found applications
echo "Available in the App Store:"
printf '%s\n' "${found_apps[@]}"

echo ""

# I display the applications that could not be found
echo "Not available:"
printf '%s\n' "${missing_apps[@]}"