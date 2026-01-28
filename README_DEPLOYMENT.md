# 🚀 HexBuzz Deployment - Quick Start

## Current Status: 95% Complete ✅

Your HexBuzz Flutter web app has been deployed to your VPS. Everything is working except for one small Caddy configuration detail.

## What's Working ✅

- ✅ Flutter web app built and deployed
- ✅ Files on VPS at `/home/rmondo/hex_buzz/`
- ✅ Web server running on port 8223
- ✅ Systemd service `hex-buzz` active and auto-starting
- ✅ Caddy reverse proxy configured

## Final Step Required ⚠️

Run this one command to complete the setup:

```bash
./fix-caddy.sh
```

This fixes the path handling in Caddy so `/hex_buzz` routes correctly to your app.

## Then Access Your App 🌐

Once the fix is applied:

**http://85.131.251.195/hex_buzz**

## Available Commands

### Deployment
```bash
./quick-deploy.sh        # Full redeploy (build + deploy + configure)
./deploy.sh              # Deploy only (no Caddy changes)
./fix-caddy.sh          # Fix Caddy configuration
./check-deployment.sh    # Check status
```

### Service Management
```bash
# Check status
ssh xserver_vps12_rmondo "sudo systemctl status hex-buzz"

# Restart service
ssh xserver_vps12_rmondo "sudo systemctl restart hex-buzz"

# View logs
ssh xserver_vps12_rmondo "sudo journalctl -u hex-buzz -f"
```

## What Was Set Up

### VPS Architecture
```
Internet → Caddy (:80)
    ↓
/hex_buzz → host.docker.internal:8223
    ↓
Python HTTP Server → Flutter Web App
```

### Files Created
- `deploy.sh` - Main deployment script
- `update-caddy.sh` - Caddy configuration updater
- `fix-caddy.sh` - Caddy path fixing script
- `quick-deploy.sh` - One-command deployment
- `check-deployment.sh` - Status checker
- `DEPLOYMENT.md` - Full documentation
- `DEPLOYMENT_STATUS.md` - Current status

### VPS Configuration
- **App Location**: `/home/rmondo/hex_buzz/`
- **Service**: `/etc/systemd/system/hex-buzz.service`
- **Port**: 8223 (internal)
- **Caddy Config**: `/home/rmondo/repos/reverse-proxy/Caddyfile`

## Troubleshooting

If something doesn't work after running `./fix-caddy.sh`:

1. **Check if web server is running**
   ```bash
   ssh xserver_vps12_rmondo "curl http://localhost:8223"
   ```
   Should return HTML content

2. **Check Caddy logs**
   ```bash
   ssh xserver_vps12_rmondo "docker logs central-caddy --tail 50"
   ```

3. **Check service logs**
   ```bash
   ssh xserver_vps12_rmondo "sudo journalctl -u hex-buzz -n 50"
   ```

4. **Full status check**
   ```bash
   ./check-deployment.sh
   ```

## Next Deployment

After making code changes, simply run:
```bash
./quick-deploy.sh
```

This will rebuild and redeploy your app while preserving the Caddy configuration.

## Documentation

See `DEPLOYMENT.md` for detailed documentation including:
- Manual deployment steps
- Advanced configuration
- Security notes
- Performance optimization
- Rollback procedures
