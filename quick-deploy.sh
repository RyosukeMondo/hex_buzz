#!/bin/bash
# Quick one-command deployment
set -e

echo "🚀 Starting HexBuzz deployment..."
echo ""

./deploy.sh
echo ""
./update-caddy.sh

echo ""
echo "✅ Deployment complete!"
echo ""
echo "🌐 Access your app at: http://YOUR_VPS_IP/hex_buzz"
echo ""
echo "📊 To check logs: ssh xserver_vps12_rmondo 'sudo journalctl -u hex-buzz -f'"
