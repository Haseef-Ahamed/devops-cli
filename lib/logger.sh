#!/bin/bash

# logger.sh - Logging system with rotation for DevOps CLI

# Log configuration
readonly LOG_DIR="$HOME/.devops-cli/logs"
readonly LOG_FILE="$LOG_DIR/devops-cli.log"
readonly MAX_LOG_SIZE=$((10 * 1024 * 1024))  # 10MB
readonly MAX_LOG_FILES=5

# Log levels
readonly LOG_LEVEL_DEBUG=0
readonly LOG_LEVEL_INFO=1
readonly LOG_LEVEL_WARN=2
readonly LOG_LEVEL_ERROR=3

# Current log level (can be configured)
LOG_LEVEL=${LOG_LEVEL:-$LOG_LEVEL_INFO}

# Initialize logging system
init_logging() {
    # Create log directory if it doesn't exist
    if [[ ! -d "$LOG_DIR" ]]; then
        mkdir -p "$LOG_DIR" 2>/dev/null || {
            echo "WARNING: Could not create log directory: $LOG_DIR" >&2
            return 1
        }
    fi
    
    # Create log file if it doesn't exist
    if [[ ! -f "$LOG_FILE" ]]; then
        touch "$LOG_FILE" 2>/dev/null || {
            echo "WARNING: Could not create log file: $LOG_FILE" >&2
            return 1
        }
    fi
    
    # Check if rotation is needed
    check_log_rotation
}

# Check and perform log rotation if needed
check_log_rotation() {
    if [[ ! -f "$LOG_FILE" ]]; then
        return 0
    fi
    
    local log_size
    log_size=$(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)
    
    if [[ $log_size -ge $MAX_LOG_SIZE ]]; then
        rotate_logs
    fi
}

# Rotate log files
rotate_logs() {
    # Remove oldest log if we have max files
    if [[ -f "$LOG_FILE.$MAX_LOG_FILES" ]]; then
        rm -f "$LOG_FILE.$MAX_LOG_FILES"
    fi
    
    # Rotate existing logs
    for ((i = MAX_LOG_FILES - 1; i >= 1; i--)); do
        if [[ -f "$LOG_FILE.$i" ]]; then
            mv "$LOG_FILE.$i" "$LOG_FILE.$((i + 1))"
        fi
    done
    
    # Move current log to .1
    if [[ -f "$LOG_FILE" ]]; then
        mv "$LOG_FILE" "$LOG_FILE.1"
        touch "$LOG_FILE"
    fi
    
    log_info "Log rotation completed"
}

# Write log entry
write_log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Write to log file if available
    if [[ -w "$LOG_FILE" ]]; then
        echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
        check_log_rotation
    fi
}

# Log debug message
log_debug() {
    if [[ $LOG_LEVEL -le $LOG_LEVEL_DEBUG ]]; then
        write_log "DEBUG" "$1"
    fi
}

# Log info message
log_info() {
    if [[ $LOG_LEVEL -le $LOG_LEVEL_INFO ]]; then
        write_log "INFO" "$1"
    fi
}

# Log warning message
log_warn() {
    if [[ $LOG_LEVEL -le $LOG_LEVEL_WARN ]]; then
        write_log "WARN" "$1"
    fi
}

# Log error message
log_error() {
    if [[ $LOG_LEVEL -le $LOG_LEVEL_ERROR ]]; then
        write_log "ERROR" "$1"
    fi
}

# Log command execution
log_command() {
    local command="$1"
    log_info "Executing command: $command"
}

# Set log level from string
set_log_level() {
    case "${1^^}" in
        DEBUG)
            LOG_LEVEL=$LOG_LEVEL_DEBUG
            ;;
        INFO)
            LOG_LEVEL=$LOG_LEVEL_INFO
            ;;
        WARN|WARNING)
            LOG_LEVEL=$LOG_LEVEL_WARN
            ;;
        ERROR)
            LOG_LEVEL=$LOG_LEVEL_ERROR
            ;;
        *)
            echo "Invalid log level: $1" >&2
            return 1
            ;;
    esac
}

# Get log file path
get_log_file() {
    echo "$LOG_FILE"
}

# Clean old logs (manual cleanup)
clean_old_logs() {
    local days=${1:-30}
    find "$LOG_DIR" -name "devops-cli.log.*" -type f -mtime "+$days" -delete 2>/dev/null
    log_info "Cleaned logs older than $days days"
}
