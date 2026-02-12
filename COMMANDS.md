# DevOps CLI - Command Reference

A comprehensive command-line interface for DevOps operations providing unified access to server management, deployment, backup, monitoring, and log analysis.

## Table of Contents

- [Installation](#installation)
- [Configuration](#configuration)
- [Commands](#commands)
  - [Server Management](#server-management)
  - [Deployment](#deployment)
  - [Backup Operations](#backup-operations)
  - [System Monitoring](#system-monitoring)
  - [Log Management](#log-management)
  - [Configuration Management](#configuration-management)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)

## Installation

1. Clone or copy the `devops-cli` directory to your system
2. Make the main script executable:
   ```bash
   chmod +x devops-cli/devops-cli
   ```
3. Add to your PATH (optional):
   ```bash
   sudo ln -s /path/to/devops-cli/devops-cli /usr/local/bin/devops-cli
   ```

## Configuration

DevOps CLI stores its configuration in `~/.devops-cli/config`. The configuration file is created automatically on first run with default values.

### Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
| `log_level` | INFO | Logging level (DEBUG, INFO, WARN, ERROR) |
| `backup_dir` | ~/.devops-cli/backups | Directory for storing backups |
| `deploy_dir` | /var/www | Default deployment directory |
| `server_timeout` | 30 | Server operation timeout (seconds) |
| `monitor_interval` | 5 | Monitoring refresh interval (seconds) |
| `log_retention_days` | 30 | Days to retain old logs |

### Managing Configuration

```bash
# View current configuration
devops-cli config show

# Set a configuration value
devops-cli config set log_level DEBUG

# Validate configuration
devops-cli config validate

# Reset to defaults
devops-cli config reset

# Edit configuration file
devops-cli config edit
```

## Commands

### Server Management

Manage system services and servers.

#### Subcommands

**`start <service>`** - Start a service
```bash
devops-cli server start nginx
devops-cli server start apache2
```

**`stop <service>`** - Stop a service
```bash
devops-cli server stop nginx
```

**`restart <service>`** - Restart a service
```bash
devops-cli server restart mysql
```

**`status [service]`** - Check service status
```bash
# Check specific service
devops-cli server status nginx

# Check all running services
devops-cli server status
```

**`list`** - List available services
```bash
devops-cli server list
```

---

### Deployment

Manage application deployments with rollback support.

#### Subcommands

**`app <name> [source]`** - Deploy an application
```bash
# Deploy from source directory
devops-cli deploy app myapp /path/to/source

# Create deployment directory
devops-cli deploy app myapp
```

**`rollback <name>`** - Rollback to previous version
```bash
devops-cli deploy rollback myapp
```

**`status [name]`** - Check deployment status
```bash
# Check specific deployment
devops-cli deploy status myapp

# Check all deployments
devops-cli deploy status
```

**`list`** - List all deployments
```bash
devops-cli deploy list
```

#### Features

- Automatic backup before deployment
- Rollback to previous version
- Deployment history tracking
- Automatic permission setting

---

### Backup Operations

Create and manage compressed backups.

#### Subcommands

**`create <name> <path>`** - Create a backup
```bash
devops-cli backup create mydb /var/lib/mysql
devops-cli backup create config /etc/nginx
```

**`restore <name> <destination>`** - Restore from backup
```bash
devops-cli backup restore mydb_20260212_233201 /var/lib/mysql
```

**`list`** - List available backups
```bash
devops-cli backup list
```

**`delete <name>`** - Delete a backup
```bash
devops-cli backup delete mydb_20260212_233201
```

#### Features

- Compressed tar.gz format
- Automatic timestamping
- Size information
- Confirmation prompts for destructive operations

---

### System Monitoring

Monitor system resources and service health.

#### Subcommands

**`cpu [--watch]`** - Monitor CPU usage
```bash
# One-time check
devops-cli monitor cpu

# Continuous monitoring
devops-cli monitor cpu --watch
```

**`memory [--watch]`** - Monitor memory usage
```bash
devops-cli monitor memory
devops-cli monitor memory --watch
```

**`disk`** - Monitor disk usage
```bash
devops-cli monitor disk
```

**`network [--watch]`** - Monitor network statistics
```bash
devops-cli monitor network
devops-cli monitor network --watch
```

**`services`** - Monitor service health
```bash
devops-cli monitor services
```

#### Features

- Real-time monitoring with `--watch` flag
- Top resource consumers
- Service health checks
- Network connection statistics

---

### Log Management

View, search, and manage logs.

#### Subcommands

**`view [file] [-n lines]`** - View logs
```bash
# View DevOps CLI logs
devops-cli logs view

# View specific log file
devops-cli logs view /var/log/nginx/error.log

# View last 100 lines
devops-cli logs view -n 100
```

**`tail [file]`** - Tail logs in real-time
```bash
# Tail DevOps CLI logs
devops-cli logs tail

# Tail specific log file
devops-cli logs tail /var/log/nginx/access.log
```

**`search <pattern> [file]`** - Search logs
```bash
# Search in DevOps CLI logs
devops-cli logs search "ERROR"

# Search in specific file
devops-cli logs search "404" /var/log/nginx/access.log
```

**`rotate`** - Manually rotate logs
```bash
devops-cli logs rotate
```

**`clean [days]`** - Clean old logs
```bash
# Clean logs older than 30 days (default)
devops-cli logs clean

# Clean logs older than 7 days
devops-cli logs clean 7
```

#### Features

- Automatic log rotation (10MB threshold)
- Keeps last 5 rotated logs
- Pattern search with highlighting
- Configurable retention period

---

### Configuration Management

Manage DevOps CLI configuration.

See [Configuration](#configuration) section above for details.

## Examples

### Common Workflows

#### Deploy a Web Application
```bash
# Create backup of current deployment
devops-cli backup create webapp /var/www/myapp

# Deploy new version
devops-cli deploy app myapp /home/user/myapp-v2

# Restart web server
devops-cli server restart nginx

# Check deployment status
devops-cli deploy status myapp
```

#### System Health Check
```bash
# Check all services
devops-cli server status

# Monitor system resources
devops-cli monitor cpu
devops-cli monitor memory
devops-cli monitor disk

# Check service health
devops-cli monitor services
```

#### Backup and Restore Database
```bash
# Create database backup
devops-cli backup create mysql_prod /var/lib/mysql

# List backups
devops-cli backup list

# Restore from backup
devops-cli server stop mysql
devops-cli backup restore mysql_prod_20260212_120000 /var/lib/mysql
devops-cli server start mysql
```

#### Troubleshooting with Logs
```bash
# Search for errors
devops-cli logs search "ERROR"

# Tail logs in real-time
devops-cli logs tail

# View recent entries
devops-cli logs view -n 100
```

## Troubleshooting

### Permission Errors

Many operations require root privileges. Use `sudo`:
```bash
sudo devops-cli server start nginx
```

### Configuration Issues

Validate your configuration:
```bash
devops-cli config validate
```

Reset to defaults if needed:
```bash
devops-cli config reset
```

### Log Files

DevOps CLI logs all operations to `~/.devops-cli/logs/devops-cli.log`. Check this file for detailed error messages:
```bash
devops-cli logs view
```

Enable debug logging for more details:
```bash
devops-cli --debug server start nginx
```

Or set it permanently:
```bash
devops-cli config set log_level DEBUG
```

### Missing Dependencies

Some features require specific tools:
- **Server management**: `systemctl` or `service`
- **Monitoring**: `top`, `free`, `df`, `netstat`
- **Backups**: `tar`

Install missing tools using your package manager.

### Getting Help

For command-specific help:
```bash
devops-cli <command> --help
```

Examples:
```bash
devops-cli server --help
devops-cli backup --help
devops-cli monitor --help
```

## Global Options

- `-h, --help` - Show help message
- `-v, --version` - Show version information
- `--debug` - Enable debug logging

## File Locations

- **Configuration**: `~/.devops-cli/config`
- **Logs**: `~/.devops-cli/logs/devops-cli.log`
- **Backups**: `~/.devops-cli/backups/` (configurable)
- **Deployments**: `/var/www/` (configurable)

## Exit Codes

- `0` - Success
- `1` - General error
- Other non-zero values indicate specific errors

## Support

For issues or questions, check the log files and use the `--debug` flag for detailed output.
