#!/bin/bash

# backup.sh - Backup operations module

show_backup_help() {
    cat << 'EOF'
Usage: devops-cli backup <subcommand> [options]

Backup management commands

SUBCOMMANDS:
    create <name> <path>  Create a new backup
    restore <name> <dest> Restore from backup
    list                  List available backups
    delete <name>         Delete a backup

OPTIONS:
    -h, --help           Show this help message

EXAMPLES:
    devops-cli backup create mydb /var/lib/mysql
    devops-cli backup restore mydb_20260212 /var/lib/mysql
    devops-cli backup list
    devops-cli backup delete mydb_20260212
EOF
}

backup_create() {
    local backup_name="$1"
    local source_path="$2"
    
    validate_not_empty "$backup_name" "Backup name"
    validate_not_empty "$source_path" "Source path"
    validate_dir_exists "$source_path"
    
    local backup_dir
    backup_dir=$(get_config "backup_dir")
    
    # Create backup directory if needed
    if [[ ! -d "$backup_dir" ]]; then
        mkdir -p "$backup_dir" || die "Failed to create backup directory" 1
    fi
    
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$backup_dir/${backup_name}_${timestamp}.tar.gz"
    
    log_command "backup create $backup_name $source_path"
    print_info "Creating backup: $backup_name"
    print_info "Source: $source_path"
    print_info "Destination: $backup_file"
    
    # Create compressed backup
    if tar -czf "$backup_file" -C "$(dirname "$source_path")" "$(basename "$source_path")" 2>/dev/null; then
        local size
        size=$(du -h "$backup_file" | cut -f1)
        print_success "Backup created successfully"
        echo "Backup file: $backup_file"
        echo "Size: $size"
        log_info "Created backup: $backup_file ($size)"
    else
        die "Failed to create backup" 1
    fi
}

backup_restore() {
    local backup_name="$1"
    local dest_path="$2"
    
    validate_not_empty "$backup_name" "Backup name"
    validate_not_empty "$dest_path" "Destination path"
    
    local backup_dir
    backup_dir=$(get_config "backup_dir")
    local backup_file="$backup_dir/${backup_name}.tar.gz"
    
    # If exact name not found, try to find matching backup
    if [[ ! -f "$backup_file" ]]; then
        backup_file=$(find "$backup_dir" -name "${backup_name}*.tar.gz" | head -1)
        if [[ -z "$backup_file" ]]; then
            die "Backup not found: $backup_name" 1
        fi
    fi
    
    log_command "backup restore $backup_name $dest_path"
    print_info "Restoring backup: $(basename "$backup_file")"
    print_info "Destination: $dest_path"
    
    if ! confirm_action "This will overwrite existing files. Continue?"; then
        print_info "Restore cancelled"
        return 0
    fi
    
    # Create destination directory if needed
    mkdir -p "$dest_path" || die "Failed to create destination directory" 1
    
    # Extract backup
    if tar -xzf "$backup_file" -C "$dest_path" 2>/dev/null; then
        print_success "Backup restored successfully to $dest_path"
        log_info "Restored backup: $backup_file to $dest_path"
    else
        die "Failed to restore backup" 1
    fi
}

backup_list() {
    local backup_dir
    backup_dir=$(get_config "backup_dir")
    
    log_command "backup list"
    print_info "Available backups in $backup_dir:"
    
    if [[ ! -d "$backup_dir" ]]; then
        print_info "No backup directory found"
        return 0
    fi
    
    local count=0
    while IFS= read -r backup; do
        if [[ -f "$backup" ]]; then
            local name size mtime
            name=$(basename "$backup")
            size=$(du -h "$backup" | cut -f1)
            mtime=$(stat -c %y "$backup" 2>/dev/null | cut -d'.' -f1 || stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$backup" 2>/dev/null)
            
            echo "  $name"
            echo "    Size: $size"
            echo "    Created: $mtime"
            echo ""
            ((count++))
        fi
    done < <(find "$backup_dir" -name "*.tar.gz" -type f | sort -r)
    
    if [[ $count -eq 0 ]]; then
        print_info "No backups found"
    else
        print_info "Total: $count backup(s)"
    fi
}

backup_delete() {
    local backup_name="$1"
    validate_not_empty "$backup_name" "Backup name"
    
    local backup_dir
    backup_dir=$(get_config "backup_dir")
    local backup_file="$backup_dir/${backup_name}.tar.gz"
    
    # If exact name not found, try to find matching backup
    if [[ ! -f "$backup_file" ]]; then
        backup_file=$(find "$backup_dir" -name "${backup_name}*.tar.gz" | head -1)
        if [[ -z "$backup_file" ]]; then
            die "Backup not found: $backup_name" 1
        fi
    fi
    
    log_command "backup delete $backup_name"
    print_warning "Deleting backup: $(basename "$backup_file")"
    
    if ! confirm_action "Are you sure you want to delete this backup?"; then
        print_info "Delete cancelled"
        return 0
    fi
    
    if rm -f "$backup_file"; then
        print_success "Backup deleted successfully"
        log_info "Deleted backup: $backup_file"
    else
        die "Failed to delete backup" 1
    fi
}

# Main backup command handler
handle_backup_command() {
    local subcommand="$1"
    shift
    
    case "$subcommand" in
        create)
            backup_create "$@"
            ;;
        restore)
            backup_restore "$@"
            ;;
        list)
            backup_list
            ;;
        delete)
            backup_delete "$@"
            ;;
        -h|--help|help|"")
            show_backup_help
            ;;
        *)
            print_error "Unknown subcommand: $subcommand"
            echo ""
            show_backup_help
            exit 1
            ;;
    esac
}
