#!/bin/bash

# Credential Cleanup Script for GitGuardian Security Issues
# This script removes any potentially exposed credentials from git history

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

print_color "$BLUE" "🔐 GitGuardian Security Cleanup Script"
echo

# Check if BFG Repo-Cleaner is available
if ! command -v java &> /dev/null; then
    print_color "$RED" "Java is required for BFG Repo-Cleaner but not installed."
    print_color "$YELLOW" "Install Java: sudo apt install default-jre"
    exit 1
fi

# Download BFG if not present
if [ ! -f "bfg.jar" ]; then
    print_color "$YELLOW" "Downloading BFG Repo-Cleaner..."
    wget -O bfg.jar https://repo1.maven.org/maven2/com/madgag/bfg/1.14.0/bfg-1.14.0.jar
fi

print_color "$YELLOW" "⚠️  WARNING: This will rewrite git history!"
print_color "$YELLOW" "Make sure you have a backup of your repository."
echo
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_color "$BLUE" "Cleanup cancelled."
    exit 0
fi

# Create patterns file for sensitive data
cat > sensitive-patterns.txt << EOF
your-app-password
your-email-password
demo@lumi-systems.io
SecurePassword123!
paperless
change-me-to-a-random-string
EOF

print_color "$BLUE" "Cleaning sensitive patterns from git history..."

# Use BFG to remove sensitive patterns
java -jar bfg.jar --replace-text sensitive-patterns.txt --no-blob-protection .

print_color "$GREEN" "✅ Sensitive patterns removed from git history"

# Clean up references
print_color "$BLUE" "Cleaning up git references..."
git reflog expire --expire=now --all
git gc --prune=now --aggressive

print_color "$GREEN" "✅ Git cleanup completed"

# Remove temporary files
rm -f sensitive-patterns.txt bfg.jar

print_color "$YELLOW" "📋 Next Steps:"
echo "1. Force push to remote: git push --force-with-lease origin main"
echo "2. Notify team members to re-clone the repository"
echo "3. Rotate any potentially exposed credentials"
echo "4. Update GitGuardian to acknowledge the fix"

print_color "$GREEN" "🔐 Security cleanup completed!"
