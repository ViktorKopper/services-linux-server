#!/bin/bash
#
# Server Installation Script
# -------------------------------------------------------------------------
# Description: Installs and configures various server applications and tools
#              on a Debian-based Linux system using Docker containers.
# Author: Viktor Kopper
# Usage: sudo ./ServerInstall.sh [--help] [--all] [--basic] [--docker] [--gitlab] [--nginx] [--redmine] [--zabbix] [--grafana]
# Requirements: Debian-based Linux system with sudo privileges
# -------------------------------------------------------------------------

# -------------------------------------------------------------------------
# CONFIGURATION SECTION
# -------------------------------------------------------------------------

# Define colors for better terminal output readability
# These ANSI color codes make important messages stand out
RED='\033[0;31m'    # Used for errors and warnings
GREEN='\033[0;32m'  # Used for success messages
YELLOW='\033[0;33m' # Used for information and processing messages
NC='\033[0m'        # No Color - resets text formatting

# Define log file with timestamp to ensure unique log files for each run
# This helps with troubleshooting multiple installation attempts
LOG_FILE="/tmp/server_install_$(date +%Y%m%d_%H%M%S).log"

# Global variable to control dry-run mode
DRY_RUN=false

# -------------------------------------------------------------------------
# UTILITY FUNCTIONS
# -------------------------------------------------------------------------

# Function: log
# Purpose: Writes timestamped log messages to both terminal and log file
# Parameters:
#   $1 - Message to log
#   $2 - Log level (INFO, ERROR, WARNING) - defaults to INFO
log() {
    local message="$1"
    local level="${2:-INFO}"
    if [ "$DRY_RUN" = true ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] [DRY-RUN] $message"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" | tee -a "$LOG_FILE"
    fi
}

# Function: dry_run_log
# Purpose: Shows what commands would be executed in dry-run mode
# Parameters:
#   $1 - Command description
#   $2 - Actual command that would be executed
dry_run_log() {
    local description="$1"
    local command="$2"
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}[DRY-RUN] Would execute: $description${NC}"
        echo -e "${YELLOW}[DRY-RUN] Command: $command${NC}"
    fi
}

# Function: execute_command
# Purpose: Executes a command or shows what would be executed in dry-run mode
# Parameters:
#   $1 - Command description
#   $2 - Actual command to execute
#   $3 - Optional: return code for success simulation in dry-run (default: 0)
execute_command() {
    local description="$1"
    local command="$2"
    local dry_run_return_code="${3:-0}"
    
    if [ "$DRY_RUN" = true ]; then
        dry_run_log "$description" "$command"
        return "$dry_run_return_code"
    else
        log "$description"
        eval "$command"
        return $?
    fi
}

# Function: check_root
# Purpose: Verifies the script is running with root privileges
# Parameters:
#   $@ - All command line arguments (passed to sudo command if needed)
# Notes: Most installation operations require root privileges
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log "This script must be run as root" "ERROR"
        echo -e "${RED}This script must be run as root${NC}"
        echo "Please run with: sudo $0 $*"
        exit 1
    fi
}

# Function: show_help
# Purpose: Displays usage information and available options
# Notes: Called when --help is specified or when invalid options are provided
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo "Install and configure various server applications and tools."
    echo
    echo "Options:"
    echo "  --help      Show this help message"
    echo "  --dry-run   Show what would be executed without actually running commands"
    echo "  --all       Install all components"
    echo "  --basic     Install basic utilities only"
    echo "  --docker    Install Docker only"
    echo "  --gitlab    Install GitLab only"
    echo "  --nginx     Install Nginx only"
    echo "  --redmine   Install Redmine only"
    echo "  --zabbix    Install Zabbix only"
    echo "  --grafana   Install Grafana only"
    echo
    echo "If no options are provided, the script will prompt for each component."
    echo "The --dry-run option can be combined with any other option to preview actions."
    exit 0
}

# Function: confirm
# Purpose: Prompts user for yes/no confirmation with a default option
# Parameters:
#   $1 - Prompt message to display
#   $2 - Default response (Y or N) - defaults to Y
# Returns: 0 for yes, 1 for no
# Notes: Used in interactive mode to confirm each installation step
confirm() {
    local prompt="$1"
    local default="${2:-Y}"
    
    # Set the prompt options based on the default value
    if [ "$default" = "Y" ]; then
        local options="[Y/n]"
    else
        local options="[y/N]"
    fi
    
    # Display prompt and get user response
    read -p "$prompt $options: " response
    response=${response:-$default}  # Use default if no response given
    
    # Return appropriate exit code based on response
    if [[ $response =~ ^[Yy]$ ]]; then
        return 0  # Success (yes)
    else
        return 1  # Failure (no)
    fi
}

# -------------------------------------------------------------------------
# SYSTEM PREPARATION FUNCTIONS
# -------------------------------------------------------------------------

# Function: update_system
# Purpose: Updates package lists and upgrades installed packages
# Notes: This is a prerequisite for all installations to ensure latest packages
update_system() {
    execute_command "Updating package lists" "apt update"
    if [ $? -ne 0 ]; then
        log "Failed to update package lists" "ERROR"
        echo -e "${RED}Failed to update package lists. Check $LOG_FILE for details.${NC}"
        return 1
    fi
    
    execute_command "Upgrading installed packages" "apt upgrade -y"
    if [ $? -ne 0 ]; then
        log "Failed to upgrade system packages" "ERROR"
        echo -e "${RED}Failed to upgrade system packages. Check $LOG_FILE for details.${NC}"
        return 1
    fi
    
    log "System packages updated successfully"
    return 0
}

# Function: install_basic
# Purpose: Installs essential system utilities and tools
# Notes: These tools are useful for system administration and monitoring
install_basic() {
    log "Installing basic utilities"
    echo -e "${YELLOW}Installing basic utilities...${NC}"
    
    # Group installations to reduce redundancy and improve readability
    # mc - Midnight Commander file manager
    # inxi - System information tool
    # curl - Command line tool for transferring data
    # fail2ban - Intrusion prevention system
    # htop - Interactive process viewer
    # iotop - I/O monitoring tool
    # net-tools - Network utilities (ifconfig, netstat, etc.)
    # wget - Command line downloader
    # lsof - Lists open files
    # git - Version control system
    # unzip, tar - Archive utilities
    # chrony - NTP client/server
    execute_command "Installing basic utilities" "apt install -y mc inxi curl fail2ban htop iotop net-tools wget lsof git unzip tar chrony"
    
    # Check if installation was successful
    if [ $? -ne 0 ]; then
        log "Failed to install basic utilities" "ERROR"
        echo -e "${RED}Failed to install basic utilities. Check $LOG_FILE for details.${NC}"
        return 1
    fi
    
    log "Basic utilities installed successfully"
    echo -e "${GREEN}Basic utilities installed successfully${NC}"
    return 0
}

# -------------------------------------------------------------------------
# DOCKER INSTALLATION
# -------------------------------------------------------------------------

# Function: install_docker
# Purpose: Installs Docker Engine, Docker CLI, and Docker Compose
# Notes: Follows official Docker installation procedure for Debian
install_docker() {
    log "Installing Docker"
    echo -e "${YELLOW}Installing Docker...${NC}"
    
    # Remove old versions of Docker to prevent conflicts
    # This ensures a clean installation of the latest Docker packages
    log "Removing old Docker versions if present"
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
        apt-get remove -y $pkg 2>/dev/null
    done
    
    # Install prerequisites for Docker repository
    log "Installing Docker prerequisites"
    apt-get update
    apt-get install -y ca-certificates curl gnupg
    
    # Set up Docker's official GPG key for package verification
    # This ensures packages are authentic and haven't been tampered with
    log "Setting up Docker repository"
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    
    # Add Docker's official repository to apt sources
    # This dynamically detects the system architecture and codename
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker packages
    # docker-ce - Docker Engine
    # docker-ce-cli - Docker CLI
    # containerd.io - containerd runtime
    # docker-buildx-plugin - BuildKit for Docker
    # docker-compose-plugin - Docker Compose V2
    log "Installing Docker packages"
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Check if Docker installation was successful
    if [ $? -ne 0 ]; then
        log "Failed to install Docker" "ERROR"
        echo -e "${RED}Failed to install Docker. Check $LOG_FILE for details.${NC}"
        return 1
    fi
    
    # Add current user to docker group to allow non-root Docker usage
    # This is a security best practice to avoid running Docker as root
    if [ -n "$SUDO_USER" ]; then
        log "Adding user $SUDO_USER to docker group"
        usermod -aG docker "$SUDO_USER"
        echo -e "${YELLOW}Added user $SUDO_USER to docker group. Log out and back in to apply changes.${NC}"
    fi
    
    # Verify Docker installation by running hello-world container
    # This confirms Docker is properly installed and can pull/run containers
    log "Verifying Docker installation"
    if docker run --rm hello-world > /dev/null 2>&1; then
        log "Docker installed and verified successfully"
        echo -e "${GREEN}Docker installed and verified successfully${NC}"
        return 0
    else
        log "Docker installation verification failed" "ERROR"
        echo -e "${RED}Docker installation verification failed. Check $LOG_FILE for details.${NC}"
        return 1
    fi
}

# -------------------------------------------------------------------------
# GITLAB INSTALLATION
# -------------------------------------------------------------------------

# Function: install_gitlab
# Purpose: Installs GitLab using Docker Compose
# Notes: GitLab is a complete DevOps platform for software development
install_gitlab() {
    log "Installing GitLab"
    echo -e "${YELLOW}Installing GitLab...${NC}"
    
    # Create GitLab directory for configuration files
    local gitlab_dir="/home/docker-configs/gitlab"
    execute_command "Creating GitLab configuration directory" "mkdir -p $gitlab_dir"
    cd "$gitlab_dir" || {
        log "Failed to create or access GitLab directory" "ERROR"
        echo -e "${RED}Failed to create or access GitLab directory${NC}"
        return 1
    }
    
    # Prompt for GitLab configuration
    # Hostname is used for GitLab's external URL and SSL configuration
    if [ "$DRY_RUN" = false ]; then
        read -p "Enter GitLab hostname (e.g., gitlab.example.com): " gitlab_hostname
        gitlab_hostname=${gitlab_hostname:-gitlab.example.com}
        
        # Version selection allows for specific GitLab versions or latest
        read -p "Enter GitLab version (e.g., 16.10.0, latest): " gitlab_version
        gitlab_version=${gitlab_version:-latest}
        
        # HTTP port configuration
        read -p "Enter HTTP port for GitLab (default: 8080): " gitlab_http_port
        gitlab_http_port=${gitlab_http_port:-8080}
        
        # HTTPS port configuration
        read -p "Enter HTTPS port for GitLab (default: 8443): " gitlab_https_port
        gitlab_https_port=${gitlab_https_port:-8443}
        
        # SSH port configuration
        read -p "Enter SSH port for GitLab (default: 2222): " gitlab_ssh_port
        gitlab_ssh_port=${gitlab_ssh_port:-2222}
    else
        gitlab_hostname="gitlab.example.com"
        gitlab_version="latest"
        gitlab_http_port="8080"
        gitlab_https_port="8443"
        gitlab_ssh_port="2222"
    fi
    
    # Set GitLab data directory
    local gitlab_home="/srv/gitlab"
    execute_command "Creating GitLab data directory" "mkdir -p $gitlab_home"
    
    # Create .env file for GitLab
    log "Creating GitLab .env file"
    if [ "$DRY_RUN" = false ]; then
        cat <<EOF > .env
# GitLab Configuration
GITLAB_HOSTNAME=$gitlab_hostname
GITLAB_VERSION=$gitlab_version
GITLAB_HOME=$gitlab_home
GITLAB_HTTP_PORT=$gitlab_http_port
GITLAB_HTTPS_PORT=$gitlab_https_port
GITLAB_SSH_PORT=$gitlab_ssh_port

# GitLab URLs
GITLAB_EXTERNAL_URL=https://$gitlab_hostname
EOF
    else
        dry_run_log "Creating GitLab .env file" "cat > .env with GitLab configuration variables"
    fi
    
    # Create docker-compose.yml for GitLab
    log "Creating GitLab docker-compose.yml"
    if [ "$DRY_RUN" = false ]; then
        cat <<EOF > docker-compose.yml
version: '3.8'
services:
  gitlab:
    image: gitlab/gitlab-ee:\${GITLAB_VERSION}
    container_name: gitlab
    restart: unless-stopped
    hostname: '\${GITLAB_HOSTNAME}'
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url '\${GITLAB_EXTERNAL_URL}'
        gitlab_rails['gitlab_shell_ssh_port'] = \${GITLAB_SSH_PORT}
        # Disable built-in nginx to avoid port conflicts
        nginx['listen_port'] = 80
        nginx['listen_https'] = false
        # Configure GitLab to work behind reverse proxy
        gitlab_rails['trusted_proxies'] = ['172.16.0.0/12', '192.168.0.0/16', '10.0.0.0/8']
        gitlab_rails['gitlab_default_theme'] = 2
    ports:
      - '\${GITLAB_HTTP_PORT}:80'
      - '\${GITLAB_HTTPS_PORT}:443'
      - '\${GITLAB_SSH_PORT}:22'
    volumes:
      - '\${GITLAB_HOME}/config:/etc/gitlab'
      - '\${GITLAB_HOME}/logs:/var/log/gitlab'
      - '\${GITLAB_HOME}/data:/var/opt/gitlab'
    shm_size: '256m'
    networks:
      - gitlab-network

networks:
  gitlab-network:
    driver: bridge

volumes:
  gitlab-config:
  gitlab-logs:
  gitlab-data:
EOF
    else
        dry_run_log "Creating GitLab docker-compose.yml" "cat > docker-compose.yml with GitLab service configuration"
    fi
    
    # Create README file with instructions
    log "Creating GitLab README file"
    if [ "$DRY_RUN" = false ]; then
        cat <<EOF > README.md
# GitLab Docker Setup

## Configuration
- **Hostname**: $gitlab_hostname
- **Version**: $gitlab_version
- **HTTP Port**: $gitlab_http_port
- **HTTPS Port**: $gitlab_https_port
- **SSH Port**: $gitlab_ssh_port

## Usage

### Start GitLab
\`\`\`bash
docker-compose up -d
\`\`\`

### Stop GitLab
\`\`\`bash
docker-compose down
\`\`\`

### View logs
\`\`\`bash
docker-compose logs -f
\`\`\`

### Access GitLab
- Web interface: https://$gitlab_hostname:$gitlab_https_port or http://$gitlab_hostname:$gitlab_http_port
- SSH: git@$gitlab_hostname:$gitlab_ssh_port

### Initial Setup
1. Wait for GitLab to start (may take several minutes)
2. Get initial root password: \`docker exec -it gitlab grep 'Password:' /etc/gitlab/initial_root_password\`
3. Login with username 'root' and the password from step 2
4. Change the root password immediately after first login

## Data Persistence
GitLab data is stored in: $gitlab_home
- Configuration: $gitlab_home/config
- Logs: $gitlab_home/logs  
- Data: $gitlab_home/data
EOF
    else
        dry_run_log "Creating GitLab README file" "cat > README.md with GitLab setup instructions"
    fi
    
    # Start GitLab using Docker Compose
    execute_command "Starting GitLab container" "docker-compose up -d"
    if [ $? -ne 0 ]; then
        log "Failed to start GitLab container" "ERROR"
        echo -e "${RED}Failed to start GitLab container. Check $LOG_FILE for details.${NC}"
        return 1
    fi
    
    log "GitLab installed successfully"
    echo -e "${GREEN}GitLab installed successfully${NC}"
    echo -e "${YELLOW}Configuration files saved to: $gitlab_dir${NC}"
    echo -e "${YELLOW}GitLab may take a few minutes to start. You can access it at:${NC}"
    echo -e "${YELLOW}  - HTTP: http://$gitlab_hostname:$gitlab_http_port${NC}"
    echo -e "${YELLOW}  - HTTPS: https://$gitlab_hostname:$gitlab_https_port${NC}"
    echo -e "${YELLOW}Initial root password: docker exec -it gitlab grep 'Password:' /etc/gitlab/initial_root_password${NC}"
    return 0
}

# -------------------------------------------------------------------------
# NGINX INSTALLATION
# -------------------------------------------------------------------------

# Function: install_nginx
# Purpose: Installs Nginx web server using Docker
# Notes: Nginx is a high-performance web server and reverse proxy
install_nginx() {
    log "Installing Nginx"
    echo -e "${YELLOW}Installing Nginx...${NC}"
    
    # Prompt for Nginx port configuration
    # Default is 80, but user can specify a different port
    read -p "Enter port to expose Nginx (default: 80): " nginx_port
    nginx_port=${nginx_port:-80}
    
    # Pull the official Nginx Docker image
    log "Pulling Nginx Docker image"
    if ! docker pull nginx; then
        log "Failed to pull Nginx Docker image" "ERROR"
        echo -e "${RED}Failed to pull Nginx Docker image. Check $LOG_FILE for details.${NC}"
        return 1
    fi
    
    # Create and start Nginx container
    # - Maps the specified port to container port 80
    # - Runs in detached mode (-d)
    # - Names the container 'docker-nginx' for easy reference
    log "Creating Nginx container"
    if docker run --name docker-nginx -p "${nginx_port}:80" -d nginx; then
        log "Nginx installed successfully"
        echo -e "${GREEN}Nginx installed successfully${NC}"
        echo -e "${YELLOW}Nginx is running on port ${nginx_port}${NC}"
        return 0
    else
        log "Failed to create Nginx container" "ERROR"
        echo -e "${RED}Failed to create Nginx container. Check $LOG_FILE for details.${NC}"
        return 1
    fi
}

# -------------------------------------------------------------------------
# REDMINE INSTALLATION
# -------------------------------------------------------------------------

# Function: install_redmine
# Purpose: Installs Redmine project management system using Docker
# Notes: Redmine requires a database (PostgreSQL or MySQL)
install_redmine() {
    log "Installing Redmine"
    echo -e "${YELLOW}Installing Redmine...${NC}"
    
    # Create Redmine directory for configuration files
    local redmine_dir="/home/docker-configs/redmine"
    execute_command "Creating Redmine configuration directory" "mkdir -p $redmine_dir"
    cd "$redmine_dir" || {
        log "Failed to create or access Redmine directory" "ERROR"
        echo -e "${RED}Failed to create or access Redmine directory${NC}"
        return 1
    }
    
    # Prompt for Redmine configuration
    if [ "$DRY_RUN" = false ]; then
        read -p "Enter Redmine port (default: 3000): " redmine_port
        redmine_port=${redmine_port:-3000}
        
        # Prompt for database type selection
        # PostgreSQL is recommended for better performance and features
        echo "Select database type for Redmine:"
        echo "1) PostgreSQL (recommended)"
        echo "2) MySQL"
        read -p "Enter choice [1-2]: " db_choice
        db_choice=${db_choice:-1}
        
        # Generate secure random password for database
        db_password=$(openssl rand -base64 16)
    else
        redmine_port="3000"
        db_choice="1"
        db_password="demo_redmine_password_123"
    fi
    
    # Set database configuration based on choice
    if [ "$db_choice" = "1" ]; then
        db_type="postgres"
        db_image="postgres:15"
        db_container="redmine-postgres"
    else
        db_type="mysql"
        db_image="mysql:8.0"
        db_container="redmine-mysql"
    fi
    
    # Create .env file for Redmine
    log "Creating Redmine .env file"
    if [ "$DRY_RUN" = false ]; then
        cat <<EOF > .env
# Redmine Configuration
REDMINE_PORT=$redmine_port
REDMINE_VERSION=latest

# Database Configuration
DB_TYPE=$db_type
DB_IMAGE=$db_image
DB_CONTAINER=$db_container
DB_PASSWORD=$db_password
DB_USER=redmine
DB_NAME=redmine

# Network Configuration
REDMINE_NETWORK=redmine-network
EOF
    else
        dry_run_log "Creating Redmine .env file" "cat > .env with Redmine configuration variables"
    fi
    
    # Create docker-compose.yml for Redmine
    log "Creating Redmine docker-compose.yml"
    if [ "$DRY_RUN" = false ]; then
        if [ "$db_choice" = "1" ]; then
            # PostgreSQL configuration
            cat <<EOF > docker-compose.yml
version: '3.8'

services:
  postgres:
    image: \${DB_IMAGE}
    container_name: \${DB_CONTAINER}
    restart: unless-stopped
    environment:
      POSTGRES_PASSWORD: \${DB_PASSWORD}
      POSTGRES_USER: \${DB_USER}
      POSTGRES_DB: \${DB_NAME}
    volumes:
      - redmine-postgres-data:/var/lib/postgresql/data
    networks:
      - \${REDMINE_NETWORK}

  redmine:
    image: redmine:\${REDMINE_VERSION}
    container_name: redmine
    restart: unless-stopped
    ports:
      - "\${REDMINE_PORT}:3000"
    environment:
      REDMINE_DB_POSTGRES: \${DB_CONTAINER}
      REDMINE_DB_USERNAME: \${DB_USER}
      REDMINE_DB_PASSWORD: \${DB_PASSWORD}
      REDMINE_DB_DATABASE: \${DB_NAME}
    volumes:
      - redmine-data:/usr/src/redmine/files
      - redmine-plugins:/usr/src/redmine/plugins
      - redmine-themes:/usr/src/redmine/public/themes
    networks:
      - \${REDMINE_NETWORK}
    depends_on:
      - postgres

networks:
  redmine-network:
    driver: bridge

volumes:
  redmine-postgres-data:
  redmine-data:
  redmine-plugins:
  redmine-themes:
EOF
        else
            # MySQL configuration
            cat <<EOF > docker-compose.yml
version: '3.8'

services:
  mysql:
    image: \${DB_IMAGE}
    container_name: \${DB_CONTAINER}
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: \${DB_PASSWORD}
      MYSQL_DATABASE: \${DB_NAME}
      MYSQL_USER: \${DB_USER}
      MYSQL_PASSWORD: \${DB_PASSWORD}
    command: --default-authentication-plugin=mysql_native_password
    volumes:
      - redmine-mysql-data:/var/lib/mysql
    networks:
      - \${REDMINE_NETWORK}

  redmine:
    image: redmine:\${REDMINE_VERSION}
    container_name: redmine
    restart: unless-stopped
    ports:
      - "\${REDMINE_PORT}:3000"
    environment:
      REDMINE_DB_MYSQL: \${DB_CONTAINER}
      REDMINE_DB_USERNAME: \${DB_USER}
      REDMINE_DB_PASSWORD: \${DB_PASSWORD}
      REDMINE_DB_DATABASE: \${DB_NAME}
    volumes:
      - redmine-data:/usr/src/redmine/files
      - redmine-plugins:/usr/src/redmine/plugins
      - redmine-themes:/usr/src/redmine/public/themes
    networks:
      - \${REDMINE_NETWORK}
    depends_on:
      - mysql

networks:
  redmine-network:
    driver: bridge

volumes:
  redmine-mysql-data:
  redmine-data:
  redmine-plugins:
  redmine-themes:
EOF
        fi
    else
        dry_run_log "Creating Redmine docker-compose.yml" "cat > docker-compose.yml with Redmine and database configuration"
    fi
    
    # Create README file with instructions
    log "Creating Redmine README file"
    if [ "$DRY_RUN" = false ]; then
        cat <<EOF > README.md
# Redmine Docker Setup

## Configuration
- **Port**: $redmine_port
- **Database**: $([ "$db_choice" = "1" ] && echo "PostgreSQL" || echo "MySQL")
- **Database User**: redmine
- **Database Name**: redmine

## Usage

### Start Redmine
\`\`\`bash
docker-compose up -d
\`\`\`

### Stop Redmine
\`\`\`bash
docker-compose down
\`\`\`

### View logs
\`\`\`bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f redmine
docker-compose logs -f $([ "$db_choice" = "1" ] && echo "postgres" || echo "mysql")
\`\`\`

### Access Redmine
- Web interface: http://localhost:$redmine_port
- Default login: **admin** / **admin**

### Initial Setup
1. Wait for all containers to start (may take several minutes)
2. Access the web interface at http://localhost:$redmine_port
3. Login with username 'admin' and password 'admin'
4. Change the admin password immediately after first login
5. Configure your first project and users

### Database Access
- **Database Password**: See .env file
- **Database Connection**: 
  $(if [ "$db_choice" = "1" ]; then
    echo "  - PostgreSQL: \`docker-compose exec postgres psql -U redmine -d redmine\`"
  else
    echo "  - MySQL: \`docker-compose exec mysql mysql -u redmine -p redmine\`"
  fi)

### Customization
- **Plugins**: Place plugins in the redmine-plugins volume
- **Themes**: Place themes in the redmine-themes volume
- **Files**: User uploaded files are stored in redmine-data volume

### Data Persistence
Redmine data is stored in Docker volumes:
- Application data: redmine-data
- Plugins: redmine-plugins
- Themes: redmine-themes
$(if [ "$db_choice" = "1" ]; then
  echo "- PostgreSQL data: redmine-postgres-data"
else
  echo "- MySQL data: redmine-mysql-data"
fi)

### Backup
To backup your Redmine installation:
\`\`\`bash
# Backup database
$(if [ "$db_choice" = "1" ]; then
  echo "docker-compose exec postgres pg_dump -U redmine redmine > redmine_backup.sql"
else
  echo "docker-compose exec mysql mysqldump -u redmine -p redmine > redmine_backup.sql"
fi)

# Backup files
docker run --rm -v redmine-data:/data -v \$(pwd):/backup alpine tar czf /backup/redmine_files_backup.tar.gz -C /data .
\`\`\`

### Troubleshooting
- Check container status: \`docker-compose ps\`
- View detailed logs: \`docker-compose logs [service-name]\`
- Restart services: \`docker-compose restart [service-name]\`
- Access container: \`docker-compose exec redmine /bin/bash\`

### Common Issues
1. **Database connection errors**: Wait longer for database to initialize
2. **Permission issues**: Check file permissions on mounted volumes
3. **Plugin issues**: Restart Redmine after installing plugins
4. **Performance issues**: Consider increasing container memory limits
EOF
    else
        dry_run_log "Creating Redmine README file" "cat > README.md with Redmine setup instructions"
    fi
    
    # Start Redmine using Docker Compose
    execute_command "Starting Redmine containers" "docker-compose up -d"
    if [ $? -ne 0 ]; then
        log "Failed to start Redmine containers" "ERROR"
        echo -e "${RED}Failed to start Redmine containers. Check $LOG_FILE for details.${NC}"
        return 1
    fi
    
    log "Redmine installed successfully"
    echo -e "${GREEN}Redmine installed successfully${NC}"
    echo -e "${YELLOW}Configuration files saved to: $redmine_dir${NC}"
    echo -e "${YELLOW}Redmine web interface: http://localhost:$redmine_port${NC}"
    echo -e "${YELLOW}Default login: admin / admin${NC}"
    echo -e "${YELLOW}Database: $([ "$db_choice" = "1" ] && echo "PostgreSQL" || echo "MySQL")${NC}"
    echo -e "${YELLOW}Database password saved in .env file${NC}"
    
    return 0
}

# -------------------------------------------------------------------------
# ZABBIX INSTALLATION
# -------------------------------------------------------------------------

# Function: install_zabbix
# Purpose: Installs Zabbix monitoring system using Docker
# Notes: Zabbix requires MySQL database and includes web interface
install_zabbix() {
    log "Installing Zabbix"
    echo -e "${YELLOW}Installing Zabbix...${NC}"
    
    # Create Zabbix directory for configuration files
    local zabbix_dir="/home/docker-configs/zabbix"
    execute_command "Creating Zabbix configuration directory" "mkdir -p $zabbix_dir"
    cd "$zabbix_dir" || {
        log "Failed to create or access Zabbix directory" "ERROR"
        echo -e "${RED}Failed to create or access Zabbix directory${NC}"
        return 1
    }
    
    # Prompt for Zabbix configuration
    if [ "$DRY_RUN" = false ]; then
        read -p "Enter Zabbix web port (default: 9000): " zabbix_web_port
        zabbix_web_port=${zabbix_web_port:-9000}
        
        read -p "Enter Zabbix server port (default: 10051): " zabbix_server_port
        zabbix_server_port=${zabbix_server_port:-10051}
        
        read -p "Enter timezone (default: Europe/Bratislava): " zabbix_timezone
        zabbix_timezone=${zabbix_timezone:-Europe/Bratislava}
        
        # Generate secure random passwords for MySQL
        mysql_password=$(openssl rand -base64 16)
        mysql_root_password=$(openssl rand -base64 16)
    else
        zabbix_web_port="9000"
        zabbix_server_port="10051"
        zabbix_timezone="Europe/Bratislava"
        mysql_password="demo_password_123"
        mysql_root_password="demo_root_password_123"
    fi
    
    # Create .env file for Zabbix
    log "Creating Zabbix .env file"
    if [ "$DRY_RUN" = false ]; then
        cat <<EOF > .env
# Zabbix Configuration
ZABBIX_WEB_PORT=$zabbix_web_port
ZABBIX_SERVER_PORT=$zabbix_server_port
ZABBIX_TIMEZONE=$zabbix_timezone

# MySQL Configuration
MYSQL_DATABASE=zabbix
MYSQL_USER=zabbix
MYSQL_PASSWORD=$mysql_password
MYSQL_ROOT_PASSWORD=$mysql_root_password

# Docker Network
ZABBIX_NETWORK_SUBNET=172.35.0.0/16
ZABBIX_NETWORK_IPRANGE=172.35.240.0/20

# Zabbix Images
ZABBIX_VERSION=alpine-7.2-latest
MYSQL_VERSION=8.0-oracle
EOF
    else
        dry_run_log "Creating Zabbix .env file" "cat > .env with Zabbix configuration variables"
    fi
    
    # Create docker-compose.yml for Zabbix
    log "Creating Zabbix docker-compose.yml"
    if [ "$DRY_RUN" = false ]; then
        cat <<EOF > docker-compose.yml
version: '3.8'

services:
  mysql-server:
    image: mysql:\${MYSQL_VERSION}
    container_name: zabbix-mysql-server
    restart: unless-stopped
    environment:
      MYSQL_DATABASE: \${MYSQL_DATABASE}
      MYSQL_USER: \${MYSQL_USER}
      MYSQL_PASSWORD: \${MYSQL_PASSWORD}
      MYSQL_ROOT_PASSWORD: \${MYSQL_ROOT_PASSWORD}
    command:
      - mysqld
      - --character-set-server=utf8
      - --collation-server=utf8_bin
      - --default-authentication-plugin=mysql_native_password
    volumes:
      - zabbix-mysql-data:/var/lib/mysql
    networks:
      - zabbix-net

  zabbix-java-gateway:
    image: zabbix/zabbix-java-gateway:\${ZABBIX_VERSION}
    container_name: zabbix-java-gateway
    restart: unless-stopped
    networks:
      - zabbix-net

  zabbix-server:
    image: zabbix/zabbix-server-mysql:\${ZABBIX_VERSION}
    container_name: zabbix-server-mysql
    restart: unless-stopped
    environment:
      DB_SERVER_HOST: mysql-server
      MYSQL_DATABASE: \${MYSQL_DATABASE}
      MYSQL_USER: \${MYSQL_USER}
      MYSQL_PASSWORD: \${MYSQL_PASSWORD}
      MYSQL_ROOT_PASSWORD: \${MYSQL_ROOT_PASSWORD}
      ZBX_JAVAGATEWAY: zabbix-java-gateway
    ports:
      - "\${ZABBIX_SERVER_PORT}:10051"
    volumes:
      - zabbix-server-data:/var/lib/zabbix
    networks:
      - zabbix-net
    depends_on:
      - mysql-server
      - zabbix-java-gateway

  zabbix-web:
    image: zabbix/zabbix-web-nginx-mysql:\${ZABBIX_VERSION}
    container_name: zabbix-web-nginx-mysql
    restart: unless-stopped
    environment:
      DB_SERVER_HOST: mysql-server
      MYSQL_DATABASE: \${MYSQL_DATABASE}
      MYSQL_USER: \${MYSQL_USER}
      MYSQL_PASSWORD: \${MYSQL_PASSWORD}
      MYSQL_ROOT_PASSWORD: \${MYSQL_ROOT_PASSWORD}
      ZBX_SERVER_HOST: zabbix-server
      PHP_TZ: \${ZABBIX_TIMEZONE}
    ports:
      - "\${ZABBIX_WEB_PORT}:8080"
    volumes:
      - zabbix-web-data:/etc/ssl/nginx
    networks:
      - zabbix-net
    depends_on:
      - mysql-server
      - zabbix-server

networks:
  zabbix-net:
    driver: bridge
    ipam:
      config:
        - subnet: \${ZABBIX_NETWORK_SUBNET}
          ip_range: \${ZABBIX_NETWORK_IPRANGE}

volumes:
  zabbix-mysql-data:
  zabbix-server-data:
  zabbix-web-data:
EOF
    else
        dry_run_log "Creating Zabbix docker-compose.yml" "cat > docker-compose.yml with Zabbix services configuration"
    fi
    
    # Create README file with instructions
    log "Creating Zabbix README file"
    if [ "$DRY_RUN" = false ]; then
        cat <<EOF > README.md
# Zabbix Docker Setup

## Configuration
- **Web Port**: $zabbix_web_port
- **Server Port**: $zabbix_server_port
- **Timezone**: $zabbix_timezone
- **MySQL Database**: zabbix
- **MySQL User**: zabbix

## Usage

### Start Zabbix
\`\`\`bash
docker-compose up -d
\`\`\`

### Stop Zabbix
\`\`\`bash
docker-compose down
\`\`\`

### View logs
\`\`\`bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f zabbix-server
docker-compose logs -f zabbix-web
docker-compose logs -f mysql-server
\`\`\`

### Access Zabbix
- Web interface: http://localhost:$zabbix_web_port
- Default login: **Admin** / **zabbix**

### Initial Setup
1. Wait for all containers to start (may take several minutes)
2. Access the web interface at http://localhost:$zabbix_web_port
3. Login with username 'Admin' and password 'zabbix'
4. Change the admin password immediately after first login
5. Configure your first hosts and monitoring items

### Database Access
- **MySQL Password**: See .env file
- **MySQL Root Password**: See .env file
- Connect to database: \`docker-compose exec mysql-server mysql -u zabbix -p zabbix\`

### Monitoring Agents
To monitor other hosts, install Zabbix agent on target systems and configure them to connect to this server on port $zabbix_server_port.

### Data Persistence
Zabbix data is stored in Docker volumes:
- MySQL data: zabbix-mysql-data
- Server data: zabbix-server-data
- Web data: zabbix-web-data

### Troubleshooting
- Check container status: \`docker-compose ps\`
- View detailed logs: \`docker-compose logs [service-name]\`
- Restart services: \`docker-compose restart [service-name]\`
EOF
    else
        dry_run_log "Creating Zabbix README file" "cat > README.md with Zabbix setup instructions"
    fi
    
    # Start Zabbix using Docker Compose
    execute_command "Starting Zabbix containers" "docker-compose up -d"
    if [ $? -ne 0 ]; then
        log "Failed to start Zabbix containers" "ERROR"
        echo -e "${RED}Failed to start Zabbix containers. Check $LOG_FILE for details.${NC}"
        return 1
    fi
    
    log "Zabbix installed successfully"
    echo -e "${GREEN}Zabbix installed successfully${NC}"
    echo -e "${YELLOW}Configuration files saved to: $zabbix_dir${NC}"
    echo -e "${YELLOW}Zabbix web interface: http://localhost:$zabbix_web_port${NC}"
    echo -e "${YELLOW}Zabbix server port: $zabbix_server_port${NC}"
    echo -e "${YELLOW}Default login: Admin / zabbix${NC}"
    echo -e "${YELLOW}MySQL credentials saved in .env file${NC}"
    
    return 0
}

# -------------------------------------------------------------------------
# GRAFANA INSTALLATION
# -------------------------------------------------------------------------

# Function: install_grafana
# Purpose: Installs Grafana visualization and analytics platform using Docker
# Notes: Grafana is used for metrics visualization and dashboards
install_grafana() {
    log "Installing Grafana"
    echo -e "${YELLOW}Installing Grafana...${NC}"
    
    # Create Grafana directory for configuration files
    local grafana_dir="/home/docker-configs/grafana"
    execute_command "Creating Grafana configuration directory" "mkdir -p $grafana_dir"
    cd "$grafana_dir" || {
        log "Failed to create or access Grafana directory" "ERROR"
        echo -e "${RED}Failed to create or access Grafana directory${NC}"
        return 1
    }
    
    # Prompt for Grafana configuration
    if [ "$DRY_RUN" = false ]; then
        read -p "Enter port to expose Grafana (default: 3000): " grafana_port
        grafana_port=${grafana_port:-3000}
        
        read -p "Enter Grafana admin password (default: admin): " grafana_admin_password
        grafana_admin_password=${grafana_admin_password:-admin}
        
        read -p "Enter organization name (default: Main Org.): " grafana_org_name
        grafana_org_name=${grafana_org_name:-"Main Org."}
    else
        grafana_port="3000"
        grafana_admin_password="admin"
        grafana_org_name="Main Org."
    fi
    
    # Create .env file for Grafana
    log "Creating Grafana .env file"
    if [ "$DRY_RUN" = false ]; then
        cat <<EOF > .env
# Grafana Configuration
GRAFANA_PORT=$grafana_port
GF_SECURITY_ADMIN_PASSWORD=$grafana_admin_password
GF_USERS_DEFAULT_ORG_NAME=$grafana_org_name

# Grafana Settings
GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource,grafana-worldmap-panel,grafana-piechart-panel
GF_USERS_ALLOW_SIGN_UP=false
GF_USERS_ALLOW_ORG_CREATE=false
GF_AUTH_ANONYMOUS_ENABLED=false

# Data persistence
GRAFANA_DATA_PATH=/var/lib/grafana
EOF
    else
        dry_run_log "Creating Grafana .env file" "cat > .env with Grafana configuration variables"
    fi
    
    # Create docker-compose.yml for Grafana
    log "Creating Grafana docker-compose.yml"
    if [ "$DRY_RUN" = false ]; then
        cat <<EOF > docker-compose.yml
version: '3.8'

services:
  grafana:
    image: grafana/grafana-enterprise:latest
    container_name: grafana
    restart: unless-stopped
    ports:
      - "\${GRAFANA_PORT}:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=\${GF_SECURITY_ADMIN_PASSWORD}
      - GF_USERS_DEFAULT_ORG_NAME=\${GF_USERS_DEFAULT_ORG_NAME}
      - GF_INSTALL_PLUGINS=\${GF_INSTALL_PLUGINS}
      - GF_USERS_ALLOW_SIGN_UP=\${GF_USERS_ALLOW_SIGN_UP}
      - GF_USERS_ALLOW_ORG_CREATE=\${GF_USERS_ALLOW_ORG_CREATE}
      - GF_AUTH_ANONYMOUS_ENABLED=\${GF_AUTH_ANONYMOUS_ENABLED}
    volumes:
      - grafana-storage:\${GRAFANA_DATA_PATH}
      - grafana-config:/etc/grafana
      - grafana-logs:/var/log/grafana
    networks:
      - grafana-network
    user: "472"  # grafana user

networks:
  grafana-network:
    driver: bridge

volumes:
  grafana-storage:
  grafana-config:
  grafana-logs:
EOF
    else
        dry_run_log "Creating Grafana docker-compose.yml" "cat > docker-compose.yml with Grafana service configuration"
    fi
    
    # Create README file with instructions
    log "Creating Grafana README file"
    if [ "$DRY_RUN" = false ]; then
        cat <<EOF > README.md
# Grafana Docker Setup

## Configuration
- **Port**: $grafana_port
- **Admin Password**: $grafana_admin_password
- **Organization**: $grafana_org_name

## Usage

### Start Grafana
\`\`\`bash
docker-compose up -d
\`\`\`

### Stop Grafana
\`\`\`bash
docker-compose down
\`\`\`

### View logs
\`\`\`bash
docker-compose logs -f
\`\`\`

### Access Grafana
- Web interface: http://localhost:$grafana_port
- Default login: **admin** / **$grafana_admin_password**

### Initial Setup
1. Access the web interface at http://localhost:$grafana_port
2. Login with username 'admin' and password '$grafana_admin_password'
3. Change the admin password if using default
4. Configure your first data source (Prometheus, InfluxDB, etc.)
5. Import or create dashboards

### Pre-installed Plugins
The following plugins are automatically installed:
- Clock Panel
- Simple JSON Datasource
- Worldmap Panel
- Pie Chart Panel

### Data Sources
Common data sources you can configure:
- **Prometheus**: For metrics from Prometheus server
- **InfluxDB**: For time series data
- **MySQL/PostgreSQL**: For relational database queries
- **Elasticsearch**: For log analysis
- **Zabbix**: Connect to your Zabbix monitoring system

### Data Persistence
Grafana data is stored in Docker volumes:
- Storage: grafana-storage (dashboards, users, etc.)
- Config: grafana-config (configuration files)
- Logs: grafana-logs (application logs)

### Troubleshooting
- Check container status: \`docker-compose ps\`
- View logs: \`docker-compose logs grafana\`
- Restart service: \`docker-compose restart grafana\`
- Access container: \`docker-compose exec grafana /bin/bash\`

### Security Notes
- Change default admin password immediately
- Configure proper authentication (LDAP, OAuth, etc.) for production
- Set up SSL/TLS for secure access
- Review user permissions and roles
EOF
    else
        dry_run_log "Creating Grafana README file" "cat > README.md with Grafana setup instructions"
    fi
    
    # Start Grafana using Docker Compose
    execute_command "Starting Grafana container" "docker-compose up -d"
    if [ $? -ne 0 ]; then
        log "Failed to start Grafana container" "ERROR"
        echo -e "${RED}Failed to start Grafana container. Check $LOG_FILE for details.${NC}"
        return 1
    fi
    
    log "Grafana installed successfully"
    echo -e "${GREEN}Grafana installed successfully${NC}"
    echo -e "${YELLOW}Configuration files saved to: $grafana_dir${NC}"
    echo -e "${YELLOW}Grafana web interface: http://localhost:$grafana_port${NC}"
    echo -e "${YELLOW}Default login: admin / $grafana_admin_password${NC}"
    
    return 0
}

# -------------------------------------------------------------------------
# MAIN EXECUTION FLOW
# -------------------------------------------------------------------------

# Function: main
# Purpose: Main execution flow that orchestrates the installation process
# Parameters:
#   $@ - All command line arguments
main() {
    # Parse command line arguments first to check for dry-run
    local install_components=()
    local has_install_args=false
    
    for arg in "$@"; do
        case $arg in
            --dry-run)
                DRY_RUN=true
                log "Running in DRY-RUN mode - no actual changes will be made"
                echo -e "${YELLOW}DRY-RUN MODE: Commands will be displayed but not executed${NC}"
                ;;
            --help)
                show_help
                ;;
            --all|--basic|--docker|--gitlab|--nginx|--redmine|--zabbix|--grafana)
                install_components+=("$arg")
                has_install_args=true
                ;;
            *)
                echo -e "${RED}Unknown option: $arg${NC}"
                show_help
                ;;
        esac
    done
    
    # Check for root privileges before proceeding (skip in dry-run mode)
    if [ "$DRY_RUN" = false ]; then
        check_root "$@"
    else
        log "Skipping root check in dry-run mode"
    fi
    
    # Parse command line arguments and execute appropriate functions
    if [ "$has_install_args" = false ]; then
        # Interactive mode - prompt for each component
        update_system
        
        if confirm "Install basic utilities?"; then
            install_basic
        fi
        
        if confirm "Install Docker?"; then
            install_docker
        fi
        
        if confirm "Install GitLab?"; then
            install_gitlab
        fi
        
        if confirm "Install Nginx?"; then
            install_nginx
        fi
        
        if confirm "Install Redmine?"; then
            install_redmine
        fi
        
        if confirm "Install Zabbix?"; then
            install_zabbix
        fi
        
        if confirm "Install Grafana?"; then
            install_grafana
        fi
    else
        # Command line mode - process arguments
        for arg in "$@"; do
            case $arg in
                --help)
                    # Show help and exit
                    show_help
                    ;;
                --all)
                    # Install all components
                    update_system
                    install_basic
                    install_docker
                    install_gitlab
                    install_nginx
                    install_redmine
                    install_zabbix
                    install_grafana
                    break
                    ;;
                --basic)
                    # Install basic utilities only
                    update_system
                    install_basic
                    ;;
                --docker)
                    # Install Docker only
                    update_system
                    install_docker
                    ;;
                --gitlab)
                    # Install GitLab only
                    update_system
                    install_gitlab
                    ;;
                --nginx)
                    # Install Nginx only
                    update_system
                    install_nginx
                    ;;
                --redmine)
                    # Install Redmine only
                    update_system
                    install_redmine
                    ;;
                --zabbix)
                    # Install Zabbix only
                    update_system
                    install_zabbix
                    ;;
                --grafana)
                    # Install Grafana only
                    update_system
                    install_grafana
                    ;;
                *)
                    # Handle unknown options
                    echo -e "${RED}Unknown option: $arg${NC}"
                    show_help
                    ;;
            esac
        done
    fi
    
    # Final completion message
    log "Installation completed"
    echo -e "${GREEN}Installation completed. Check $LOG_FILE for details.${NC}"
}

# -------------------------------------------------------------------------
# SCRIPT EXECUTION
# -------------------------------------------------------------------------

# Run main function with all command line arguments
main "$@"
