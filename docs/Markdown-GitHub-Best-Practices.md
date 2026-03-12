# Markdown and GitHub Best Practices Guide

This guide outlines best practices for creating effective documentation using Markdown and GitHub-specific features for the MarquezHouse project.

## Table of Contents

- [Document Structure](#document-structure)
- [Markdown Syntax](#markdown-syntax)
- [GitHub-Specific Features](#github-specific-features)
- [Documentation Organization](#documentation-organization)
- [README Best Practices](#readme-best-practices)
- [PowerShell Code Documentation](#powershell-code-documentation)
- [Accessibility Guidelines](#accessibility-guidelines)
- [Documentation Maintenance](#documentation-maintenance)

## Document Structure

### Consistent Heading Hierarchy

```markdown
# Document Title (H1) - Use only once per document
## Major Section (H2)
### Subsection (H3)
#### Sub-subsection (H4)
##### Detail Level (H5)
###### Rarely Used (H6)
```

### Project TOC Structure

For documents longer than 3 sections, include a TOC:

```markdown
## Table of Contents

- [Installation](#installation)
- [Configuration](#configuration)
  - [Basic Setup](#basic-setup)
  - [Advanced Options](#advanced-options)
- [Usage Examples](#usage-examples)
- [Troubleshooting](#troubleshooting)
```

### Document Metadata

Include frontmatter for complex documents:

```markdown
---
title: "PowerShell Audio Automation Guide"
description: "Complete guide for setting up automated audio control"
author: "Eric Marquez"
date: "2025-06-27"
version: "1.0"
tags: ["powershell", "automation", "audio", "windows"]
---
```

## Markdown Syntax

### Headers and Formatting

```markdown
# ✅ Good: Clear, descriptive headers
## Setting Up Audio Automation
### Prerequisites

# ✅ Good: Emphasis usage
**Important:** Always run scripts as Administrator
*Note:* This feature requires Windows 10 or later
***Critical:*** Back up your system before making changes

# ❌ Bad: Inconsistent or unclear headers
## setup
### some stuff
```

### Code Blocks

Always specify the language for syntax highlighting:

```markdown
# ✅ Good: Language-specific code blocks
```powershell
# PowerShell script example
$currentTime = Get-Date
Write-Host "Current time: $currentTime"
```

```json
{
  "businessHours": {
    "start": 8,
    "end": 17
  }
}
```

```bash
# Bash commands
chmod +x script.sh
./script.sh
```

# ✅ Good: Inline code for file names and short snippets
Run the `MuteAudio.ps1` script to control audio settings.
Use the `$env:USERNAME` variable to get the current user.
```

### Lists and Tables

```markdown
# ✅ Good: Ordered lists for sequential steps
1. Open PowerShell as Administrator
2. Navigate to the script directory
3. Run the installation script
4. Verify the scheduled task was created

# ✅ Good: Unordered lists for features or options
- Audio muting/unmuting
- Scheduled task management
- Error logging
- Configuration file support

# ✅ Good: Task lists for project tracking
- [x] Create audio control script
- [x] Add error handling
- [ ] Implement configuration file
- [ ] Add unit tests

# ✅ Good: Tables for structured data
| Parameter | Type   | Required | Default | Description               |
| --------- | ------ | -------- | ------- | ------------------------- |
| StartHour | int    | No       | 8       | Business hours start time |
| EndHour   | int    | No       | 17      | Business hours end time   |
| Force     | switch | No       | false   | Force execution           |
```

### Links and References

```markdown
# ✅ Good: Descriptive link text
For more information, see the [PowerShell documentation](https://docs.microsoft.com/powershell/).
Download the latest version from our [releases page](./releases).

# ✅ Good: Reference-style links for cleaner text
Check out the [official PowerShell guide][ps-guide] and [Windows API documentation][win-api].

[ps-guide]: https://docs.microsoft.com/powershell/
[win-api]: https://docs.microsoft.com/windows/win32/api/

# ✅ Good: Relative links for internal documentation
See also: [Installation Guide](./installation.md) | [Troubleshooting](./troubleshooting.md)

# ❌ Bad: Non-descriptive links
Click [here](https://example.com) for more info.
See https://docs.microsoft.com/powershell/ for details.
```

### Images and Media

```markdown
# ✅ Good: Descriptive alt text and titles
![PowerShell script execution in Windows Terminal](./images/powershell-execution.png "Running the MuteAudio script")

# ✅ Good: Responsive images with HTML
<img src="./images/architecture-diagram.png" alt="System architecture diagram" width="600" title="MarquezHouse automation architecture">

# ✅ Good: Badges for status indicators
![Build Status](https://img.shields.io/github/workflow/status/username/repo/CI)
![Version](https://img.shields.io/github/v/release/username/repo)
![License](https://img.shields.io/github/license/username/repo)
```

## GitHub-Specific Features

### Issue and Pull Request Templates

Create `.github/ISSUE_TEMPLATE/bug_report.md`:

```markdown
---
name: Bug report
about: Create a report to help us improve
title: '[BUG] '
labels: 'bug'
assignees: ''
---

## Bug Description
A clear and concise description of what the bug is.

## To Reproduce
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

## Expected Behavior
A clear description of what you expected to happen.

## Screenshots
If applicable, add screenshots to help explain your problem.

## Environment
- OS: [e.g. Windows 11]
- PowerShell Version: [e.g. 7.3.0]
- Script Version: [e.g. 1.2.0]

## Additional Context
Add any other context about the problem here.
```

### Pull Request Template

Create `.github/pull_request_template.md`:

```markdown
## Description
Brief description of the changes in this PR.

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing
- [ ] I have tested my changes locally
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes

## Checklist
- [ ] My code follows the style guidelines of this project
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
```

### GitHub Actions Integration

```markdown
# ✅ Good: Document CI/CD status
## Build Status

| Branch  | Status                                                                        | Coverage                                                                        |
| ------- | ----------------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| main    | ![CI](https://github.com/username/repo/workflows/CI/badge.svg?branch=main)    | ![Coverage](https://codecov.io/gh/username/repo/branch/main/graph/badge.svg)    |
| develop | ![CI](https://github.com/username/repo/workflows/CI/badge.svg?branch=develop) | ![Coverage](https://codecov.io/gh/username/repo/branch/develop/graph/badge.svg) |
```

## Documentation Organization

### File Structure

```
docs/
├── README.md                 # Main documentation entry point
├── installation/
│   ├── README.md            # Installation overview
│   ├── windows.md           # Windows-specific installation
│   └── prerequisites.md     # System requirements
├── configuration/
│   ├── README.md            # Configuration overview
│   ├── audio-settings.md    # Audio configuration
│   └── scheduled-tasks.md   # Task scheduling
├── guides/
│   ├── getting-started.md   # Quick start guide
│   ├── advanced-usage.md    # Advanced features
│   └── troubleshooting.md   # Common issues and solutions
├── api/
│   ├── README.md            # API documentation overview
│   └── powershell-modules.md # PowerShell module reference
└── contributing/
    ├── README.md            # Contribution guidelines
    ├── code-style.md        # Coding standards
    └── testing.md           # Testing procedures
```

### Cross-References

```markdown
# ✅ Good: Create logical connections between documents
For installation instructions, see the [Installation Guide](./installation/README.md).

Before configuring audio settings, ensure you've completed the [Prerequisites](./installation/prerequisites.md).

If you encounter issues, check the [Troubleshooting Guide](./guides/troubleshooting.md).

Related topics:
- [PowerShell Best Practices](./PowerShell-Best-Practices.md)
- [Configuration Management](./configuration/README.md)
- [API Reference](./api/powershell-modules.md)
```

## README Best Practices

### Complete README Structure

```markdown
# Project Name

Brief, compelling description of what the project does.

[![Build Status](https://img.shields.io/github/workflow/status/username/repo/CI)](https://github.com/username/repo/actions)
[![Version](https://img.shields.io/github/v/release/username/repo)](https://github.com/username/repo/releases)
[![License](https://img.shields.io/github/license/username/repo)](LICENSE)

## Features

- 🔇 Automatic audio muting based on business hours
- ⏰ Configurable scheduled tasks
- 📋 Comprehensive logging
- ⚙️ Easy configuration management
- 🔒 Security-first design

## Quick Start

```powershell
# Clone the repository
git clone https://github.com/username/MarquezHouse.git

# Navigate to the audio automation directory
cd MarquezHouse/src/Computer/Audio

# Run the audio control script
.\MuteAudio.ps1
```

## Installation

### Prerequisites

- Windows 10/11
- PowerShell 5.1 or later
- Administrator privileges

### Setup

1. **Download the scripts**
   ```powershell
   git clone https://github.com/username/MarquezHouse.git
   ```

2. **Configure execution policy**
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

3. **Run the setup script**
   ```powershell
   .\Setup.ps1
   ```

## Usage

### Basic Usage

```powershell
# Automatic mode (default)
.\MuteAudio.ps1

# Custom business hours
.\MuteAudio.ps1 -StartBusinessHour 9 -EndBusinessHour 18

# Force mute regardless of time
.\MuteAudio.ps1 -Force -Action Mute
```

### Configuration

Create a `config.json` file:

```json
{
  "businessHours": {
    "start": 8,
    "end": 17
  },
  "logging": {
    "enabled": true,
    "level": "Info"
  }
}
```

## Documentation

- [Installation Guide](docs/installation/README.md)
- [Configuration Reference](docs/configuration/README.md)
- [PowerShell Best Practices](docs/PowerShell-Best-Practices.md)
- [API Documentation](docs/api/README.md)
- [Troubleshooting](docs/guides/troubleshooting.md)

## Contributing

We welcome contributions! Please read our [Contributing Guidelines](CONTRIBUTING.md) and [Code of Conduct](CODE_OF_CONDUCT.md).

### Development Setup

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- 📖 [Documentation](docs/)
- 🐛 [Report Issues](https://github.com/username/repo/issues)
- 💬 [Discussions](https://github.com/username/repo/discussions)
- 📧 [Email Support](mailto:support@example.com)

## Acknowledgments

- [PowerShell Community](https://github.com/PowerShell/PowerShell)
- [Windows API Documentation](https://docs.microsoft.com/windows/win32/api/)
- Contributors and testers

---

Made with ❤️ for home automation enthusiasts
```

## PowerShell Code Documentation

### PowerShell Script Documentation

```markdown
# Audio Control Script Documentation

## Overview

The `MuteAudio.ps1` script provides automated audio control based on configurable business hours.

## Parameters

### StartBusinessHour
- **Type:** `int`
- **Default:** `8`
- **Range:** `0-23`
- **Description:** Hour when business hours begin (24-hour format)

### EndBusinessHour
- **Type:** `int`
- **Default:** `17`
- **Range:** `0-23`
- **Description:** Hour when business hours end (24-hour format)

### Force
- **Type:** `switch`
- **Default:** `$false`
- **Description:** Forces the specified action regardless of current time

## Examples

### Example 1: Default Usage
```powershell
.\MuteAudio.ps1
```
Runs with default business hours (8 AM to 5 PM).

### Example 2: Custom Hours
```powershell
.\MuteAudio.ps1 -StartBusinessHour 9 -EndBusinessHour 18
```
Sets business hours from 9 AM to 6 PM.

### Example 3: Force Mute
```powershell
.\MuteAudio.ps1 -Force
```
Mutes audio immediately, ignoring time checks.

## Error Codes

| Code | Description        | Resolution             |
| ---- | ------------------ | ---------------------- |
| 0    | Success            | No action needed       |
| 1    | Permission denied  | Run as Administrator   |
| 2    | Invalid parameters | Check parameter values |
| 3    | Audio API error    | Check audio drivers    |

## Dependencies

- Windows Media API
- Administrative privileges
- Audio hardware/drivers

## Troubleshooting

### Audio not muting
1. Verify script is running as Administrator
2. Check if audio drivers are properly installed
3. Ensure no other applications are controlling audio

### Scheduled task not running
1. Verify task exists: `Get-ScheduledTask -TaskName "MuteAudioTask"`
2. Check task history for errors
3. Verify script path in task action
```

## Accessibility Guidelines

### Writing Accessible Documentation

```markdown
# ✅ Good: Clear headings and structure
## Installation Steps
Follow these steps in order:

1. **Download** - Get the latest release
2. **Extract** - Unzip to your desired location  
3. **Configure** - Edit the configuration file
4. **Test** - Run a test to verify setup

# ✅ Good: Alternative text for images
![Screenshot showing the PowerShell execution with green text indicating success](./images/success-screenshot.png)

# ✅ Good: Clear link descriptions
Download the [PowerShell 7.3 installer (64-bit)](https://github.com/PowerShell/PowerShell/releases/download/v7.3.0/PowerShell-7.3.0-win-x64.msi) from GitHub.

# ✅ Good: Descriptive table headers
| Step | Action      | Expected Result           | Troubleshooting        |
| ---- | ----------- | ------------------------- | ---------------------- |
| 1    | Run script  | Audio mutes               | Check admin privileges |
| 2    | Verify task | Task appears in scheduler | Re-run setup script    |
```

### Color and Contrast

```markdown
# ✅ Good: Use semantic formatting instead of color references
> **Important:** This step requires administrator privileges.

> **Warning:** This action will modify system settings.

> **Note:** Configuration changes take effect immediately.

# ❌ Bad: Color-dependent information
Click the red button to stop or the green button to start.

# ✅ Good: Clear action descriptions  
Click **Stop** (red button) to halt execution or **Start** (green button) to begin.
```

## Documentation Maintenance

### Documentation Updates

```markdown
# Keep documentation current with these practices:

## Version Control
- Update version numbers in documentation when code changes
- Maintain a changelog for significant updates
- Tag documentation versions with code releases

## Regular Reviews
- Review documentation monthly for accuracy
- Test all code examples and commands
- Update screenshots and images as UI changes
- Check all external links for validity

## User Feedback
- Monitor issues and discussions for documentation problems
- Add FAQ entries for common questions
- Update troubleshooting sections based on user reports
- Incorporate user suggestions for clarity improvements
```

### Link Maintenance

```markdown
# Automated link checking
Create a GitHub Action to check links regularly:

```yaml
name: Check Links
on:
  schedule:
    - cron: '0 0 * * 0'  # Weekly on Sunday
  workflow_dispatch:

jobs:
  link-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Check links
        uses: gaurav-nelson/github-action-markdown-link-check@v1
        with:
          use-quiet-mode: 'yes'
          use-verbose-mode: 'yes'
          config-file: '.github/link-check-config.json'
```

### Style Guide Compliance

```markdown
# Regular style checking
- Use consistent terminology throughout documentation
- Maintain the same tone and voice across all documents
- Follow established formatting patterns
- Use the same capitalization rules for headings
- Apply consistent code formatting standards
- Ensure all examples are tested and functional
```

This guide provides a comprehensive foundation for creating and maintaining high-quality documentation using Markdown and GitHub features.
