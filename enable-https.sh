#!/bin/bash
# Enable HTTPS for HexBuzz with Let's Encrypt
set -e

VPS_HOST="xserver_vps12_rmondo"
CADDY_FILE="/home/rmondo/repos/reverse-proxy/Caddyfile"
DOMAIN="${1:-}"

echo "=== HexBuzz HTTPS Setup ==="
echo ""

if [ -z "$DOMAIN" ]; then
    echo "❌ Error: Domain name required"
    echo ""
    echo "Usage: ./enable-https.sh DOMAIN"
    echo "Example: ./enable-https.sh hex-buzz.example.com"
    echo ""
    echo "Before running this script:"
    echo "1. Create DNS A record: DOMAIN → 85.131.251.195"
    echo "2. Wait for DNS propagation (test with: dig DOMAIN)"
    echo ""
    exit 1
fi

echo "📝 Using domain: $DOMAIN"
echo ""

# Check DNS resolution
echo "🔍 Checking DNS resolution..."
RESOLVED_IP=$(dig +short "$DOMAIN" @8.8.8.8 | tail -n1)
if [ "$RESOLVED_IP" != "85.131.251.195" ]; then
    echo "⚠️  Warning: DNS not pointing to VPS"
    echo "   Expected: 85.131.251.195"
    echo "   Got: $RESOLVED_IP"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "✓ DNS resolved correctly"
echo ""

# Backup current Caddyfile
echo "💾 Backing up Caddyfile..."
ssh "$VPS_HOST" "cp $CADDY_FILE ${CADDY_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
echo "✓ Backup created"
echo ""

# Create new Caddyfile with HTTPS
echo "📝 Updating Caddyfile for HTTPS..."
ssh "$VPS_HOST" "cat > $CADDY_FILE << 'EOFCADDY'
# Central Caddy Reverse Proxy - HTTPS Enabled

# HexBuzz with HTTPS
$DOMAIN {
    handle /hex_buzz* {
        uri strip_prefix /hex_buzz
        reverse_proxy host.docker.internal:8223
    }

    # Redirect root to hex_buzz
    handle / {
        redir /hex_buzz permanent
    }

    # Enable gzip compression
    encode gzip

    # Security headers
    header {
        X-Content-Type-Options \"nosniff\"
        X-Frame-Options \"SAMEORIGIN\"
        X-XSS-Protection \"1; mode=block\"
        Referrer-Policy \"strict-origin-when-cross-origin\"
        Strict-Transport-Security \"max-age=31536000; includeSubDomains; preload\"
        -Server
    }

    # Logging
    log {
        output stdout
        format console
    }
}

# Existing routes (HTTP only)
:80 {
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

    encode gzip

    header {
        X-Content-Type-Options \"nosniff\"
        X-Frame-Options \"SAMEORIGIN\"
        X-XSS-Protection \"1; mode=block\"
        Referrer-Policy \"strict-origin-when-cross-origin\"
        -Server
    }

    log {
        output stdout
        format console
    }
}
EOFCADDY"
echo "✓ Caddyfile updated"
echo ""

# Reload Caddy
echo "🔄 Reloading Caddy..."
CADDY_CONTAINER=$(ssh "$VPS_HOST" "docker ps | grep caddy | awk '{print \$NF}'")
if [ -z "$CADDY_CONTAINER" ]; then
    echo "❌ Error: Could not find Caddy container"
    exit 1
fi

ssh "$VPS_HOST" "docker exec $CADDY_CONTAINER caddy reload --config /etc/caddy/Caddyfile"
echo "✓ Caddy reloaded"
echo ""

# Wait for certificate provisioning
echo "⏳ Waiting for Let's Encrypt certificate provisioning (30 seconds)..."
sleep 30

# Test HTTPS endpoint
echo "🌐 Testing HTTPS endpoint..."
HTTPS_STATUS=$(curl -s -o /dev/null -w '%{http_code}' "https://$DOMAIN/hex_buzz" 2>/dev/null || echo "000")

if [ "$HTTPS_STATUS" = "200" ]; then
    echo "✅ HTTPS is working!"
    echo ""
    echo "🎉 Success! Your app is now available at:"
    echo "   https://$DOMAIN/hex_buzz"
    echo ""

    # Show certificate info
    echo "📜 Certificate information:"
    ssh "$VPS_HOST" "docker exec $CADDY_CONTAINER caddy list-modules | grep tls || echo 'Certificate info available in logs'"
    echo ""

    echo "📊 Next steps:"
    echo "1. Update your Flutter app to use HTTPS URL"
    echo "2. Redeploy: ./quick-deploy.sh"
    echo "3. Test in browser: https://$DOMAIN/hex_buzz"
    echo "4. Verify service worker loads correctly"
else
    echo "⚠️  Warning: HTTPS endpoint returned status $HTTPS_STATUS"
    echo ""
    echo "Troubleshooting:"
    echo "1. Check Caddy logs:"
    echo "   ssh $VPS_HOST 'docker logs $CADDY_CONTAINER --tail 50'"
    echo ""
    echo "2. Check port 443 is open:"
    echo "   nc -zv 85.131.251.195 443"
    echo ""
    echo "3. Check certificate provisioning:"
    echo "   ssh $VPS_HOST 'docker exec $CADDY_CONTAINER ls -la /data/caddy/certificates/'"
fi

echo ""
echo "📝 Certificate auto-renewal is handled by Caddy"
echo "📝 Caddyfile location: $CADDY_FILE"
