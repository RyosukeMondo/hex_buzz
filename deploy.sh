#!/bin/bash
# HexBuzz Web Deployment Script
set -e

echo "=== HexBuzz Deployment ==="

# Configuration
VPS_HOST="xserver_vps12_rmondo"
VPS_DEPLOY_PATH="/home/rmondo/hex_buzz"
VPS_PORT=8223
BUILD_DIR="build/web"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Step 1: Building Flutter web app...${NC}"
flutter build web --release --base-href /hex_buzz/

if [ ! -d "$BUILD_DIR" ]; then
    echo "Error: Build directory not found at $BUILD_DIR"
    exit 1
fi

echo -e "${GREEN}✓ Build completed${NC}"

echo -e "${BLUE}Step 2: Preparing VPS deployment directory...${NC}"
ssh "$VPS_HOST" "mkdir -p $VPS_DEPLOY_PATH"

echo -e "${GREEN}✓ VPS directory ready${NC}"

echo -e "${BLUE}Step 3: Copying build files to VPS...${NC}"
rsync -avz --delete "$BUILD_DIR/" "$VPS_HOST:$VPS_DEPLOY_PATH/"

echo -e "${GREEN}✓ Files copied${NC}"

echo -e "${BLUE}Step 4: Setting up web server...${NC}"

# Create a simple HTTP server script on VPS
ssh "$VPS_HOST" "cat > $VPS_DEPLOY_PATH/serve.sh << 'EOFSERVER'
#!/bin/bash
cd /home/rmondo/hex_buzz
python3 -m http.server 8223
EOFSERVER"

ssh "$VPS_HOST" "chmod +x $VPS_DEPLOY_PATH/serve.sh"

echo -e "${GREEN}✓ Web server script created${NC}"

echo -e "${BLUE}Step 5: Setting up systemd service...${NC}"

# Create systemd service
ssh "$VPS_HOST" "sudo tee /etc/systemd/system/hex-buzz.service > /dev/null << 'EOFSERVICE'
[Unit]
Description=HexBuzz Web Server
After=network.target

[Service]
Type=simple
User=rmondo
WorkingDirectory=/home/rmondo/hex_buzz
ExecStart=/usr/bin/python3 -m http.server 8223
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOFSERVICE"

# Reload systemd and start service
ssh "$VPS_HOST" "sudo systemctl daemon-reload && sudo systemctl enable hex-buzz && sudo systemctl restart hex-buzz"

echo -e "${GREEN}✓ Systemd service configured and started${NC}"

echo -e "${BLUE}Step 6: Checking service status...${NC}"
ssh "$VPS_HOST" "sudo systemctl status hex-buzz --no-pager" || true

echo -e "${GREEN}=== Deployment Complete! ===${NC}"
echo ""
echo "The app is now running on the VPS at port $VPS_PORT"
echo "Next step: Update Caddyfile to add the /hex_buzz route"
echo ""
echo "Run './update-caddy.sh' to configure the reverse proxy"
