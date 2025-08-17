# Configuration Guide

This guide covers advanced configuration options for your Paperless-ngx installation.

## Environment Variables

The main configuration is handled through environment variables in `/opt/paperless/docker-compose.env`.

### Core Settings

```bash
# Basic Configuration
PAPERLESS_URL=https://yourdomain.com
PAPERLESS_TIME_ZONE=Europe/Berlin
PAPERLESS_OCR_LANGUAGE=deu+eng

# Security Settings
PAPERLESS_SECRET_KEY=your-secret-key-here
PAPERLESS_ALLOWED_HOSTS=yourdomain.com,localhost,127.0.0.1

# Database Configuration (PostgreSQL)
PAPERLESS_DBHOST=db
PAPERLESS_DBNAME=paperless
PAPERLESS_DBUSER=paperless
PAPERLESS_DBPASS=paperless

# Redis Configuration
PAPERLESS_REDIS=redis://broker:6379

# User Mapping
USERMAP_UID=1000
USERMAP_GID=1000
```

### Advanced Features

```bash
# Email Configuration
PAPERLESS_EMAIL_HOST=smtp.gmail.com
PAPERLESS_EMAIL_PORT=587
PAPERLESS_EMAIL_HOST_USER=your-email@gmail.com
PAPERLESS_EMAIL_HOST_PASSWORD=${EMAIL_APP_PASSWORD}
PAPERLESS_EMAIL_USE_TLS=true

# Consumer Settings
PAPERLESS_CONSUMER_POLLING=30
PAPERLESS_CONSUMER_DELETE_DUPLICATES=true
PAPERLESS_CONSUMER_RECURSIVE=true
PAPERLESS_CONSUMER_SUBDIRS_AS_TAGS=true

# OCR Settings
PAPERLESS_OCR_LANGUAGE=deu+eng
PAPERLESS_OCR_MODE=skip
PAPERLESS_OCR_SKIP_ARCHIVE_FILE=with_text
PAPERLESS_OCR_CLEAN=clean-final
PAPERLESS_OCR_DESKEW=true
PAPERLESS_OCR_ROTATE_PAGES=true
PAPERLESS_OCR_ROTATE_PAGES_THRESHOLD=12.0

# Tika Integration (for Office documents)
PAPERLESS_TIKA_ENABLED=1
PAPERLESS_TIKA_GOTENBERG_ENDPOINT=http://gotenberg:3000
PAPERLESS_TIKA_ENDPOINT=http://tika:9998

# Filename Formatting
PAPERLESS_FILENAME_FORMAT={created_year}/{correspondent}/{title}
```

## Docker Compose Customization

### Adding Tika and Gotenberg Services

Edit `/opt/paperless/docker-compose.yml` to add document parsing capabilities:

```yaml
services:
  # ... existing services ...

  gotenberg:
    image: gotenberg/gotenberg:7
    restart: unless-stopped
    command:
      - "gotenberg"
      - "--chromium-disable-javascript=true"
      - "--chromium-allow-list=file:///tmp/.*"

  tika:
    image: apache/tika:latest
    restart: unless-stopped
```

### Custom Volume Mounts

```yaml
services:
  webserver:
    volumes:
      - /path/to/consume:/usr/src/paperless/consume
      - /path/to/media:/usr/src/paperless/media
      - /path/to/data:/usr/src/paperless/data
      - /path/to/export:/usr/src/paperless/export
      # Add custom directories
      - /path/to/templates:/usr/src/paperless/templates
      - /path/to/scripts:/usr/src/paperless/scripts
```

## Caddy Configuration

### Basic Reverse Proxy (`/etc/caddy/Caddyfile`)

```caddy
yourdomain.com {
    encode zstd gzip
    reverse_proxy localhost:8000
    
    # Security headers
    header {
        # Enable HSTS
        Strict-Transport-Security max-age=31536000;
        # Prevent MIME type sniffing
        X-Content-Type-Options nosniff
        # Enable XSS protection
        X-XSS-Protection "1; mode=block"
        # Prevent clickjacking
        X-Frame-Options DENY
        # Content Security Policy
        Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'"
    }
}
```

### Advanced Caddy Configuration

```caddy
yourdomain.com {
    encode zstd gzip
    
    # Rate limiting
    rate_limit {
        zone dynamic {
            key {remote_host}
            events 100
            window 1m
        }
    }
    
    # Logging
    log {
        output file /var/log/caddy/paperless.log {
            roll_size 100mb
            roll_keep 5
            roll_keep_for 720h
        }
        format json
    }
    
    # Custom error pages
    handle_errors {
        @5xx expression {http.error.status_code} >= 500
        handle @5xx {
            respond "Service temporarily unavailable" 503
        }
    }
    
    reverse_proxy localhost:8000 {
        # Health check
        health_uri /
        health_interval 30s
        health_timeout 5s
        
        # Load balancing (if multiple instances)
        lb_policy round_robin
    }
}

# Redirect www to non-www
www.yourdomain.com {
    redir https://yourdomain.com{uri} permanent
}
```

## Database Configuration

### PostgreSQL Tuning

Create `/opt/paperless/postgres.conf`:

```ini
# Memory settings
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 4MB
maintenance_work_mem = 64MB

# Checkpoint settings
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100

# Connection settings
max_connections = 100

# Logging
log_statement = 'none'
log_min_duration_statement = 1000
```

Mount it in docker-compose.yml:

```yaml
services:
  db:
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./postgres.conf:/etc/postgresql/postgresql.conf
    command: postgres -c config_file=/etc/postgresql/postgresql.conf
```

## Security Hardening

### 1. Firewall Configuration

```bash
# UFW (Ubuntu Firewall)
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# iptables (alternative)
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -j DROP
```

### 2. Fail2Ban Configuration

```bash
# Install fail2ban
sudo apt install fail2ban

# Create jail for Caddy
sudo tee /etc/fail2ban/jail.d/caddy.conf << EOF
[caddy]
enabled = true
port = http,https
filter = caddy
logpath = /var/log/caddy/*.log
maxretry = 5
bantime = 3600
findtime = 600
EOF

# Create filter
sudo tee /etc/fail2ban/filter.d/caddy.conf << EOF
[Definition]
failregex = ^.*"remote_ip":"<HOST>".*"status":(?:401|403|404).*$
ignoreregex =
EOF

sudo systemctl restart fail2ban
```

### 3. SSL/TLS Hardening

Add to Caddyfile:

```caddy
yourdomain.com {
    # Force HTTPS
    tls {
        protocols tls1.2 tls1.3
        ciphers TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384 TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
    }
    
    # HSTS with preload
    header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
    
    # ... rest of configuration
}
```

## Backup Configuration

### Automated Backup Script

```bash
#!/bin/bash
# /usr/local/bin/paperless-backup.sh

set -euo pipefail

BACKUP_DIR="/backup/paperless"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="$BACKUP_DIR/$DATE"
RETENTION_DAYS=30

# Create backup directory
mkdir -p "$BACKUP_PATH"

# Database backup
echo "Backing up database..."
docker compose -f /opt/paperless/docker-compose.yml exec -T db pg_dump -U paperless paperless | gzip > "$BACKUP_PATH/database.sql.gz"

# Media files backup
echo "Backing up media files..."
tar -czf "$BACKUP_PATH/media.tar.gz" -C /path/to/media .

# Data directory backup
echo "Backing up data directory..."
tar -czf "$BACKUP_PATH/data.tar.gz" -C /path/to/data .

# Configuration backup
echo "Backing up configuration..."
tar -czf "$BACKUP_PATH/config.tar.gz" -C /opt/paperless .
cp /etc/caddy/Caddyfile "$BACKUP_PATH/"

# Cleanup old backups
echo "Cleaning up old backups..."
find "$BACKUP_DIR" -type d -mtime +$RETENTION_DAYS -exec rm -rf {} +

# Create latest symlink
ln -sfn "$BACKUP_PATH" "$BACKUP_DIR/latest"

echo "Backup completed: $BACKUP_PATH"
```

### Restore Script

```bash
#!/bin/bash
# /usr/local/bin/paperless-restore.sh

set -euo pipefail

BACKUP_PATH=$1

if [ -z "$BACKUP_PATH" ]; then
    echo "Usage: $0 /path/to/backup"
    exit 1
fi

echo "Stopping services..."
docker compose -f /opt/paperless/docker-compose.yml down

echo "Restoring database..."
zcat "$BACKUP_PATH/database.sql.gz" | docker compose -f /opt/paperless/docker-compose.yml exec -T db psql -U paperless paperless

echo "Restoring media files..."
tar -xzf "$BACKUP_PATH/media.tar.gz" -C /path/to/media

echo "Restoring data directory..."
tar -xzf "$BACKUP_PATH/data.tar.gz" -C /path/to/data

echo "Restoring configuration..."
tar -xzf "$BACKUP_PATH/config.tar.gz" -C /opt/paperless

echo "Starting services..."
docker compose -f /opt/paperless/docker-compose.yml up -d

echo "Restore completed!"
```

## Monitoring and Maintenance

### Health Check Script

```bash
#!/bin/bash
# /usr/local/bin/paperless-health.sh

# Check container status
if ! docker compose -f /opt/paperless/docker-compose.yml ps | grep -q "Up"; then
    echo "ERROR: Some containers are not running"
    exit 1
fi

# Check web service
if ! curl -f -s http://localhost:8000 > /dev/null; then
    echo "ERROR: Web service not responding"
    exit 1
fi

# Check disk space
DISK_USAGE=$(df /opt/paperless | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 90 ]; then
    echo "WARNING: Disk usage is ${DISK_USAGE}%"
fi

# Check database connection
if ! docker compose -f /opt/paperless/docker-compose.yml exec -T db pg_isready -U paperless > /dev/null; then
    echo "ERROR: Database not responding"
    exit 1
fi

echo "All systems operational"
```

### Log Rotation

```bash
# /etc/logrotate.d/paperless
/var/log/caddy/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 caddy caddy
    postrotate
        systemctl reload caddy
    endscript
}
```

## Performance Optimization

### Redis Configuration

Create `/opt/paperless/redis.conf`:

```ini
# Memory management
maxmemory 256mb
maxmemory-policy allkeys-lru

# Persistence
save 900 1
save 300 10
save 60 10000

# Network
tcp-keepalive 300
timeout 0
```

### PostgreSQL Performance

```ini
# In postgres.conf
shared_buffers = 25% of RAM
effective_cache_size = 75% of RAM
random_page_cost = 1.1
effective_io_concurrency = 200
```

## Integration Examples

### Email Consumption

```bash
# Environment variables for email fetching
PAPERLESS_CONSUMER_ENABLE_BARCODES=true
PAPERLESS_CONSUMER_BARCODE_TIFF_SUPPORT=true

# Email settings
PAPERLESS_EMAIL_TASK_CRON="*/10 * * * *"
PAPERLESS_EMAIL_HOST=imap.gmail.com
PAPERLESS_EMAIL_PORT=993
PAPERLESS_EMAIL_HOST_USER=your-email@gmail.com
PAPERLESS_EMAIL_HOST_PASSWORD=${EMAIL_APP_PASSWORD}
PAPERLESS_EMAIL_USE_SSL=true
```

### API Integration

```python
# Python example for API usage
import requests

API_URL = "https://yourdomain.com/api"
TOKEN = "your-api-token"

headers = {"Authorization": f"Token {TOKEN}"}

# Upload document
with open("document.pdf", "rb") as f:
    response = requests.post(
        f"{API_URL}/documents/post_document/",
        files={"document": f},
        headers=headers
    )

print(response.json())
```

---

**Next Steps**: See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues and solutions.
