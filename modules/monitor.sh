#!/bin/bash

# monitor.sh - System monitoring module

show_monitor_help() {
    cat << 'EOF'
Usage: devops-cli monitor <subcommand> [options]

System monitoring commands

SUBCOMMANDS:
    cpu                  Monitor CPU usage
    memory               Monitor memory usage
    disk                 Monitor disk usage
    network              Monitor network statistics
    services             Monitor service health

OPTIONS:
    -h, --help          Show this help message
    -w, --watch         Continuous monitoring mode

EXAMPLES:
    devops-cli monitor cpu
    devops-cli monitor memory --watch
    devops-cli monitor disk
    devops-cli monitor services
EOF
}

monitor_cpu() {
    local watch_mode=false
    
    if [[ "${1:-}" == "-w" || "${1:-}" == "--watch" ]]; then
        watch_mode=true
    fi
    
    log_command "monitor cpu"
    print_info "CPU Usage:"
    
    if $watch_mode; then
        local interval
        interval=$(get_config "monitor_interval")
        print_info "Watching CPU usage (Ctrl+C to stop, interval: ${interval}s)"
        
        while true; do
            clear
            echo "=== CPU Usage ($(get_timestamp)) ==="
            top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print "CPU Usage: " 100 - $1"%"}'
            echo ""
            top -bn1 | head -n 12
            sleep "$interval"
        done
    else
        top -bn1 | grep "Cpu(s)"
        echo ""
        print_info "Top CPU-consuming processes:"
        ps aux --sort=-%cpu | head -6
    fi
}

monitor_memory() {
    local watch_mode=false
    
    if [[ "${1:-}" == "-w" || "${1:-}" == "--watch" ]]; then
        watch_mode=true
    fi
    
    log_command "monitor memory"
    print_info "Memory Usage:"
    
    if $watch_mode; then
        local interval
        interval=$(get_config "monitor_interval")
        print_info "Watching memory usage (Ctrl+C to stop, interval: ${interval}s)"
        
        while true; do
            clear
            echo "=== Memory Usage ($(get_timestamp)) ==="
            free -h
            echo ""
            print_info "Top memory-consuming processes:"
            ps aux --sort=-%mem | head -6
            sleep "$interval"
        done
    else
        free -h
        echo ""
        print_info "Top memory-consuming processes:"
        ps aux --sort=-%mem | head -6
    fi
}

monitor_disk() {
    log_command "monitor disk"
    print_info "Disk Usage:"
    
    df -h | grep -v "tmpfs\|udev"
    
    echo ""
    print_info "Largest directories in /var:"
    du -sh /var/* 2>/dev/null | sort -rh | head -5
}

monitor_network() {
    local watch_mode=false
    
    if [[ "${1:-}" == "-w" || "${1:-}" == "--watch" ]]; then
        watch_mode=true
    fi
    
    log_command "monitor network"
    print_info "Network Statistics:"
    
    if $watch_mode; then
        local interval
        interval=$(get_config "monitor_interval")
        print_info "Watching network (Ctrl+C to stop, interval: ${interval}s)"
        
        while true; do
            clear
            echo "=== Network Statistics ($(get_timestamp)) ==="
            netstat -i 2>/dev/null || ip -s link
            echo ""
            print_info "Active connections:"
            netstat -tn 2>/dev/null | grep ESTABLISHED | wc -l
            sleep "$interval"
        done
    else
        netstat -i 2>/dev/null || ip -s link
        echo ""
        print_info "Active connections:"
        netstat -tn 2>/dev/null | grep ESTABLISHED | head -10
    fi
}

monitor_services() {
    log_command "monitor services"
    print_info "Service Health Check:"
    
    local services=("nginx" "apache2" "mysql" "postgresql" "redis-server" "mongodb" "docker")
    
    for service in "${services[@]}"; do
        if command_exists systemctl; then
            if systemctl is-active --quiet "$service" 2>/dev/null; then
                print_success "$service: Running"
            elif systemctl list-unit-files | grep -q "^${service}.service"; then
                print_warning "$service: Stopped"
            fi
        fi
    done
    
    echo ""
    print_info "All running services:"
    if command_exists systemctl; then
        systemctl list-units --type=service --state=running --no-pager | head -15
    else
        ps aux | grep -E 'nginx|apache|mysql|postgres|redis|mongo|docker' | grep -v grep
    fi
}

# Main monitor command handler
handle_monitor_command() {
    local subcommand="$1"
    shift
    
    case "$subcommand" in
        cpu)
            monitor_cpu "$@"
            ;;
        memory|mem)
            monitor_memory "$@"
            ;;
        disk)
            monitor_disk "$@"
            ;;
        network|net)
            monitor_network "$@"
            ;;
        services)
            monitor_services "$@"
            ;;
        -h|--help|help|"")
            show_monitor_help
            ;;
        *)
            print_error "Unknown subcommand: $subcommand"
            echo ""
            show_monitor_help
            exit 1
            ;;
    esac
}
