# Detailed Installation Guide

This guide provides comprehensive instructions for installing Paperless-ngx using the automated installation script.

## Pre-Installation Checklist

### System Requirements

- [ ] **Operating System**: Ubuntu 20.04+ or AnduinOS
- [ ] **Memory**: Minimum 2GB RAM (4GB+ recommended)
- [ ] **Storage**: At least 10GB free disk space
- [ ] **Network**: Internet connection for downloading packages
- [ ] **Privileges**: Root/sudo access

### Network Requirements

- [ ] **Domain Name**: Valid domain pointing to your server
- [ ] **DNS Configuration**: A record configured for your domain
- [ ] **Firewall**: Ports 22 (SSH), 80 (HTTP), and 443 (HTTPS) open for incoming connections
- [ ] **Port Availability**: Ensure ports 22, 80, and 443 are not in use by conflicting services

### Pre-Installation Commands

```bash
# Check available disk space
df -h

# Check memory
free -h

# Check if ports are available
sudo netstat -tlnp | grep :22
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :443

# Verify DNS resolution
nslookup yourdomain.com
```

## Step-by-Step Installation

### 1. Download the Script

```bash
# Option 1: Clone the repository
git clone https://github.com/ruppdi75/paperless-ngx_public_server.git
cd paperless-ngx_public_server

# Option 2: Download directly
wget https://raw.githubusercontent.com/ruppdi75/paperless-ngx_public_server/main/install_paperless_ngx.sh
chmod +x install_paperless_ngx.sh
```

### 2. Prepare Your Environment

```bash
# Update your system (recommended)
sudo apt update && sudo apt upgrade -y

# Install curl and wget if not present
sudo apt install -y curl wget

# Create a backup user (optional but recommended)
sudo adduser paperless-backup
```

### 3. Run the Installation Script

```bash
# Make sure you're in the correct directory
cd paperless-ngx_public_server

# Run the installation script
sudo ./install_paperless_ngx.sh
```

### 4. Follow Interactive Prompts

The script will guide you through configuration. Here's what to expect:

#### Domain Configuration
```
Enter the full domain for Paperless-ngx (e.g., paperless.example.com): 
```
- Enter your fully qualified domain name
- Example: `documents.mydomain.com`

#### Directory Configuration
```
Consume directory path [/opt/paperless/consume]: 
Media directory path [/opt/paperless/media]: 
Data directory path [/opt/paperless/data]: 
Export directory path [/opt/paperless/export]: 
```
- Press Enter to use defaults, or specify custom paths
- Ensure sufficient disk space in chosen locations

#### User Credentials
```
Enter username for Paperless-ngx superuser: 
Enter secure password for superuser: 
```
- Choose a strong username (avoid 'admin' for security)
- Use a secure password with at least 8 characters

## Installation Process Phases

### Phase 0: System Initialization ⚙️
- Verifies root privileges
- Detects operating system
- Creates logging infrastructure
- Initializes installation environment

**Expected Duration**: 30 seconds

### Phase 1: Configuration Collection 📝
- Interactive prompts for all settings
- Input validation and verification
- Configuration logging (passwords masked)

**Expected Duration**: 2-5 minutes (depending on user input)

### Phase 2: Dependency Installation 📦
- System package updates
- Docker installation and configuration
- Docker Compose installation
- Caddy web server installation
- User permission configuration

**Expected Duration**: 5-15 minutes (depending on internet speed)

### Phase 3: Paperless-ngx Setup 🗂️
- Directory structure creation
- Docker configuration download
- Security configuration (localhost binding)
- Volume mount configuration
- Docker image download

**Expected Duration**: 5-10 minutes (depending on internet speed)

### Phase 4: Caddy Configuration 🔒
- Reverse proxy configuration
- HTTPS/SSL setup
- Security headers configuration

**Expected Duration**: 30 seconds

### Phase 5: Service Startup 🚀
- Container orchestration startup
- Health checks and verification
- Superuser account creation
- Service enablement and startup

**Expected Duration**: 2-5 minutes

### Phase 6: Final Reporting 📊
- Installation summary generation
- Log file creation
- Access information display

**Expected Duration**: 30 seconds

## Post-Installation Verification

### 1. Check Service Status

```bash
# Check Docker containers
sudo docker compose -f /opt/paperless/docker-compose.yml ps

# Check Caddy status
sudo systemctl status caddy

# Check if services are listening
sudo netstat -tlnp | grep :8000  # Paperless (should be localhost only)
sudo netstat -tlnp | grep :80    # Caddy HTTP
sudo netstat -tlnp | grep :443   # Caddy HTTPS
```

### 2. Test Web Access

```bash
# Test local access
curl -I http://localhost:8000

# Test domain access (replace with your domain)
curl -I https://yourdomain.com
```

### 3. Review Logs

```bash
# View installation logs
cat logs/install_log_summary.txt

# Check for any errors
cat logs/install_log_errors_for_ai.txt

# View Paperless logs
sudo docker compose -f /opt/paperless/docker-compose.yml logs webserver

# View Caddy logs
sudo journalctl -u caddy -n 50
```

## First Login and Setup

1. **Access the Web Interface**:
   - Navigate to `https://yourdomain.com`
   - You should see the Paperless-ngx login page

2. **Login with Your Credentials**:
   - Use the username and password you provided during installation

3. **Initial Configuration**:
   - Set your timezone in Settings → General
   - Configure language preferences
   - Set up document processing rules
   - Configure email settings (if needed)

4. **Test Document Upload**:
   - Place a test PDF in your consume directory
   - Watch it appear in the web interface within a few minutes

## Directory Structure After Installation

```
/opt/paperless/                 # Main installation directory
├── docker-compose.yml          # Docker configuration
├── docker-compose.env          # Environment variables
├── .env                        # Additional environment settings
└── logs/                       # Container logs

/path/to/consume/               # Document intake directory
/path/to/media/                 # Processed documents
/path/to/data/                  # Database and search index
/path/to/export/                # Document exports

/etc/caddy/                     # Caddy configuration
└── Caddyfile                   # Reverse proxy settings

/var/log/                       # System logs
├── caddy/                      # Caddy logs
└── docker/                     # Docker logs
```

## Backup Recommendations

After successful installation, set up regular backups:

```bash
# Create backup script
cat > /usr/local/bin/paperless-backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/backup/paperless/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup database
docker compose -f /opt/paperless/docker-compose.yml exec -T db pg_dump -U paperless paperless > "$BACKUP_DIR/database.sql"

# Backup media files
cp -r /path/to/media "$BACKUP_DIR/"
cp -r /path/to/data "$BACKUP_DIR/"

# Backup configuration
cp -r /opt/paperless "$BACKUP_DIR/config"
cp /etc/caddy/Caddyfile "$BACKUP_DIR/"

echo "Backup completed: $BACKUP_DIR"
EOF

chmod +x /usr/local/bin/paperless-backup.sh

# Set up daily backup cron job
echo "0 2 * * * root /usr/local/bin/paperless-backup.sh" >> /etc/crontab
```

## Troubleshooting Installation Issues

If the installation fails, check:

1. **Log Files**: Review `logs/install_log_errors_for_ai.txt`
2. **System Resources**: Ensure adequate disk space and memory
3. **Network Connectivity**: Verify internet access and DNS resolution
4. **Permissions**: Confirm script is run with sudo
5. **Port Conflicts**: Check if required ports are available

For specific error solutions, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

## Manual Cleanup (if needed)

If you need to completely remove the installation:

```bash
# Stop and remove containers
sudo docker compose -f /opt/paperless/docker-compose.yml down -v

# Remove Docker images
sudo docker rmi $(sudo docker images | grep paperless | awk '{print $3}')

# Remove directories (BE CAREFUL!)
sudo rm -rf /opt/paperless
# Only remove your data directories if you're sure!

# Remove Caddy configuration
sudo rm /etc/caddy/Caddyfile
sudo systemctl reload caddy

# Remove Docker (if desired)
sudo apt remove docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

---

**Next Steps**: After successful installation, see [CONFIGURATION.md](CONFIGURATION.md) for advanced configuration options.
