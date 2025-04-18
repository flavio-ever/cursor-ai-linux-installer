#!/bin/bash

# =============================================================================
# Cursor Linux Installer - Installer/Updater for Cursor AI IDE on Linux
# Author: flavio-ever
# Repository: https://github.com/flavio-ever/cursor-linux-installer
# Version: 1.0.1
# 
# This script facilitates the installation, update, and configuration of
# Cursor AI IDE on Linux systems, creating shortcuts and shell integration.
# =============================================================================

# Icons
CHECK="✓"
CROSS="✖"
ARROW="→"
GEAR="⚙"
DOWNLOAD="↓"
LIGHTNING="⚡"
INFO="ℹ"
QUESTION="❓"

# -----------------------------------------------------------------------------
# Configuration Constants
# -----------------------------------------------------------------------------
readonly INSTALL_DIR="/opt/cursor"
readonly APPIMAGE_PATH="${INSTALL_DIR}/cursor.AppImage"
readonly ICON_PATH="${INSTALL_DIR}/cursor.png"
readonly DESKTOP_ENTRY_PATH="/usr/share/applications/cursor.desktop"
readonly ICON_URL="https://raw.githubusercontent.com/rahuljangirwork/copmany-logos/refs/heads/main/cursor.png"
readonly API_URL="https://www.cursor.com/api/download?platform=linux-x64&releaseTrack=stable"
readonly LOG_FILE="/tmp/cursor_linux_installer.log"

# Function to display colored messages
print_message() {
    local color=$1
    local message=$2
    case $color in
        "green") echo -e "\e[32m${CHECK} $message\e[0m" ;;
        "yellow") echo -e "\e[33m${INFO} $message\e[0m" ;;
        "red") echo -e "\e[31m${CROSS} $message\e[0m" ;;
        *) echo "$message" ;;
    esac
}

# Cursor shell function template to be added to config files
read -r -d '' CURSOR_FUNCTION << 'EOL'
# Cursor AI IDE launcher function
function cursor() {
    local args=""
    if [ $# -eq 0 ]; then
        args=$(pwd)
    else
        for arg in "$@"; do
            args="$args $arg"
        done
    fi
    local executable="/opt/cursor/cursor.AppImage"
    if [ -f "$executable" ]; then
        (nohup "$executable" --no-sandbox $args >/dev/null 2>&1 &)
    else
        echo "Error: Cursor AI IDE is not installed or not found at $executable"
        echo "Please run the Cursor Linux Installer first."
    fi
}
EOL

# -----------------------------------------------------------------------------
# Utility Functions
# -----------------------------------------------------------------------------

# Function to log messages to both console and log file
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    case "$level" in
        "INFO")
            print_message "green" "[INFO] $message"
            ;;
        "WARNING")
            print_message "yellow" "[WARNING] $message"
            ;;
        "ERROR")
            print_message "red" "[ERROR] $message"
            ;;
        *)
            echo "$message"
            ;;
    esac
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Check if the script is running with sudo/root privileges
check_root_privileges() {
    if [ "$EUID" -ne 0 ]; then
        log_message "ERROR" "This script requires root privileges."
        log_message "ERROR" "Please run with sudo: sudo $0"
        exit 1
    fi
}

# Check if system dependencies are installed
check_dependencies() {
    log_message "INFO" "Checking for required dependencies..."
    
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
        log_message "WARNING" "Missing required dependencies: ${missing_deps[*]}"
        log_message "INFO" "Installing dependencies..."
        
        apt-get update -qq || {
            log_message "ERROR" "Failed to update package lists. Aborting."
            exit 1
        }
        
        apt-get install -y "${missing_deps[@]}" || {
            log_message "ERROR" "Failed to install dependencies. Aborting."
            exit 1
        }
        
        log_message "INFO" "Dependencies installed successfully."
    else
        log_message "INFO" "All required dependencies are already installed."
    fi
}

# Check if Cursor is currently running
is_cursor_running() {
    if pgrep -f "cursor.AppImage" > /dev/null; then
        return 0  # Cursor is running
    else
        return 1  # Cursor is not running
    fi
}

# -----------------------------------------------------------------------------
# Version Management Functions
# -----------------------------------------------------------------------------

# Fetch version information from Cursor API
fetch_version_info() {
    log_message "INFO" "Fetching latest version information from Cursor API..."
    
    local api_response
    api_response=$(curl -s "$API_URL")
    
    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to connect to Cursor API."
        return 1
    fi
    
    DOWNLOAD_URL=$(echo "$api_response" | grep -o '"downloadUrl":"[^"]*"' | cut -d'"' -f4)
    LATEST_VERSION=$(echo "$api_response" | grep -o '"version":"[^"]*"' | cut -d'"' -f4)
    
    if [[ -z "$DOWNLOAD_URL" || -z "$LATEST_VERSION" ]]; then
        log_message "ERROR" "Failed to parse version information from API response."
        return 1
    fi
    
    log_message "INFO" "Latest version available: $LATEST_VERSION"
    return 0
}

# Get the currently installed version of Cursor
get_installed_version() {
    if [[ -f "$APPIMAGE_PATH" && -x "$APPIMAGE_PATH" ]]; then
        log_message "INFO" "Attempting to detect Cursor version..."
        
        # First check version.txt file
        log_message "INFO" "Trying to get version from version.txt..."
        if [ -f "$INSTALL_DIR/version.txt" ]; then
            CURRENT_VERSION=$(cat "$INSTALL_DIR/version.txt")
            if [[ -n "$CURRENT_VERSION" ]]; then
                log_message "INFO" "Current installed version: $CURRENT_VERSION"
                return 0
            fi
        fi
        
        # If that fails, try to extract from AppImage using file
        log_message "INFO" "Trying to get version from AppImage using file command..."
        CURRENT_VERSION=$(file "$APPIMAGE_PATH" | grep -o "Cursor-[0-9]\+\.[0-9]\+\.[0-9]\+" | cut -d'-' -f2)
        
        if [[ -n "$CURRENT_VERSION" ]]; then
            log_message "INFO" "Current installed version (from file command): $CURRENT_VERSION"
            return 0
        fi
        
        # If still fails, try to extract from AppImage using strings
        log_message "INFO" "Trying to get version from AppImage contents..."
        CURRENT_VERSION=$(strings "$APPIMAGE_PATH" | grep -o "Cursor-[0-9]\+\.[0-9]\+\.[0-9]\+" | head -1 | cut -d'-' -f2)
        
        if [[ -n "$CURRENT_VERSION" ]]; then
            log_message "INFO" "Current installed version (from AppImage): $CURRENT_VERSION"
            return 0
        fi
        
        CURRENT_VERSION="unknown"
        log_message "WARNING" "Cursor is installed but version detection failed after all attempts."
        return 1
    else
        CURRENT_VERSION="not installed"
        log_message "INFO" "Cursor is not currently installed."
        return 1
    fi
}

# Compare version strings
is_version_newer() {
    local current="$1"
    local latest="$2"
    
    if [[ "$current" == "not installed" || "$current" == "unknown" ]]; then
        return 0  # Consider as needing update if no version or unknown
    fi
    
    # Split versions into components
    IFS='.' read -ra current_parts <<< "$current"
    IFS='.' read -ra latest_parts <<< "$latest"
    
    # Compare version components
    for i in {0..2}; do
        if [[ "${latest_parts[i]}" -gt "${current_parts[i]}" ]]; then
            return 0  # Latest is newer
        elif [[ "${latest_parts[i]}" -lt "${current_parts[i]}" ]]; then
            return 1  # Current is newer
        fi
    done
    
    return 1  # Versions are equal
}

# -----------------------------------------------------------------------------
# Installation Functions
# -----------------------------------------------------------------------------

# Create desktop entry for application menu integration
create_desktop_entry() {
    log_message "INFO" "Creating desktop entry for Cursor..."
    
    cat > "$DESKTOP_ENTRY_PATH" << EOL
[Desktop Entry]
Name=Cursor AI IDE
Comment=Modern AI-powered code editor
Exec=$APPIMAGE_PATH --no-sandbox %F
Icon=$ICON_PATH
Terminal=false
Type=Application
StartupWMClass=Cursor
Categories=Development;IDE;TextEditor;
MimeType=text/plain;application/x-shellscript;application/javascript;application/json;text/css;text/html;text/x-c;text/x-csrc;text/x-c++src;text/x-python;
Keywords=Text;Editor;Development;IDE;AI;
EOL
    
    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to create desktop entry."
        return 1
    fi
    
    log_message "INFO" "Desktop entry created successfully."
    return 0
}

# Download and install the Cursor AppImage
download_and_install() {
    log_message "INFO" "Installing Cursor AI IDE version $LATEST_VERSION..."
    
    # Create installation directory if it doesn't exist
    mkdir -p "$INSTALL_DIR"
    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to create installation directory."
        return 1
    fi
    
    # Download the AppImage
    log_message "INFO" "Downloading Cursor AppImage..."
    curl -L "$DOWNLOAD_URL" -o "$APPIMAGE_PATH"
    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to download Cursor AppImage."
        return 1
    fi
    
    # Make the AppImage executable
    chmod +x "$APPIMAGE_PATH"
    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to make AppImage executable."
        return 1
    fi
    
    # Create version.txt file
    echo "$LATEST_VERSION" > "$INSTALL_DIR/version.txt"
    if [ $? -ne 0 ]; then
        log_message "WARNING" "Failed to create version.txt file."
    fi
    
    # Download the icon
    log_message "INFO" "Downloading Cursor icon..."
    curl -L "$ICON_URL" -o "$ICON_PATH"
    if [ $? -ne 0 ]; then
        log_message "WARNING" "Failed to download Cursor icon. Using default."
    fi
    
    # Create desktop entry
    create_desktop_entry
    
    log_message "INFO" "Installation completed successfully!"
    return 0
}

# Uninstall Cursor completely
uninstall_cursor() {
    log_message "INFO" "Uninstalling Cursor AI IDE..."
    
    # Check if Cursor is running
    if is_cursor_running; then
        log_message "ERROR" "Cursor is currently running. Please close it first."
        return 1
    fi
    
    # Remove desktop entry
    if [ -f "$DESKTOP_ENTRY_PATH" ]; then
        rm -f "$DESKTOP_ENTRY_PATH"
        log_message "INFO" "Removed desktop entry."
    fi
    
    # Remove installation directory
    if [ -d "$INSTALL_DIR" ]; then
        rm -rf "$INSTALL_DIR"
        log_message "INFO" "Removed installation directory."
    fi
    
    log_message "INFO" "Cursor AI IDE has been uninstalled."
    
    # Optional: Remove shell function
    read -p "Do you want to remove the 'cursor' shell function from your config files? [y/N] " remove_function
    if [[ "$remove_function" =~ ^[Yy]$ ]]; then
        remove_shell_function
    fi
    
    return 0
}

# -----------------------------------------------------------------------------
# Shell Integration Functions
# -----------------------------------------------------------------------------

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
    
    log_message "INFO" "Detected shell configuration file: $SHELL_CONFIG"
    return 0
}

# Add the cursor function to the shell configuration
add_shell_function() {
    detect_shell_config
    
    # Check if the function already exists
    if grep -q "function cursor()" "$SHELL_CONFIG"; then
        log_message "INFO" "Cursor function already exists in $SHELL_CONFIG."
        return 0
    fi
    
    # Add the function to the config file
    echo -e "\n$CURSOR_FUNCTION" >> "$SHELL_CONFIG"
    
    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to add cursor function to shell config."
        return 1
    fi
    
    log_message "INFO" "Added 'cursor' function to $SHELL_CONFIG."
    log_message "INFO" "Please restart your terminal or run 'source $SHELL_CONFIG' to use the cursor command."
    return 0
}

# Remove the cursor function from shell configuration
remove_shell_function() {
    detect_shell_config
    
    # Create a temporary file
    local temp_file=$(mktemp)
    
    # Remove the function definition from the config file
    sed '/# Cursor AI IDE launcher function/,/^}$/d' "$SHELL_CONFIG" > "$temp_file"
    
    # Replace the original file
    mv "$temp_file" "$SHELL_CONFIG"
    
    log_message "INFO" "Removed 'cursor' function from $SHELL_CONFIG."
    log_message "INFO" "Please restart your terminal or run 'source $SHELL_CONFIG' to apply changes."
    return 0
}

# -----------------------------------------------------------------------------
# Main Operations
# -----------------------------------------------------------------------------

# Perform a fresh installation of Cursor
perform_installation() {
    check_dependencies
    
    if ! fetch_version_info; then
        log_message "ERROR" "Installation failed. Could not get version information."
        exit 1
    fi
    
    if is_cursor_running; then
        log_message "ERROR" "Cursor is currently running. Please close it before installing."
        exit 1
    fi
    
    if download_and_install; then
        add_shell_function
        log_message "INFO" "Cursor AI IDE has been successfully installed."
        log_message "INFO" "You can now run Cursor by typing 'cursor' in a new terminal or from your applications menu."
    else
        log_message "ERROR" "Installation failed."
        exit 1
    fi
}

# Update an existing Cursor installation
perform_update() {
    check_dependencies
    
    if ! fetch_version_info; then
        log_message "ERROR" "Update failed. Could not get version information."
        exit 1
    fi
    
    get_installed_version
    
    if [ "$CURRENT_VERSION" = "not installed" ]; then
        log_message "INFO" "Cursor is not currently installed. Performing fresh installation..."
        perform_installation
        return
    fi
    
    if ! is_version_newer "$CURRENT_VERSION" "$LATEST_VERSION"; then
        log_message "INFO" "Cursor is already up to date (version $CURRENT_VERSION)."
        
        # Make sure shell function is set up even if no update is needed
        add_shell_function
        return
    fi
    
    log_message "INFO" "Updating from version $CURRENT_VERSION to $LATEST_VERSION..."
    
    if is_cursor_running; then
        log_message "ERROR" "Cursor is currently running. Please close it before updating."
        exit 1
    fi
    
    if download_and_install; then
        add_shell_function
        log_message "INFO" "Cursor AI IDE has been successfully updated to version $LATEST_VERSION."
    else
        log_message "ERROR" "Update failed."
        exit 1
    fi
}

# Show help and usage information
show_help() {
    cat << EOL
Cursor Linux Installer - Installer/Updater for Cursor AI IDE on Linux
Usage: $0 [OPTIONS]

Options:
  ${GEAR} --install     Perform a fresh installation of Cursor AI IDE
  ${DOWNLOAD} --update      Update existing Cursor AI IDE installation
  ${CROSS} --uninstall   Remove Cursor AI IDE completely
  ${INFO} --version     Check current installed version
  ${INFO} --help        Show this help message

If no option is specified, the script will install or update Cursor automatically.

Required Dependencies:
  - libfuse2: Essential for running AppImages
  - curl or wget: For downloading files

The installer will automatically install these dependencies if they are missing.

For more information and updates, visit:
${ARROW} https://github.com/flavio-ever/cursor-linux-installer
EOL
}

# Check current version
check_version() {
    get_installed_version
    if [ "$CURRENT_VERSION" = "not installed" ]; then
        log_message "INFO" "Cursor AI IDE is not currently installed."
    else
        log_message "INFO" "Current installed version: $CURRENT_VERSION"
        
        if fetch_version_info; then
            if is_version_newer "$CURRENT_VERSION" "$LATEST_VERSION"; then
                log_message "INFO" "A newer version ($LATEST_VERSION) is available!"
            else
                log_message "INFO" "You have the latest version installed."
            fi
        fi
    fi
}

# Main function to handle installation or update
main() {
    # Initialize log file
    echo "=== Cursor Linux Installer Log $(date) ===" > "$LOG_FILE"
    
    # Parse command line options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --install)
                ACTION="install"
                shift
                ;;
            --update)
                ACTION="update"
                shift
                ;;
            --uninstall)
                ACTION="uninstall"
                shift
                ;;
            --version)
                check_version
                exit 0
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_message "ERROR" "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Default action is install/update
    if [ -z "$ACTION" ]; then
        if [ -f "$APPIMAGE_PATH" ]; then
            ACTION="update"
        else
            ACTION="install"
        fi
    fi
    
    # Check for root privileges
    check_root_privileges
    
    case "$ACTION" in
        install)
            log_message "INFO" "Starting Cursor AI IDE installation..."
            perform_installation
            ;;
        update)
            log_message "INFO" "Checking for Cursor AI IDE updates..."
            perform_update
            ;;
        uninstall)
            uninstall_cursor
            ;;
    esac
    
    log_message "INFO" "Operation completed. Log saved to $LOG_FILE"
}

# -----------------------------------------------------------------------------
# Execute Main Function
# -----------------------------------------------------------------------------
main "$@"