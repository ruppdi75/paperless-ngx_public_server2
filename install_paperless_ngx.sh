#!/bin/bash

#===============================================================================
# Paperless-ngx Installation Script with Caddy HTTPS Proxy
# 
# This script automates the complete installation of Paperless-ngx via Docker
# and secures it with a Caddy reverse proxy for HTTPS connections.
# 
# Supported OS: Ubuntu, AnduinOS
# Author: Windsurf AI Editor
# Version: 1.0
#===============================================================================

set -euo pipefail  # Exit on error, undefined vars, pipe failures

#===============================================================================
# GLOBAL VARIABLES AND CONFIGURATION
#===============================================================================

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Script configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_DIR="${SCRIPT_DIR}/logs"
readonly PAPERLESS_DIR="/opt/paperless"
readonly TIMESTAMP=$(date '+%Y%m%d_%H%M%S')

# Log files
readonly LOG_DETAILED="${LOG_DIR}/install_log_detailed.txt"
readonly LOG_SUMMARY="${LOG_DIR}/install_log_summary.txt"
readonly LOG_ERRORS_AI="${LOG_DIR}/install_log_errors_for_ai.txt"
readonly CONFIG_LOG="${LOG_DIR}/config_details.log"

# Global variables for user configuration
DETECTED_OS=""
USER_DOMAIN=""
CONSUME_DIR=""
MEDIA_DIR=""
DATA_DIR=""
EXPORT_DIR=""
PAPERLESS_USER=""
PAPERLESS_PASSWORD=""
USER_UID=""
USER_GID=""
PAPERLESS_REPO_DIR=""

#===============================================================================
# UTILITY FUNCTIONS
#===============================================================================

# Print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Print section headers
print_header() {
    local message=$1
    echo
    print_color "$CYAN" "==============================================================================="
    print_color "$CYAN" " $message"
    print_color "$CYAN" "==============================================================================="
    echo
}

# Print phase headers
print_phase() {
    local phase_num=$1
    local phase_name=$2
    echo
    print_color "$PURPLE" ">>> PHASE $phase_num: $phase_name <<<"
    echo
}

# Logging function - writes to both console and log file
log_action() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Console output with colors
    case $level in
        "INFO")  print_color "$BLUE" "[INFO] $message" ;;
        "SUCCESS") print_color "$GREEN" "[SUCCESS] $message" ;;
        "WARNING") print_color "$YELLOW" "[WARNING] $message" ;;
        "ERROR") print_color "$RED" "[ERROR] $message" ;;
        *) echo "$message" ;;
    esac
    
    # Log file output without colors
    echo "[$timestamp] [$level] $message" >> "$LOG_DETAILED"
}

# Error handling function
handle_error() {
    local exit_code=$1
    local command=$2
    local context=$3
    
    if [ $exit_code -ne 0 ]; then
        log_action "ERROR" "Command failed with exit code $exit_code: $command"
        log_action "ERROR" "Context: $context"
        
        # Write to AI error log
        {
            echo "Problem: Command '$command' failed with exit code $exit_code"
            echo "Context: $context"
            echo "Timestamp: $(date)"
            echo "Improvement instruction: Analyze the command failure and modify the script to handle this error condition."
            echo "---"
        } >> "$LOG_ERRORS_AI"
        
        exit $exit_code
    fi
}

# Validate input function
validate_input() {
    local input=$1
    local field_name=$2
    
    if [[ -z "$input" ]]; then
        log_action "ERROR" "$field_name cannot be empty"
        return 1
    fi
    return 0
}

# Mask password for logging
mask_password() {
    local password=$1
    local length=${#password}
    
    if [ $length -le 4 ]; then
        echo "****"
        return
    fi
    
    local visible_chars=$((length / 4))
    local start_part="${password:0:$visible_chars}"
    local end_part="${password: -$visible_chars}"
    
    echo "${start_part}****${end_part}"
}

#===============================================================================
# PHASE 0: INITIALIZATION AND SYSTEM CHECK
#===============================================================================

initialize_system() {
    print_phase "0" "INITIALIZATION AND SYSTEM CHECK"
    
    # Welcome screen
    print_header "PAPERLESS-NGX INSTALLATION SCRIPT"
    print_color "$GREEN" "This script will install and configure:"
    echo "  • Paperless-ngx document management system via Docker"
    echo "  • Caddy reverse proxy for HTTPS access"
    echo "  • Complete system configuration and security setup"
    echo
    
    # Create log directory
    mkdir -p "$LOG_DIR"
    
    # Initialize log files
    {
        echo "Paperless-ngx Installation Log - Detailed"
        echo "Started: $(date)"
        echo "Script: $0"
        echo "==============================================================================="
    } > "$LOG_DETAILED"
    
    {
        echo "Paperless-ngx Installation Summary"
        echo "Started: $(date)"
        echo "==============================================================================="
    } > "$LOG_SUMMARY"
    
    {
        echo "AI-Friendly Error Log for Paperless-ngx Installation"
        echo "Started: $(date)"
        echo "==============================================================================="
    } > "$LOG_ERRORS_AI"
    
    {
        echo "Configuration Details Log"
        echo "Started: $(date)"
        echo "==============================================================================="
    } > "$CONFIG_LOG"
    
    log_action "SUCCESS" "Log files initialized"
    
    # Check root privileges
    if [[ $EUID -ne 0 ]]; then
        log_action "ERROR" "This script must be run with sudo privileges"
        print_color "$RED" "Please run: sudo $0"
        exit 1
    fi
    
    log_action "SUCCESS" "Root privileges confirmed"
    
    # Detect operating system
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        case "$ID" in
            "ubuntu")
                DETECTED_OS="Ubuntu"
                log_action "SUCCESS" "Detected OS: Ubuntu $VERSION_ID"
                ;;
            "anduinos")
                DETECTED_OS="AnduinOS"
                log_action "SUCCESS" "Detected OS: AnduinOS"
                ;;
            *)
                log_action "ERROR" "Unsupported operating system: $ID"
                print_color "$RED" "This script only supports Ubuntu and AnduinOS"
                exit 1
                ;;
        esac
    else
        log_action "ERROR" "Cannot detect operating system"
        exit 1
    fi
    
    echo "[SUCCESS] System initialization completed" >> "$LOG_SUMMARY"
}

#===============================================================================
# PHASE 1: INTERACTIVE CONFIGURATION
#===============================================================================

collect_user_configuration() {
    print_phase "1" "INTERACTIVE CONFIGURATION"
    
    # Domain configuration
    while true; do
        echo
        print_color "$YELLOW" "Domain Configuration:"
        read -p "Enter the full domain for Paperless-ngx (e.g., paperless.example.com): " USER_DOMAIN
        
        if validate_input "$USER_DOMAIN" "Domain"; then
            # Basic domain validation
            if [[ "$USER_DOMAIN" =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9]$ ]]; then
                break
            else
                print_color "$RED" "Invalid domain format. Please enter a valid domain."
            fi
        fi
    done
    
    # Directory configuration
    echo
    print_color "$YELLOW" "Directory Configuration:"
    
    read -p "Consume directory path [/opt/paperless/consume]: " CONSUME_DIR
    CONSUME_DIR=${CONSUME_DIR:-"/opt/paperless/consume"}
    
    read -p "Media directory path [/opt/paperless/media]: " MEDIA_DIR
    MEDIA_DIR=${MEDIA_DIR:-"/opt/paperless/media"}
    
    read -p "Data directory path [/opt/paperless/data]: " DATA_DIR
    DATA_DIR=${DATA_DIR:-"/opt/paperless/data"}
    
    read -p "Export directory path [/opt/paperless/export]: " EXPORT_DIR
    EXPORT_DIR=${EXPORT_DIR:-"/opt/paperless/export"}
    
    # User credentials
    echo
    print_color "$YELLOW" "Paperless-ngx User Configuration:"
    
    while true; do
        read -p "Enter username for Paperless-ngx superuser: " PAPERLESS_USER
        if validate_input "$PAPERLESS_USER" "Username"; then
            break
        fi
    done
    
    while true; do
        read -s -p "Enter secure password for superuser: " PAPERLESS_PASSWORD
        echo
        if validate_input "$PAPERLESS_PASSWORD" "Password"; then
            if [[ ${#PAPERLESS_PASSWORD} -lt 8 ]]; then
                print_color "$RED" "Password must be at least 8 characters long"
                continue
            fi
            break
        fi
    done
    
    # Get user ID and group ID
    if [[ -n "${SUDO_USER:-}" ]]; then
        USER_UID=$(id -u "$SUDO_USER")
        USER_GID=$(id -g "$SUDO_USER")
    else
        USER_UID=$(id -u)
        USER_GID=$(id -g)
    fi
    
    log_action "INFO" "Using UID: $USER_UID, GID: $USER_GID for file permissions"
    
    # Write configuration to log
    {
        echo "Configuration collected at: $(date)"
        echo "Domain: $USER_DOMAIN"
        echo "Consume Directory: $CONSUME_DIR"
        echo "Media Directory: $MEDIA_DIR"
        echo "Data Directory: $DATA_DIR"
        echo "Export Directory: $EXPORT_DIR"
        echo "Username: $PAPERLESS_USER"
        echo "Password: $(mask_password "$PAPERLESS_PASSWORD")"
        echo "User UID: $USER_UID"
        echo "User GID: $USER_GID"
        echo "Detected OS: $DETECTED_OS"
    } >> "$CONFIG_LOG"
    
    log_action "SUCCESS" "Configuration collected and validated"
    echo "[SUCCESS] User configuration collected" >> "$LOG_SUMMARY"
}

#===============================================================================
# PHASE 2: DEPENDENCY INSTALLATION
#===============================================================================

install_dependencies() {
    print_phase "2" "DEPENDENCY INSTALLATION"
    
    case "$DETECTED_OS" in
        "Ubuntu")
            install_dependencies_ubuntu
            ;;
        "AnduinOS")
            install_dependencies_anduinos
            ;;
    esac
    
    echo "[SUCCESS] Dependencies installed" >> "$LOG_SUMMARY"
}

install_dependencies_ubuntu() {
    log_action "INFO" "Installing dependencies for Ubuntu"
    
    # Update system
    log_action "INFO" "Updating package lists"
    apt update
    handle_error $? "apt update" "System package update"
    
    log_action "INFO" "Upgrading system packages"
    apt upgrade -y
    handle_error $? "apt upgrade -y" "System package upgrade"
    
    # Install Docker
    log_action "INFO" "Installing Docker"
    
    # Remove old Docker versions
    apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Install prerequisites
    apt install -y ca-certificates curl gnupg lsb-release
    handle_error $? "apt install prerequisites" "Docker prerequisites installation"
    
    # Add Docker GPG key
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    handle_error $? "Docker GPG key installation" "Adding Docker repository key"
    
    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    handle_error $? "Docker repository addition" "Adding Docker APT repository"
    
    # Update and install Docker
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    handle_error $? "Docker installation" "Installing Docker packages"
    
    # Start and enable Docker
    systemctl start docker
    systemctl enable docker
    handle_error $? "Docker service start" "Starting Docker service"
    
    # Add user to docker group
    if [[ -n "${SUDO_USER:-}" ]]; then
        usermod -aG docker "$SUDO_USER"
        log_action "SUCCESS" "Added $SUDO_USER to docker group"
    fi
    
    # Install Docker Compose (standalone)
    log_action "INFO" "Installing Docker Compose"
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    handle_error $? "Docker Compose download" "Downloading Docker Compose"
    
    chmod +x /usr/local/bin/docker-compose
    handle_error $? "Docker Compose permissions" "Setting Docker Compose permissions"
    
    # Install Caddy
    install_caddy_ubuntu
    
    log_action "SUCCESS" "All dependencies installed for Ubuntu"
}

install_dependencies_anduinos() {
    log_action "INFO" "Installing dependencies for AnduinOS"
    
    # Install Docker using get-docker.sh script
    log_action "INFO" "Installing Docker via get-docker.sh"
    curl -fsSL https://get.docker.com -o get-docker.sh
    handle_error $? "Docker script download" "Downloading Docker installation script"
    
    sh get-docker.sh
    handle_error $? "Docker installation script" "Running Docker installation script"
    
    rm get-docker.sh
    
    # Add user to docker group
    if [[ -n "${SUDO_USER:-}" ]]; then
        usermod -aG docker "$SUDO_USER"
        log_action "SUCCESS" "Added $SUDO_USER to docker group (requires re-login for full effect)"
    fi
    
    # Install Docker Compose
    log_action "INFO" "Installing Docker Compose"
    apt update
    apt install -y docker-compose
    handle_error $? "Docker Compose installation" "Installing Docker Compose via APT"
    
    # Install Caddy (same as Ubuntu)
    install_caddy_ubuntu
    
    log_action "SUCCESS" "All dependencies installed for AnduinOS"
}

install_caddy_ubuntu() {
    log_action "INFO" "Installing Caddy web server"
    
    # Add Caddy repository
    apt install -y debian-keyring debian-archive-keyring apt-transport-https
    handle_error $? "Caddy prerequisites" "Installing Caddy prerequisites"
    
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
    handle_error $? "Caddy GPG key" "Adding Caddy GPG key"
    
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
    handle_error $? "Caddy repository" "Adding Caddy repository"
    
    # Install Caddy
    apt update
    apt install -y caddy
    handle_error $? "Caddy installation" "Installing Caddy package"
    
    log_action "SUCCESS" "Caddy installed successfully"
}

#===============================================================================
# PHASE 3: PAPERLESS-NGX CONFIGURATION AND SETUP
#===============================================================================

setup_paperless() {
    print_phase "3" "PAPERLESS-NGX CONFIGURATION AND SETUP"
    
    # Create directory structure
    log_action "INFO" "Creating Paperless-ngx directory structure"
    
    mkdir -p "$PAPERLESS_DIR"
    mkdir -p "$CONSUME_DIR"
    mkdir -p "$MEDIA_DIR"
    mkdir -p "$DATA_DIR"
    mkdir -p "$EXPORT_DIR"
    
    # Set correct permissions
    if [[ -n "${SUDO_USER:-}" ]]; then
        chown -R "$USER_UID:$USER_GID" "$PAPERLESS_DIR"
        chown -R "$USER_UID:$USER_GID" "$CONSUME_DIR"
        chown -R "$USER_UID:$USER_GID" "$MEDIA_DIR"
        chown -R "$USER_UID:$USER_GID" "$DATA_DIR"
        chown -R "$USER_UID:$USER_GID" "$EXPORT_DIR"
    fi
    
    log_action "SUCCESS" "Directory structure created with correct permissions"
    
    # Clone the complete Paperless-ngx repository
    log_action "INFO" "Cloning complete Paperless-ngx repository"
    
    PAPERLESS_REPO_DIR="$PAPERLESS_DIR/paperless-ngx"
    
    # Check if git is installed
    if ! command -v git &> /dev/null; then
        log_action "INFO" "Installing git"
        case "$DETECTED_OS" in
            "Ubuntu"|"AnduinOS")
                apt update && apt install -y git
                handle_error $? "git installation" "Installing git package"
                ;;
        esac
    fi
    
    # Clone the repository
    cd "$PAPERLESS_DIR"
    git clone https://github.com/paperless-ngx/paperless-ngx.git
    handle_error $? "Repository clone" "Cloning paperless-ngx repository"
    
    # Set correct permissions for cloned repository
    if [[ -n "${SUDO_USER:-}" ]]; then
        chown -R "$USER_UID:$USER_GID" "$PAPERLESS_REPO_DIR"
    fi
    
    log_action "SUCCESS" "Paperless-ngx repository cloned successfully"
    
    # Copy configuration files from the repository
    log_action "INFO" "Setting up configuration files from repository"
    
    cd "$PAPERLESS_DIR"
    
    # Copy docker-compose.yml (PostgreSQL version)
    cp "$PAPERLESS_REPO_DIR/docker/compose/docker-compose.postgres.yml" docker-compose.yml
    handle_error $? "docker-compose.yml copy" "Copying docker-compose.yml from repository"
    
    # Copy environment files
    cp "$PAPERLESS_REPO_DIR/docker/compose/docker-compose.env" docker-compose.env
    handle_error $? "docker-compose.env copy" "Copying docker-compose.env from repository"
    
    cp "$PAPERLESS_REPO_DIR/.env" .env
    handle_error $? ".env copy" "Copying .env file from repository"
    
    log_action "SUCCESS" "Configuration files copied from repository"
    
    # Modify docker-compose.yml
    log_action "INFO" "Configuring docker-compose.yml"
    
    # Change port binding to localhost only
    sed -i 's/8000:8000/127.0.0.1:8000:8000/g' docker-compose.yml
    handle_error $? "Port configuration" "Modifying port binding in docker-compose.yml"
    
    # Replace volume paths with absolute paths
    sed -i "s|./consume|$CONSUME_DIR|g" docker-compose.yml
    sed -i "s|./media|$MEDIA_DIR|g" docker-compose.yml
    sed -i "s|./data|$DATA_DIR|g" docker-compose.yml
    sed -i "s|./export|$EXPORT_DIR|g" docker-compose.yml
    
    # Add user mapping to webserver service
    sed -i "/webserver:/a\\    user: \"$USER_UID:$USER_GID\"" docker-compose.yml
    handle_error $? "User mapping configuration" "Adding user mapping to docker-compose.yml"
    
    log_action "SUCCESS" "docker-compose.yml configured"
    
    # Configure environment files
    log_action "INFO" "Configuring environment files"
    
    # Set user mapping in docker-compose.env
    sed -i "s/USERMAP_UID=1000/USERMAP_UID=$USER_UID/g" docker-compose.env
    sed -i "s/USERMAP_GID=1000/USERMAP_GID=$USER_GID/g" docker-compose.env
    
    # Add timezone configuration
    echo "PAPERLESS_TIME_ZONE=Europe/Berlin" >> docker-compose.env
    
    log_action "SUCCESS" "Environment files configured"
    
    # Apply our security enhancements
    log_action "INFO" "Applying security enhancements"
    
    # Copy our secure environment template if it exists
    if [[ -f "$SCRIPT_DIR/.env.template" ]]; then
        cp "$SCRIPT_DIR/.env.template" "$PAPERLESS_DIR/.env.template"
        log_action "SUCCESS" "Secure environment template copied"
    fi
    
    # Copy our security documentation if it exists
    if [[ -f "$SCRIPT_DIR/SECURITY_GUIDE.md" ]]; then
        cp "$SCRIPT_DIR/SECURITY_GUIDE.md" "$PAPERLESS_DIR/SECURITY_GUIDE.md"
        log_action "SUCCESS" "Security guide copied"
    fi
    
    # Copy our credential generation script if it exists
    if [[ -f "$SCRIPT_DIR/scripts/generate_secrets.sh" ]]; then
        mkdir -p "$PAPERLESS_DIR/scripts"
        cp "$SCRIPT_DIR/scripts/generate_secrets.sh" "$PAPERLESS_DIR/scripts/generate_secrets.sh"
        chmod +x "$PAPERLESS_DIR/scripts/generate_secrets.sh"
        log_action "SUCCESS" "Credential generation script copied"
    fi
    
    log_action "SUCCESS" "Security enhancements applied"
    
    # Pull Docker images
    log_action "INFO" "Pulling Docker images (this may take several minutes)"
    docker compose pull
    handle_error $? "Docker image pull" "Pulling Paperless-ngx Docker images"
    
    log_action "SUCCESS" "Docker images pulled successfully"
    echo "[SUCCESS] Paperless-ngx configuration completed" >> "$LOG_SUMMARY"
}

#===============================================================================
# PHASE 4: CADDY REVERSE PROXY CONFIGURATION
#===============================================================================

setup_caddy() {
    print_phase "4" "CADDY REVERSE PROXY CONFIGURATION"
    
    log_action "INFO" "Creating Caddy configuration"
    
    # Create Caddyfile
    cat > /etc/caddy/Caddyfile << EOF
$USER_DOMAIN {
    encode zstd gzip
    reverse_proxy localhost:8000
}
EOF
    
    handle_error $? "Caddyfile creation" "Creating Caddy configuration file"
    
    log_action "SUCCESS" "Caddyfile created with configuration:"
    log_action "INFO" "Domain: $USER_DOMAIN"
    log_action "INFO" "Proxy target: localhost:8000"
    
    # Log the exact content written
    {
        echo "Caddyfile content created at $(date):"
        cat /etc/caddy/Caddyfile
    } >> "$LOG_DETAILED"
    
    echo "[SUCCESS] Caddy reverse proxy configured" >> "$LOG_SUMMARY"
}

#===============================================================================
# PHASE 5: SERVICE STARTUP AND VERIFICATION
#===============================================================================

start_and_verify_services() {
    print_phase "5" "SERVICE STARTUP AND VERIFICATION"
    
    # Start Paperless-ngx
    log_action "INFO" "Starting Paperless-ngx containers"
    
    cd "$PAPERLESS_DIR"
    docker compose up -d
    handle_error $? "Paperless container startup" "Starting Paperless-ngx with docker compose up -d"
    
    # Wait for containers to be ready
    log_action "INFO" "Waiting for containers to initialize (30 seconds)"
    sleep 30
    
    # Check container status
    log_action "INFO" "Checking container status"
    docker compose ps >> "$LOG_DETAILED"
    
    # Verify containers are running
    if ! docker compose ps | grep -q "Up"; then
        log_action "ERROR" "Some containers failed to start"
        docker compose logs >> "$LOG_DETAILED"
        handle_error 1 "Container health check" "Containers not running properly"
    fi
    
    log_action "SUCCESS" "Paperless-ngx containers started successfully"
    
    # Wait a bit more for the web server to be fully ready
    log_action "INFO" "Waiting for web server to be ready (30 seconds)"
    sleep 30
    
    # Create superuser
    log_action "INFO" "Creating Paperless-ngx superuser"
    
    # Use environment variables to pass credentials securely
    DJANGO_SUPERUSER_USERNAME="$PAPERLESS_USER" \
    DJANGO_SUPERUSER_PASSWORD="$PAPERLESS_PASSWORD" \
    docker compose exec -T webserver python3 manage.py createsuperuser --noinput --email admin@localhost
    
    if [ $? -eq 0 ]; then
        log_action "SUCCESS" "Superuser created successfully"
    else
        log_action "WARNING" "Superuser creation may have failed or user already exists"
    fi
    
    # Start and configure Caddy
    log_action "INFO" "Starting Caddy service"
    
    systemctl enable caddy
    handle_error $? "Caddy enable" "Enabling Caddy service"
    
    systemctl start caddy
    handle_error $? "Caddy start" "Starting Caddy service"
    
    # Reload configuration
    systemctl reload caddy
    handle_error $? "Caddy reload" "Reloading Caddy configuration"
    
    # Check Caddy status
    if systemctl is-active --quiet caddy; then
        log_action "SUCCESS" "Caddy service is running"
    else
        log_action "ERROR" "Caddy service failed to start"
        systemctl status caddy >> "$LOG_DETAILED"
        handle_error 1 "Caddy service check" "Caddy service not running"
    fi
    
    echo "[SUCCESS] All services started and verified" >> "$LOG_SUMMARY"
}

#===============================================================================
# PHASE 6: FINAL REPORTING AND LOG CREATION
#===============================================================================

generate_final_report() {
    print_phase "6" "FINAL REPORTING AND LOG CREATION"
    
    # Terminal summary
    print_header "INSTALLATION COMPLETED SUCCESSFULLY!"
    
    print_color "$GREEN" "🎉 Your Paperless-ngx installation is ready!"
    echo
    print_color "$CYAN" "📋 Installation Summary:"
    echo "  • URL: https://$USER_DOMAIN"
    echo "  • Username: $PAPERLESS_USER"
    echo "  • Consume folder: $CONSUME_DIR"
    echo "  • Media folder: $MEDIA_DIR"
    echo "  • Data folder: $DATA_DIR"
    echo "  • Export folder: $EXPORT_DIR"
    echo
    print_color "$YELLOW" "📁 Log Files:"
    echo "  • Detailed log: $LOG_DETAILED"
    echo "  • Summary log: $LOG_SUMMARY"
    echo "  • Configuration: $CONFIG_LOG"
    echo "  • Error log: $LOG_ERRORS_AI"
    echo
    print_color "$BLUE" "🔧 Next Steps:"
    echo "  1. Access your Paperless-ngx instance at https://$USER_DOMAIN"
    echo "  2. Log in with your credentials"
    echo "  3. Configure additional settings in the web interface"
    echo "  4. Start uploading documents to $CONSUME_DIR"
    echo
    print_color "$PURPLE" "📦 Repository Resources:"
    echo "  • Full repository: $PAPERLESS_REPO_DIR"
    echo "  • Documentation: $PAPERLESS_REPO_DIR/docs/"
    echo "  • Examples: $PAPERLESS_REPO_DIR/docker/compose/"
    echo "  • Source code: $PAPERLESS_REPO_DIR/src/"
    echo
    print_color "$GREEN" "✅ Installation completed successfully!"
    
    # Create summary log
    {
        echo "INSTALLATION SUMMARY - $(date)"
        echo "=================================="
        echo "[SUCCESS] System initialization ($DETECTED_OS)"
        echo "[SUCCESS] User configuration collected"
        echo "[SUCCESS] Dependencies installed (Docker, Caddy)"
        echo "[SUCCESS] Paperless-ngx configuration completed"
        echo "[SUCCESS] Caddy reverse proxy configured"
        echo "[SUCCESS] All services started and verified"
        echo ""
        echo "CONFIGURATION:"
        echo "Domain: $USER_DOMAIN"
        echo "Username: $PAPERLESS_USER"
        echo "Directories configured: consume, media, data, export"
        echo "Services: Paperless-ngx (Docker), Caddy (HTTPS proxy)"
        echo "Repository: Full paperless-ngx repository cloned to $PAPERLESS_REPO_DIR"
        echo ""
        echo "INSTALLATION COMPLETED SUCCESSFULLY"
    } >> "$LOG_SUMMARY"
    
    log_action "SUCCESS" "Installation completed successfully"
    log_action "INFO" "All log files have been created in $LOG_DIR"
}

#===============================================================================
# MAIN EXECUTION FLOW
#===============================================================================

main() {
    # Trap to handle script interruption
    trap 'log_action "ERROR" "Script interrupted by user"; exit 130' INT TERM
    
    # Execute installation phases
    initialize_system
    collect_user_configuration
    install_dependencies
    setup_paperless
    setup_caddy
    start_and_verify_services
    generate_final_report
    
    exit 0
}

# Execute main function
main "$@"
