#!/bin/bash

# logs.sh - Log management module

show_logs_help() {
    cat << 'EOF'
Usage: devops-cli logs <subcommand> [options]

Log management commands

SUBCOMMANDS:
    view [file]          View logs with filtering
    tail [file]          Tail logs in real-time
    search <pattern>     Search logs for patterns
    rotate               Manually rotate logs
    clean [days]         Clean old logs

OPTIONS:
    -h, --help          Show this help message
    -n, --lines <num>   Number of lines to show
    -f, --follow        Follow log output

EXAMPLES:
    devops-cli logs view
    devops-cli logs tail /var/log/nginx/error.log
    devops-cli logs search "ERROR"
    devops-cli logs clean 30
EOF
}

logs_view() {
    local log_file="${1:-}"
    local lines="${2:-50}"
    
    # Default to devops-cli log if no file specified
    if [[ -z "$log_file" ]]; then
        log_file=$(get_log_file)
    fi
    
    log_command "logs view $log_file"
    
    if [[ ! -f "$log_file" ]]; then
        die "Log file not found: $log_file" 1
    fi
    
    print_info "Viewing last $lines lines of: $log_file"
    echo "========================================"
    
    tail -n "$lines" "$log_file"
}

logs_tail() {
    local log_file="${1:-}"
    
    # Default to devops-cli log if no file specified
    if [[ -z "$log_file" ]]; then
        log_file=$(get_log_file)
    fi
    
    log_command "logs tail $log_file"
    
    if [[ ! -f "$log_file" ]]; then
        die "Log file not found: $log_file" 1
    fi
    
    print_info "Tailing log file: $log_file (Ctrl+C to stop)"
    echo "========================================"
    
    tail -f "$log_file"
}

logs_search() {
    local pattern="${1:-}"
    local log_file="${2:-}"
    
    validate_not_empty "$pattern" "Search pattern"
    
    # Default to devops-cli log if no file specified
    if [[ -z "$log_file" ]]; then
        log_file=$(get_log_file)
    fi
    
    log_command "logs search $pattern $log_file"
    
    if [[ ! -f "$log_file" ]]; then
        die "Log file not found: $log_file" 1
    fi
    
    print_info "Searching for '$pattern' in: $log_file"
    echo "========================================"
    
    if grep --color=auto -i "$pattern" "$log_file"; then
        echo ""
        local count
        count=$(grep -ci "$pattern" "$log_file")
        print_success "Found $count match(es)"
    else
        print_warning "No matches found for: $pattern"
    fi
}

logs_rotate() {
    log_command "logs rotate"
    print_info "Manually rotating DevOps CLI logs"
    
    if confirm_action "Rotate logs now?"; then
        rotate_logs
        print_success "Log rotation completed"
    else
        print_info "Rotation cancelled"
    fi
}

logs_clean() {
    local days="${1:-30}"
    
    if ! [[ "$days" =~ ^[0-9]+$ ]]; then
        die "Invalid number of days: $days" 1
    fi
    
    log_command "logs clean $days"
    print_info "Cleaning logs older than $days days"
    
    if confirm_action "Delete logs older than $days days?"; then
        clean_old_logs "$days"
        print_success "Old logs cleaned"
    else
        print_info "Clean cancelled"
    fi
}

# Main logs command handler
handle_logs_command() {
    local subcommand="$1"
    shift
    
    # Parse options
    local lines=50
    local follow=false
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--lines)
                lines="$2"
                shift 2
                ;;
            -f|--follow)
                follow=true
                shift
                ;;
            -h|--help)
                show_logs_help
                return 0
                ;;
            *)
                break
                ;;
        esac
    done
    
    case "$subcommand" in
        view)
            logs_view "${1:-}" "$lines"
            ;;
        tail)
            logs_tail "${1:-}"
            ;;
        search)
            logs_search "${1:-}" "${2:-}"
            ;;
        rotate)
            logs_rotate
            ;;
        clean)
            logs_clean "${1:-}"
            ;;
        -h|--help|help|"")
            show_logs_help
            ;;
        *)
            print_error "Unknown subcommand: $subcommand"
            echo ""
            show_logs_help
            exit 1
            ;;
    esac
}
