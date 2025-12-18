#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# ──────────────────────────────────────────────────────────────────────────────
# install.sh — bootstrap an Ubuntu EC2 instance (or similar) with important plug-ins
# Usage: sudo ./install.sh
# ──────────────────────────────────────────────────────────────────────────────

### Git commit-signing defaults (SSH-based)
git config --global gpg.format ssh
git config --global user.signingkey "${HOME}/.ssh/id_ed25519.pub"
git config --global commit.gpgsign true

### Install add-ons
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y \
  curl \
  git \
  nano \
  plocate \
  wget \
  zsh

### Switch default shell to zsh for ubuntu user
# Figure out who kicked off sudo (or fall back to whoami)
TARGET_USER="${SUDO_USER:-$(whoami)}"
ZSH_PATH="$(which zsh)"

# Only change if it isn’t already zsh
current_shell="$(getent passwd "$TARGET_USER" | cut -d: -f7)"
if [[ "$current_shell" != "$ZSH_PATH" ]]; then
  chsh -s "$ZSH_PATH" "$TARGET_USER"
  echo "Changed $TARGET_USER’s shell to $ZSH_PATH"
fi

### Pull down zsh config + plugin list
ZSH_RC="$HOME/.zshrc"
ZSH_PLUGINS="$HOME/.zsh_plugins.txt"
curl -fsSL https://raw.githubusercontent.com/anhurion/vm_like_docker/main/.zsh_plugins.txt  -o "$ZSH_PLUGINS"
curl -fsSL https://raw.githubusercontent.com/anhurion/vm_like_docker/main/.zshrc         -o "$ZSH_RC"
chmod 644 "$ZSH_PLUGINS" "$ZSH_RC"
chown "$(whoami):$(whoami)" "$ZSH_PLUGINS" "$ZSH_RC"

### Install lsd v1.1.5
if ! command -v lsd >/dev/null 2>&1; then
  echo "Downloading and installing lsd v1.1.5..."
  curl -fsSL -O https://github.com/lsd-rs/lsd/releases/download/v1.1.5/lsd_1.1.5_amd64.deb
  dpkg -i lsd_1.1.5_amd64.deb
  rm lsd_1.1.5_amd64.deb
fi

### Install lazygit (latest)
if ! command -v lazygit >/dev/null 2>&1; then
  echo "Installing latest lazygit..."
  TAG=$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
        | grep -Po '"tag_name": *"v\K[^"]*')
  curl -fsSL \
    -o lazygit.tar.gz \
    "https://github.com/jesseduffield/lazygit/releases/download/v${TAG}/lazygit_${TAG}_Linux_x86_64.tar.gz"
  tar -xzf lazygit.tar.gz lazygit
  install -m 0755 lazygit /usr/local/bin/lazygit
  rm lazygit lazygit.tar.gz
fi

### 7) Clone Antidote (or pull updates)
ANTIDOTE_DIR="$HOME/.antidote"
if [[ -d "$ANTIDOTE_DIR/.git" ]]; then
  echo "Updating Antidote…"
  git -C "$ANTIDOTE_DIR" pull --ff-only
else
  echo "Cloning Antidote…"
  git clone --depth=1 https://github.com/mattmc3/antidote.git "$ANTIDOTE_DIR"
fi

### 8) Final message
echo
echo "Installation complete!"
echo "- New default shell: $(echo $SHELL)"
echo "- Run: " exec zsh "   (or log out/in) to activate your new zsh setup."