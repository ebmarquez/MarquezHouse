# MarquezHouse 🏠

## Smart Home Automation Scripts and Documentation

A comprehensive collection of PowerShell scripts and documentation for automating home systems, with a focus on audio control, scheduled tasks, and system management.

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://github.com/PowerShell/PowerShell)
[![Windows](https://img.shields.io/badge/Platform-Windows-lightgrey.svg)](https://www.microsoft.com/windows)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![GitHub Copilot](https://img.shields.io/badge/GitHub%20Copilot-Enabled-purple.svg)](https://github.com/features/copilot)

## 🎯 Features

- 🔇 **Automatic Audio Control** - Mute/unmute system audio based on business hours
- ⏰ **Smart Scheduling** - Configurable scheduled tasks for automation
- 📋 **Comprehensive Logging** - Detailed logging for troubleshooting
- ⚙️ **Easy Configuration** - JSON-based configuration management
- 🔒 **Security-First** - Built with security best practices
- 📚 **Rich Documentation** - Complete guides and API documentation
- 🤖 **Copilot Integration** - AI-powered development assistance

## 🚀 Quick Start

```powershell
# Clone the repository
git clone https://github.com/username/MarquezHouse.git
cd MarquezHouse

# Navigate to audio automation
cd src/Computer/Audio

# Run the audio control script
.\MuteAudio.ps1
```

## 📋 Prerequisites

- **Operating System:** Windows 10/11
- **PowerShell:** Version 5.1 or later
- **Privileges:** Administrator access required for some features
- **Hardware:** Audio hardware with Windows-compatible drivers

## 🛠️ Installation

### Quick Setup

1. **Download the scripts**
   ```powershell
   git clone https://github.com/username/MarquezHouse.git
   cd MarquezHouse
   ```

2. **Set execution policy** (if needed)
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

3. **Test the installation**
   ```powershell
   .\src\Computer\Audio\MuteAudio.ps1 -WhatIf
   ```

For detailed installation instructions, see the [Installation Guide](docs/installation/README.md).

## 📖 Usage Examples

### Basic Audio Control

```powershell
# Automatic mode (uses default business hours: 8 AM - 5 PM)
.\MuteAudio.ps1

# Custom business hours
.\MuteAudio.ps1 -StartBusinessHour 9 -EndBusinessHour 18

# Force mute regardless of time
.\MuteAudio.ps1 -Force
```

### Scheduled Task Setup

```powershell
# Create scheduled task for automatic audio control
.\ScheduledTask.ps1
```

## 🗂️ Project Structure

```
MarquezHouse/
├── 📁 src/
│   └── 📁 Computer/
│       └── 📁 Audio/
│           ├── 🔧 MuteAudio.ps1          # Main audio control script
│           └── ⏰ ScheduledTask.ps1       # Task scheduler setup
├── 📁 docs/                              # Documentation
│   ├── 📝 PowerShell-Best-Practices.md   # PowerShell coding standards
│   └── 📝 Markdown-GitHub-Best-Practices.md # Documentation guidelines
├── 📁 .copilot/                          # GitHub Copilot configuration
│   ├── ⚙️ agents.yml                     # Agent definitions
│   └── ⚙️ config.yml                     # Copilot settings
└── 📄 README.md                          # This file
```

## 📚 Documentation

### User Guides
- [📖 Installation Guide](docs/installation/README.md)
- [⚙️ Configuration Reference](docs/configuration/README.md)
- [🔧 Troubleshooting Guide](docs/guides/troubleshooting.md)

### Developer Resources
- [💻 PowerShell Best Practices](docs/PowerShell-Best-Practices.md)
- [📝 Markdown & GitHub Guidelines](docs/Markdown-GitHub-Best-Practices.md)
- [🤖 Copilot Agent Configuration](docs/copilot-setup.md)

### API Reference
- [📋 Script Parameters](docs/api/parameters.md)
- [🔧 Function Reference](docs/api/functions.md)

## 🤖 GitHub Copilot Integration

This repository is optimized for GitHub Copilot with specialized agents:

- **@powershell-expert** - PowerShell automation specialist
- **@documentation-expert** - Technical documentation specialist  
- **@home-automation-expert** - Smart home solution specialist

See [Copilot Setup Guide](docs/copilot-setup.md) for configuration details.

## 🤝 Contributing

We welcome contributions from the community! 

### Quick Contributing Steps

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

Please read our [Contributing Guidelines](CONTRIBUTING.md) and [Code of Conduct](CODE_OF_CONDUCT.md) before contributing.

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

## 🆘 Support & Community

- 📖 **Documentation:** [Complete guides and references](docs/)
- 🐛 **Report Issues:** [GitHub Issues](https://github.com/username/MarquezHouse/issues)
- 💬 **Discussions:** [GitHub Discussions](https://github.com/username/MarquezHouse/discussions)
- 📧 **Direct Support:** [Email us](mailto:support@marquezhouse.com)

## 🔗 Related Projects

- [PowerShell Gallery](https://www.powershellgallery.com/) - PowerShell modules and scripts
- [Home Assistant](https://www.home-assistant.io/) - Open source home automation
- [Windows Terminal](https://github.com/microsoft/terminal) - Modern terminal application

## 🙏 Acknowledgments

- **PowerShell Community** - For the amazing scripting platform
- **Microsoft** - For Windows API documentation and tools
- **GitHub Copilot** - For AI-powered development assistance
- **Contributors** - Everyone who helps improve this project

---

<div align="center">

**Made with ❤️ for smart home enthusiasts**

[⭐ Star this repo](https://github.com/username/MarquezHouse) • [🍴 Fork it](https://github.com/username/MarquezHouse/fork) • [📝 Contribute](CONTRIBUTING.md)

</div>
