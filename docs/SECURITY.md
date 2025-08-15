# Security Guide

## Network Security

### Firewall Setup
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

### Fail2Ban Protection
```bash
sudo apt install fail2ban
sudo tee /etc/fail2ban/jail.d/caddy.conf << 'EOF'
[caddy]
enabled = true
port = http,https
filter = caddy
logpath = /var/log/caddy/*.log
maxretry = 5
bantime = 3600
EOF
```

## SSL/TLS Security

### Strong Caddy Configuration
```caddy
yourdomain.com {
    tls {
        protocols tls1.2 tls1.3
    }
    
    header {
        Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
        X-Content-Type-Options "nosniff"
        X-Frame-Options "DENY"
        Content-Security-Policy "default-src 'self'"
    }
    
    reverse_proxy localhost:8000
}
```

## Container Security

### Docker Hardening
```yaml
services:
  webserver:
    user: "${USERMAP_UID}:${USERMAP_GID}"
    read_only: true
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
```

## Backup Security

### Encrypted Backups
```bash
# Create encrypted backup
tar -czf - /path/to/data | gpg --encrypt --recipient your-email@example.com > backup.tar.gz.gpg
```

## Best Practices

1. **Strong Passwords**: Use 12+ character passwords
2. **Regular Updates**: Keep system and containers updated
3. **Monitor Logs**: Check logs regularly for suspicious activity
4. **Backup Strategy**: Implement automated encrypted backups
5. **Access Control**: Use principle of least privilege
