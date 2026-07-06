#!/usr/bin/env bash
# Bash Profile Configuration
# Enhanced with git, node, zoxide, and developer utilities
# Bash equivalent of ../../powershell-profile/configs/ndpowershell-config.ps1
#
# Usage: add this line to your ~/.bashrc:
#   source "/path/to/shell-profiles/bash-profile/configs/ndbash-config.sh"

# Refuse to run as a standalone script - aliases/exports only survive if sourced.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "ndbash-config.sh must be sourced, not executed." >&2
    echo "Add this to your ~/.bashrc instead:" >&2
    echo "  source \"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/ndbash-config.sh\"" >&2
    exit 1
fi

NDBASH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$HOME/.local/bin:$PATH"

# ============================================================================
# Dependencies - Auto-install if missing (Debian/Ubuntu apt-based)
# ============================================================================

# Root containers often lack a `sudo` binary entirely.
_ndbash_privileged() {
    if [[ "$(id -u)" -eq 0 ]]; then
        "$@"
    else
        sudo "$@"
    fi
}

_ndbash_apt_install() {
    local missing=()
    for pkg in "$@"; do
        dpkg -s "$pkg" &>/dev/null || missing+=("$pkg")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Installing apt packages: ${missing[*]}"
        _ndbash_privileged apt-get update -qq && _ndbash_privileged apt-get install -y "${missing[@]}"
    fi
}

_ndbash_install_starship() {
    command -v starship &>/dev/null && return
    echo "Installing starship..."
    curl -fsSL https://starship.rs/install.sh | sh -s -- --yes --bin-dir "$HOME/.local/bin"
}

_ndbash_install_zoxide() {
    command -v zoxide &>/dev/null && return
    echo "Installing zoxide..."
    curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
}

_ndbash_install_eza() {
    command -v eza &>/dev/null && return
    echo "Installing eza..."
    if _ndbash_privileged apt-get install -y eza 2>/dev/null && command -v eza &>/dev/null; then
        return
    fi
    local target tmp
    case "$(dpkg --print-architecture)" in
        amd64) target="x86_64-unknown-linux-gnu" ;;
        arm64) target="aarch64-unknown-linux-gnu" ;;
        *) echo "Unsupported arch for eza auto-install; install manually: https://github.com/eza-community/eza"; return ;;
    esac
    tmp=$(mktemp -d)
    if curl -fsSL "https://github.com/eza-community/eza/releases/latest/download/eza_${target}.tar.gz" -o "$tmp/eza.tar.gz"; then
        tar -xzf "$tmp/eza.tar.gz" -C "$tmp"
        mkdir -p "$HOME/.local/bin"
        mv "$tmp/eza" "$HOME/.local/bin/eza"
        chmod +x "$HOME/.local/bin/eza"
    else
        echo "Could not download eza; install manually: https://github.com/eza-community/eza"
    fi
    rm -rf "$tmp"
}

_ndbash_install_fastfetch() {
    command -v fastfetch &>/dev/null && return
    echo "Installing fastfetch..."
    if _ndbash_privileged apt-get install -y fastfetch 2>/dev/null && command -v fastfetch &>/dev/null; then
        return
    fi
    local target tmp
    case "$(dpkg --print-architecture)" in
        amd64) target="amd64" ;;
        arm64) target="aarch64" ;;
        *) echo "Unsupported arch for fastfetch auto-install; install manually: https://github.com/fastfetch-cli/fastfetch"; return ;;
    esac
    tmp=$(mktemp -d)
    if curl -fsSL "https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-${target}.deb" -o "$tmp/fastfetch.deb"; then
        _ndbash_privileged dpkg -i "$tmp/fastfetch.deb" || _ndbash_privileged apt-get install -f -y
    else
        echo "Could not download fastfetch; install manually: https://github.com/fastfetch-cli/fastfetch"
    fi
    rm -rf "$tmp"
}

_ndbash_install_firacode_nerd_font() {
    local font_dir="$HOME/.local/share/fonts/FiraCodeNerdFont"
    compgen -G "$font_dir/*.ttf" &>/dev/null && return
    echo "Installing FiraCode Nerd Font..."
    mkdir -p "$font_dir"
    local tmp
    tmp=$(mktemp -d)
    if curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip" -o "$tmp/FiraCode.zip"; then
        unzip -oq "$tmp/FiraCode.zip" -d "$font_dir"
        fc-cache -f "$font_dir" &>/dev/null
    else
        echo "Could not download FiraCode Nerd Font; install manually: https://www.nerdfonts.com/font-downloads"
    fi
    rm -rf "$tmp"
}

_ndbash_apt_install curl git unzip fontconfig
_ndbash_install_starship
_ndbash_install_zoxide
_ndbash_install_eza
_ndbash_install_fastfetch
_ndbash_install_firacode_nerd_font
unset -f _ndbash_privileged _ndbash_apt_install _ndbash_install_starship _ndbash_install_zoxide _ndbash_install_eza _ndbash_install_fastfetch _ndbash_install_firacode_nerd_font

# ============================================================================
# Prompt & Display
# ============================================================================

# Initialize Starship with custom theme
export STARSHIP_CONFIG="$NDBASH_DIR/starship.toml"
if command -v starship &>/dev/null; then
    eval "$(starship init bash)"
fi

# Initialize zoxide for smart directory jumping
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init bash)"
fi

# Display system info on startup
NDBASH_FASTFETCH_CONFIG="$NDBASH_DIR/fastfetch-config.jsonc"
if command -v fastfetch &>/dev/null; then
    if [[ -f "$NDBASH_FASTFETCH_CONFIG" ]]; then
        fastfetch --config "$NDBASH_FASTFETCH_CONFIG"
    else
        fastfetch
    fi
fi

# ============================================================================
# Readline Configuration (bash's PSReadLine equivalent)
# ============================================================================
HISTCONTROL=ignoredups:erasedups
HISTSIZE=5000
HISTFILESIZE=10000
shopt -s histappend
bind 'set show-all-if-ambiguous on'
bind '"\t": menu-complete'
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'
# Ctrl+D delete-char-or-exit is bash's default behavior already.

# ============================================================================
# Git Aliases & Functions
# ============================================================================
g() { git "$@"; }
alias gs='git status'
alias gl='git log'
alias gp='git push'
alias gpl='git pull'
alias gc='git commit'
alias gco='git checkout'
alias ga='git add'
alias gd='git diff'
alias gb='git branch'

# Git branch switcher with filtering
gbb() {
    local pattern="${1:-}"
    local branches=()
    mapfile -t branches < <(git branch --list "*${pattern}*" | sed 's/^[* ]*//')
    if [[ ${#branches[@]} -eq 1 ]]; then
        git checkout "${branches[0]}"
    elif [[ ${#branches[@]} -gt 1 ]]; then
        if command -v fzf &>/dev/null; then
            local selected
            selected=$(printf '%s\n' "${branches[@]}" | fzf --prompt="Select branch> ")
            [[ -n "$selected" ]] && git checkout "$selected"
        else
            local b
            select b in "${branches[@]}"; do
                [[ -n "$b" ]] && git checkout "$b"
                break
            done
        fi
    else
        echo "No branches found matching: $pattern"
    fi
}

# ============================================================================
# Directory Navigation
# ============================================================================
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Quick repo navigation
repo() {
    local repo_base="${NDBASH_REPO_BASE:-$HOME/Repos}"
    [[ -z "${NDBASH_REPO_BASE:-}" && -d /mnt/d/Documents/Repos ]] && repo_base="/mnt/d/Documents/Repos"
    if [[ -n "$1" ]]; then
        if [[ -d "$repo_base/$1" ]]; then
            cd "$repo_base/$1" || return
        else
            echo "Repo not found: $1"
        fi
    else
        cd "$repo_base" || return
        ls -d */
    fi
}

# ============================================================================
# Node.js & npm Utilities
# ============================================================================
npm-scripts() {
    if [[ -f package.json ]]; then
        if command -v jq &>/dev/null; then
            jq '.scripts' package.json
        else
            node -e "console.log(JSON.stringify(require('./package.json').scripts, null, 2))"
        fi
    else
        echo "No package.json found"
    fi
}

nr() {
    if [[ -n "$1" ]]; then npm run "$1"; else npm run; fi
}

# ============================================================================
# General Utilities
# ============================================================================
if command -v eza &>/dev/null; then
    alias ll='eza -l --icons --group-directories-first'
    alias la='eza -la --icons --group-directories-first'
    alias ls='eza --icons --group-directories-first'
else
    alias ll='ls -alF'
    alias la='ls -A'
fi
alias c='clear'

# Create and enter new directory
mkcd() { mkdir -p "$1" && cd "$1" || return; }

# Update file timestamp (touch, Unix-native but kept for naming parity)
filestamp() { touch "$1"; }

# Search command history
history-search() { history | grep -i -- "$1" | tail -20; }

# Open current directory in VS Code
code-here() { code .; }

echo -e "\033[32m✓ Profile loaded successfully\033[0m"
