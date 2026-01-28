#!/bin/bash
# Fix Caddy configuration for Docker networking
set -e

VPS_HOST="xserver_vps12_rmondo"
CADDY_FILE="/home/rmondo/repos/reverse-proxy/Caddyfile"

echo "=== Fixing Caddy Configuration for Docker ==="

# Backup current Caddyfile
ssh "$VPS_HOST" "cp $CADDY_FILE ${CADDY_FILE}.backup.$(date +%Y%m%d_%H%M%S)"

# Update Caddyfile with host.docker.internal
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

echo "✓ Caddyfile updated with Docker networking"

# Reload Caddy
echo "Reloading Caddy..."
CADDY_CONTAINER=$(ssh "$VPS_HOST" "docker ps | grep caddy | awk '{print \$NF}'")
if [ -n "$CADDY_CONTAINER" ]; then
    ssh "$VPS_HOST" "docker exec $CADDY_CONTAINER caddy reload --config /etc/caddy/Caddyfile"
    echo "✓ Caddy reloaded"
else
    echo "✗ Could not find Caddy container"
    exit 1
fi

echo ""
echo "=== Testing the endpoint ==="
ssh "$VPS_HOST" "curl -s -o /dev/null -w 'HTTP Status: %{http_code}\n' http://localhost/hex_buzz"

echo ""
echo "✅ Configuration fixed!"
