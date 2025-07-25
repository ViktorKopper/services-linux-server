# Server Services Installation Script

A comprehensive Bash script for automated installation and configuration of various server applications and tools on Debian-based Linux systems using Docker containers.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Available Services](#available-services)
- [Directory Structure](#directory-structure)
- [Configuration Files](#configuration-files)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## 🔍 Overview

The **ServerServicesInstall.sh** script automates the installation and configuration of popular server applications using Docker containers. It provides an organized approach to server setup with proper configuration management, documentation, and a dry-run mode for safe testing.

### Key Benefits

- **Automated Installation**: One-command setup for multiple server applications
- **Organized Configuration**: Each service gets its own directory with configuration files
- **Dry-Run Mode**: Preview actions before execution
- **Interactive Mode**: Guided setup with user prompts
- **Production Ready**: Secure configurations with best practices
- **Comprehensive Documentation**: Detailed README files for each service

## ✨ Features

### 🔧 Core Features
- **Dry-Run Mode**: Preview all actions without making changes (`--dry-run`)
- **Interactive Installation**: Step-by-step guided setup
- **Batch Installation**: Install multiple services with single command
- **Organized File Structure**: Configuration files saved in named directories
- **Environment Variables**: .env files for easy configuration management
- **Comprehensive Logging**: Timestamped logs for troubleshooting

### 🐳 Docker Integration
- **Docker Compose**: Modern container orchestration
- **Persistent Storage**: Named volumes for data persistence
- **Network Isolation**: Dedicated networks for each service
- **Security**: Non-root containers where applicable
- **Auto-restart**: Containers restart automatically on failure

### 📚 Documentation
- **README Files**: Detailed setup guides for each service
- **Usage Examples**: Common commands and operations
- **Troubleshooting**: Common issues and solutions
- **Backup Procedures**: Data backup and restore instructions

## 🛠 Requirements

### System Requirements
- **Operating System**: Debian-based Linux (Ubuntu, Debian, etc.)
- **Privileges**: Root access (sudo)
- **Memory**: Minimum 2GB RAM (4GB+ recommended)
- **Storage**: At least 10GB free space
- **Network**: Internet connection for downloading Docker images

### Software Prerequisites
- **curl**: For downloading packages (auto-installed)
- **openssl**: For generating secure passwords (auto-installed)
- **Docker**: Auto-installed by the script if not present

## 📦 Installation

1. **Download the script:**
   ```bash
   wget https://raw.githubusercontent.com/your-repo/ServerServicesInstall.sh
   # or
   curl -O https://raw.githubusercontent.com/your-repo/ServerServicesInstall.sh
   ```

2. **Make it executable:**
   ```bash
   chmod +x ServerServicesInstall.sh
   ```

3. **Run with sudo:**
   ```bash
   sudo ./ServerServicesInstall.sh
   ```

## 🚀 Usage

### Command Syntax
```bash
sudo ./ServerServicesInstall.sh [OPTIONS]
```

### Available Options

| Option | Description |
|--------|-------------|
| `--help` | Show help message and available options |
| `--dry-run` | Preview actions without executing them |
| `--all` | Install all available components |
| `--basic` | Install basic system utilities only |
| `--docker` | Install Docker only |
| `--gitlab` | Install GitLab only |
| `--nginx` | Install Nginx only |
| `--redmine` | Install Redmine only |
| `--zabbix` | Install Zabbix only |
| `--grafana` | Install Grafana only |

### Usage Modes

#### 1. Interactive Mode (Recommended for first-time users)
```bash
sudo ./ServerServicesInstall.sh
```
The script will prompt you for each component installation.

#### 2. Dry-Run Mode (Safe preview)
```bash
# Preview all installations
sudo ./ServerServicesInstall.sh --dry-run --all

# Preview specific service
sudo ./ServerServicesInstall.sh --dry-run --gitlab
```

#### 3. Batch Mode (Automated installation)
```bash
# Install all services
sudo ./ServerServicesInstall.sh --all

# Install specific services
sudo ./ServerServicesInstall.sh --docker --gitlab --zabbix
```

## 🎯 Available Services

### Basic Utilities (`--basic`)
Essential system administration tools:
- **mc**: Midnight Commander file manager
- **htop**: Interactive process viewer
- **fail2ban**: Intrusion prevention system
- **curl/wget**: Download utilities
- **git**: Version control system
- **chrony**: NTP time synchronization

### Docker (`--docker`)
Container platform with:
- Docker Engine (CE)
- Docker CLI
- Docker Compose
- User group configuration
- Verification testing

### GitLab (`--gitlab`)
Complete DevOps platform:
- **Features**: Git repositories, CI/CD, issue tracking
- **Default Ports**: 8080 (HTTP), 8443 (HTTPS), 2222 (SSH)
- **Authentication**: Initial root password auto-generated
- **Data**: Persistent storage for repositories and configurations

### Zabbix (`--zabbix`)
Network monitoring system:
- **Components**: MySQL database, Zabbix server, web interface, Java gateway
- **Default Ports**: 9000 (Web), 10051 (Server)
- **Features**: Host monitoring, alerting, graphing
- **Authentication**: Admin/zabbix (default)

### Grafana (`--grafana`)
Visualization and analytics platform:
- **Features**: Dashboards, data sources, alerting
- **Default Port**: 3000
- **Plugins**: Pre-installed visualization plugins
- **Authentication**: admin/admin (configurable)

### Redmine (`--redmine`)
Project management system:
- **Database**: PostgreSQL (recommended) or MySQL
- **Default Port**: 3000
- **Features**: Issue tracking, project wikis, time tracking
- **Authentication**: admin/admin (default)

### Nginx (`--nginx`)
High-performance web server:
- **Default Port**: 80 (configurable)
- **Use Cases**: Reverse proxy, load balancer, static content
- **Configuration**: Basic setup, ready for customization

## 📁 Directory Structure

After installation, services are organized in `/home/docker-configs/`:

```
/home/docker-configs/
├── gitlab/
│   ├── .env                 # GitLab configuration variables
│   ├── docker-compose.yml   # GitLab service definition
│   └── README.md           # GitLab setup guide
├── zabbix/
│   ├── .env                 # Zabbix configuration variables
│   ├── docker-compose.yml   # Multi-service Zabbix setup
│   └── README.md           # Zabbix monitoring guide
├── grafana/
│   ├── .env                 # Grafana configuration variables
│   ├── docker-compose.yml   # Grafana service definition
│   └── README.md           # Dashboard and visualization guide
└── redmine/
    ├── .env                 # Redmine configuration variables
    ├── docker-compose.yml   # Redmine with database
    └── README.md           # Project management guide
```

## ⚙️ Configuration Files

### Environment Files (.env)
Each service includes a `.env` file with customizable settings:

```bash
# Example GitLab .env
GITLAB_HOSTNAME=gitlab.example.com
GITLAB_VERSION=latest
GITLAB_HTTP_PORT=8080
GITLAB_HTTPS_PORT=8443
GITLAB_SSH_PORT=2222
```

### Docker Compose Files
Production-ready service definitions with:
- **Proper networking**: Isolated networks for each service
- **Persistent volumes**: Data survives container restarts
- **Environment variables**: Configuration from .env files
- **Dependencies**: Correct startup order
- **Restart policies**: Automatic recovery from failures

### README Documentation
Each service includes comprehensive documentation:
- **Configuration overview**: Ports, credentials, features
- **Usage commands**: Start, stop, logs, backup
- **Access information**: URLs, default credentials
- **Troubleshooting**: Common issues and solutions
- **Security notes**: Production deployment recommendations

## 💡 Examples

### Basic Installation
```bash
# Install basic utilities and Docker
sudo ./ServerServicesInstall.sh --basic --docker
```

### Development Environment
```bash
# Install GitLab and Grafana for development
sudo ./ServerServicesInstall.sh --gitlab --grafana
```

### Monitoring Stack
```bash
# Install complete monitoring solution
sudo ./ServerServicesInstall.sh --zabbix --grafana
```

### Preview Before Installation
```bash
# See what would be installed
sudo ./ServerServicesInstall.sh --dry-run --all
```

### Custom GitLab Setup
```bash
# Install GitLab, then customize in /home/docker-configs/gitlab/
sudo ./ServerServicesInstall.sh --gitlab

# Edit configuration
cd /home/docker-configs/gitlab
nano .env
docker-compose up -d
```

## 🔧 Managing Services

### Starting Services
```bash
cd /home/docker-configs/[service-name]
docker-compose up -d
```

### Stopping Services
```bash
cd /home/docker-configs/[service-name]
docker-compose down
```

### Viewing Logs
```bash
cd /home/docker-configs/[service-name]
docker-compose logs -f
```

### Updating Services
```bash
cd /home/docker-configs/[service-name]
docker-compose pull
docker-compose up -d
```

## 🔍 Troubleshooting

### Common Issues

#### Permission Denied
```bash
# Make sure script is executable
chmod +x ServerServicesInstall.sh

# Run with sudo
sudo ./ServerServicesInstall.sh
```

#### Docker Not Found
```bash
# Install Docker first
sudo ./ServerServicesInstall.sh --docker
```

#### Port Conflicts
```bash
# Check what's using the port
sudo netstat -tulpn | grep :8080

# Stop conflicting service or change port in .env file
```

#### Container Won't Start
```bash
# Check logs
cd /home/docker-configs/[service]
docker-compose logs

# Check system resources
free -h
df -h
```

### Log Files
- **Installation logs**: `/tmp/server_install_YYYYMMDD_HHMMSS.log`
- **Service logs**: `docker-compose logs` in service directory

### Getting Help
1. **Check service README**: Each service has detailed troubleshooting
2. **Review logs**: Both installation and service logs
3. **Verify requirements**: System resources and network connectivity
4. **Test dry-run**: Use `--dry-run` to verify script behavior

## 🔐 Security Considerations

### Default Credentials
**⚠️ IMPORTANT**: Change all default passwords immediately after installation:

| Service | Default Credentials |
|---------|-------------------|
| GitLab | root / (auto-generated) |
| Zabbix | Admin / zabbix |
| Grafana | admin / admin |
| Redmine | admin / admin |

### Network Security
- Services use isolated Docker networks
- Only necessary ports are exposed
- Consider using a reverse proxy for production

### Data Protection
- Regular backups of Docker volumes
- Secure storage of .env files
- Use strong passwords in production

## 📈 Performance Optimization

### System Resources
- **Minimum**: 2GB RAM, 2 CPU cores
- **Recommended**: 4GB+ RAM, 4+ CPU cores
- **Storage**: SSD recommended for database performance

### Docker Optimization
```bash
# Set Docker log rotation
echo '{"log-driver":"json-file","log-opts":{"max-size":"10m","max-file":"3"}}' | sudo tee /etc/docker/daemon.json
sudo systemctl restart docker
```

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

### Development Guidelines
- Follow existing code style
- Add comments for complex logic
- Update documentation for new features
- Test with `--dry-run` mode

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

- **Issues**: Report bugs and request features via GitHub issues
- **Documentation**: Each service includes detailed README files
- **Community**: Join discussions in the project repository

## 🔄 Version History

### Current Version Features
- ✅ Dry-run mode for safe testing
- ✅ Organized configuration structure
- ✅ Comprehensive documentation
- ✅ Environment variable management
- ✅ Multi-service Docker Compose setups
- ✅ Production-ready configurations

---

**Made with ❤️ for the DevOps community**

*For the latest updates and documentation, visit the [project repository](https://github.com/your-repo/server-install-script).*

