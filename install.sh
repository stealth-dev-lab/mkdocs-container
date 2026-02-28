#!/bin/sh
# mdvault installer
# https://github.com/stealth-dev-lab/mdvault
set -e

# Configuration
IMAGE="ghcr.io/stealth-dev-lab/mdvault:latest"
DOCKER_CONFIG_DIR="${HOME}/.config/mdvault"
QUADLET_DIR="${HOME}/.config/containers/systemd"

# Colors (disabled if not a terminal)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# Print functions
info() { printf "${BLUE}[INFO]${NC} %s\n" "$1"; }
success() { printf "${GREEN}[OK]${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$1"; }
error() { printf "${RED}[ERROR]${NC} %s\n" "$1" >&2; }

# Show usage
usage() {
    cat <<EOF
mdvault installer

Usage: $0 [OPTIONS]

Options:
    --uninstall    Remove mdvault
    --update       Pull latest image and restart
    --status       Show service status
    --help         Show this help message

Examples:
    $0                 # Interactive install
    $0 --update        # Update to latest version
    $0 --uninstall     # Remove mdvault
EOF
}

# Detect container engine
detect_engine() {
    has_docker=false
    has_podman=false

    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
        has_docker=true
    fi

    if command -v podman >/dev/null 2>&1; then
        has_podman=true
    fi

    if $has_docker && $has_podman; then
        echo "both"
    elif $has_docker; then
        echo "docker"
    elif $has_podman; then
        echo "podman"
    else
        echo "none"
    fi
}

# Let user select engine
select_engine() {
    printf "\n${BLUE}Both Docker and Podman are available.${NC}\n"
    printf "Select container engine:\n"
    printf "  1) Podman (with systemd integration)\n"
    printf "  2) Docker (with Docker Compose)\n"
    printf "Choice [1]: "
    read -r choice
    case "$choice" in
        2) echo "docker" ;;
        *) echo "podman" ;;
    esac
}

# Interactive configuration
configure() {
    printf "\n${BLUE}=== mdvault Configuration ===${NC}\n\n"

    # Source directory
    default_source="${HOME}/work"
    printf "Source directory to serve [${default_source}]: "
    read -r input_source
    MDVAULT_SOURCE="${input_source:-$default_source}"

    # Expand ~ to $HOME
    MDVAULT_SOURCE=$(echo "$MDVAULT_SOURCE" | sed "s|^~|$HOME|")

    # Validate directory
    if [ ! -d "$MDVAULT_SOURCE" ]; then
        warn "Directory '$MDVAULT_SOURCE' does not exist."
        printf "Create it? [Y/n]: "
        read -r create_dir
        case "$create_dir" in
            [Nn]*) error "Installation aborted."; exit 1 ;;
            *) mkdir -p "$MDVAULT_SOURCE"; success "Created $MDVAULT_SOURCE" ;;
        esac
    fi

    # Port
    default_port="3000"
    printf "Host port [${default_port}]: "
    read -r input_port
    MDVAULT_PORT="${input_port:-$default_port}"

    # Depth
    default_depth="3"
    printf "Directory depth limit [${default_depth}]: "
    read -r input_depth
    MDVAULT_DEPTH="${input_depth:-$default_depth}"

    printf "\n${BLUE}Configuration:${NC}\n"
    printf "  Source: %s\n" "$MDVAULT_SOURCE"
    printf "  Port:   %s\n" "$MDVAULT_PORT"
    printf "  Depth:  %s\n" "$MDVAULT_DEPTH"
    printf "\nProceed with installation? [Y/n]: "
    read -r confirm
    case "$confirm" in
        [Nn]*) error "Installation aborted."; exit 1 ;;
    esac
}

# Install for Podman (Quadlet)
install_podman() {
    info "Installing mdvault with Podman Quadlet..."

    # Create quadlet directory
    mkdir -p "$QUADLET_DIR"

    # Generate quadlet file with actual values
    cat > "${QUADLET_DIR}/mdvault.container" <<EOF
[Unit]
Description=mdvault - Markdown Documentation Server
After=network-online.target

[Container]
Image=${IMAGE}
PublishPort=${MDVAULT_PORT}:8000
Volume=${MDVAULT_SOURCE}:/source:ro,Z
Environment=MKDOCS_DEPTH=${MDVAULT_DEPTH}
Exec=serve --dev-addr=0.0.0.0:8000 --livereload
AutoUpdate=registry

[Service]
Restart=on-failure
TimeoutStartSec=300

[Install]
WantedBy=default.target
EOF

    success "Created ${QUADLET_DIR}/mdvault.container"

    # Pull image
    info "Pulling image..."
    podman pull "$IMAGE"

    # Reload systemd and start service
    info "Starting service..."
    systemctl --user daemon-reload
    systemctl --user enable --now mdvault.service

    success "mdvault installed successfully!"
    print_success
}

# Install for Docker (Compose)
install_docker() {
    info "Installing mdvault with Docker Compose..."

    # Create config directory
    mkdir -p "$DOCKER_CONFIG_DIR"

    # Generate docker-compose.yml
    cat > "${DOCKER_CONFIG_DIR}/docker-compose.yml" <<EOF
services:
  mdvault:
    image: ${IMAGE}
    container_name: mdvault
    restart: unless-stopped
    ports:
      - "${MDVAULT_PORT}:8000"
    volumes:
      - "${MDVAULT_SOURCE}:/source:ro"
    environment:
      - MKDOCS_DEPTH=${MDVAULT_DEPTH}
    command: serve --dev-addr=0.0.0.0:8000 --livereload
EOF

    success "Created ${DOCKER_CONFIG_DIR}/docker-compose.yml"

    # Generate .env file
    cat > "${DOCKER_CONFIG_DIR}/.env" <<EOF
# mdvault configuration
MDVAULT_SOURCE=${MDVAULT_SOURCE}
MDVAULT_PORT=${MDVAULT_PORT}
MDVAULT_DEPTH=${MDVAULT_DEPTH}
EOF

    success "Created ${DOCKER_CONFIG_DIR}/.env"

    # Pull image and start
    info "Pulling image..."
    docker pull "$IMAGE"

    info "Starting container..."
    docker compose -f "${DOCKER_CONFIG_DIR}/docker-compose.yml" up -d

    success "mdvault installed successfully!"
    print_success
}

# Print success message with URL
print_success() {
    printf "\n${GREEN}==================================${NC}\n"
    printf "${GREEN}  mdvault is running!${NC}\n"
    printf "${GREEN}==================================${NC}\n\n"
    printf "  URL: ${BLUE}http://localhost:${MDVAULT_PORT}/${NC}\n"
    printf "  Source: %s\n" "$MDVAULT_SOURCE"
    printf "\n"
    printf "Commands:\n"
    printf "  Update:    curl -fsSL https://raw.githubusercontent.com/stealth-dev-lab/mdvault/main/install.sh | sh -s -- --update\n"
    printf "  Status:    curl -fsSL https://raw.githubusercontent.com/stealth-dev-lab/mdvault/main/install.sh | sh -s -- --status\n"
    printf "  Uninstall: curl -fsSL https://raw.githubusercontent.com/stealth-dev-lab/mdvault/main/install.sh | sh -s -- --uninstall\n"
    printf "\n"
}

# Detect which installation exists
detect_installation() {
    if [ -f "${QUADLET_DIR}/mdvault.container" ]; then
        echo "podman"
    elif [ -f "${DOCKER_CONFIG_DIR}/docker-compose.yml" ]; then
        echo "docker"
    else
        echo "none"
    fi
}

# Uninstall
uninstall() {
    installation=$(detect_installation)

    case "$installation" in
        podman)
            info "Uninstalling mdvault (Podman)..."
            systemctl --user stop mdvault.service 2>/dev/null || true
            systemctl --user disable mdvault.service 2>/dev/null || true
            rm -f "${QUADLET_DIR}/mdvault.container"
            systemctl --user daemon-reload
            # Optionally remove image
            printf "Remove container image? [y/N]: "
            read -r remove_image
            case "$remove_image" in
                [Yy]*) podman rmi "$IMAGE" 2>/dev/null || true ;;
            esac
            success "mdvault uninstalled."
            ;;
        docker)
            info "Uninstalling mdvault (Docker)..."
            docker compose -f "${DOCKER_CONFIG_DIR}/docker-compose.yml" down 2>/dev/null || true
            rm -rf "$DOCKER_CONFIG_DIR"
            # Optionally remove image
            printf "Remove container image? [y/N]: "
            read -r remove_image
            case "$remove_image" in
                [Yy]*) docker rmi "$IMAGE" 2>/dev/null || true ;;
            esac
            success "mdvault uninstalled."
            ;;
        none)
            warn "mdvault is not installed."
            ;;
    esac
}

# Update
update() {
    installation=$(detect_installation)

    case "$installation" in
        podman)
            info "Updating mdvault (Podman)..."
            podman pull "$IMAGE"
            systemctl --user restart mdvault.service
            success "mdvault updated and restarted."
            ;;
        docker)
            info "Updating mdvault (Docker)..."
            docker pull "$IMAGE"
            docker compose -f "${DOCKER_CONFIG_DIR}/docker-compose.yml" up -d --force-recreate
            success "mdvault updated and restarted."
            ;;
        none)
            error "mdvault is not installed. Run install first."
            exit 1
            ;;
    esac
}

# Show status
status() {
    installation=$(detect_installation)

    case "$installation" in
        podman)
            info "mdvault status (Podman):"
            systemctl --user status mdvault.service --no-pager || true
            printf "\nContainer:\n"
            podman ps -a --filter name=systemd-mdvault --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || true
            ;;
        docker)
            info "mdvault status (Docker):"
            docker compose -f "${DOCKER_CONFIG_DIR}/docker-compose.yml" ps 2>/dev/null || true
            ;;
        none)
            warn "mdvault is not installed."
            ;;
    esac
}

# Main
main() {
    case "${1:-}" in
        --help|-h)
            usage
            exit 0
            ;;
        --uninstall)
            uninstall
            exit 0
            ;;
        --update)
            update
            exit 0
            ;;
        --status)
            status
            exit 0
            ;;
        "")
            # Install
            ;;
        *)
            error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac

    # Check if already installed
    installation=$(detect_installation)
    if [ "$installation" != "none" ]; then
        warn "mdvault is already installed (${installation})."
        printf "Reinstall? [y/N]: "
        read -r reinstall
        case "$reinstall" in
            [Yy]*)
                uninstall
                ;;
            *)
                info "Use --update to update the existing installation."
                exit 0
                ;;
        esac
    fi

    # Detect container engine
    engine=$(detect_engine)

    case "$engine" in
        none)
            error "Neither Docker nor Podman found."
            error "Please install Docker or Podman first."
            exit 1
            ;;
        both)
            engine=$(select_engine)
            ;;
    esac

    info "Using $engine"

    # Interactive configuration
    configure

    # Install
    case "$engine" in
        podman)
            install_podman
            ;;
        docker)
            install_docker
            ;;
    esac
}

main "$@"
