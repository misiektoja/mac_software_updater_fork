#!/bin/zsh

# I enable colors
autoload -U colors && colors

# I set the variable with Caskroom location depending on architecture
# Apple Silicon vs Intel
if [[ -d "/opt/homebrew/Caskroom" ]]; then
    CASKROOM_PATH="/opt/homebrew/Caskroom"
else
    CASKROOM_PATH="/usr/local/Caskroom"
fi

echo "Scanning Applications folder using physical method..."

# I initialize arrays
typeset -a list_cask list_mas list_other

# I iterate through every application
# The (N) flag prevents errors on empty results
for app_path in /Applications/*.app(N); do
    app_name=$(basename "$app_path" .app)

    # 1. CHECKING PHYSICAL LINK (CASK)
    # I check if the file is a symbolic link (-L)
    if [[ -L "$app_path" ]]; then
        # I read where this link points to
        target_path=$(readlink "$app_path")
        
        # If the target path contains Caskroom then it is 100% Homebrew
        if [[ "$target_path" == *"$CASKROOM_PATH"* ]]; then
            list_cask+=("$app_name")
            continue
        fi
    fi

    # 2. CHECKING APP STORE (MAS)
    # I check for the presence of a receipt inside the package
    if [[ -d "$app_path/Contents/_MASReceipt" ]]; then
        list_mas+=("$app_name")
        continue
    fi

    # 3. CHECKING BY NAME (FALLBACK FOR CASK)
    # Sometimes links are broken e.g. by app auto-update
    # I check if the app name normalized matches the list of installed casks
    # This is the last resort for Casks
    
    # I fetch the list of casks only once lazy loading
    if [[ -z "$installed_casks" ]]; then
       installed_casks=$(brew list --cask | tr -d ' -' | tr '[:upper:]' '[:lower:]')
    fi
    
    # I normalize the current application name
    norm_name=$(echo "$app_name" | tr -d ' -' | tr '[:upper:]' '[:lower:]')
    
    if [[ "$installed_casks" == *"$norm_name"* ]]; then
         list_cask+=("$app_name")
         continue
    fi

    # 4. OTHER
    list_other+=("$app_name")
done

# Display function
print_group() {
    local color="$1"
    local title="$2"
    local count="$3"
    local -a items=("${(@P)4}")

    # I use formatting without dashes in separators
    print "\n${color}${title} ($count)${reset_color}"
    if [[ $count -gt 0 ]]; then
        print -l "${(o)items}"
    else
        print "  (none)"
    fi
}

# I display results
print_group "$fg[green]" "HOMEBREW (CASKS)" "${#list_cask[@]}" "list_cask"
print_group "$fg[blue]" "APP STORE (MAS)" "${#list_mas[@]}" "list_mas"
print_group "$fg[yellow]" "OTHER" "${#list_other[@]}" "list_other"