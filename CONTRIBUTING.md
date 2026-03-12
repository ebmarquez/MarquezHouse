# Contributing to MarquezHouse

Thank you for your interest in contributing to the MarquezHouse home automation project! This document provides guidelines for contributing to our PowerShell scripts and documentation.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Contribution Guidelines](#contribution-guidelines)
- [PowerShell Standards](#powershell-standards)
- [Documentation Standards](#documentation-standards)
- [Testing Requirements](#testing-requirements)
- [Pull Request Process](#pull-request-process)

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## Getting Started

### Prerequisites

- Windows 10/11
- PowerShell 5.1 or later (PowerShell 7+ recommended)
- Git for version control
- A code editor (VS Code recommended with PowerShell extension)
- Administrator privileges for testing system-level scripts

### Fork and Clone

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```powershell
   git clone https://github.com/yourusername/MarquezHouse.git
   cd MarquezHouse
   ```

3. Add the upstream remote:
   ```powershell
   git remote add upstream https://github.com/emarquez/MarquezHouse.git
   ```

## Development Setup

### Environment Configuration

1. **Set PowerShell execution policy:**
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

2. **Install development dependencies:**
   ```powershell
   # Install Pester for testing
   Install-Module -Name Pester -Force -SkipPublisherCheck

   # Install PSScriptAnalyzer for code quality
   Install-Module -Name PSScriptAnalyzer -Force
   ```

3. **Configure VS Code (recommended):**
   - Install PowerShell extension
   - Configure settings for PSScriptAnalyzer integration
   - Set up formatting preferences

## Contribution Guidelines

### Types of Contributions

We welcome several types of contributions:

- **Bug fixes** - Fix issues in existing scripts
- **New features** - Add new automation capabilities
- **Documentation** - Improve or add documentation
- **Testing** - Add or improve test coverage
- **Performance** - Optimize existing code

### Before You Start

1. **Check existing issues** - See if your idea/bug is already being worked on
2. **Create an issue** - Describe your proposed change for discussion
3. **Wait for feedback** - Ensure your approach aligns with project goals

## PowerShell Standards

### Script Structure

All PowerShell scripts must include:

```powershell
<#
.SYNOPSIS
    Brief description of what the script does.

.DESCRIPTION
    Detailed description including prerequisites and behavior.

.PARAMETER ParameterName
    Description of each parameter.

.EXAMPLE
    Example usage of the script.

.NOTES
    Author: Your Name
    Date: Creation Date
    Version: Version Number
    
.LINK
    https://github.com/emarquez/MarquezHouse
#>

param(
    # Parameter definitions with validation
)

# Script logic here
```

### Coding Standards

- **Use approved verbs** for functions (Get-, Set-, New-, etc.)
- **Follow naming conventions**: PascalCase for functions, camelCase for variables
- **Include error handling** with try-catch blocks
- **Add meaningful comments** for complex logic
- **Use parameter validation** where appropriate
- **Include logging** for debugging purposes

### Example Function Template

```powershell
function Get-AudioStatus {
    <#
    .SYNOPSIS
        Gets the current system audio status.
    
    .DESCRIPTION
        Retrieves information about the current audio state including
        mute status and volume level.
    
    .EXAMPLE
        Get-AudioStatus
        Returns the current audio status.
    #>
    
    [CmdletBinding()]
    param()
    
    try {
        # Function implementation
        Write-Verbose "Getting audio status..."
        
        # Return structured object
        return [PSCustomObject]@{
            IsMuted = $false
            Volume = 50
            Timestamp = Get-Date
        }
    }
    catch {
        Write-Error "Failed to get audio status: $($_.Exception.Message)"
        throw
    }
}
```

## Documentation Standards

### Markdown Guidelines

- Follow the [Markdown Best Practices](docs/Markdown-GitHub-Best-Practices.md)
- Use descriptive headings and consistent formatting
- Include code examples with proper syntax highlighting
- Add table of contents for longer documents
- Use relative links for internal references

### Documentation Requirements

All contributions must include appropriate documentation:

- **Script documentation**: Comment-based help in PowerShell files
- **README updates**: Update main README if adding new features
- **API documentation**: Document new functions and parameters
- **Examples**: Include usage examples for new functionality

## Testing Requirements

### Unit Testing

Use Pester for PowerShell unit tests:

```powershell
Describe "MuteAudio Tests" {
    Context "Parameter Validation" {
        It "Should accept valid business hours" {
            { .\MuteAudio.ps1 -StartBusinessHour 8 -EndBusinessHour 17 } | Should -Not -Throw
        }
        
        It "Should reject invalid parameters" {
            { .\MuteAudio.ps1 -StartBusinessHour 25 } | Should -Throw
        }
    }
}
```

### Integration Testing

- Test scripts in a clean environment
- Verify scheduled task creation/removal
- Test error handling scenarios
- Validate logging functionality

### Test Coverage

- All new functions must have unit tests
- Critical paths should have integration tests
- Include both positive and negative test cases
- Test parameter validation and error conditions

## Pull Request Process

### Before Submitting

1. **Run tests locally:**
   ```powershell
   # Run PSScriptAnalyzer
   Invoke-ScriptAnalyzer -Path . -Recurse

   # Run Pester tests
   Invoke-Pester
   ```

2. **Update documentation:**
   - Update relevant markdown files
   - Add comment-based help to new functions
   - Include usage examples

3. **Commit guidelines:**
   - Use clear, descriptive commit messages
   - Follow conventional commits format when possible
   - Keep commits focused and atomic

### Commit Message Format

```
type(scope): brief description

Longer description if needed

Fixes #issue-number
```

Examples:
- `feat(audio): add volume level control`
- `fix(scheduler): handle task creation errors`
- `docs(readme): update installation instructions`

### Pull Request Template

When creating a pull request, include:

- **Description** of changes made
- **Type of change** (bug fix, feature, docs, etc.)
- **Testing** performed
- **Screenshots** if applicable (for UI changes)
- **Related issues** being addressed

### Review Process

1. **Automated checks** must pass (if configured)
2. **Code review** by maintainers
3. **Testing** in different environments
4. **Documentation review** for completeness
5. **Final approval** and merge

## Style Guide

### PowerShell Style

- **Indentation**: 4 spaces (no tabs)
- **Line length**: Maximum 120 characters
- **Braces**: Opening brace on same line
- **Variables**: Use descriptive names, avoid abbreviations
- **Functions**: One responsibility per function

### Documentation Style

- **Tone**: Professional but approachable
- **Structure**: Use headings and lists for organization
- **Examples**: Include practical, working examples
- **Links**: Use descriptive link text, avoid "click here"

## Getting Help

If you need help with contributing:

- **Documentation**: Check existing docs in the `/docs` folder
- **Issues**: Create an issue for questions or problems
- **Discussions**: Use GitHub Discussions for general questions
- **Contact**: Reach out to maintainers directly if needed

## Recognition

Contributors will be recognized in:

- **README acknowledgments** section
- **Release notes** for significant contributions
- **Contributor list** (if we create one)

Thank you for helping make MarquezHouse better! 🏠✨
