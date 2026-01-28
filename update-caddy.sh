#!/bin/bash
# Update Caddy configuration to add HexBuzz route
set -e

VPS_HOST="xserver_vps12_rmondo"
CADDY_FILE="/home/rmondo/repos/reverse-proxy/Caddyfile"

echo "=== Updating Caddy Configuration ==="

# Backup current Caddyfile
ssh "$VPS_HOST" "cp $CADDY_FILE ${CADDY_FILE}.backup.$(date +%Y%m%d_%H%M%S)"

# Check if HTTPS is already configured
if ssh "$VPS_HOST" "grep -q 'mondo-ai-studio.xvps.jp' $CADDY_FILE"; then
    echo "✓ HTTPS configuration detected, skipping update"
    echo "  (Caddyfile already configured for HTTPS)"
    echo ""
    echo "If you need to update the configuration, edit:"
    echo "  $CADDY_FILE"
    echo ""
    echo "Then reload with:"
    echo "  ssh $VPS_HOST 'docker exec central-caddy caddy reload --config /etc/caddy/Caddyfile'"
    exit 0
fi

# Read current Caddyfile and add hex_buzz route (HTTP only)
ssh "$VPS_HOST" "cat > $CADDY_FILE << 'EOFCADDY'
# Central Caddy Reverse Proxy

:80 {
    # /hex_buzz route - HexBuzz game
    handle /hex_buzz* {
        uri strip_prefix /hex_buzz
        reverse_proxy host.docker.internal:8223
    }

    # /home route - proxy to chisel tunnel (Windows PC port 8222)
    handle /home* {
        reverse_proxy host.docker.internal:8222
    }

    # /fab-forward-sales - proxy to Next.js app
    handle /fab-forward-sales* {
        reverse_proxy fab-forward-app:3000
    }

    # Root path redirect to /fab-forward-sales
    redir / /fab-forward-sales permanent

    # Enable gzip compression
    encode gzip

    # Security headers
    header {
        X-Content-Type-Options \"nosniff\"
        X-Frame-Options \"SAMEORIGIN\"
        X-XSS-Protection \"1; mode=block\"
        Referrer-Policy \"strict-origin-when-cross-origin\"
        -Server
    }

    # Logging
    log {
        output stdout
        format console
    }
}
EOFCADDY"

echo "✓ Caddyfile updated"

# Check if Caddy is running in Docker
echo "Reloading Caddy configuration..."
if ssh "$VPS_HOST" "docker ps | grep -q caddy"; then
    echo "Detected Caddy running in Docker"
    # Get container name/id
    CADDY_CONTAINER=$(ssh "$VPS_HOST" "docker ps | grep caddy | awk '{print \$1}'")
    if [ -n "$CADDY_CONTAINER" ]; then
        ssh "$VPS_HOST" "docker exec $CADDY_CONTAINER caddy reload --config /etc/caddy/Caddyfile"
        echo "✓ Caddy reloaded in Docker"
    else
        echo "Warning: Could not find Caddy container"
    fi
elif ssh "$VPS_HOST" "systemctl is-active --quiet caddy"; then
    echo "Detected Caddy running as systemd service"
    ssh "$VPS_HOST" "sudo systemctl reload caddy"
    echo "✓ Caddy service reloaded"
else
    echo "Warning: Could not detect how Caddy is running"
    echo "You may need to manually reload Caddy"
fi

echo ""
echo "=== Configuration Complete ==="
echo ""
echo "Your HexBuzz app should now be accessible at:"
echo "http://YOUR_VPS_IP/hex_buzz"
echo ""
echo "To test: curl http://localhost/hex_buzz (on VPS)"
