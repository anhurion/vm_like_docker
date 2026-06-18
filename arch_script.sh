#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
# ──────────────────────────────────────────────────────────────────────────────
# install.sh — bootstrap an Arch Linux instance with important plug-ins
# Usage: sudo ./install.sh
# ──────────────────────────────────────────────────────────────────────────────

### Resolve the real user and their home directory
TARGET_USER="${SUDO_USER:-$(whoami)}"
TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)

### Git commit-signing defaults (SSH-based)
git config --global gpg.format ssh

### Full system upgrade first, then install add-ons
# IMPORTANT: always -Syu, never -Sy alone — partial upgrades break Arch
pacman -Syu --noconfirm --needed \
  curl \
  git \
  nano \
  plocate \
  wget \
  zsh

### Switch default shell to zsh
ZSH_PATH="$(which zsh)"
current_shell="$(getent passwd "$TARGET_USER" | cut -d: -f7)"
if [[ "$current_shell" != "$ZSH_PATH" ]]; then
  chsh -s "$ZSH_PATH" "$TARGET_USER"
  echo "Changed $TARGET_USER's shell to $ZSH_PATH"
fi

### Pull down zsh config + plugin list
ZSH_RC="$TARGET_HOME/.zshrc"
ZSH_PLUGINS="$TARGET_HOME/.zsh_plugins.txt"
curl -fsSL https://raw.githubusercontent.com/anhurion/vm_like_docker/main/.zsh_plugins.txt -o "$ZSH_PLUGINS"
curl -fsSL https://raw.githubusercontent.com/anhurion/vm_like_docker/main/.zshrc            -o "$ZSH_RC"
chmod 644 "$ZSH_PLUGINS" "$ZSH_RC"
chown "$TARGET_USER:$TARGET_USER" "$ZSH_PLUGINS" "$ZSH_RC"

### Install lsd
if ! command -v lsd >/dev/null 2>&1; then
  echo "Installing lsd..."
  pacman -S --noconfirm --needed lsd
fi

### Install lazygit
if ! command -v lazygit >/dev/null 2>&1; then
  echo "Installing lazygit..."
  pacman -S --noconfirm --needed lazygit
fi

### Clone Antidote (or pull updates)
ANTIDOTE_DIR="$TARGET_HOME/.antidote"
if [[ -d "$ANTIDOTE_DIR/.git" ]]; then
  echo "Updating Antidote..."
  sudo -u "$TARGET_USER" git -C "$ANTIDOTE_DIR" pull --ff-only
else
  echo "Cloning Antidote..."
  sudo -u "$TARGET_USER" git clone --depth=1 https://github.com/mattmc3/antidote.git "$ANTIDOTE_DIR"
fi

### Final message
echo
echo "Installation complete!"
echo "- User: $TARGET_USER"
echo "- Home: $TARGET_HOME"
echo "- New default shell: $ZSH_PATH"
echo "- Run:  exec zsh   (or log out/in) to activate your new zsh setup."
