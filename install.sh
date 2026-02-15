#!/usr/bin/env bash
#
# UNSW CSE Scraper - AI Tool Integration Installer
#
# Auto-detects and installs skills for Claude Code, Cursor, Codex, Gemini CLI, and Windsurf
#
# Usage:
#   ./install.sh                    # Auto-detect and install
#   ./install.sh --target claude    # Install for specific tool
#   ./install.sh --target all       # Install for all detected tools
#   ./install.sh --uninstall        # Remove installations
#
# One-liner:
#   curl -fsSL https://raw.githubusercontent.com/Genius-Cai/unsw-cse-scraper/main/install.sh | bash
#

set -e

# Color codes (compatible with macOS bash 3.2+)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Emoji fallbacks for older terminals
CHECK="${GREEN}✓${NC}"
CROSS="${RED}✗${NC}"
ARROW="${BLUE}→${NC}"
INFO="${CYAN}ℹ${NC}"
WARN="${YELLOW}⚠${NC}"

# Global variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET=""
UNINSTALL=false
DETECTED_TOOLS=()
BACKUP_SUFFIX=".backup.$(date +%Y%m%d_%H%M%S)"

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --target)
                TARGET="$2"
                shift 2
                ;;
            --uninstall)
                UNINSTALL=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo -e "${CROSS} Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

show_help() {
    cat << EOF
${BOLD}UNSW CSE Scraper - AI Tool Integration Installer${NC}

${BOLD}Usage:${NC}
    $0 [OPTIONS]

${BOLD}Options:${NC}
    --target <tool>     Install for specific tool (claude|cursor|codex|gemini|windsurf|all)
    --uninstall         Remove all installations
    -h, --help          Show this help message

${BOLD}Examples:${NC}
    $0                          ${ARROW} Auto-detect and install
    $0 --target claude          ${ARROW} Install for Claude Code only
    $0 --target all             ${ARROW} Install for all detected tools
    $0 --uninstall              ${ARROW} Remove all installations

${BOLD}Supported Tools:${NC}
    • Claude Code   - ~/.claude/skills/unsw-cse/
    • Cursor        - .cursorrules in project root
    • Codex         - AGENTS.md in project root
    • Gemini CLI    - ~/.gemini/skills/unsw-cse/
    • Windsurf      - .windsurfrules in project root
EOF
}

# Print functions
print_header() {
    echo ""
    echo -e "${BOLD}${MAGENTA}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${MAGENTA}║${NC}  ${BOLD}UNSW CSE Scraper - AI Tool Integration${NC}         ${BOLD}${MAGENTA}║${NC}"
    echo -e "${BOLD}${MAGENTA}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_status() {
    echo -e "${1} ${2}"
}

print_success() {
    print_status "${CHECK}" "$1"
}

print_error() {
    print_status "${CROSS}" "$1"
}

print_info() {
    print_status "${INFO}" "$1"
}

print_warn() {
    print_status "${WARN}" "$1"
}

print_arrow() {
    print_status "${ARROW}" "$1"
}

# Detect installed AI tools
detect_tools() {
    print_info "Detecting installed AI tools..."
    echo ""

    # Claude Code
    if [[ -d "$HOME/.claude" ]]; then
        DETECTED_TOOLS+=("claude")
        print_success "Claude Code detected (~/.claude/)"
    fi

    # Cursor
    if command -v cursor &> /dev/null || [[ -d "$HOME/.cursor" ]] || [[ -d "/Applications/Cursor.app" ]]; then
        DETECTED_TOOLS+=("cursor")
        print_success "Cursor detected"
    fi

    # Codex
    if command -v codex &> /dev/null; then
        DETECTED_TOOLS+=("codex")
        print_success "Codex CLI detected"
    fi

    # Gemini
    if command -v gemini &> /dev/null || [[ -d "$HOME/.gemini" ]]; then
        DETECTED_TOOLS+=("gemini")
        print_success "Gemini CLI detected"
    fi

    # Windsurf
    if command -v windsurf &> /dev/null || [[ -d "$HOME/.windsurf" ]] || [[ -d "/Applications/Windsurf.app" ]]; then
        DETECTED_TOOLS+=("windsurf")
        print_success "Windsurf detected"
    fi

    echo ""

    if [[ ${#DETECTED_TOOLS[@]} -eq 0 ]]; then
        print_error "No AI tools detected!"
        print_info "Supported tools: Claude Code, Cursor, Codex, Gemini CLI, Windsurf"
        exit 1
    fi

    print_info "Found ${#DETECTED_TOOLS[@]} tool(s): ${DETECTED_TOOLS[*]}"
}

# Interactive menu
show_menu() {
    echo ""
    echo -e "${BOLD}Select installation target:${NC}"
    echo ""

    local i=1
    for tool in "${DETECTED_TOOLS[@]}"; do
        echo "  $i) $tool"
        ((i++))
    done
    echo "  $i) all (install for all detected tools)"
    echo "  0) cancel"
    echo ""

    while true; do
        read -p "Enter your choice [0-$i]: " choice

        if [[ "$choice" == "0" ]]; then
            print_info "Installation cancelled"
            exit 0
        elif [[ "$choice" == "$i" ]]; then
            TARGET="all"
            break
        elif [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -lt $i ]]; then
            TARGET="${DETECTED_TOOLS[$((choice-1))]}"
            break
        else
            print_error "Invalid choice. Please try again."
        fi
    done
}

# Backup file if exists
backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local backup="${file}${BACKUP_SUFFIX}"
        cp "$file" "$backup"
        print_info "Backed up existing file: $backup"
    fi
}

# Install for Claude Code
install_claude() {
    print_info "Installing for Claude Code..."

    local src="${SCRIPT_DIR}/skills/unsw-cse/SKILL.md"
    local dest="$HOME/.claude/skills/unsw-cse/SKILL.md"

    if [[ ! -f "$src" ]]; then
        print_error "Source file not found: $src"
        return 1
    fi

    # Create directory structure
    mkdir -p "$(dirname "$dest")"

    # Backup and copy
    backup_file "$dest"
    cp "$src" "$dest"

    print_success "Installed: $dest"
    print_arrow "Restart Claude Code or run: /skills reload"
}

# Install for Cursor
install_cursor() {
    print_info "Installing for Cursor..."

    local src="${SCRIPT_DIR}/.cursorrules"
    local dest="${SCRIPT_DIR}/.cursorrules"

    if [[ ! -f "$src" ]]; then
        print_error "Source file not found: $src"
        return 1
    fi

    # For Cursor, .cursorrules stays in project root
    # We just verify it exists
    if [[ -f "$dest" ]]; then
        print_success "Cursor rules already in place: $dest"
        print_arrow "Restart Cursor to reload configuration"
    else
        print_error ".cursorrules not found in project root"
        return 1
    fi
}

# Install for Codex
install_codex() {
    print_info "Installing for Codex..."

    local src="${SCRIPT_DIR}/AGENTS.md"
    local dest="${SCRIPT_DIR}/AGENTS.md"

    if [[ ! -f "$src" ]]; then
        print_error "Source file not found: $src"
        return 1
    fi

    # For Codex, AGENTS.md stays in project root
    if [[ -f "$dest" ]]; then
        print_success "Codex agents config already in place: $dest"
        print_arrow "Run: codex chat (in this directory)"
    else
        print_error "AGENTS.md not found in project root"
        return 1
    fi
}

# Install for Gemini
install_gemini() {
    print_info "Installing for Gemini CLI..."

    local src="${SCRIPT_DIR}/.gemini/SKILL.md"
    local dest="$HOME/.gemini/skills/unsw-cse/SKILL.md"

    if [[ ! -f "$src" ]]; then
        print_error "Source file not found: $src"
        return 1
    fi

    # Create directory structure
    mkdir -p "$(dirname "$dest")"

    # Backup and copy
    backup_file "$dest"
    cp "$src" "$dest"

    print_success "Installed: $dest"
    print_arrow "Restart Gemini CLI or reload skills"
}

# Install for Windsurf
install_windsurf() {
    print_info "Installing for Windsurf..."

    local src="${SCRIPT_DIR}/.cursorrules"
    local dest="${SCRIPT_DIR}/.windsurfrules"

    if [[ ! -f "$src" ]]; then
        print_error "Source file not found: $src"
        return 1
    fi

    # Copy .cursorrules to .windsurfrules
    backup_file "$dest"
    cp "$src" "$dest"

    print_success "Installed: $dest"
    print_arrow "Restart Windsurf to reload configuration"
}

# Uninstall for Claude Code
uninstall_claude() {
    local dest="$HOME/.claude/skills/unsw-cse/SKILL.md"
    if [[ -f "$dest" ]]; then
        rm -f "$dest"
        # Remove directory if empty
        rmdir "$(dirname "$dest")" 2>/dev/null || true
        print_success "Removed: $dest"
    else
        print_info "Not installed: $dest"
    fi
}

# Uninstall for Cursor
uninstall_cursor() {
    local dest="${SCRIPT_DIR}/.cursorrules"
    if [[ -f "$dest" ]]; then
        print_warn "Keeping project file: $dest"
        print_info "Manual removal required if desired"
    else
        print_info "Not installed: $dest"
    fi
}

# Uninstall for Codex
uninstall_codex() {
    local dest="${SCRIPT_DIR}/AGENTS.md"
    if [[ -f "$dest" ]]; then
        print_warn "Keeping project file: $dest"
        print_info "Manual removal required if desired"
    else
        print_info "Not installed: $dest"
    fi
}

# Uninstall for Gemini
uninstall_gemini() {
    local dest="$HOME/.gemini/skills/unsw-cse/SKILL.md"
    if [[ -f "$dest" ]]; then
        rm -f "$dest"
        # Remove directory if empty
        rmdir "$(dirname "$dest")" 2>/dev/null || true
        print_success "Removed: $dest"
    else
        print_info "Not installed: $dest"
    fi
}

# Uninstall for Windsurf
uninstall_windsurf() {
    local dest="${SCRIPT_DIR}/.windsurfrules"
    if [[ -f "$dest" ]]; then
        rm -f "$dest"
        print_success "Removed: $dest"
    else
        print_info "Not installed: $dest"
    fi
}

# Main installation logic
do_install() {
    local tool="$1"

    echo ""
    echo -e "${BOLD}${BLUE}Installing for: $tool${NC}"
    echo ""

    case "$tool" in
        claude)
            install_claude
            ;;
        cursor)
            install_cursor
            ;;
        codex)
            install_codex
            ;;
        gemini)
            install_gemini
            ;;
        windsurf)
            install_windsurf
            ;;
        *)
            print_error "Unknown tool: $tool"
            return 1
            ;;
    esac

    echo ""
}

# Main uninstallation logic
do_uninstall() {
    local tool="$1"

    echo ""
    echo -e "${BOLD}${YELLOW}Uninstalling for: $tool${NC}"
    echo ""

    case "$tool" in
        claude)
            uninstall_claude
            ;;
        cursor)
            uninstall_cursor
            ;;
        codex)
            uninstall_codex
            ;;
        gemini)
            uninstall_gemini
            ;;
        windsurf)
            uninstall_windsurf
            ;;
        *)
            print_error "Unknown tool: $tool"
            return 1
            ;;
    esac

    echo ""
}

# Main function
main() {
    parse_args "$@"

    print_header

    if [[ "$UNINSTALL" == true ]]; then
        print_warn "Starting uninstallation..."
        detect_tools

        if [[ -z "$TARGET" ]]; then
            # Uninstall from all detected tools
            for tool in "${DETECTED_TOOLS[@]}"; do
                do_uninstall "$tool"
            done
        elif [[ "$TARGET" == "all" ]]; then
            # Uninstall from all detected tools
            for tool in "${DETECTED_TOOLS[@]}"; do
                do_uninstall "$tool"
            done
        else
            # Uninstall from specific tool
            do_uninstall "$TARGET"
        fi

        echo ""
        print_success "${BOLD}Uninstallation complete!${NC}"
        echo ""
        exit 0
    fi

    # Detect installed tools
    detect_tools

    # Determine target
    if [[ -z "$TARGET" ]]; then
        if [[ ${#DETECTED_TOOLS[@]} -eq 1 ]]; then
            # Only one tool detected, auto-select
            TARGET="${DETECTED_TOOLS[0]}"
            print_info "Auto-selected: $TARGET"
        else
            # Multiple tools detected, show menu
            show_menu
        fi
    fi

    # Validate target
    if [[ "$TARGET" == "all" ]]; then
        # Install for all detected tools
        for tool in "${DETECTED_TOOLS[@]}"; do
            do_install "$tool"
        done
    else
        # Check if target is in detected tools
        local found=false
        for tool in "${DETECTED_TOOLS[@]}"; do
            if [[ "$tool" == "$TARGET" ]]; then
                found=true
                break
            fi
        done

        if [[ "$found" == false ]]; then
            print_error "Tool '$TARGET' not detected or not supported"
            print_info "Detected tools: ${DETECTED_TOOLS[*]}"
            exit 1
        fi

        # Install for specific tool
        do_install "$TARGET"
    fi

    # Success message
    echo ""
    echo -e "${BOLD}${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${GREEN}║${NC}  ${BOLD}Installation Complete!${NC}                            ${BOLD}${GREEN}║${NC}"
    echo -e "${BOLD}${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
    print_info "Next steps:"
    echo ""

    if [[ "$TARGET" == "all" ]] || [[ "$TARGET" == "claude" ]] && [[ " ${DETECTED_TOOLS[*]} " =~ " claude " ]]; then
        print_arrow "Claude Code: Run ${BOLD}/skills reload${NC} or restart"
    fi

    if [[ "$TARGET" == "all" ]] || [[ "$TARGET" == "cursor" ]] && [[ " ${DETECTED_TOOLS[*]} " =~ " cursor " ]]; then
        print_arrow "Cursor: Restart the editor"
    fi

    if [[ "$TARGET" == "all" ]] || [[ "$TARGET" == "codex" ]] && [[ " ${DETECTED_TOOLS[*]} " =~ " codex " ]]; then
        print_arrow "Codex: Run ${BOLD}codex chat${NC} in this directory"
    fi

    if [[ "$TARGET" == "all" ]] || [[ "$TARGET" == "gemini" ]] && [[ " ${DETECTED_TOOLS[*]} " =~ " gemini " ]]; then
        print_arrow "Gemini CLI: Restart or reload skills"
    fi

    if [[ "$TARGET" == "all" ]] || [[ "$TARGET" == "windsurf" ]] && [[ " ${DETECTED_TOOLS[*]} " =~ " windsurf " ]]; then
        print_arrow "Windsurf: Restart the editor"
    fi

    echo ""
    print_info "For help: ${BOLD}./install.sh --help${NC}"
    echo ""
}

# Run main function
main "$@"
