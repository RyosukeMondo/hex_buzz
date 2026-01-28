#!/bin/bash

# Claude-Flow Daemon Manager
# Helps setup and manage claude-flow daemon in different modes

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CLAUDE_FLOW_ROOT="$PROJECT_ROOT/.claude-flow"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

check_node_version() {
    if ! command -v node &> /dev/null; then
        print_error "Node.js is not installed"
        exit 1
    fi

    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 18 ]; then
        print_error "Node.js version must be >= 18 (current: $NODE_VERSION)"
        exit 1
    fi

    print_success "Node.js $(node -v) detected"
}

check_mcp_installed() {
    if claude mcp list 2>/dev/null | grep -q "claude-flow"; then
        return 0
    else
        return 1
    fi
}

install_mcp_server() {
    print_header "Installing MCP Server (Project-Specific)"

    check_node_version

    print_info "This will add claude-flow as an MCP server to Claude Code"
    print_info "The server will start automatically with Claude Code"
    echo

    read -p "Continue? (y/n): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Installing MCP server..."

        cd "$CLAUDE_FLOW_ROOT"

        # Install using Claude CLI
        if command -v claude &> /dev/null; then
            claude mcp add claude-flow -- npx -y claude-flow@v3alpha mcp start
            print_success "MCP server installed!"
        else
            print_error "Claude CLI not found. Please install Claude Code first."
            exit 1
        fi

        echo
        print_success "MCP Server Setup Complete!"
        print_info "The server will start automatically when you launch Claude Code"
        print_info ""
        print_info "Verify installation:"
        print_info "  claude mcp list"
        print_info ""
        print_info "Usage in Claude Code:"
        print_info '  "Use the architect agent to review my code"'
    fi
}

install_pm2_service() {
    print_header "Installing PM2 Service (System-Wide)"

    check_node_version

    print_info "This will install claude-flow as a system-wide PM2 service"
    print_info "The daemon will run continuously and serve all projects"
    echo

    read -p "Continue? (y/n): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Check if PM2 is installed
        if ! command -v pm2 &> /dev/null; then
            print_info "Installing PM2..."
            npm install -g pm2
        fi

        print_success "PM2 installed"

        # Install claude-flow globally
        print_info "Installing claude-flow globally..."
        npm install -g claude-flow@v3alpha

        print_success "claude-flow installed globally"

        # Create ecosystem config
        ECOSYSTEM_FILE="$HOME/.claude-flow-ecosystem.config.js"

        print_info "Creating PM2 ecosystem config..."

        cat > "$ECOSYSTEM_FILE" <<EOF
module.exports = {
  apps: [{
    name: 'claude-flow',
    script: 'claude-flow',
    args: 'daemon start --port 3000 --config $CLAUDE_FLOW_ROOT/config/claude-flow.yaml',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '2G',
    env: {
      NODE_ENV: 'production',
      CLAUDE_FLOW_PROJECT_ROOT: '$PROJECT_ROOT',
      CLAUDE_FLOW_CONFIG: '$CLAUDE_FLOW_ROOT/config/claude-flow.yaml',
      CLAUDE_FLOW_VECTOR_STORE: '$CLAUDE_FLOW_ROOT/vector_store'
    },
    error_file: '$CLAUDE_FLOW_ROOT/logs/pm2-error.log',
    out_file: '$CLAUDE_FLOW_ROOT/logs/pm2-out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
  }]
};
EOF

        print_success "Ecosystem config created: $ECOSYSTEM_FILE"

        # Create logs directory
        mkdir -p "$CLAUDE_FLOW_ROOT/logs"

        # Start service
        print_info "Starting PM2 service..."
        pm2 start "$ECOSYSTEM_FILE"

        # Save PM2 configuration
        pm2 save

        # Setup startup script
        print_info "Configuring auto-start on boot..."
        pm2 startup | tail -n 1 | bash || print_warning "Could not setup auto-start (may need sudo)"

        echo
        print_success "PM2 Service Setup Complete!"
        print_info ""
        print_info "Service status:"
        pm2 status claude-flow
        print_info ""
        print_info "Useful commands:"
        print_info "  pm2 status claude-flow    - Check status"
        print_info "  pm2 logs claude-flow       - View logs"
        print_info "  pm2 restart claude-flow    - Restart"
        print_info "  pm2 stop claude-flow       - Stop"
        print_info "  pm2 monit                  - Monitor"
        print_info ""
        print_info "Health check:"
        print_info "  curl http://localhost:3000/health"
    fi
}

install_systemd_service() {
    print_header "Installing systemd Service (System-Wide)"

    check_node_version

    if [ "$EUID" -eq 0 ]; then
        print_error "Do not run this script as root. We'll use sudo when needed."
        exit 1
    fi

    print_info "This will install claude-flow as a systemd service"
    print_info "Requires sudo privileges"
    echo

    read -p "Continue? (y/n): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Install claude-flow globally
        print_info "Installing claude-flow globally..."
        npm install -g claude-flow@v3alpha

        print_success "claude-flow installed globally"

        # Create systemd service file
        SERVICE_FILE="/tmp/claude-flow.service"

        print_info "Creating systemd service file..."

        cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Claude-Flow Multi-Agent Orchestration Platform
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$CLAUDE_FLOW_ROOT
ExecStart=$(which node) $(which claude-flow) daemon start --port 3000 --config $CLAUDE_FLOW_ROOT/config/claude-flow.yaml
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal
Environment="NODE_ENV=production"
Environment="CLAUDE_FLOW_PROJECT_ROOT=$PROJECT_ROOT"
Environment="CLAUDE_FLOW_CONFIG=$CLAUDE_FLOW_ROOT/config/claude-flow.yaml"
Environment="CLAUDE_FLOW_VECTOR_STORE=$CLAUDE_FLOW_ROOT/vector_store"

[Install]
WantedBy=multi-user.target
EOF

        print_success "Service file created"

        # Install service
        print_info "Installing service (requires sudo)..."
        sudo cp "$SERVICE_FILE" /etc/systemd/system/claude-flow.service
        sudo systemctl daemon-reload

        # Enable and start
        print_info "Enabling and starting service..."
        sudo systemctl enable claude-flow
        sudo systemctl start claude-flow

        # Wait a moment for service to start
        sleep 2

        # Check status
        if sudo systemctl is-active --quiet claude-flow; then
            print_success "Service is running!"
        else
            print_error "Service failed to start. Check logs with: sudo journalctl -u claude-flow -n 50"
            exit 1
        fi

        echo
        print_success "systemd Service Setup Complete!"
        print_info ""
        print_info "Service status:"
        sudo systemctl status claude-flow --no-pager
        print_info ""
        print_info "Useful commands:"
        print_info "  sudo systemctl status claude-flow     - Check status"
        print_info "  sudo systemctl restart claude-flow    - Restart"
        print_info "  sudo systemctl stop claude-flow       - Stop"
        print_info "  sudo journalctl -u claude-flow -f     - View logs"
        print_info ""
        print_info "Health check:"
        print_info "  curl http://localhost:3000/health"

        # Cleanup
        rm "$SERVICE_FILE"
    fi
}

check_status() {
    print_header "Claude-Flow Status"

    # Check MCP Server
    echo -e "${BLUE}MCP Server (Project-Specific):${NC}"
    if check_mcp_installed; then
        print_success "Installed"
        claude mcp list | grep claude-flow || true
    else
        print_warning "Not installed"
    fi
    echo

    # Check PM2 Service
    echo -e "${BLUE}PM2 Service (System-Wide):${NC}"
    if command -v pm2 &> /dev/null; then
        if pm2 list | grep -q claude-flow; then
            print_success "Running"
            pm2 describe claude-flow 2>/dev/null | grep -E "(status|uptime|memory)" || true
        else
            print_warning "Not running"
        fi
    else
        print_warning "PM2 not installed"
    fi
    echo

    # Check systemd Service
    echo -e "${BLUE}systemd Service (System-Wide):${NC}"
    if systemctl list-unit-files | grep -q claude-flow.service; then
        if sudo systemctl is-active --quiet claude-flow; then
            print_success "Running"
            sudo systemctl status claude-flow --no-pager | grep -E "(Active|Main PID)" || true
        else
            print_warning "Not running"
        fi
    else
        print_warning "Not installed"
    fi
    echo

    # Check if daemon is responding
    echo -e "${BLUE}Daemon Health Check:${NC}"
    if curl -s http://localhost:3000/health &> /dev/null; then
        print_success "Daemon responding on port 3000"
        curl -s http://localhost:3000/health | jq . 2>/dev/null || cat
    else
        print_warning "No daemon responding on port 3000"
    fi
}

uninstall_all() {
    print_header "Uninstalling Claude-Flow"

    print_warning "This will remove all claude-flow installations"
    echo
    read -p "Are you sure? (y/n): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Remove MCP Server
        if check_mcp_installed; then
            print_info "Removing MCP server..."
            claude mcp remove claude-flow
            print_success "MCP server removed"
        fi

        # Stop and remove PM2 service
        if command -v pm2 &> /dev/null && pm2 list | grep -q claude-flow; then
            print_info "Stopping PM2 service..."
            pm2 delete claude-flow
            pm2 save
            print_success "PM2 service removed"
        fi

        # Stop and remove systemd service
        if systemctl list-unit-files | grep -q claude-flow.service; then
            print_info "Stopping systemd service..."
            sudo systemctl stop claude-flow
            sudo systemctl disable claude-flow
            sudo rm /etc/systemd/system/claude-flow.service
            sudo systemctl daemon-reload
            print_success "systemd service removed"
        fi

        # Optionally remove global installation
        read -p "Remove global claude-flow installation? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            npm uninstall -g claude-flow
            print_success "Global installation removed"
        fi

        print_success "Uninstallation complete!"
    fi
}

show_menu() {
    clear
    print_header "Claude-Flow Daemon Manager"

    echo "Choose daemon mode:"
    echo
    echo "  1) MCP Server (Project-Specific) ⭐ RECOMMENDED"
    echo "     - Auto-managed by Claude Code"
    echo "     - Project-specific configuration"
    echo "     - Zero maintenance"
    echo
    echo "  2) PM2 Service (System-Wide)"
    echo "     - Always running daemon"
    echo "     - Serves multiple projects"
    echo "     - Easy to monitor and manage"
    echo
    echo "  3) systemd Service (System-Wide)"
    echo "     - Native Linux service"
    echo "     - System integration"
    echo "     - Best for production servers"
    echo
    echo "  4) Check Status"
    echo "  5) Uninstall All"
    echo "  6) Exit"
    echo
    read -p "Select option (1-6): " choice

    case $choice in
        1) install_mcp_server ;;
        2) install_pm2_service ;;
        3) install_systemd_service ;;
        4) check_status ;;
        5) uninstall_all ;;
        6) exit 0 ;;
        *)
            print_error "Invalid option"
            sleep 2
            show_menu
            ;;
    esac

    echo
    read -p "Press Enter to continue..."
    show_menu
}

# Main execution
if [ $# -eq 0 ]; then
    show_menu
else
    case "$1" in
        mcp) install_mcp_server ;;
        pm2) install_pm2_service ;;
        systemd) install_systemd_service ;;
        status) check_status ;;
        uninstall) uninstall_all ;;
        *)
            echo "Usage: $0 [mcp|pm2|systemd|status|uninstall]"
            exit 1
            ;;
    esac
fi
