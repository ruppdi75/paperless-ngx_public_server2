# Paperless-ngx Automated Installation Script

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Docker](https://img.shields.io/badge/Docker-Required-blue.svg)](https://www.docker.com/)
[![Caddy](https://img.shields.io/badge/Caddy-v2-orange.svg)](https://caddyserver.com/)

A comprehensive, interactive Bash script that automates the complete installation and configuration of [Paperless-ngx](https://github.com/paperless-ngx/paperless-ngx) document management system with HTTPS security via Caddy reverse proxy.

## 🚀 Features

- **Fully Automated Installation**: One-command setup for the entire Paperless-ngx stack
- **HTTPS Security**: Automatic SSL/TLS certificate management with Caddy
- **Interactive Configuration**: User-friendly prompts for all configuration options
- **Multi-OS Support**: Compatible with Ubuntu and AnduinOS
- **Comprehensive Logging**: Detailed logs for troubleshooting and monitoring
- **Docker-based**: Uses official Paperless-ngx Docker containers with PostgreSQL
- **Security Best Practices**: Proper file permissions and secure credential handling
- **Error Recovery**: Robust error handling with detailed error reporting

## 📋 Prerequisites

- **Operating System**: Ubuntu 20.04+ or AnduinOS
- **Privileges**: Root/sudo access required
- **Domain**: A valid domain name pointing to your server
- **Ports**: Ports 22 (SSH), 80 (HTTP), and 443 (HTTPS) must be accessible from the internet
- **Memory**: At least 2GB RAM recommended
- **Storage**: At least 10GB free disk space

## 🛠️ Installation

### Quick Start

1. **Clone the repository**:
   ```bash
   git clone https://github.com/ruppdi75/paperless-ngx_public_server.git
   cd paperless-ngx_public_server
   ```

2. **Make the script executable**:
   ```bash
   chmod +x install_paperless_ngx.sh
   ```

3. **Run the installation script**:
   ```bash
   sudo ./install_paperless_ngx.sh
   ```

4. **Follow the interactive prompts** to configure your installation.

### What the Script Does

The installation process is divided into 6 phases:

#### Phase 0: System Initialization
- Checks for root privileges
- Detects operating system (Ubuntu/AnduinOS)
- Initializes logging system
- Creates log directory structure

#### Phase 1: Interactive Configuration
- Collects domain name for HTTPS access
- Configures directory paths for document storage
- Sets up Paperless-ngx administrator credentials
- Determines user/group IDs for proper file permissions

#### Phase 2: Dependency Installation
- **Ubuntu**: Installs Docker via official repository
- **AnduinOS**: Installs Docker via get-docker.sh script
- Installs Docker Compose
- Installs Caddy web server
- Configures user permissions

#### Phase 3: Paperless-ngx Setup
- Creates directory structure with proper permissions
- Downloads official Docker Compose configuration
- Modifies configuration for security (localhost binding)
- Configures volume mounts to user-specified directories
- Downloads and pulls Docker images

#### Phase 4: Caddy Configuration
- Creates Caddyfile with reverse proxy configuration
- Configures automatic HTTPS with Let's Encrypt
- Sets up compression and security headers

#### Phase 5: Service Startup
- Starts Paperless-ngx containers
- Verifies container health
- Creates administrator user account
- Starts and enables Caddy service
- Performs final service verification

#### Phase 6: Final Reporting
- Generates comprehensive installation report
- Creates summary logs
- Provides access information and next steps

## 📁 Project Structure

```
paperless-ngx_public_server/
├── install_paperless_ngx.sh    # Main installation script
├── README.md                   # This documentation
├── LICENSE                     # MIT License
├── .gitignore                  # Git ignore rules
├── docs/                       # Documentation
│   ├── INSTALLATION.md         # Detailed installation guide
│   ├── CONFIGURATION.md        # Configuration options
│   ├── TROUBLESHOOTING.md      # Common issues and solutions
│   └── SECURITY.md             # Security considerations
├── examples/                   # Example configurations
│   ├── docker-compose.yml      # Example Docker Compose file
│   ├── Caddyfile               # Example Caddy configuration
│   └── paperless.env           # Example environment variables
└── logs/                       # Log files (created during installation)
    ├── install_log_detailed.txt
    ├── install_log_summary.txt
    ├── install_log_errors_for_ai.txt
    └── config_details.log
```

## 🔧 Configuration Options

During installation, you'll be prompted for:

| Option | Description | Default | Example |
|--------|-------------|---------|----------|
| **Domain** | Full domain name for HTTPS access | None | `paperless.example.com` |
| **Consume Directory** | Path for incoming documents | `/opt/paperless/consume` | `/home/user/paperless/consume` |
| **Media Directory** | Path for processed documents | `/opt/paperless/media` | `/home/user/paperless/media` |
| **Data Directory** | Path for database and search index | `/opt/paperless/data` | `/home/user/paperless/data` |
| **Export Directory** | Path for document exports | `/opt/paperless/export` | `/home/user/paperless/export` |
| **Admin Username** | Paperless-ngx administrator username | None | `admin` |
| **Admin Password** | Secure password (min. 8 characters) | None | `SecurePassword123!` |

## 📊 Logging System

The script creates comprehensive logs in the `logs/` directory:

- **`install_log_detailed.txt`**: Complete installation log with timestamps
- **`install_log_summary.txt`**: High-level summary of installation steps
- **`install_log_errors_for_ai.txt`**: AI-friendly error descriptions for troubleshooting
- **`config_details.log`**: Configuration settings (passwords are masked)

## 🔒 Security Features

- **HTTPS Only**: Automatic SSL/TLS certificates via Let's Encrypt
- **Localhost Binding**: Paperless-ngx only accessible via reverse proxy
- **Secure Credentials**: Passwords are masked in logs
- **File Permissions**: Proper ownership and permissions for all directories
- **Container Security**: Non-root user execution in containers

## 🚨 Troubleshooting

### Common Issues

1. **Port 80/443 already in use**:
   ```bash
   sudo netstat -tlnp | grep :80
   sudo netstat -tlnp | grep :443
   ```

2. **Docker permission denied**:
   ```bash
   sudo usermod -aG docker $USER
   # Log out and back in
   ```

3. **Caddy fails to start**:
   ```bash
   sudo systemctl status caddy
   sudo journalctl -u caddy -f
   ```

4. **Domain not resolving**:
   - Ensure DNS A record points to your server IP
   - Check firewall rules for ports 80 and 443

### Log Analysis

Check the generated logs for detailed error information:
```bash
# View detailed installation log
cat logs/install_log_detailed.txt

# View error summary
cat logs/install_log_errors_for_ai.txt

# Check Paperless-ngx container logs
sudo docker compose -f /opt/paperless/docker-compose.yml logs
```

## 📚 Post-Installation

After successful installation:

1. **Access your instance**: Navigate to `https://yourdomain.com`
2. **Login**: Use the credentials you provided during installation
3. **Configure settings**: Adjust timezone, language, and other preferences
4. **Start uploading**: Place documents in your consume directory
5. **Set up automation**: Configure email fetching, scheduled tasks, etc.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Development Setup

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Paperless-ngx](https://github.com/paperless-ngx/paperless-ngx) team for the excellent document management system
- [Caddy](https://caddyserver.com/) for the powerful and easy-to-use web server
- [Docker](https://www.docker.com/) for containerization technology

## 📞 Support

If you encounter any issues:

1. Check the [troubleshooting guide](docs/TROUBLESHOOTING.md)
2. Review the installation logs
3. Open an issue on GitHub with:
   - Your operating system
   - Error messages from logs
   - Steps to reproduce the issue

## 🔄 Updates

To update your installation:

1. Pull the latest changes: `git pull origin main`
2. Review the changelog for breaking changes
3. Re-run the installation script if needed

---

**Made with ❤️ for the self-hosted community**

*This script automates the installation process but always review the code before running it with sudo privileges.*
