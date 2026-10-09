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

MODE="link"
DRY_RUN=false

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Stow-like symlink manager tailored for this repository.

Options:
  -h, --help       Show this help message
  -d, -D, --delete Remove managed symlinks (stow -D style)
  -n, --dry-run    Preview changes without modifying the filesystem
  -R, --restow     Unlink and then re-link all items

Targets:
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
            echo "Unknown option: $1" >&2
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
            echo "  [ok]     $display_dst -> $display_src"
            return 0
        else
            echo "  [update] $display_dst -> $display_src (was $current_target)"
            if [ "$DRY_RUN" = false ]; then
                rm "$dst"
                ln -s "$src" "$dst"
            fi
            return 0
        fi
    fi

    # Existing real file or directory to replace
    if [ -e "$dst" ]; then
        echo "  [link]   $display_dst -> $display_src"
        if [ "$DRY_RUN" = false ]; then
            rm -rf "$dst"
            ln -s "$src" "$dst"
        fi
        return 0
    fi

    # Destination does not exist
    echo "  [link]   $display_dst -> $display_src"
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
            echo "  [unlink] $display_dst"
            if [ "$DRY_RUN" = false ]; then
                rm "$dst"
            fi
        else
            echo "  [skip]   symlink pointing elsewhere: $display_dst -> $current_target"
        fi
    elif [ -e "$dst" ]; then
        echo "  [skip]   non-symlink: $display_dst"
    else
        echo "  [skip]   does not exist: $display_dst"
    fi
}

process_mapping() {
    local src_dir="$1"
    local dst_dir="$2"
    local action="$3"

    if [ ! -d "$src_dir" ]; then
        return 0
    fi

    echo "==> Target: $(format_path "$dst_dir")"

    if [ "$action" = "link" ]; then
        if [ ! -d "$dst_dir" ]; then
            echo "  [dir]    $(format_path "$dst_dir")"
            if [ "$DRY_RUN" = false ]; then
                mkdir -p "$dst_dir"
            fi
        fi
    fi

    shopt -s nullglob
    local items=("$src_dir"/*)
    shopt -u nullglob

    if [ "${#items[@]}" -eq 0 ]; then
        echo "  (no items found in $(format_path "$src_dir"))"
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
        echo "[DRY RUN] No files will be modified."
        echo ""
    fi

    local mappings=(
        "$DOTFILES_DIR/.config:$HOME_DIR/.config"
        "$DOTFILES_DIR/.local/bin:$HOME_DIR/.local/bin"
    )

    if [ "$MODE" = "restow" ]; then
        echo "Unlinking previous dotfiles..."
        for mapping in "${mappings[@]}"; do
            local src="${mapping%%:*}"
            local dst="${mapping#*:}"
            process_mapping "$src" "$dst" "delete"
        done
        echo ""
        echo "Re-linking dotfiles..."
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

    echo ""
    echo "Done!"
}

run
