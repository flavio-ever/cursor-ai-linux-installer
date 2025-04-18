#!/bin/bash

# =============================================================================
# Cursor AI IDE Manager
# Author: flavio-ever
# Repository: https://github.com/flavio-ever/cursor-linux-installer
# 
# User-friendly manager for Cursor AI IDE on Linux systems.
# This script works in conjunction with the main installer.
# =============================================================================

# UI Configuration
readonly BOLD='\033[1m'
readonly RESET='\033[0m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

readonly CHECK="✓"
readonly CROSS="✖"
readonly ARROW="→"
readonly GEAR="⚙"
readonly DOWNLOAD="↓"
readonly LIGHTNING="⚡"
readonly INFO="ℹ"

# Configuration
readonly INSTALLER_URL="https://raw.githubusercontent.com/flavio-ever/cursor-linux-installer/main/installer.sh"
readonly INSTALLER_PATH="/tmp/cursor-installer.sh"
readonly INSTALL_DIR="/opt/cursor"
readonly APPIMAGE_PATH="$INSTALL_DIR/cursor.AppImage"
readonly MANAGER_PATH="$HOME/.local/bin/cursor-manager"

# Print colored messages
print_message() {
    local color=$1
    local message=$2
    case $color in
        "green") echo -e "${BOLD}${GREEN}${message}${NC}" ;;
        "yellow") echo -e "${BOLD}${YELLOW}${message}${NC}" ;;
        "red") echo -e "${BOLD}${RED}${message}${NC}" ;;
        "blue") echo -e "${BOLD}${BLUE}${message}${NC}" ;;
        *) echo -e "${BOLD}${message}${NC}" ;;
    esac
}

# Download the installer script
download_installer() {
    print_message "blue" "${DOWNLOAD} Downloading installer..."
    if ! curl -fsSL "$INSTALLER_URL" -o "$INSTALLER_PATH"; then
        print_message "red" "${CROSS} Failed to download installer."
        return 1
    fi
    chmod +x "$INSTALLER_PATH"
    return 0
}

# Check if Cursor is installed
is_cursor_installed() {
    [ -f "$APPIMAGE_PATH" ] && [ -x "$APPIMAGE_PATH" ]
}

# Check if Cursor is running
is_cursor_running() {
    pgrep -f "cursor.AppImage" > /dev/null
}

# Check if system dependencies are installed
check_dependencies() {
    print_message "blue" "${INFO} Checking required dependencies..."
    
    local missing_deps=()
    
    # Essential utilities for downloading and installation
    # curl: Required for downloading the AppImage and API communication
    # wget: Alternative download method if curl fails
    for dep in curl wget; do
        if ! command -v "$dep" &>/dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    # libfuse2: Critical dependency for running AppImages
    # Without this, the AppImage won't even start
    if ! dpkg -l | grep -q "^ii.*libfuse2"; then
        missing_deps+=("libfuse2")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_message "yellow" "${INFO} Missing dependencies: ${missing_deps[*]}"
        print_message "blue" "${INFO} Installing dependencies..."
        
        if ! sudo apt-get update -qq; then
            print_message "red" "${CROSS} Failed to update package lists. Aborting."
            return 1
        fi
        
        if ! sudo apt-get install -y "${missing_deps[@]}"; then
            print_message "red" "${CROSS} Failed to install dependencies. Aborting."
            return 1
        fi
        
        print_message "green" "${CHECK} Dependencies installed successfully."
    else
        print_message "green" "${CHECK} All required dependencies are already installed."
    fi
}

# Identify the user's shell configuration file
detect_shell_config() {
    # Get the user's shell
    local user_shell=$(basename "$SHELL")
    
    case "$user_shell" in
        bash)
            if [ -f "$HOME/.bashrc" ]; then
                SHELL_CONFIG="$HOME/.bashrc"
            else
                SHELL_CONFIG="$HOME/.bash_profile"
                if [ ! -f "$SHELL_CONFIG" ]; then
                    touch "$SHELL_CONFIG"
                fi
            fi
            ;;
        zsh)
            SHELL_CONFIG="$HOME/.zshrc"
            if [ ! -f "$SHELL_CONFIG" ]; then
                touch "$SHELL_CONFIG"
            fi
            ;;
        fish)
            SHELL_CONFIG="$HOME/.config/fish/config.fish"
            if [ ! -f "$SHELL_CONFIG" ]; then
                mkdir -p "$(dirname "$SHELL_CONFIG")"
                touch "$SHELL_CONFIG"
            fi
            ;;
        *)
            # Default to .bashrc for unknown shells
            SHELL_CONFIG="$HOME/.bashrc"
            if [ ! -f "$SHELL_CONFIG" ]; then
                touch "$SHELL_CONFIG"
            fi
            ;;
    esac
    
    print_message "blue" "${INFO} Detected shell configuration file: $SHELL_CONFIG"
    return 0
}

# Install the manager script
install_manager() {
    print_message "blue" "${DOWNLOAD} Installing Cursor AI IDE Manager..."
    
    # Create installation directory
    mkdir -p "$(dirname "$MANAGER_PATH")"
    
    # Copy the script to the installation directory
    if ! cp "$0" "$MANAGER_PATH"; then
        print_message "red" "${CROSS} Failed to copy manager script."
        return 1
    fi
    
    # Make the script executable
    chmod +x "$MANAGER_PATH"
    
    # Detect shell and add to PATH
    detect_shell_config
    
    # Add to PATH if not already present
    if ! grep -q "export PATH=\"$(dirname "$MANAGER_PATH"):\$PATH\"" "$SHELL_CONFIG" 2>/dev/null; then
        echo "export PATH=\"$(dirname "$MANAGER_PATH"):\$PATH\"" >> "$SHELL_CONFIG"
    fi
    
    print_message "green" "${CHECK} Cursor AI IDE Manager installed successfully!"
    print_message "yellow" "${INFO} Please restart your terminal or run:"
    print_message "blue" "  ${ARROW} source $SHELL_CONFIG"
    
    return 0
}

# Install Cursor
install_cursor() {
    if is_cursor_installed; then
        print_message "yellow" "${INFO} Cursor is already installed."
        return 0
    fi

    if ! check_dependencies; then
        return 1
    fi

    if ! download_installer; then
        return 1
    fi

    print_message "blue" "${LIGHTNING} Installing Cursor AI IDE..."
    sudo "$INSTALLER_PATH" --install
}

# Update Cursor
update_cursor() {
    if ! is_cursor_installed; then
        print_message "yellow" "${INFO} Cursor is not installed. Installing..."
        install_cursor
        return $?
    fi

    if ! check_dependencies; then
        return 1
    fi

    if ! download_installer; then
        return 1
    fi

    print_message "blue" "${LIGHTNING} Checking for updates..."
    sudo "$INSTALLER_PATH" --update
}

# Uninstall Cursor
uninstall_cursor() {
    if ! is_cursor_installed; then
        print_message "yellow" "${INFO} Cursor is not installed."
        return 0
    fi

    if is_cursor_running; then
        print_message "red" "${CROSS} Cursor is currently running. Please close it first."
        return 1
    fi

    if ! download_installer; then
        return 1
    fi

    print_message "blue" "${LIGHTNING} Uninstalling Cursor AI IDE..."
    sudo "$INSTALLER_PATH" --uninstall
}

# Check version
check_version() {
    if ! download_installer; then
        return 1
    fi

    print_message "blue" "${INFO} Checking Cursor AI IDE version..."
    sudo "$INSTALLER_PATH" --version
}

# Remove the manager itself
remove_manager() {
    print_message "yellow" "${INFO} Removing Cursor AI IDE Manager..."
    
    # Remove manager script
    if [ -f "$MANAGER_PATH" ]; then
        rm "$MANAGER_PATH"
        print_message "green" "${CHECK} Removed cursor-manager script."
    fi
    
    # Remove PATH entry from .bashrc if it's the only entry
    if grep -q "export PATH=\"$HOME/.local/bin:\$PATH\"" "$HOME/.bashrc" 2>/dev/null; then
        # Check if this is the only PATH entry
        if ! grep -q "export PATH=" "$HOME/.bashrc" | grep -v "$HOME/.local/bin"; then
            # Remove the line
            sed -i "/export PATH=\"$HOME\/.local\/bin:\$PATH\"/d" "$HOME/.bashrc"
            print_message "green" "${CHECK} Removed PATH entry from .bashrc."
        else
            print_message "yellow" "${INFO} Keeping PATH entry in .bashrc as it contains other entries."
        fi
    fi
    
    print_message "green" "${CHECK} Cursor AI IDE Manager removed successfully!"
    print_message "yellow" "${INFO} Please restart your terminal to apply changes."
    return 0
}

# Show help
show_help() {
    cat << EOL
Cursor AI IDE Manager - User-friendly interface for managing Cursor AI IDE

Usage: cursor-manager [COMMAND]

Commands:
  ${GEAR} install         Install Cursor AI IDE
  ${DOWNLOAD} update          Update Cursor AI IDE
  ${CROSS} uninstall       Uninstall Cursor AI IDE
  ${INFO} version         Check Cursor AI IDE version
  ${CROSS} remove-manager   Remove the cursor-manager itself
  ${INFO} install-manager   Install the cursor-manager itself
  ${INFO} help            Show this help message

If no command is specified, the manager will check for updates.

For more information and updates, visit:
${ARROW} https://github.com/flavio-ever/cursor-linux-installer
EOL
}

# Main function
main() {
    local command=$1

    case $command in
        "install")
            install_cursor
            ;;
        "update")
            update_cursor
            ;;
        "uninstall")
            uninstall_cursor
            ;;
        "version")
            check_version
            ;;
        "remove-manager")
            remove_manager
            ;;
        "install-manager")
            install_manager
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        "")
            update_cursor
            ;;
        *)
            print_message "red" "${CROSS} Invalid command: $command"
            show_help
            return 1
            ;;
    esac

    return 0
}

# Execute main function
main "$@" 