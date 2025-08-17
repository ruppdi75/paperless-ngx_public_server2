#!/bin/bash

# Secure Secret Generation Script for Paperless-ngx
# This script generates secure passwords and secrets for the application

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_color() {
    echo -e "${1}${2}${NC}"
}

# Function to generate secure random password
generate_password() {
    local length=${1:-32}
    openssl rand -base64 $((length * 3 / 4)) | tr -d "=+/" | cut -c1-${length}
}

# Function to generate Django secret key
generate_django_secret() {
    python3 -c "
import secrets
import string
alphabet = string.ascii_letters + string.digits + '!@#$%^&*(-_=+)'
print(''.join(secrets.choice(alphabet) for i in range(50)))
"
}

# Function to mask password for display
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

# Check if .env already exists
if [ -f ".env" ]; then
    print_color "$YELLOW" "Warning: .env file already exists!"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_color "$BLUE" "Exiting without changes."
        exit 0
    fi
fi

# Check if .env.template exists
if [ ! -f ".env.template" ]; then
    print_color "$RED" "Error: .env.template not found!"
    exit 1
fi

print_color "$BLUE" "🔐 Generating secure credentials for Paperless-ngx..."

# Generate secure passwords
DB_PASSWORD=$(generate_password 32)
DJANGO_SECRET=$(generate_django_secret)

# Get user input for admin credentials
echo
print_color "$YELLOW" "📝 Admin User Configuration:"
read -p "Enter admin username: " ADMIN_USERNAME
while true; do
    read -s -p "Enter secure admin password (min 12 chars): " ADMIN_PASSWORD
    echo
    if [[ ${#ADMIN_PASSWORD} -lt 12 ]]; then
        print_color "$RED" "Password must be at least 12 characters long"
        continue
    fi
    break
done

read -p "Enter admin email: " ADMIN_EMAIL

# Optional: Email configuration
echo
print_color "$YELLOW" "📧 Email Configuration (optional - press Enter to skip):"
read -p "SMTP Host (e.g., smtp.gmail.com): " SMTP_HOST
if [ ! -z "$SMTP_HOST" ]; then
    read -p "SMTP Port (e.g., 587): " SMTP_PORT
    read -p "Email username: " EMAIL_USER
    read -s -p "Email password/app password: " EMAIL_PASSWORD
    echo
    read -p "Use TLS? (y/N): " USE_TLS
    
    # IMAP settings for email consumption
    read -p "IMAP Host (e.g., imap.gmail.com): " IMAP_HOST
    if [ ! -z "$IMAP_HOST" ]; then
        read -p "IMAP Port (e.g., 993): " IMAP_PORT
        read -p "Use SSL for IMAP? (Y/n): " USE_SSL
    fi
fi

# Domain configuration
echo
print_color "$YELLOW" "🌐 Domain Configuration:"
read -p "Enter your domain (e.g., paperless.example.com) or press Enter for localhost: " DOMAIN
if [ -z "$DOMAIN" ]; then
    ALLOWED_HOSTS="localhost,127.0.0.1"
    CORS_HOSTS="http://localhost:8000"
else
    ALLOWED_HOSTS="localhost,127.0.0.1,$DOMAIN"
    CORS_HOSTS="http://localhost:8000,https://$DOMAIN"
fi

# Create .env file from template
cp .env.template .env

# Replace placeholders with actual values
sed -i "s/YOUR_SECURE_DB_PASSWORD_HERE/$DB_PASSWORD/g" .env
sed -i "s/YOUR_DJANGO_SECRET_KEY_HERE/$DJANGO_SECRET/g" .env
sed -i "s/YOUR_ADMIN_USERNAME_HERE/$ADMIN_USERNAME/g" .env
sed -i "s/YOUR_SECURE_ADMIN_PASSWORD_HERE/$ADMIN_PASSWORD/g" .env
sed -i "s/admin@localhost/$ADMIN_EMAIL/g" .env
sed -i "s/your-domain.com/$DOMAIN/g" .env

# Configure email if provided
if [ ! -z "$SMTP_HOST" ]; then
    sed -i "s/# PAPERLESS_EMAIL_HOST=smtp.gmail.com/PAPERLESS_EMAIL_HOST=$SMTP_HOST/g" .env
    sed -i "s/# PAPERLESS_EMAIL_PORT=587/PAPERLESS_EMAIL_PORT=$SMTP_PORT/g" .env
    sed -i "s/# PAPERLESS_EMAIL_HOST_USER=your-email@example.com/PAPERLESS_EMAIL_HOST_USER=$EMAIL_USER/g" .env
    sed -i "s/# PAPERLESS_EMAIL_HOST_PASSWORD=YOUR_EMAIL_APP_PASSWORD_HERE/PAPERLESS_EMAIL_HOST_PASSWORD=$EMAIL_PASSWORD/g" .env
    
    if [[ $USE_TLS =~ ^[Yy]$ ]]; then
        sed -i "s/# PAPERLESS_EMAIL_USE_TLS=true/PAPERLESS_EMAIL_USE_TLS=true/g" .env
    fi
    
    # IMAP configuration
    if [ ! -z "$IMAP_HOST" ]; then
        sed -i "s/# PAPERLESS_EMAIL_TASK_CRON=\"\*\/10 \* \* \* \*\"/PAPERLESS_EMAIL_TASK_CRON=\"*\/10 * * * *\"/g" .env
        sed -i "s/# PAPERLESS_EMAIL_HOST=imap.gmail.com/PAPERLESS_EMAIL_HOST=$IMAP_HOST/g" .env
        sed -i "s/# PAPERLESS_EMAIL_PORT=993/PAPERLESS_EMAIL_PORT=$IMAP_PORT/g" .env
        
        if [[ ! $USE_SSL =~ ^[Nn]$ ]]; then
            sed -i "s/# PAPERLESS_EMAIL_USE_SSL=true/PAPERLESS_EMAIL_USE_SSL=true/g" .env
        fi
    fi
fi

# Set proper permissions
chmod 600 .env

print_color "$GREEN" "✅ Secure configuration generated successfully!"
echo
print_color "$BLUE" "📋 Configuration Summary:"
echo "Database Password: $(mask_password "$DB_PASSWORD")"
echo "Admin Username: $ADMIN_USERNAME"
echo "Admin Password: $(mask_password "$ADMIN_PASSWORD")"
echo "Admin Email: $ADMIN_EMAIL"
if [ ! -z "$SMTP_HOST" ]; then
    echo "SMTP Host: $SMTP_HOST"
    echo "Email User: $EMAIL_USER"
    echo "Email Password: $(mask_password "$EMAIL_PASSWORD")"
fi
echo
print_color "$YELLOW" "⚠️  Important Security Notes:"
echo "1. The .env file contains sensitive information - never commit it to version control"
echo "2. Backup your .env file securely"
echo "3. Use strong, unique passwords for all accounts"
echo "4. Enable 2FA where possible"
echo "5. Regularly rotate passwords"
echo
print_color "$GREEN" "🚀 You can now run the installation script safely!"
