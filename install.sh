#!/bin/bash

# =============================================================================
# Cursor AI IDE Installer
# Author: flavio-ever
# Repository: https://github.com/flavio-ever/cursor-linux-installer
# 
# This script installs the Cursor AI IDE Manager, which provides a user-friendly
# interface for managing Cursor AI IDE on Linux systems.
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
readonly MANAGER_URL="https://raw.githubusercontent.com/flavio-ever/cursor-linux-installer/main/cursor-manager"
readonly INSTALL_DIR="$HOME/.local/bin"
readonly MANAGER_PATH="$INSTALL_DIR/cursor-manager"

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

# Install the manager
install_manager() {
    print_message "blue" "${DOWNLOAD} Installing Cursor AI IDE Manager..."
    
    # Create installation directory
    mkdir -p "$INSTALL_DIR"
    
    # Download manager
    if ! curl -fsSL "$MANAGER_URL" -o "$MANAGER_PATH"; then
        print_message "red" "${CROSS} Failed to download Cursor AI IDE Manager."
        return 1
    fi
    
    # Make manager executable
    chmod +x "$MANAGER_PATH"
    
    # Add to PATH if not already present
    if ! grep -q "export PATH=\"$INSTALL_DIR:\$PATH\"" "$HOME/.bashrc" 2>/dev/null; then
        echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$HOME/.bashrc"
    fi
    
    print_message "green" "${CHECK} Cursor AI IDE Manager installed successfully!"
    print_message "yellow" "${INFO} Restart your terminal or run:"
    print_message "blue" "  ${ARROW} source ~/.bashrc"
    
    return 0
}

# Main function
main() {
    # Check if curl is installed
    if ! command -v curl &> /dev/null; then
        print_message "red" "${CROSS} Error: curl is not installed."
        print_message "yellow" "${INFO} Please install curl first:"
        print_message "blue" "  ${ARROW} sudo apt install curl"
        return 1
    fi
    
    # Install the manager
    if ! install_manager; then
        return 1
    fi
    
    print_message "green" "${CHECK} Installation completed successfully!"
    print_message "yellow" "${INFO} Available commands:"
    print_message "blue" "  ${ARROW} cursor-manager install   - Install Cursor AI IDE"
    print_message "blue" "  ${ARROW} cursor-manager update   - Update Cursor AI IDE"
    print_message "blue" "  ${ARROW} cursor-manager version  - Check versions"
    print_message "blue" "  ${ARROW} cursor-manager uninstall - Uninstall Cursor AI IDE"
    
    return 0
}

# Execute main function
main "$@"