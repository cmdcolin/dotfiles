#!/bin/bash
# Dotfiles installer dispatcher
set -e

show_help() {
    cat << 'EOF'
Usage: ./install.sh [OPTION]

Install development environment and dotfiles.

Options:
    mac       Install macOS environment
    ubuntu    Install Ubuntu/Linux environment
    linux     Alias for ubuntu
    -h        Show this help message

If no option specified, auto-detects based on OS.

Examples:
    ./install.sh mac     # macOS setup
    ./install.sh ubuntu  # Ubuntu/Linux setup
EOF
}

# Detect OS if not specified
OS="${1:-}"

if [ -z "$OS" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="mac"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="ubuntu"
    else
        echo "Error: Unknown OS. Please specify: ./install.sh mac|ubuntu"
        exit 1
    fi
fi

case "$OS" in
    -h|--help|help)
        show_help
        exit 0
        ;;
    mac)
        ./install_mac.sh
        ;;
    ubuntu|linux)
        ./install_linux.sh
        ;;
    *)
        echo "Error: Unknown option '$OS'"
        show_help
        exit 1
        ;;
esac
