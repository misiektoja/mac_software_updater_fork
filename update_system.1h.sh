#!/bin/zsh

# <bitbar.title>macOS Software Update & Migration Toolkit</bitbar.title>
# <bitbar.version>v1.1.2</bitbar.version>
# <bitbar.author>pr-fuzzylogic</bitbar.author>
# <bitbar.author.github>pr-fuzzylogic</bitbar.author.github>
# <bitbar.desc>Monitors Homebrew and App Store updates, tracks history and stats.</bitbar.desc>
# <bitbar.dependencies>brew,mas</bitbar.dependencies>
# <bitbar.abouturl>https://github.com/pr-fuzzylogic/mac_software_updater</bitbar.abouturl>
# <swiftbar.hideSwiftBar>true</swiftbar.hideSwiftBar>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>

# Set standard locale to avoid parsing errors with grep or sort on different system languages 
export LC_ALL=C

# Set the path to Homebrew environment
if [[ -d "/opt/homebrew/bin" ]]; then
    export PATH="/opt/homebrew/bin:$PATH"
else
    export PATH="/usr/local/bin:$PATH"
fi

# --- CRITICAL CHECK: HOMEBREW EXISTENCE ---
# Verify if Homebrew is installed because the script cannot function without it 
if ! command -v brew &> /dev/null; then
    if [[ "$1" == "run" ]]; then
        echo "❌ Error: Homebrew is not installed!"
        echo "This tool requires Homebrew to function."
        echo "Please install it from https://brew.sh/"
        echo "Press any key to exit."
        read -k1
        exit 1
    fi
    echo "⚠️ Brew Missing | color=red"
    echo "---"
    echo "Homebrew is strictly required | color=red"
    exit 0
fi

# Define the history file location in standard macOS Library
HISTORY_FILE="$HOME/Library/Application Support/MacSoftwareUpdater/update_history.log"
mkdir -p "$(dirname "$HISTORY_FILE")"

# --- UPDATE SECTION (Runs in Terminal) ---
if [[ "$1" == "run" ]]; then
    # Set error flags to stop on failure 
    set -e
    set -o pipefail
    
    echo "🚀 Starting System Update..."
    echo "---------------------------"

    # Count packages for history before upgrading 
    c_brew=0
    c_mas=0
    c_brew=$(brew outdated | wc -l | tr -d ' ')
    if command -v mas &> /dev/null; then
        c_mas=$(mas outdated | wc -l | tr -d ' ')
    fi
    
    total_up=$((c_brew + c_mas))

    if [[ $total_up -gt 0 ]]; then
        echo "📝 Logging update count ($total_up)..."
        echo "$(date +%s)|$total_up" >> "$HISTORY_FILE"
        
        # Rotate log file if it exceeds 500 lines to maintain performance 
        if [[ $(wc -l < "$HISTORY_FILE") -gt 500 ]]; then
            echo "🧹 Rotating history log (keeping last 100 entries)..."
            tail -n 100 "$HISTORY_FILE" > "$HISTORY_FILE.tmp" && mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
        fi
    fi

    # Perform the actual update commands 
    echo "📦 Updating Homebrew Database..."
    brew update
    echo "📦 Upgrading Formulae and Casks..."
    brew upgrade --greedy
    echo "🧹 Cleaning up..."
    brew cleanup --prune=all
    
    if command -v mas &> /dev/null; then
        echo "🍎 Updating App Store Applications..."
        mas upgrade
    fi

    echo "---------------------------"
    echo "✅ Update Complete!"
    
    # Trigger a refresh in SwiftBar 
    echo "🔄 Refreshing SwiftBar..."
    open -g "swiftbar://refreshplugin?name=$(basename "$0")"

    echo "Done! Press any key to close."
    read -k1
    exit
fi

# --- STATUS CHECK SECTION (Background) ---

# Check Homebrew for updates 
list_brew=$(brew outdated --verbose --greedy)
count_brew=$(echo -n "$list_brew" | grep -c -- '[^[:space:]]')

# Check App Store for updates
list_mas=""
count_mas=0
if command -v mas &> /dev/null; then
    list_mas=$(mas outdated)
	# added -- to the grep command to explicitly signify the end of command options
    count_mas=$(echo -n "$list_mas" | grep -c -- '[^[:space:]]')
fi

total=$((count_brew + count_mas))

# Collect total installed statistics for the submenu
count_casks=$(brew list --cask | wc -l | tr -d ' ')
count_formulae=$(brew list --formula | wc -l | tr -d ' ')
count_mas_installed=0
if command -v mas &> /dev/null; then
    count_mas_installed=$(mas list | wc -l | tr -d ' ')
fi
total_installed=$((count_casks + count_formulae + count_mas_installed))

# Calculate history statistics safely
updates_week=0
updates_month=0
current_time=$(date +%s)

if [[ -f "$HISTORY_FILE" ]]; then
    while IFS='|' read -r log_time log_count; do
        # Guard against empty lines or invalid data
        if [[ -z "$log_time" ]] || [[ -z "$log_count" ]]; then
            continue
        fi
        if [[ ! "$log_time" =~ ^[0-9]+$ ]] || [[ ! "$log_count" =~ ^[0-9]+$ ]]; then
            continue
        fi

        diff=$((current_time - log_time))
        
        if [[ $diff -le 604800 ]]; then
            updates_week=$((updates_week + log_count))
        fi
        
        if [[ $diff -le 2592000 ]]; then
            updates_month=$((updates_month + log_count))
        fi
    done < "$HISTORY_FILE"
fi


# --- UI RENDERING ---

# Set main menu bar icon based on status
if [[ $total -gt 0 ]]; then
    # Space is needed for better look
    echo " $total | sfimage=arrow.triangle.2.circlepath.circle color=red"
else
    echo " | sfimage=checkmark.circle"
fi
echo "---"

# Show update details
if [[ $total -eq 0 ]]; then
    echo "System is up to date | color=green sfimage=checkmark.shield"
else
    if [[ $count_brew -gt 0 ]]; then
        echo "Homebrew ($count_brew): | color=gray size=12 sfimage=shippingbox"
        echo "$list_brew" | while read -r line; do echo "$line | size=12 font=Monaco"; done
        echo "---"
    fi
    if [[ $count_mas -gt 0 ]]; then
        echo "App Store ($count_mas): | color=gray size=12 sfimage=bag"
        # Show without digital ID
        echo "$list_mas" | awk '{$1=""; print $0}' | while read -r line; do echo "$line | size=12 font=Monaco"; done
    fi
fi

# Render statistics and history with submenus 
echo "---"
echo "Monitored: $total_installed items | color=gray size=12 sfimage=chart.bar.xaxis"
echo "-- Apps (Brew Cask): $count_casks | color=gray size=11 sfimage=square.stack.3d.up"
echo "-- CLI Tools (Brew Formulae): $count_formulae | color=gray size=11 sfimage=terminal"
echo "-- App Store: $count_mas_installed | color=gray size=11 sfimage=bag"

echo "History: | color=gray size=12 sfimage=clock.arrow.circlepath"
echo "-- Past 7 days: $updates_week updates | color=gray size=11 sfimage=calendar"
echo "-- Past 30 days: $updates_month updates | color=gray size=11 sfimage=calendar.badge.clock"

# Render the footer with conditional Update button 
echo "---"
script_path="${0// /\\ }"
if [[ $total -gt 0 ]]; then
    echo "Update All | bash='$script_path' param1=run terminal=true sfimage=arrow.triangle.2.circlepath.circle"
else
    echo "Update All | color=gray sfimage=checkmark.circle"
fi
echo "Last check: $(date +%H:%M) | size=10 color=gray"
echo "Refresh now | refresh=true sfimage=arrow.clockwise"