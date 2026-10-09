#!/usr/bin/env bash
#
# link.sh - Stow-like symlink manager for succulent dotfiles
#
# Symlinks:
#   .config/*    -> ~/.config/*
#   .local/bin/* -> ~/.local/bin/*
#

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="${HOME:-}"

if [ -z "$HOME_DIR" ]; then
    echo "Error: HOME environment variable is not set." >&2
    exit 1
fi

# Terminal colors (enabled if stdout is a TTY)
if [ -t 1 ]; then
    GREEN="\033[0;32m"
    YELLOW="\033[0;33m"
    BLUE="\033[0;34m"
    RED="\033[0;31m"
    GRAY="\033[0;90m"
    BOLD="\033[1m"
    RESET="\033[0m"
else
    GREEN=""
    YELLOW=""
    BLUE=""
    RED=""
    GRAY=""
    BOLD=""
    RESET=""
fi

MODE="link"
DRY_RUN=false

usage() {
    cat <<EOF
${BOLD}Usage:${RESET} $(basename "$0") [OPTIONS]

Stow-like symlink manager tailored for this repository.

${BOLD}Options:${RESET}
  -h, --help       Show this help message
  -d, -D, --delete Remove managed symlinks (stow -D style)
  -n, --dry-run    Preview changes without modifying the filesystem
  -R, --restow     Unlink and then re-link all items

${BOLD}Targets:${RESET}
  $DOTFILES_DIR/.config/*    -> ~/.config/*
  $DOTFILES_DIR/.local/bin/* -> ~/.local/bin/*
EOF
}

# Parse command line flags
while [ "$#" -gt 0 ]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        -d|-D|--delete|--unlink)
            MODE="delete"
            shift
            ;;
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -R|--restow)
            MODE="restow"
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${RESET}" >&2
            usage
            exit 1
            ;;
    esac
done

# Format paths with ~ for tidy logging
format_path() {
    local path="$1"
    if [[ "$path" == "$HOME_DIR"* ]]; then
        echo "~${path#"$HOME_DIR"}"
    else
        echo "$path"
    fi
}

# Safely back up existing files or folders before replacing with a symlink
backup_target() {
    local target="$1"
    local backup="${target}.bak"

    if [ -e "$backup" ] || [ -L "$backup" ]; then
        backup="${target}.bak.$(date +%Y%m%d%H%M%S)"
    fi

    echo -e "  ${YELLOW}! Backing up existing item:${RESET} $(format_path "$target") -> $(format_path "$backup")"
    if [ "$DRY_RUN" = false ]; then
        mv "$target" "$backup"
    fi
}

link_item() {
    local src="$1"
    local dst="$2"
    local display_dst
    display_dst="$(format_path "$dst")"
    local display_src
    display_src="$(format_path "$src")"

    # Already a symlink
    if [ -L "$dst" ]; then
        local current_target
        current_target="$(readlink "$dst")"
        if [ "$current_target" = "$src" ]; then
            echo -e "  ${GRAY}✓ Already linked:${RESET} $display_dst -> $display_src"
            return 0
        else
            echo -e "  ${YELLOW}↻ Updating symlink:${RESET} $display_dst -> $display_src (was $current_target)"
            if [ "$DRY_RUN" = false ]; then
                rm "$dst"
                ln -s "$src" "$dst"
            fi
            return 0
        fi
    fi

    # Existing real file or directory
    if [ -e "$dst" ]; then
        backup_target "$dst"
    fi

    echo -e "  ${GREEN}+ Linking:${RESET} $display_dst -> $display_src"
    if [ "$DRY_RUN" = false ]; then
        ln -s "$src" "$dst"
    fi
}

unlink_item() {
    local src="$1"
    local dst="$2"
    local display_dst
    display_dst="$(format_path "$dst")"

    if [ -L "$dst" ]; then
        local current_target
        current_target="$(readlink "$dst")"
        if [ "$current_target" = "$src" ]; then
            echo -e "  ${RED}- Removing symlink:${RESET} $display_dst"
            if [ "$DRY_RUN" = false ]; then
                rm "$dst"
            fi
        else
            echo -e "  ${GRAY}• Skipping symlink pointing elsewhere:${RESET} $display_dst -> $current_target"
        fi
    elif [ -e "$dst" ]; then
        echo -e "  ${GRAY}• Skipping non-symlink:${RESET} $display_dst"
    else
        echo -e "  ${GRAY}• Does not exist:${RESET} $display_dst"
    fi
}

process_mapping() {
    local src_dir="$1"
    local dst_dir="$2"
    local action="$3"

    if [ ! -d "$src_dir" ]; then
        return 0
    fi

    echo -e "${BOLD}${BLUE}==> Target: $(format_path "$dst_dir")${RESET}"

    if [ "$action" = "link" ]; then
        if [ ! -d "$dst_dir" ]; then
            echo -e "  ${GREEN}* Creating directory:${RESET} $(format_path "$dst_dir")"
            if [ "$DRY_RUN" = false ]; then
                mkdir -p "$dst_dir"
            fi
        fi
    fi

    shopt -s nullglob
    local items=("$src_dir"/*)
    shopt -u nullglob

    if [ "${#items[@]}" -eq 0 ]; then
        echo -e "  ${GRAY}(no items found in $(format_path "$src_dir"))${RESET}"
        return 0
    fi

    for src_item in "${items[@]}"; do
        local base_name
        base_name="$(basename "$src_item")"

        # Ignore OS metadata
        if [ "$base_name" = ".DS_Store" ]; then
            continue
        fi

        local dst_item="$dst_dir/$base_name"

        if [ "$action" = "link" ]; then
            link_item "$src_item" "$dst_item"
        elif [ "$action" = "delete" ]; then
            unlink_item "$src_item" "$dst_item"
        fi
    done
}

run() {
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}${BOLD}[DRY RUN] No files will be modified.${RESET}\n"
    fi

    local mappings=(
        "$DOTFILES_DIR/.config:$HOME_DIR/.config"
        "$DOTFILES_DIR/.local/bin:$HOME_DIR/.local/bin"
    )

    if [ "$MODE" = "restow" ]; then
        echo -e "${BOLD}Unlinking previous dotfiles...${RESET}"
        for mapping in "${mappings[@]}"; do
            local src="${mapping%%:*}"
            local dst="${mapping#*:}"
            process_mapping "$src" "$dst" "delete"
        done
        echo ""
        echo -e "${BOLD}Re-linking dotfiles...${RESET}"
        for mapping in "${mappings[@]}"; do
            local src="${mapping%%:*}"
            local dst="${mapping#*:}"
            process_mapping "$src" "$dst" "link"
        done
    else
        for mapping in "${mappings[@]}"; do
            local src="${mapping%%:*}"
            local dst="${mapping#*:}"
            process_mapping "$src" "$dst" "$MODE"
        done
    fi

    echo -e "\n${BOLD}${GREEN}Done!${RESET}"
}

run
