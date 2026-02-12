#!/bin/bash

# helpers.sh - Common utility functions for DevOps CLI

# Color codes for terminal output
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_RESET='\033[0m'

# Print colored output
print_error() {
    echo -e "${COLOR_RED}ERROR: $1${COLOR_RESET}" >&2
}

print_success() {
    echo -e "${COLOR_GREEN}SUCCESS: $1${COLOR_RESET}"
}

print_warning() {
    echo -e "${COLOR_YELLOW}WARNING: $1${COLOR_RESET}"
}

print_info() {
    echo -e "${COLOR_BLUE}INFO: $1${COLOR_RESET}"
}

# Exit with error message
die() {
    print_error "$1"
    log_error "$1"
    exit "${2:-1}"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        die "This command requires root privileges. Please run with sudo." 1
    fi
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Validate required dependencies
check_dependencies() {
    local deps=("$@")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command_exists "$dep"; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        die "Missing required dependencies: ${missing[*]}" 1
    fi
}

# Validate input is not empty
validate_not_empty() {
    local value="$1"
    local field_name="$2"
    
    if [[ -z "$value" ]]; then
        die "$field_name cannot be empty" 1
    fi
}

# Validate file exists
validate_file_exists() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        die "File not found: $file" 1
    fi
}

# Validate directory exists
validate_dir_exists() {
    local dir="$1"
    
    if [[ ! -d "$dir" ]]; then
        die "Directory not found: $dir" 1
    fi
}

# Confirm action with user
confirm_action() {
    local prompt="$1"
    local response
    
    read -r -p "$prompt [y/N]: " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Get timestamp
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Format bytes to human readable
format_bytes() {
    local bytes=$1
    local units=("B" "KB" "MB" "GB" "TB")
    local unit=0
    
    while (( bytes > 1024 && unit < 4 )); do
        bytes=$((bytes / 1024))
        ((unit++))
    done
    
    echo "${bytes}${units[$unit]}"
}

# Check if port is in use
check_port() {
    local port=$1
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        return 0
    else
        return 1
    fi
}

# Sanitize input (remove special characters)
sanitize_input() {
    local input="$1"
    echo "$input" | sed 's/[^a-zA-Z0-9._-]//g'
}
