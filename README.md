# Cursor AI Linux Installer

<img src="resources/cursor.svg" alt="Cursor Logo" width="128" height="128">

A simple installer script for Cursor AI IDE on Linux systems. Downloads and installs the latest version of Cursor with desktop integration.

## Motivation

This script was born out of the need to simplify the installation process of Cursor AI IDE on Linux systems. While Cursor is an excellent code editor, the company's official installation process for Linux is not straightforward and lacks proper desktop integration. This script aims to bridge that gap by providing a seamless installation experience with full desktop integration, automatic updates, and proper shell integration.

## Features

- One-command installation
- Desktop menu integration
- Direct AppImage execution
- Clean and simple installation process
- User-friendly feedback
- No additional tools required
- Optional management tool

## Installation

### Basic Installation (Recommended)

Install Cursor AI IDE with a single command:

```bash
curl -fsSL https://raw.githubusercontent.com/flavio-ever/cursor-ai-linux-installer/main/installer.sh | sudo bash
```

### Command Options

You can also use specific commands:

```bash
# Install Cursor
curl -fsSL https://raw.githubusercontent.com/flavio-ever/cursor-ai-linux-installer/main/installer.sh | sudo bash -s -- --install

# Update Cursor
curl -fsSL https://raw.githubusercontent.com/flavio-ever/cursor-ai-linux-installer/main/installer.sh | sudo bash -s -- --update

# Uninstall Cursor
curl -fsSL https://raw.githubusercontent.com/flavio-ever/cursor-ai-linux-installer/main/installer.sh | sudo bash -s -- --uninstall

# Check version
curl -fsSL https://raw.githubusercontent.com/flavio-ever/cursor-ai-linux-installer/main/installer.sh | sudo bash -s -- --version

# Show help
curl -fsSL https://raw.githubusercontent.com/flavio-ever/cursor-ai-linux-installer/main/installer.sh | sudo bash -s -- --help
```

### Optional: Cursor Manager

If you prefer a more user-friendly way to manage Cursor, you can install the Cursor Manager:

```bash
curl -fsSL https://raw.githubusercontent.com/flavio-ever/cursor-ai-linux-installer/main/cursor-manager.sh | bash
```

After installation, you can use these commands:

```bash
# Install Cursor
cursor-manager install

# Update Cursor
cursor-manager update

# Check version
cursor-manager version

# Uninstall Cursor
cursor-manager uninstall

# Remove the manager
cursor-manager remove-manager
```

The installer will:

1. Check and install required dependencies
2. Create necessary directories
3. Download the latest Cursor AppImage
4. Make it executable
5. Create desktop menu entry
6. Add shell integration
7. Set up automatic updates

## Usage

After installation, you can:

- Open Cursor from your applications menu
- Use the `cursor` command in your terminal
- Run directly: `/opt/cursor/cursor.AppImage`

## Installation Location

The Cursor AI IDE will be installed to:

```
/opt/cursor/cursor.AppImage
```

And the desktop entry will be created at:

```
/usr/share/applications/cursor.desktop
```

If you use the Cursor Manager, it will be installed at:

```
~/.local/bin/cursor-manager
```

## Requirements

- Linux system
- curl
- Internet connection
- sudo privileges

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Support

Found an issue? Please:

1. Check existing issues
2. Create a new issue with:
   - OS and version
   - Error message or unexpected behavior

## Recent Updates

### v1.0.0

- Initial release
- Installation and update support
- Shell integration
- Desktop menu integration

### v1.0.1

- Add shell detection for bash, zsh and fish support
- Add proper dependency checking similar to installer.sh
- Improve PATH handling for different shell configurations

### v1.0.2

- Simplified installation process
- Removed redundant install.sh script
- Improved manager installation

### v1.0.3

- Fix download
