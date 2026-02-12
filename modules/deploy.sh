#!/bin/bash

# deploy.sh - Deployment module

show_deploy_help() {
    cat << 'EOF'
Usage: devops-cli deploy <subcommand> [options]

Deployment management commands

SUBCOMMANDS:
    app <name> [source]  Deploy application from source
    rollback <name>      Rollback to previous version
    status [name]        Check deployment status
    list                 List all deployments

OPTIONS:
    -h, --help          Show this help message

EXAMPLES:
    devops-cli deploy app myapp /path/to/source
    devops-cli deploy status myapp
    devops-cli deploy rollback myapp
    devops-cli deploy list
EOF
}

deploy_app() {
    local app_name="$1"
    local source_path="$2"
    
    validate_not_empty "$app_name" "Application name"
    
    local deploy_dir
    deploy_dir=$(get_config "deploy_dir")
    local app_deploy_dir="$deploy_dir/$app_name"
    
    log_command "deploy app $app_name $source_path"
    print_info "Deploying application: $app_name"
    
    # Create deployment directory
    if [[ ! -d "$deploy_dir" ]]; then
        sudo mkdir -p "$deploy_dir" || die "Failed to create deployment directory" 1
    fi
    
    # Backup current deployment if exists
    if [[ -d "$app_deploy_dir" ]]; then
        local backup_name="${app_name}_$(date +%Y%m%d_%H%M%S)"
        print_info "Backing up current deployment to: $backup_name"
        sudo mv "$app_deploy_dir" "${app_deploy_dir}.backup.${backup_name}" || \
            print_warning "Failed to backup current deployment"
        log_info "Backed up deployment: $backup_name"
    fi
    
    # Deploy new version
    if [[ -n "$source_path" ]]; then
        validate_dir_exists "$source_path"
        print_info "Copying from source: $source_path"
        sudo cp -r "$source_path" "$app_deploy_dir" || die "Failed to copy application files" 1
    else
        sudo mkdir -p "$app_deploy_dir" || die "Failed to create deployment directory" 1
        print_info "Created deployment directory: $app_deploy_dir"
    fi
    
    # Set permissions
    sudo chown -R www-data:www-data "$app_deploy_dir" 2>/dev/null || \
        print_warning "Could not set www-data ownership"
    
    print_success "Application $app_name deployed successfully to $app_deploy_dir"
    log_info "Deployed application: $app_name to $app_deploy_dir"
}

deploy_rollback() {
    local app_name="$1"
    validate_not_empty "$app_name" "Application name"
    
    local deploy_dir
    deploy_dir=$(get_config "deploy_dir")
    local app_deploy_dir="$deploy_dir/$app_name"
    
    log_command "deploy rollback $app_name"
    
    # Find latest backup
    local latest_backup
    latest_backup=$(find "$deploy_dir" -maxdepth 1 -name "${app_name}.backup.*" -type d | sort -r | head -1)
    
    if [[ -z "$latest_backup" ]]; then
        die "No backup found for application: $app_name" 1
    fi
    
    print_info "Found backup: $(basename "$latest_backup")"
    
    if ! confirm_action "Rollback $app_name to this backup?"; then
        print_info "Rollback cancelled"
        return 0
    fi
    
    # Remove current deployment
    if [[ -d "$app_deploy_dir" ]]; then
        sudo rm -rf "$app_deploy_dir" || die "Failed to remove current deployment" 1
    fi
    
    # Restore backup
    sudo mv "$latest_backup" "$app_deploy_dir" || die "Failed to restore backup" 1
    
    print_success "Application $app_name rolled back successfully"
    log_info "Rolled back application: $app_name"
}

deploy_status() {
    local app_name="$1"
    local deploy_dir
    deploy_dir=$(get_config "deploy_dir")
    
    log_command "deploy status $app_name"
    
    if [[ -n "$app_name" ]]; then
        local app_deploy_dir="$deploy_dir/$app_name"
        
        if [[ -d "$app_deploy_dir" ]]; then
            print_success "Application $app_name is deployed"
            echo "Location: $app_deploy_dir"
            echo "Size: $(du -sh "$app_deploy_dir" 2>/dev/null | cut -f1)"
            echo "Modified: $(stat -c %y "$app_deploy_dir" 2>/dev/null || stat -f %Sm "$app_deploy_dir" 2>/dev/null)"
            
            # Check for backups
            local backup_count
            backup_count=$(find "$deploy_dir" -maxdepth 1 -name "${app_name}.backup.*" -type d 2>/dev/null | wc -l)
            echo "Backups available: $backup_count"
        else
            print_warning "Application $app_name is not deployed"
        fi
    else
        print_info "All deployments in $deploy_dir:"
        if [[ -d "$deploy_dir" ]]; then
            ls -lh "$deploy_dir" 2>/dev/null | grep -v "backup" || print_info "No deployments found"
        else
            print_info "No deployments found"
        fi
    fi
}

deploy_list() {
    local deploy_dir
    deploy_dir=$(get_config "deploy_dir")
    
    log_command "deploy list"
    print_info "Deployed applications:"
    
    if [[ -d "$deploy_dir" ]]; then
        local count=0
        for app in "$deploy_dir"/*; do
            if [[ -d "$app" ]] && [[ ! "$(basename "$app")" =~ \.backup\. ]]; then
                echo "  - $(basename "$app")"
                ((count++))
            fi
        done
        
        if [[ $count -eq 0 ]]; then
            print_info "No applications deployed"
        else
            echo ""
            print_info "Total: $count application(s)"
        fi
    else
        print_info "No deployment directory found"
    fi
}

# Main deploy command handler
handle_deploy_command() {
    local subcommand="$1"
    shift
    
    case "$subcommand" in
        app)
            deploy_app "$@"
            ;;
        rollback)
            deploy_rollback "$@"
            ;;
        status)
            deploy_status "$@"
            ;;
        list)
            deploy_list
            ;;
        -h|--help|help|"")
            show_deploy_help
            ;;
        *)
            print_error "Unknown subcommand: $subcommand"
            echo ""
            show_deploy_help
            exit 1
            ;;
    esac
}
