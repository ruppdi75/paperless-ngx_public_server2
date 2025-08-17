# 🔐 Security Guide for Paperless-ngx

This guide provides comprehensive security recommendations for deploying Paperless-ngx safely.

## Quick Start - Secure Setup

### 1. Generate Secure Configuration
```bash
# Run the secure credential generation script
./scripts/generate_secrets.sh
```

This script will:
- Generate strong random passwords
- Create a secure Django secret key
- Set up proper environment variables
- Configure email settings securely

### 2. Verify Security Settings
- Ensure `.env` file has proper permissions (600)
- Confirm `.env` is in `.gitignore`
- Use environment variables for all sensitive data

## Security Best Practices

### 🔑 Credential Management

#### ✅ DO:
- Use the provided `.env.template` and `generate_secrets.sh`
- Generate passwords with minimum 12 characters
- Use unique passwords for each service
- Store credentials in environment variables
- Use app-specific passwords for email services
- Regularly rotate passwords

#### ❌ DON'T:
- Hardcode passwords in configuration files
- Commit `.env` files to version control
- Use default or weak passwords
- Share credentials in plain text
- Store credentials in documentation

### 📧 Email Security

For email integration (like demo@lumi-systems.io):

#### Secure Configuration:
```bash
# Use app-specific passwords, not account passwords
PAPERLESS_EMAIL_HOST_PASSWORD=your-app-specific-password

# Enable encryption
PAPERLESS_EMAIL_USE_TLS=true
PAPERLESS_EMAIL_USE_SSL=true
```

#### Email Provider Setup:
1. **Gmail**: Use App Passwords, not your main password
2. **Outlook**: Use App Passwords with 2FA enabled
3. **Custom SMTP**: Ensure TLS/SSL is enabled

### 🐳 Docker Security

#### Container Security:
- Run containers as non-root user
- Use specific image tags, not `latest`
- Regularly update base images
- Limit container resources

#### Network Security:
- Bind services to localhost only: `127.0.0.1:8000:8000`
- Use reverse proxy (Caddy/Nginx) for HTTPS
- Configure proper firewall rules

### 🌐 Web Security

#### HTTPS Configuration:
```bash
# Always use HTTPS in production
PAPERLESS_ALLOWED_HOSTS=your-domain.com
PAPERLESS_CORS_ALLOWED_HOSTS=https://your-domain.com
```

#### Additional Headers:
- Enable HSTS
- Set proper CSP headers
- Configure secure cookies

### 📁 File System Security

#### Permissions:
```bash
# Set proper ownership
chown -R paperless:paperless /opt/paperless/

# Secure permissions
chmod 750 /opt/paperless/
chmod 600 /opt/paperless/.env
```

#### Backup Security:
```bash
# Encrypted backups
tar -czf - /opt/paperless/data | gpg --encrypt --recipient admin@yourdomain.com > backup.tar.gz.gpg
```

## Environment Variables Reference

### Required Security Variables:
```bash
# Database
POSTGRES_PASSWORD=secure-random-password-32-chars

# Django
PAPERLESS_SECRET_KEY=django-secret-key-50-chars
PAPERLESS_ALLOWED_HOSTS=localhost,127.0.0.1,your-domain.com

# Admin User
DJANGO_SUPERUSER_USERNAME=your-admin-username
DJANGO_SUPERUSER_PASSWORD=secure-admin-password-12-chars-min
```

### Optional Email Variables:
```bash
# SMTP Configuration
PAPERLESS_EMAIL_HOST=smtp.gmail.com
PAPERLESS_EMAIL_PORT=587
PAPERLESS_EMAIL_HOST_USER=your-email@domain.com
PAPERLESS_EMAIL_HOST_PASSWORD=app-specific-password
PAPERLESS_EMAIL_USE_TLS=true

# IMAP Configuration (for email consumption)
PAPERLESS_EMAIL_HOST=imap.gmail.com
PAPERLESS_EMAIL_PORT=993
PAPERLESS_EMAIL_USE_SSL=true
```

## Security Checklist

### Pre-Deployment:
- [ ] Generated secure passwords using `generate_secrets.sh`
- [ ] Configured `.env` file with proper permissions
- [ ] Verified `.env` is in `.gitignore`
- [ ] Set up email with app-specific passwords
- [ ] Configured HTTPS/TLS for all connections

### Post-Deployment:
- [ ] Changed default admin password
- [ ] Enabled 2FA where possible
- [ ] Set up automated backups
- [ ] Configured log monitoring
- [ ] Updated all containers to latest versions

### Regular Maintenance:
- [ ] Rotate passwords quarterly
- [ ] Update container images monthly
- [ ] Review access logs weekly
- [ ] Test backup restoration quarterly

## Incident Response

### If Credentials Are Compromised:
1. Immediately rotate all passwords
2. Review access logs for suspicious activity
3. Update `.env` file with new credentials
4. Restart all services
5. Notify relevant stakeholders

### If System Is Breached:
1. Isolate the system
2. Preserve logs for analysis
3. Restore from clean backup
4. Implement additional security measures
5. Conduct security audit

## Additional Resources

- [OWASP Security Guidelines](https://owasp.org/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [Django Security Documentation](https://docs.djangoproject.com/en/stable/topics/security/)

## Support

For security-related questions or to report vulnerabilities:
- Review this security guide
- Check the troubleshooting documentation
- Follow responsible disclosure practices
