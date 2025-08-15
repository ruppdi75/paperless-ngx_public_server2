# Troubleshooting Guide

This guide helps you diagnose and resolve common issues with your Paperless-ngx installation.

## Quick Diagnostics

### System Health Check

```bash
# Run this comprehensive health check
#!/bin/bash
echo "=== Paperless-ngx Health Check ==="

# Check if script exists and is executable
if [[ -x "./install_paperless_ngx.sh" ]]; then
    echo "✅ Installation script found and executable"
else
    echo "❌ Installation script missing or not executable"
fi

# Check system resources
echo "📊 System Resources:"
echo "Memory: $(free -h | grep '^Mem:' | awk '{print $3 "/" $2}')"
echo "Disk: $(df -h / | tail -1 | awk '{print $3 "/" $2 " (" $5 " used)"}')"

# Check services
echo "🔧 Service Status:"
if systemctl is-active --quiet docker; then
    echo "✅ Docker: Running"
else
    echo "❌ Docker: Not running"
fi

if systemctl is-active --quiet caddy; then
    echo "✅ Caddy: Running"
else
    echo "❌ Caddy: Not running"
fi

# Check containers (if installed)
if [[ -f "/opt/paperless/docker-compose.yml" ]]; then
    echo "📦 Container Status:"
    docker compose -f /opt/paperless/docker-compose.yml ps
else
    echo "📦 Paperless not yet installed"
fi

# Check ports
echo "🌐 Port Status:"
netstat -tlnp | grep -E ':(80|443|8000)\s' || echo "No services listening on standard ports"

# Check logs
echo "📝 Recent Errors:"
if [[ -f "logs/install_log_errors_for_ai.txt" ]]; then
    tail -5 logs/install_log_errors_for_ai.txt
else
    echo "No error log found"
fi
```

## Installation Issues

### 1. Script Won't Start

**Problem**: Script fails to execute or shows permission denied

**Solutions**:
```bash
# Make script executable
chmod +x install_paperless_ngx.sh

# Check if running with sudo
sudo ./install_paperless_ngx.sh

# Verify script integrity
head -1 install_paperless_ngx.sh  # Should show #!/bin/bash
```

### 2. Operating System Not Supported

**Problem**: Script exits with "Unsupported operating system"

**Solutions**:
```bash
# Check your OS
cat /etc/os-release

# For other Ubuntu-based distributions, modify the script:
# Edit line ~95 in install_paperless_ngx.sh
# Add your distribution ID to the case statement
```

### 3. Insufficient Privileges

**Problem**: "This script must be run with sudo privileges"

**Solutions**:
```bash
# Run with sudo
sudo ./install_paperless_ngx.sh

# Check if you have sudo access
sudo -v

# If sudo not available, run as root
su -
./install_paperless_ngx.sh
```

## Dependency Installation Issues

### 1. Docker Installation Fails

**Problem**: Docker installation fails or times out

**Solutions**:
```bash
# Manual Docker installation (Ubuntu)
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Test Docker
sudo docker run hello-world
```

### 2. Caddy Installation Fails

**Problem**: Caddy repository or installation fails

**Solutions**:
```bash
# Manual Caddy installation
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy

# Alternative: Download binary directly
curl -L "https://github.com/caddyserver/caddy/releases/latest/download/caddy_linux_amd64.tar.gz" | sudo tar -xz -C /usr/local/bin caddy
sudo chmod +x /usr/local/bin/caddy
```

### 3. Network/Firewall Issues

**Problem**: Downloads fail or timeout

**Solutions**:
```bash
# Check internet connectivity
ping -c 3 google.com
curl -I https://github.com

# Check DNS resolution
nslookup github.com
nslookup download.docker.com

# Temporary firewall disable (for testing only)
sudo ufw disable
# Run installation
sudo ufw enable

# Check proxy settings
echo $http_proxy
echo $https_proxy
```

## Container Issues

### 1. Containers Won't Start

**Problem**: Docker containers fail to start or exit immediately

**Diagnostic Commands**:
```bash
# Check container status
docker compose -f /opt/paperless/docker-compose.yml ps

# View container logs
docker compose -f /opt/paperless/docker-compose.yml logs

# Check specific service logs
docker compose -f /opt/paperless/docker-compose.yml logs webserver
docker compose -f /opt/paperless/docker-compose.yml logs db
docker compose -f /opt/paperless/docker-compose.yml logs broker
```

**Common Solutions**:
```bash
# Restart containers
docker compose -f /opt/paperless/docker-compose.yml restart

# Rebuild containers
docker compose -f /opt/paperless/docker-compose.yml down
docker compose -f /opt/paperless/docker-compose.yml up -d --build

# Check disk space
df -h

# Check memory usage
free -h

# Fix permissions
sudo chown -R $USER:$USER /path/to/paperless/directories
```

### 2. Database Connection Issues

**Problem**: Webserver can't connect to PostgreSQL

**Solutions**:
```bash
# Check database container
docker compose -f /opt/paperless/docker-compose.yml logs db

# Test database connection
docker compose -f /opt/paperless/docker-compose.yml exec db psql -U paperless -d paperless -c "SELECT version();"

# Reset database (DESTRUCTIVE - will lose data)
docker compose -f /opt/paperless/docker-compose.yml down -v
docker volume rm paperless_pgdata
docker compose -f /opt/paperless/docker-compose.yml up -d
```

### 3. Permission Issues

**Problem**: Permission denied errors in containers

**Solutions**:
```bash
# Check current user ID
id

# Fix ownership of directories
sudo chown -R $(id -u):$(id -g) /path/to/consume
sudo chown -R $(id -u):$(id -g) /path/to/media
sudo chown -R $(id -u):$(id -g) /path/to/data
sudo chown -R $(id -u):$(id -g) /path/to/export

# Update docker-compose.env
echo "USERMAP_UID=$(id -u)" >> /opt/paperless/docker-compose.env
echo "USERMAP_GID=$(id -g)" >> /opt/paperless/docker-compose.env

# Restart containers
docker compose -f /opt/paperless/docker-compose.yml restart
```

## Web Access Issues

### 1. Can't Access via Domain

**Problem**: HTTPS domain doesn't work

**Diagnostic Steps**:
```bash
# Check DNS resolution
nslookup yourdomain.com

# Test local access
curl -I http://localhost:8000

# Check Caddy status
sudo systemctl status caddy

# View Caddy logs
sudo journalctl -u caddy -f

# Test Caddy config
sudo caddy validate --config /etc/caddy/Caddyfile
```

**Solutions**:
```bash
# Reload Caddy configuration
sudo systemctl reload caddy

# Restart Caddy
sudo systemctl restart caddy

# Check firewall
sudo ufw status
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Manual certificate request
sudo caddy run --config /etc/caddy/Caddyfile
```

### 2. SSL Certificate Issues

**Problem**: SSL certificate errors or warnings

**Solutions**:
```bash
# Check certificate status
echo | openssl s_client -servername yourdomain.com -connect yourdomain.com:443 2>/dev/null | openssl x509 -noout -dates

# Force certificate renewal
sudo systemctl stop caddy
sudo caddy run --config /etc/caddy/Caddyfile
# Press Ctrl+C after certificate is obtained
sudo systemctl start caddy

# Check Let's Encrypt rate limits
# https://letsencrypt.org/docs/rate-limits/
```

### 3. Port Conflicts

**Problem**: Ports 80 or 443 already in use

**Diagnostic**:
```bash
# Check what's using the ports
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :443
sudo lsof -i :80
sudo lsof -i :443
```

**Solutions**:
```bash
# Stop conflicting services
sudo systemctl stop apache2  # if Apache is running
sudo systemctl stop nginx    # if Nginx is running

# Disable conflicting services
sudo systemctl disable apache2
sudo systemctl disable nginx

# Or configure alternative ports in Caddyfile
yourdomain.com:8080 {
    reverse_proxy localhost:8000
}
```

## Performance Issues

### 1. Slow Document Processing

**Problem**: Documents take too long to process

**Solutions**:
```bash
# Check system resources
htop
iotop

# Increase container resources in docker-compose.yml
services:
  webserver:
    deploy:
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 1G

# Check OCR settings in docker-compose.env
PAPERLESS_OCR_LANGUAGE=eng  # Use only needed languages
PAPERLESS_OCR_MODE=skip     # Skip OCR for already-text PDFs
```

### 2. High Memory Usage

**Problem**: System running out of memory

**Solutions**:
```bash
# Monitor memory usage
docker stats

# Reduce PostgreSQL memory usage
# Edit /opt/paperless/docker-compose.yml
services:
  db:
    environment:
      - POSTGRES_SHARED_BUFFERS=128MB
      - POSTGRES_EFFECTIVE_CACHE_SIZE=512MB

# Restart containers
docker compose -f /opt/paperless/docker-compose.yml restart
```

## Data Recovery

### 1. Corrupted Database

**Problem**: Database corruption or data loss

**Recovery Steps**:
```bash
# Stop containers
docker compose -f /opt/paperless/docker-compose.yml down

# Backup current state
sudo cp -r /path/to/data /path/to/data.backup

# Try database repair
docker compose -f /opt/paperless/docker-compose.yml up db -d
docker compose -f /opt/paperless/docker-compose.yml exec db pg_dump -U paperless paperless > backup.sql

# If repair fails, restore from backup
# (Assuming you have a backup from /usr/local/bin/paperless-backup.sh)
zcat /backup/paperless/latest/database.sql.gz | docker compose -f /opt/paperless/docker-compose.yml exec -T db psql -U paperless paperless
```

### 2. Lost Documents

**Problem**: Documents disappeared from web interface

**Solutions**:
```bash
# Check if files exist on disk
ls -la /path/to/media/documents/

# Rebuild search index
docker compose -f /opt/paperless/docker-compose.yml exec webserver document_index reindex

# Re-import documents
docker compose -f /opt/paperless/docker-compose.yml exec webserver document_consumer
```

## Log Analysis

### Understanding Log Files

```bash
# Installation logs
cat logs/install_log_detailed.txt     # Complete installation log
cat logs/install_log_summary.txt      # High-level summary
cat logs/install_log_errors_for_ai.txt # Error descriptions

# System logs
sudo journalctl -u docker -f          # Docker service logs
sudo journalctl -u caddy -f           # Caddy service logs

# Container logs
docker compose -f /opt/paperless/docker-compose.yml logs -f webserver
docker compose -f /opt/paperless/docker-compose.yml logs -f db
docker compose -f /opt/paperless/docker-compose.yml logs -f broker
```

### Common Error Patterns

| Error Message | Likely Cause | Solution |
|---------------|--------------|----------|
| `Permission denied` | File ownership/permissions | Fix with `chown` and `chmod` |
| `Port already in use` | Service conflict | Stop conflicting service |
| `No space left on device` | Disk full | Clean up disk space |
| `Connection refused` | Service not running | Start/restart service |
| `DNS resolution failed` | Network/DNS issue | Check DNS settings |
| `Certificate error` | SSL/TLS issue | Renew certificates |

## Getting Help

### Information to Collect

When seeking help, provide:

1. **System Information**:
   ```bash
   uname -a
   cat /etc/os-release
   docker --version
   docker compose version
   ```

2. **Error Logs**:
   ```bash
   cat logs/install_log_errors_for_ai.txt
   docker compose -f /opt/paperless/docker-compose.yml logs --tail=50
   ```

3. **Configuration**:
   ```bash
   cat /opt/paperless/docker-compose.env | grep -v PASSWORD
   cat /etc/caddy/Caddyfile
   ```

4. **Service Status**:
   ```bash
   systemctl status docker caddy
   docker compose -f /opt/paperless/docker-compose.yml ps
   ```

### Community Resources

- **Paperless-ngx Documentation**: https://docs.paperless-ngx.com/
- **GitHub Issues**: https://github.com/paperless-ngx/paperless-ngx/issues
- **Reddit Community**: r/selfhosted, r/paperless
- **Discord/Matrix**: Check project documentation for chat links

### Professional Support

For production deployments or complex issues, consider:
- Hiring a DevOps consultant
- Using managed hosting services
- Professional Docker/Linux support

---

**Remember**: Always backup your data before attempting major fixes!
