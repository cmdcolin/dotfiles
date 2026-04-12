#!/bin/bash
# Format all shell and zsh files in the repository
set -e

if ! command -v shfmt &>/dev/null; then
  echo "Error: shfmt not found. Please install it (e.g., 'brew install shfmt' or 'go install mvdan.cc/sh/v3/cmd/shfmt@latest')"
  exit 1
fi

echo "🎨 Formatting shell and zsh files..."

# Find all .sh files and known zsh config files
find . \( -name "*.sh" -o -name ".zshrc" -o -name ".zshrc.local" -o -name ".zpreztorc" \) | xargs shfmt -w -i 2

echo "✅ Done!"
