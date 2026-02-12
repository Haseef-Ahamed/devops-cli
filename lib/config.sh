#!/bin/bash

# config.sh - Configuration management for DevOps CLI

# Configuration file location
readonly CONFIG_DIR="$HOME/.devops-cli"
readonly CONFIG_FILE="$CONFIG_DIR/config"

# Default configuration values
declare -A DEFAULT_CONFIG=(
    [log_level]="INFO"
    [backup_dir]="$HOME/.devops-cli/backups"
    [deploy_dir]="/var/www"
    [server_timeout]="30"
    [monitor_interval]="5"
    [log_retention_days]="30"
)

# Current configuration (loaded from file)
declare -A CONFIG

# Initialize configuration system
init_config() {
    # Create config directory if it doesn't exist
    if [[ ! -d "$CONFIG_DIR" ]]; then
        mkdir -p "$CONFIG_DIR" 2>/dev/null || {
            print_error "Could not create config directory: $CONFIG_DIR"
            return 1
        }
    fi
    
    # Create default config file if it doesn't exist
    if [[ ! -f "$CONFIG_FILE" ]]; then
        create_default_config
    fi
    
    # Load configuration
    load_config
}

# Create default configuration file
create_default_config() {
    cat > "$CONFIG_FILE" << 'EOF'
# DevOps CLI Configuration File
# Edit this file to customize your DevOps CLI settings

# Logging configuration
log_level=INFO

# Backup configuration
backup_dir=$HOME/.devops-cli/backups

# Deployment configuration
deploy_dir=/var/www

# Server configuration
server_timeout=30

# Monitoring configuration
monitor_interval=5

# Log retention (days)
log_retention_days=30
EOF
    
    log_info "Created default configuration file: $CONFIG_FILE"
}

# Load configuration from file
load_config() {
    # Start with defaults
    for key in "${!DEFAULT_CONFIG[@]}"; do
        CONFIG[$key]="${DEFAULT_CONFIG[$key]}"
    done
    
    # Override with values from config file
    if [[ -f "$CONFIG_FILE" ]]; then
        while IFS='=' read -r key value; do
            # Skip comments and empty lines
            [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
            
            # Trim whitespace
            key=$(echo "$key" | xargs)
            value=$(echo "$value" | xargs)
            
            # Expand variables in value
            value=$(eval echo "$value")
            
            CONFIG[$key]="$value"
        done < "$CONFIG_FILE"
    fi
    
    log_debug "Configuration loaded from $CONFIG_FILE"
}

# Get configuration value
get_config() {
    local key="$1"
    local default="${2:-}"
    
    if [[ -n "${CONFIG[$key]}" ]]; then
        echo "${CONFIG[$key]}"
    elif [[ -n "$default" ]]; then
        echo "$default"
    else
        echo "${DEFAULT_CONFIG[$key]}"
    fi
}

# Set configuration value
set_config() {
    local key="$1"
    local value="$2"
    
    # Update in-memory config
    CONFIG[$key]="$value"
    
    # Update config file
    if [[ -f "$CONFIG_FILE" ]]; then
        # Check if key exists in file
        if grep -q "^${key}=" "$CONFIG_FILE"; then
            # Update existing key
            sed -i.bak "s|^${key}=.*|${key}=${value}|" "$CONFIG_FILE"
        else
            # Add new key
            echo "${key}=${value}" >> "$CONFIG_FILE"
        fi
        rm -f "${CONFIG_FILE}.bak"
        log_info "Configuration updated: $key=$value"
    else
        print_error "Configuration file not found: $CONFIG_FILE"
        return 1
    fi
}

# Show all configuration
show_config() {
    print_info "Current Configuration:"
    echo "======================"
    
    for key in "${!CONFIG[@]}"; do
        echo "$key = ${CONFIG[$key]}"
    done | sort
    
    echo ""
    echo "Config file: $CONFIG_FILE"
}

# Reset configuration to defaults
reset_config() {
    if confirm_action "Reset configuration to defaults?"; then
        create_default_config
        load_config
        print_success "Configuration reset to defaults"
        log_info "Configuration reset to defaults"
    fi
}

# Validate configuration
validate_config() {
    local errors=0
    
    # Validate log level
    local log_level
    log_level=$(get_config "log_level")
    if [[ ! "$log_level" =~ ^(DEBUG|INFO|WARN|ERROR)$ ]]; then
        print_error "Invalid log_level: $log_level"
        ((errors++))
    fi
    
    # Validate numeric values
    local server_timeout
    server_timeout=$(get_config "server_timeout")
    if ! [[ "$server_timeout" =~ ^[0-9]+$ ]]; then
        print_error "Invalid server_timeout: $server_timeout (must be numeric)"
        ((errors++))
    fi
    
    local monitor_interval
    monitor_interval=$(get_config "monitor_interval")
    if ! [[ "$monitor_interval" =~ ^[0-9]+$ ]]; then
        print_error "Invalid monitor_interval: $monitor_interval (must be numeric)"
        ((errors++))
    fi
    
    if [[ $errors -eq 0 ]]; then
        print_success "Configuration is valid"
        return 0
    else
        print_error "Configuration has $errors error(s)"
        return 1
    fi
}

# Get config file path
get_config_file() {
    echo "$CONFIG_FILE"
}
