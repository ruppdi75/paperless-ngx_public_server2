# Contributing to Paperless-ngx Installation Script

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

## How to Contribute

### Reporting Issues

1. **Search existing issues** first to avoid duplicates
2. **Use the issue template** when creating new issues
3. **Provide detailed information**:
   - Operating system and version
   - Error messages and logs
   - Steps to reproduce
   - Expected vs actual behavior

### Submitting Changes

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature-name`
3. **Make your changes** following our coding standards
4. **Test thoroughly** on supported operating systems
5. **Update documentation** if needed
6. **Submit a pull request**

### Development Setup

```bash
# Clone your fork
git clone https://github.com/yourusername/paperless-ngx_public_server.git
cd paperless-ngx_public_server

# Create a test environment
mkdir test-environment
cd test-environment

# Test the script (in a VM or container)
sudo ../install_paperless_ngx.sh
```

## Coding Standards

### Bash Script Guidelines

- Use `set -euo pipefail` for error handling
- Quote all variables: `"$VARIABLE"`
- Use meaningful function names
- Add comments for complex logic
- Follow consistent indentation (4 spaces)

### Documentation Standards

- Use clear, concise language
- Include code examples
- Update README if adding features
- Maintain consistent formatting

### Testing Requirements

- Test on Ubuntu 20.04+ and 22.04+
- Test with different user configurations
- Verify all installation phases work correctly
- Test error handling and recovery

## Pull Request Process

1. **Ensure tests pass** on supported systems
2. **Update documentation** for any new features
3. **Follow commit message format**:
   ```
   type(scope): description
   
   Longer description if needed
   
   Fixes #issue-number
   ```

4. **Request review** from maintainers
5. **Address feedback** promptly

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn and grow
- Follow the project's goals and vision

## Areas for Contribution

### High Priority
- Additional OS support (Debian, CentOS, etc.)
- Enhanced error recovery mechanisms
- Automated testing framework
- Performance optimizations

### Medium Priority
- Additional configuration options
- Integration with monitoring systems
- Backup automation improvements
- Security enhancements

### Documentation
- Translation to other languages
- Video tutorials
- FAQ expansion
- Use case examples

## Getting Help

- **GitHub Issues**: For bugs and feature requests
- **Discussions**: For questions and general discussion
- **Documentation**: Check existing docs first

## Recognition

Contributors will be recognized in:
- README.md contributors section
- Release notes
- Project documentation

Thank you for helping make this project better!
