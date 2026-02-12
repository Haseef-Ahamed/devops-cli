#!/bin/bash

# server.sh - Server management module

show_server_help() {
    cat << 'EOF'
Usage: devops-cli server <subcommand> [options]

Server management commands

SUBCOMMANDS:
    start <service>      Start a server/service
    stop <service>       Stop a server/service
    restart <service>    Restart a server/service
    status [service]     Check server/service status
    list                 List available services

OPTIONS:
    -h, --help          Show this help message

EXAMPLES:
    devops-cli server start nginx
    devops-cli server status
    devops-cli server restart apache2
    devops-cli server list
EOF
}

server_start() {
    local service="$1"
    validate_not_empty "$service" "Service name"
    
    log_command "server start $service"
    print_info "Starting service: $service"
    
    if command_exists systemctl; then
        if sudo systemctl start "$service" 2>/dev/null; then
            print_success "Service $service started successfully"
            log_info "Service $service started"
        else
            die "Failed to start service: $service" 1
        fi
    elif command_exists service; then
        if sudo service "$service" start 2>/dev/null; then
            print_success "Service $service started successfully"
            log_info "Service $service started"
        else
            die "Failed to start service: $service" 1
        fi
    else
        die "No service management tool found (systemctl or service)" 1
    fi
}

server_stop() {
    local service="$1"
    validate_not_empty "$service" "Service name"
    
    log_command "server stop $service"
    
    if ! confirm_action "Stop service $service?"; then
        print_info "Operation cancelled"
        return 0
    fi
    
    print_info "Stopping service: $service"
    
    if command_exists systemctl; then
        if sudo systemctl stop "$service" 2>/dev/null; then
            print_success "Service $service stopped successfully"
            log_info "Service $service stopped"
        else
            die "Failed to stop service: $service" 1
        fi
    elif command_exists service; then
        if sudo service "$service" stop 2>/dev/null; then
            print_success "Service $service stopped successfully"
            log_info "Service $service stopped"
        else
            die "Failed to stop service: $service" 1
        fi
    else
        die "No service management tool found (systemctl or service)" 1
    fi
}

server_restart() {
    local service="$1"
    validate_not_empty "$service" "Service name"
    
    log_command "server restart $service"
    print_info "Restarting service: $service"
    
    if command_exists systemctl; then
        if sudo systemctl restart "$service" 2>/dev/null; then
            print_success "Service $service restarted successfully"
            log_info "Service $service restarted"
        else
            die "Failed to restart service: $service" 1
        fi
    elif command_exists service; then
        if sudo service "$service" restart 2>/dev/null; then
            print_success "Service $service restarted successfully"
            log_info "Service $service restarted"
        else
            die "Failed to restart service: $service" 1
        fi
    else
        die "No service management tool found (systemctl or service)" 1
    fi
}

server_status() {
    local service="$1"
    
    log_command "server status $service"
    
    if [[ -z "$service" ]]; then
        # Show all services status
        print_info "System services status:"
        if command_exists systemctl; then
            systemctl list-units --type=service --state=running
        else
            print_warning "systemctl not available, showing process list"
            ps aux | grep -E 'nginx|apache|mysql|postgresql|redis|mongodb' | grep -v grep
        fi
    else
        # Show specific service status
        print_info "Status for service: $service"
        if command_exists systemctl; then
            systemctl status "$service"
        elif command_exists service; then
            service "$service" status
        else
            die "No service management tool found (systemctl or service)" 1
        fi
    fi
}

server_list() {
    log_command "server list"
    print_info "Available services:"
    
    if command_exists systemctl; then
        systemctl list-unit-files --type=service | grep -E 'enabled|disabled' | head -20
        echo ""
        print_info "Showing first 20 services. Use 'systemctl list-unit-files' for full list."
    else
        print_warning "systemctl not available"
        print_info "Common services to manage: nginx, apache2, mysql, postgresql, redis-server, mongodb"
    fi
}

# Main server command handler
handle_server_command() {
    local subcommand="$1"
    shift
    
    case "$subcommand" in
        start)
            server_start "$@"
            ;;
        stop)
            server_stop "$@"
            ;;
        restart)
            server_restart "$@"
            ;;
        status)
            server_status "$@"
            ;;
        list)
            server_list
            ;;
        -h|--help|help|"")
            show_server_help
            ;;
        *)
            print_error "Unknown subcommand: $subcommand"
            echo ""
            show_server_help
            exit 1
            ;;
    esac
}
