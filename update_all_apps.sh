#!/bin/zsh

# I fetch the latest package definitions from repositories
brew update

# I upgrade command line tools
echo "Upgrading Formulae..."
brew upgrade

# I upgrade GUI applications
# I use the greedy flag to force updates for apps with built-in auto-update mechanisms
echo "Upgrading Casks..."
brew upgrade --cask --greedy

# I remove old versions and clear the cache
echo "Cleaning up the system..."
brew cleanup --prune=all

# I check if mas is installed and upgrade applications from the Apple App Store
if command -v mas &> /dev/null; then
    echo "Upgrading App Store apps..."
    mas upgrade
fi

echo "System updated successfully"