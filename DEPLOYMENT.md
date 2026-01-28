# HexBuzz Deployment Guide

## Overview
This guide covers deploying the HexBuzz Flutter web app to your VPS with Caddy reverse proxy.

## Architecture
```
Internet → Caddy (:80) → /hex_buzz → Python HTTP Server (:8223) → Flutter Web App
```

## Prerequisites
- Flutter SDK installed locally
- SSH access to VPS (xserver_vps12_rmondo)
- Caddy reverse proxy running on VPS
- Python 3 installed on VPS

## Quick Deployment

### Full Deployment (Build + Deploy + Configure Caddy)
```bash
./deploy.sh && ./update-caddy.sh
```

### Deploy Only (Without Caddy Update)
```bash
./deploy.sh
```

### Update Caddy Configuration Only
```bash
./update-caddy.sh
```

## Manual Deployment Steps

### 1. Build Flutter Web App
```bash
flutter build web --release --web-renderer canvaskit --base-href /hex_buzz/
```

### 2. Copy to VPS
```bash
rsync -avz --delete build/web/ xserver_vps12_rmondo:/home/rmondo/hex_buzz/
```

### 3. Start Web Server on VPS
```bash
ssh xserver_vps12_rmondo
cd /home/rmondo/hex_buzz
python3 -m http.server 8223
```

### 4. Configure Systemd Service
The deployment script automatically creates a systemd service. To manage it:

```bash
# Check status
ssh xserver_vps12_rmondo "sudo systemctl status hex-buzz"

# Start service
ssh xserver_vps12_rmondo "sudo systemctl start hex-buzz"

# Stop service
ssh xserver_vps12_rmondo "sudo systemctl stop hex-buzz"

# Restart service
ssh xserver_vps12_rmondo "sudo systemctl restart hex-buzz"

# View logs
ssh xserver_vps12_rmondo "sudo journalctl -u hex-buzz -f"
```

## Accessing the App
After deployment, the app will be accessible at:
- External: `http://YOUR_VPS_IP/hex_buzz`
- From VPS: `http://localhost/hex_buzz`

## Troubleshooting

### Service not starting
```bash
ssh xserver_vps12_rmondo "sudo journalctl -u hex-buzz -n 50"
```

### Port already in use
```bash
ssh xserver_vps12_rmondo "sudo lsof -i :8223"
```

### Caddy not routing correctly
```bash
# Check Caddy logs (if running in Docker)
ssh xserver_vps12_rmondo "docker logs <caddy-container-name>"

# Check Caddyfile syntax
ssh xserver_vps12_rmondo "caddy validate --config /home/rmondo/repos/reverse-proxy/Caddyfile"
```

### Clear Flutter web cache
If changes don't appear:
```bash
flutter clean
flutter pub get
flutter build web --release --web-renderer canvaskit --base-href /hex_buzz/
```

## Configuration Files

### Caddyfile Location
`/home/rmondo/repos/reverse-proxy/Caddyfile`

### Web Server Location
`/home/rmondo/hex_buzz/`

### Systemd Service
`/etc/systemd/system/hex-buzz.service`

## Rollback

### Restore Previous Caddyfile
```bash
ssh xserver_vps12_rmondo "ls -l /home/rmondo/repos/reverse-proxy/Caddyfile.backup.*"
ssh xserver_vps12_rmondo "cp /home/rmondo/repos/reverse-proxy/Caddyfile.backup.TIMESTAMP /home/rmondo/repos/reverse-proxy/Caddyfile"
# Then reload Caddy
```

## Security Notes
- The app runs on localhost:8223, not exposed directly to the internet
- Caddy handles SSL/TLS termination
- Security headers are configured in Caddyfile
- No authentication is configured by default

## Performance Optimization
- Flutter web renderer: CanvasKit (better rendering quality)
- Gzip compression enabled in Caddy
- Static files served efficiently by Python's http.server

## Monitoring
Monitor the service with:
```bash
# Real-time logs
ssh xserver_vps12_rmondo "sudo journalctl -u hex-buzz -f"

# Service status
ssh xserver_vps12_rmondo "sudo systemctl status hex-buzz"
```
