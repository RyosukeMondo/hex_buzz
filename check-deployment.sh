#!/bin/bash
# Check deployment status
set -e

VPS_HOST="xserver_vps12_rmondo"

echo "=== HexBuzz Deployment Status ==="
echo ""

echo "📦 Checking VPS files..."
ssh "$VPS_HOST" "ls -lh /home/rmondo/hex_buzz/index.html 2>/dev/null && echo '✓ Files deployed' || echo '✗ Files not found'"
echo ""

echo "🔧 Checking systemd service..."
ssh "$VPS_HOST" "sudo systemctl is-active hex-buzz && echo '✓ Service running' || echo '✗ Service not running'"
echo ""

echo "📊 Service status:"
ssh "$VPS_HOST" "sudo systemctl status hex-buzz --no-pager -n 5"
echo ""

echo "🌐 Checking web server response..."
ssh "$VPS_HOST" "curl -s -o /dev/null -w 'HTTP Status: %{http_code}\n' http://localhost:8223/ || echo '✗ Server not responding'"
echo ""

echo "🔀 Checking Caddy route..."
ssh "$VPS_HOST" "curl -s -o /dev/null -w 'HTTP Status: %{http_code}\n' http://localhost/hex_buzz || echo '✗ Caddy route not working'"
echo ""

echo "📝 Recent logs (last 10 lines):"
ssh "$VPS_HOST" "sudo journalctl -u hex-buzz -n 10 --no-pager"
