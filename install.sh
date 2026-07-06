#!/usr/bin/env bash
# shell-profiles remote bootstrap installer (Debian/Ubuntu-based Linux)
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/n3rddoom/shell-profiles/master/install.sh | bash
#
# Env overrides:
#   SHPROF_INSTALL_DIR   where to clone the repo   (default: ~/.local/share/shell-profiles)
#   SHPROF_BRANCH        branch/tag to install     (default: master)
set -euo pipefail

REPO_URL="https://github.com/n3rddoom/shell-profiles.git"
BRANCH="${SHPROF_BRANCH:-master}"
INSTALL_DIR="${SHPROF_INSTALL_DIR:-$HOME/.local/share/shell-profiles}"
BASHRC="$HOME/.bashrc"

if ! command -v apt-get &>/dev/null; then
    echo "This installer targets Debian/Ubuntu-based systems (apt-get not found)." >&2
    exit 1
fi

_privileged() {
    if [[ "$(id -u)" -eq 0 ]]; then
        "$@"
    else
        sudo "$@"
    fi
}

missing=()
command -v git  &>/dev/null || missing+=(git)
command -v curl &>/dev/null || missing+=(curl)
if [[ ${#missing[@]} -gt 0 ]]; then
    echo "Installing prerequisites: ${missing[*]}"
    _privileged apt-get update -qq && _privileged apt-get install -y "${missing[@]}"
fi

if [[ -d "$INSTALL_DIR/.git" ]]; then
    echo "Updating existing shell-profiles checkout at $INSTALL_DIR..."
    git -C "$INSTALL_DIR" pull --ff-only origin "$BRANCH"
else
    echo "Cloning shell-profiles ($BRANCH) into $INSTALL_DIR..."
    mkdir -p "$(dirname "$INSTALL_DIR")"
    git clone --depth=1 --branch "$BRANCH" "$REPO_URL" "$INSTALL_DIR"
fi

SOURCE_LINE="source \"$INSTALL_DIR/bash-profile/configs/ndbash-config.sh\""
if ! grep -qF "$SOURCE_LINE" "$BASHRC" 2>/dev/null; then
    {
        echo ""
        echo "# shell-profiles bash profile"
        echo "$SOURCE_LINE"
    } >> "$BASHRC"
    echo "Added source line to $BASHRC"
else
    echo "$BASHRC already sources ndbash-config.sh"
fi

echo "Running first-time setup (installs starship, zoxide, eza, fastfetch, FiraCode Nerd Font)..."
# ndbash-config.sh is written to tolerate individual install failures (it's sourced
# into interactive shells long-term); disable errexit so one flaky download here
# can't abort the rest of this one-shot bootstrap.
set +e
# shellcheck source=bash-profile/configs/ndbash-config.sh
source "$INSTALL_DIR/bash-profile/configs/ndbash-config.sh"
set -e

echo ""
echo "Done. Start a new shell or run: source ~/.bashrc"
